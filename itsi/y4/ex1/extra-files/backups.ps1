# Requires -Version 5.1
$ErrorActionPreference = 'Stop'

# ---------------- CONFIG ----------------
$IncomingDir   = "D:\app\data"           # Encrypted .gpg dumps arrive here
$BackupRoot    = "D:\app\backups"
$ArchiveDir    = Join-Path $BackupRoot "archive"

$Generations   = 5    # number of live backup dirs to keep
$ArchivesKeep  = 20   # number of old zipped archives to keep

# Logging
$EventLogName   = "Application"
$PrimarySource  = "PostgresDumpCollector"
$FallbackSource = "Windows PowerShell"
$TranscriptDir  = "C:\Scripts\logs"
# ----------------------------------------

# Ensure required folders exist
New-Item -ItemType Directory -Force -Path $BackupRoot, $ArchiveDir, $TranscriptDir | Out-Null

# Transcript for debugging
$RunID = Get-Date -Format "yyyyMMdd_HHmmss"
Start-Transcript -Path (Join-Path $TranscriptDir "pg_collector_$RunID.log") -Force | Out-Null

# Prepare event log source
$script:Source = $PrimarySource
try
{
	if (-not [System.Diagnostics.EventLog]::SourceExists($PrimarySource))
	{
		New-EventLog -LogName $EventLogName -Source $PrimarySource
	}
} catch
{
	$script:Source = $FallbackSource
}

function Log-Info
{ param($id, $msg)
	Write-EventLog -LogName $EventLogName -Source $script:Source `
		-EntryType Information -EventId $id -Message $msg
}
function Log-Error
{ param($id, $msg)
	Write-EventLog -LogName $EventLogName -Source $script:Source `
		-EntryType Error -EventId $id -Message $msg
}

try
{
	$Stamp  = Get-Date -Format "yyyyMMdd-HHmmss"
	$RunDir = Join-Path $BackupRoot ("backup-" + $Stamp)
	New-Item -ItemType Directory -Path $RunDir -Force | Out-Null
	Log-Info 1000 "Starting collection run. Destination: $RunDir"

	# Collect only encrypted .gpg backups
	$files = Get-ChildItem -Path $IncomingDir -File -Filter *.gpg
	if (-not $files)
	{
		Log-Info 1001 "No new .gpg backup files found in $IncomingDir"
	} else
	{
		$manifest = [System.Collections.Generic.List[object]]::new()
		foreach ($f in $files)
		{
			try
			{
				$target = Join-Path $RunDir $f.Name
				Move-Item -Path $f.FullName -Destination $target -Force
				$hash = (Get-FileHash -Algorithm SHA256 $target).Hash
				$manifest.Add([PSCustomObject]@{
						File      = $f.Name
						SizeBytes = (Get-Item $target).Length
						SHA256    = $hash
					})
				Log-Info 1002 "Moved $($f.FullName) -> $target"
			} catch
			{
				Log-Error 2100 "Failed to move $($f.FullName): $($_.Exception.Message)"
			}
		}

		# Create manifest + checksums
		$manifestPath  = Join-Path $RunDir "manifest.json"
		$checksumPath  = Join-Path $RunDir "checksums.sha256"
		$manifest | ConvertTo-Json -Depth 3 | Set-Content $manifestPath
		($manifest | ForEach-Object { "$($_.SHA256)  $($_.File)" }) | Set-Content $checksumPath
		Log-Info 1003 "Manifest and checksums written for $($manifest.Count) .gpg file(s)"
	}

	# --- Retention and archiving logic ---
	$Backups = Get-ChildItem -Path $BackupRoot -Directory |
		Where-Object { $_.Name -like 'backup-*' } |
		Sort-Object Name -Descending

	if ($Backups.Count -gt $Generations)
	{
		$Old = $Backups | Select-Object -Skip $Generations
		foreach ($B in $Old)
		{
			try
			{
				$zipDest = Join-Path $ArchiveDir ("{0}.zip" -f $B.Name)
				Compress-Archive -Path $B.FullName -DestinationPath $zipDest -CompressionLevel Optimal
				Remove-Item -LiteralPath $B.FullName -Recurse -Force
				Log-Info 1100 "Archived $($B.Name) -> $zipDest"
			} catch
			{
				Log-Error 2200 "Archiving failed for $($B.FullName): $($_.Exception.Message)"
			}
		}
	}

	# Prune oldest zipped archives
	$Archives = Get-ChildItem -Path $ArchiveDir -Filter '*.zip' | Sort-Object Name -Descending
	if ($Archives.Count -gt $ArchivesKeep)
	{
		$Archives | Select-Object -Skip $ArchivesKeep | ForEach-Object {
			try
			{
				Remove-Item $_.FullName -Force
				Log-Info 1200 "Removed old archive: $($_.Name)"
			} catch
			{
				Log-Error 2300 "Failed to remove archive: $($_.Name): $($_.Exception.Message)"
			}
		}
	}

	Log-Info 1004 "Collection and archiving process completed successfully. RunDir=$RunDir"
} catch
{
	Log-Error 2000 "Unhandled failure: $($_.Exception.Message)`n$($_.Exception | Format-List * | Out-String)"
	exit 1
} finally
{
	Stop-Transcript | Out-Null
}
