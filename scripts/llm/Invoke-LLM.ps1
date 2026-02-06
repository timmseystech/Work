Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Invoke-LLM.ps1 (simple launcher)
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\llm\Invoke-LLM.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\llm\Invoke-LLM.ps1 --prompt "Say LLM OK"
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\llm\Invoke-LLM.ps1 --provider local-llamacpp --nohistory --prompt "Hello"

function _GetArgValue([string]$name) {
  for ($i=0; $i -lt $args.Count; $i++) {
    if ($args[$i] -eq $name -and ($i+1) -lt $args.Count) { return [string]$args[$i+1] }
  }
  return $null
}
function _HasArg([string]$name) {
  for ($i=0; $i -lt $args.Count; $i++) { if ($args[$i] -eq $name) { return $true } }
  return $false
}

$RepoRoot  = Join-Path $HOME 'src\work\Work'
$Loader    = Join-Path $RepoRoot 'scripts\ai-functions.ps1'
if (-not (Test-Path $Loader)) { throw "Loader missing: $Loader" }

. $Loader

$Provider  = _GetArgValue '--provider'
$Prompt    = _GetArgValue '--prompt'
$NoHistory = _HasArg '--nohistory'
$Repl      = _HasArg '--repl'
$Help      = _HasArg '--help'

if ($Help) {
  @"
Invoke-LLM.ps1 - simple LLM launcher

One-shot:
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\llm\Invoke-LLM.ps1 --prompt "Say LLM OK"

With provider and no history:
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\llm\Invoke-LLM.ps1 --provider local-llamacpp --nohistory --prompt "Hello"

REPL mode:
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\llm\Invoke-LLM.ps1 --repl

Flags:
  --provider <name>   (optional) openai | local-llamacpp (defaults to config)
  --prompt  <text>    (optional) one-shot prompt
  --nohistory         (optional) do not write prompt to history logs
  --repl              (optional) interactive prompt loop
  --help
"@ | Out-Host
  exit 0
}

# Default to REPL if nothing provided
if (-not $Prompt -and -not $Repl) { $Repl = $true }

if ($Prompt) {
  $out = $null
  try {
    if ($Provider) { $out = Invoke-LLMChat -Provider $Provider -Prompt $Prompt -NoHistory:$NoHistory }
    else           { $out = Invoke-LLMChat -Prompt $Prompt -NoHistory:$NoHistory }
  } catch {
    "ERROR:" | Out-Host
    $_.Exception.Message | Out-Host
    exit 1
  }
  $out | Out-Host
  exit 0
}

if ($Repl) {
  "LLM REPL started. Type /exit to quit. (/clear clears screen only)" | Out-Host
  while ($true) {
    $line = Read-Host -Prompt 'You'
    if ($null -eq $line) { continue }
    $t = $line.Trim()
    if (-not $t) { continue }

    if ($t -eq '/exit') { break }
    if ($t -eq '/clear') { Clear-Host; continue }

    $out = $null
    try {
      if ($Provider) { $out = Invoke-LLMChat -Provider $Provider -Prompt $t -NoHistory:$NoHistory }
      else           { $out = Invoke-LLMChat -Prompt $t -NoHistory:$NoHistory }
    } catch {
      "ERROR:" | Out-Host
      $_.Exception.Message | Out-Host
      continue
    }

    "LLM> $out" | Out-Host
  }

  "REPL exited." | Out-Host
  exit 0
}

throw "Invalid state: provide --prompt or --repl (or run with --help)."
