on [mistrals-api-console](https://console.mistral.ai) create an agent with no tools and the following settings
Model: Mistral Medium
Temperature: 0.7
Max Tokens: 2048
top_p: 1
Response Format: Text

put the prompt in the instructions field then click deploy and copy the agent id and also get your api key from the api console

- move the `.env.example` to `~/.config/nvim/.env` and put the api key in it
- move the `mistral_fix.lua` to `~/.config/nvim/lua/mistral_fix.lua`
- then put this in init.lua
```lua
require("mistral_fix").setup({
	agent_id = "your-agent-id",
})
```
