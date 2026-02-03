Set-StrictMode -Version Latest

function Invoke-LLMTerminal {
  [CmdletBinding()]
  param(
    [string]$Provider
  )

  Write-Host ""
  Write-Host "=== LLM Terminal (standalone) ==="
  Write-Host "Commands: /exit  /provider <name>  /config  /help"
  Write-Host ""

    $cfg = Get-LLMConfig
  $check = Test-LLMSetup -Provider $Provider
  if (-not $check.Ok) {
    Write-Host ""
    Write-Host "LLM setup NOT ready for provider: $($check.Provider)"
    $check.Issues | ForEach-Object { Write-Host (" - " + Set-StrictMode -Version Latest

function Invoke-LLMTerminal {
  [CmdletBinding()]
  param(
    [string]$Provider
  )

  Write-Host ""
  Write-Host "=== LLM Terminal (standalone) ==="
  Write-Host "Commands: /exit  /provider <name>  /config  /help"
  Write-Host ""

  $cfg = Get-LLMConfig
  if (-not $Provider) { $Provider = $cfg.provider }

  while ($true) {
    $line = Read-Host ("[{0}]>" -f $Provider)
    if ($null -eq $line) { continue }
    $line = $line.Trim()
    if ($line.Length -eq 0) { continue }

    if ($line -eq '/exit') { break }
    if ($line -eq '/help') {
      Write-Host " /exit                Exit terminal"
      Write-Host " /provider <name>      Switch provider (openai | local-llamacpp)"
      Write-Host " /config              Print active config"
      continue
    }
    if ($line -eq '/config') {
      (Get-LLMConfig | ConvertTo-Json -Depth 10) | Write-Host
      continue
    }
    if ($line -like '/provider*') {
      $parts = $line.Split(' ',2,[System.StringSplitOptions]::RemoveEmptyEntries)
      if ($parts.Count -lt 2) { Write-Host "Usage: /provider <openai|local-llamacpp>"; continue }
      $Provider = $parts[1].Trim()
      Write-Host "Switched provider to: $Provider"
      continue
    }

    try {
      $out = Invoke-LLMChat -Prompt $line -Provider $Provider
      Write-Host ""
      Write-Host $out
      Write-Host ""
    }
    catch {
      Write-Host ("ERROR: {0}" -f $_.Exception.Message)
    }
  }
}
) }
    Write-Host ""
    Write-Host "Fix config/env/model paths then re-run Invoke-LLMTerminal."
    return
  }
  if (-not $Provider) { $Provider = $cfg.provider }

  while ($true) {
    $line = Read-Host ("[{0}]>" -f $Provider)
    if ($null -eq $line) { continue }
    $line = $line.Trim()
    if ($line.Length -eq 0) { continue }

    if ($line -eq '/exit') { break }
    if ($line -eq '/help') {
      Write-Host " /exit                Exit terminal"
      Write-Host " /provider <name>      Switch provider (openai | local-llamacpp)"
      Write-Host " /config              Print active config"
      continue
    }
    if ($line -eq '/config') {
      (Get-LLMConfig | ConvertTo-Json -Depth 10) | Write-Host
      continue
    }
    if ($line -like '/provider*') {
      $parts = $line.Split(' ',2,[System.StringSplitOptions]::RemoveEmptyEntries)
      if ($parts.Count -lt 2) { Write-Host "Usage: /provider <openai|local-llamacpp>"; continue }
      $Provider = $parts[1].Trim()
      Write-Host "Switched provider to: $Provider"
      continue
    }

    try {
      $out = Invoke-LLMChat -Prompt $line -Provider $Provider
      Write-Host ""
      Write-Host $out
      Write-Host ""
    }
    catch {
      Write-Host ("ERROR: {0}" -f $_.Exception.Message)
    }
  }
}

