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
  if (-not $Provider) { $Provider = $cfg.provider }

  $check = Test-LLMSetup -Provider $Provider
  if (-not $check.Ok) {
    Write-Host ""
    Write-Host "LLM setup NOT ready for provider: $($check.Provider)"
    foreach ($issue in $check.Issues) {
      Write-Host (" - " + $issue)
    }
    Write-Host ""
    Write-Host "Fix config/env/model paths then re-run Invoke-LLMTerminal."
    return
  }

  while ($true) {
    $line = Read-Host ("[{0}]>" -f $Provider)
    if (-not $line) { continue }

    $line = $line.Trim()
    if ($line.Length -eq 0) { continue }

    switch ($line) {
      '/exit' { break }
      '/help' {
        Write-Host " /exit                Exit terminal"
        Write-Host " /provider <name>      Switch provider (openai | local-llamacpp)"
        Write-Host " /config              Print active config"
        continue
      }
      '/config' {
        (Get-LLMConfig | ConvertTo-Json -Depth 10) | Write-Host
        continue
      }
    }

    if ($line -like '/provider*') {
      $parts = $line.Split(' ',2,[System.StringSplitOptions]::RemoveEmptyEntries)
      if ($parts.Count -lt 2) {
        Write-Host "Usage: /provider <openai|local-llamacpp>"
        continue
      }

      $Provider = $parts[1].Trim()
      $check = Test-LLMSetup -Provider $Provider
      if (-not $check.Ok) {
        Write-Host "Provider '$Provider' not ready:"
        foreach ($issue in $check.Issues) {
          Write-Host (" - " + $issue)
        }
        continue
      }

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
      Write-Host ("ERROR: " + $_.Exception.Message)
    }
  }
}
