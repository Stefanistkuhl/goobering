local M = {}

local function read_token()
	local env_path = vim.fn.expand("~/.config/nvim/.env")
	if vim.fn.filereadable(env_path) == 0 then
		return nil, "Token file not found: " .. env_path
	end
	local lines = vim.fn.readfile(env_path)
	if not lines or #lines == 0 then
		return nil, "Token file is empty"
	end
	local content = table.concat(lines, "\n")
	content = content:gsub("^%s+", ""):gsub("%s+$", "")

	if content:find("=") then
		local token
		for _, line in ipairs(lines) do
			local s = line:gsub("^%s+", ""):gsub("%s+$", "")
			local k, v = s:match("^([%w_%-]+)%s*=%s*(.+)$")
			if k and v then
				if k == "MISTRAL_API_KEY" or k == "API_KEY" or k == "TOKEN" then
					token = v:gsub("^%s+", ""):gsub("%s+$", "")
					break
				end
			end
		end
		if token and #token > 0 then
			return token
		else
			for i = #lines, 1, -1 do
				local s = lines[i]:gsub("^%s+", ""):gsub("%s+$", "")
				if #s > 0 and not s:find("=") then
					return s
				end
			end
			local v = content:match("=%s*(.+)$")
			if v then
				v = v:gsub("^%s+", ""):gsub("%s+$", "")
				if #v > 0 then
					return v
				end
			end
			return nil, "Could not extract token from .env"
		end
	else
		return content
	end
end

local function extract_typst_block(text)
	local code = text:match("```typst%s*\n(.-)\n```")
	if code then
		return code
	end
	code = text:match("```%w*%s*\n(.-)\n```")
	if code then
		return code
	end
	return text
end

local function get_visual_selection()
	local buf = vim.api.nvim_get_current_buf()

	local srow, scol = unpack(vim.api.nvim_buf_get_mark(buf, "<"))
	local erow, ecol = unpack(vim.api.nvim_buf_get_mark(buf, ">"))

	if srow == 0 or erow == 0 then
		return "", { buf = buf, srow = 0, scol = 0, erow = 0, ecol = 0, mode = "v" }
	end

	if srow > erow or (srow == erow and scol > ecol) then
		srow, erow = erow, srow
		scol, ecol = ecol, scol
	end

	local srow0 = srow - 1
	local erow0 = erow - 1

	local vmode = vim.fn.visualmode()

	local lines = vim.api.nvim_buf_get_lines(buf, srow0, erow0 + 1, false)
	if #lines == 0 then
		return "", { buf = buf, srow = srow0, scol = scol, erow = erow0, ecol = ecol, mode = vmode }
	end

	local function clamp_col(line, col)
		if col < 0 then
			return 0
		end
		local len = #line
		if col > len then
			return len
		end
		return col
	end
	scol = clamp_col(lines[1], scol)
	ecol = clamp_col(lines[#lines], ecol)

	if vmode == "V" then
		scol = 0
		ecol = #lines[#lines]
	end

	local sel_lines = vim.deepcopy(lines)
	if #sel_lines == 1 then
		sel_lines[1] = string.sub(sel_lines[1], scol + 1, ecol)
	else
		sel_lines[1] = string.sub(sel_lines[1], scol + 1)
		sel_lines[#sel_lines] = string.sub(sel_lines[#sel_lines], 1, ecol)
	end
	local text = table.concat(sel_lines, "\n")

	return text, { buf = buf, srow = srow0, scol = scol, erow = erow0, ecol = ecol, mode = vmode }
end

local function replace_range_with_text(range, new_text)
	local buf = range.buf
	local srow, scol, erow, ecol = range.srow, range.scol, range.erow, range.ecol

	local new_lines = {}
	for line in (new_text .. "\n"):gmatch("([^\n]*)\n") do
		table.insert(new_lines, line)
	end

	if #new_lines == 0 then
		new_lines = { "" }
	end

	if srow == erow then
		vim.api.nvim_buf_set_text(buf, srow, scol, erow, ecol, new_lines)
		return
	end

	local lines = vim.api.nvim_buf_get_lines(buf, srow, erow + 1, false)
	if #lines == 0 then
		vim.api.nvim_buf_set_lines(buf, srow, srow, false, new_lines)
		return
	end

	local function clamp_col(line, col)
		if col < 0 then
			return 0
		end
		local len = #line
		if col > len then
			return len
		end
		return col
	end
	local head = lines[1]
	local tail = lines[#lines]
	local head_keep = string.sub(head, 1, clamp_col(head, scol))
	local tail_keep = string.sub(tail, clamp_col(tail, ecol) + 1)

	local out = vim.deepcopy(new_lines)
	out[1] = head_keep .. out[1]
	out[#out] = out[#out] .. tail_keep

	vim.api.nvim_buf_set_lines(buf, srow, erow + 1, false, out)
end

local function json_encode(tbl)
	return vim.json.encode(tbl)
end

local function json_decode(str)
	local ok, res = pcall(vim.json.decode, str)
	if ok then
		return res
	end
	return nil, "JSON decode failed"
end

local function xhr_mistral(token, payload_tbl)
	local payload = json_encode(payload_tbl)
	local res = vim.system({
		"curl",
		"--silent",
		"--show-error",
		"--location",
		"https://api.mistral.ai/v1/conversations",
		"--header",
		"Content-Type: application/json",
		"--header",
		"Accept: application/json",
		"--header",
		"Authorization: Bearer " .. token,
		"--data-binary",
		"@-",
	}, { stdin = payload, text = true }):wait()

	if res.code ~= 0 then
		return nil, string.format("curl failed (exit %d): %s", res.code, res.stderr or "")
	end

	local obj, err = json_decode(res.stdout)
	if not obj then
		return nil, err or "invalid JSON"
	end
	return obj
end

function M.replace_visual_with_mistral(opts)
	opts = opts or {}
	local agent_id = opts.agent_id or "ag:a1053bd4:20251014:i-love-spelling:814f38c9"

	local selection, range = get_visual_selection()
	if selection == "" then
		vim.notify("No visual selection detected", vim.log.levels.WARN)
		return
	end

	local token, err = read_token()
	if not token then
		vim.notify("Token error: " .. err, vim.log.levels.ERROR)
		return
	end

	local payload = {
		inputs = selection,
		stream = false,
		agent_id = agent_id,
	}

	local obj, e = xhr_mistral(token, payload)
	if not obj then
		vim.notify("Request failed: " .. e, vim.log.levels.ERROR)
		return
	end

	local content = ""
	if obj.outputs and obj.outputs[1] and obj.outputs[1].content then
		content = obj.outputs[1].content
	end
	if content == "" then
		vim.notify("Empty response content from API", vim.log.levels.WARN)
		return
	end

	local extracted = extract_typst_block(content)
	replace_range_with_text(range, extracted)
	vim.notify("Replaced selection with Mistral response (typst block).", vim.log.levels.INFO)
end

function M.setup(opts)
	opts = opts or {}
	vim.api.nvim_create_user_command("MistralReplaceVisual", function()
		M.replace_visual_with_mistral(opts)
	end, { range = true })

	vim.keymap.set("x", "<leader>mr", function()
		M.replace_visual_with_mistral(opts)
	end, { desc = "Send visual selection to Mistral and replace with typst content" })
end

return M
