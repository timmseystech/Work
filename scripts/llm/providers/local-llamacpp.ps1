Set-StrictMode -Version Latest

function Invoke-LLMProviderLocalLlamaCpp {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Prompt,
    [Parameter(Mandatory)]$Config
  )

  $p = $Config.providers.'local-llamacpp'
  if (-not $p) { throw "local-llamacpp provider config missing in config\llm.json" }

  $exe   = [string]$p.exePath
  $model = [string]$p.modelPath

  if (-not (Test-Path $exe))   { throw "llama.cpp exe not found: $exe (offline runtime not installed yet)" }
  if (-not (Test-Path $model)) { throw "model file not found: $model (GGUF not present yet)" }

  # IMPORTANT: do NOT use $args (automatic variable). Use an explicit list and emit a real string[].
  $cliArgsList = New-Object System.Collections.Generic.List[string]
  $cliArgsList.Add('-m')
  $cliArgsList.Add($model)

  if ($null -ne $p.defaultArgs) {
    foreach ($a in @($p.defaultArgs)) {
      if ($null -eq $a) { continue }
      $cliArgsList.Add([string]$a)
    }
  }

  $useSimpleIo = $cliArgsList.Contains('--simple-io')

  if (-not $useSimpleIo) {
    $cliArgsList.Add('-p')
    $cliArgsList.Add($Prompt)
  }

  $cliArgs = $cliArgsList.ToArray()

  # Files for robust IO capture (works on Windows PowerShell 5.1)
  $stdoutFile = Join-Path $env:TEMP ("llama_stdout_{0}.txt" -f ([guid]::NewGuid().ToString('N')))
  $stderrFile = Join-Path $env:TEMP ("llama_stderr_{0}.txt" -f ([guid]::NewGuid().ToString('N')))
  $inFile     = Join-Path $env:TEMP ("llama_in_{0}.txt"     -f ([guid]::NewGuid().ToString('N')))

  try {
    if ($useSimpleIo) {
      # llama-cli --simple-io reads from STDIN
      ($Prompt + "`r`n") | Set-Content -Encoding utf8 -Path $inFile

      $proc = Start-Process -FilePath $exe -ArgumentList $cliArgs -Wait -PassThru -NoNewWindow `
        -RedirectStandardInput  $inFile `
        -RedirectStandardOutput $stdoutFile `
        -RedirectStandardError  $stderrFile
    }
    else {
      $proc = Start-Process -FilePath $exe -ArgumentList $cliArgs -Wait -PassThru -NoNewWindow `
        -RedirectStandardOutput $stdoutFile `
        -RedirectStandardError  $stderrFile
    }

    $stdout = Get-Content -Raw -ErrorAction SilentlyContinue -Path $stdoutFile
    $stderr = Get-Content -Raw -ErrorAction SilentlyContinue -Path $stderrFile

    if ($null -eq $stdout) { $stdout = '' }
    if ($null -eq $stderr) { $stderr = '' }

    if ($proc.ExitCode -ne 0) {
      throw ("llama.cpp failed (exit {0}): {1}" -f $proc.ExitCode, ($stderr + "`n" + $stdout).Trim())
    }

    # If simple-io, strip banner-ish lines and return last meaningful line
    if ($useSimpleIo) {
      $skip = '^(load_backend:|Loading model\.\.\.|build\s*:|model\s*:|modalities\s*:|available commands:|/exit|/regen|/clear|/read|\[ Prompt:|llama_memory_|Exiting\.\.\.|>$)'
      $clean = @()
      foreach ($line in ($stdout -split "`r?`n")) {
        $t = $line.Trim()
        if (-not $t) { continue }
        if ($t -match $skip) { continue }
        $clean += $t
      }
      if ($clean.Count -gt 0) { return $clean[-1] }
    }

    return $stdout.Trim()
  }
  finally {
    Remove-Item -Force -ErrorAction SilentlyContinue $stdoutFile, $stderrFile, $inFile | Out-Null
  }
}
