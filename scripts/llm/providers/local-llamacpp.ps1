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

  if (-not (Test-Path $exe))   { throw "llama.cpp exe not found: $exe" }
  if (-not (Test-Path $model)) { throw "model file not found: $model" }

  # Build arg array (no string joining, no quoting games)
  $argList = @('-m', $model)
  if ($null -ne $p.defaultArgs) {
    foreach ($a in @($p.defaultArgs)) {
      if ($null -eq $a) { continue }
      $argList += [string]$a
    }
  }

  # If NOT simple-io, pass prompt via -p; otherwise pipe prompt to stdin.
  $useSimpleIo = ($argList -contains '--simple-io')

  $stdoutFile = Join-Path $env:TEMP ("llama_stdout_{0}.txt" -f ([guid]::NewGuid().ToString('N')))
  $stderrFile = Join-Path $env:TEMP ("llama_stderr_{0}.txt" -f ([guid]::NewGuid().ToString('N')))

  try {
    $prevEap = $ErrorActionPreference
    try {
      # Prevent NativeCommandError records from killing the run
      $ErrorActionPreference = 'Continue'

      if ($useSimpleIo) {
        # Force newline + /exit to guarantee termination after first response
        $in = ($Prompt.TrimEnd() + "`r`n/exit`r`n")
        $in | & $exe @argList 1> $stdoutFile 2> $stderrFile
      } else {
        & $exe @argList -p $Prompt 1> $stdoutFile 2> $stderrFile
      }

      $code = $LASTEXITCODE
    }
    finally { $ErrorActionPreference = $prevEap }

    $stdout = Get-Content -Raw -ErrorAction SilentlyContinue -Path $stdoutFile
    $stderr = Get-Content -Raw -ErrorAction SilentlyContinue -Path $stderrFile
    if ($null -eq $stdout) { $stdout = '' }
    if ($null -eq $stderr) { $stderr = '' }

    if ($code -ne 0) {
      throw ("llama.cpp failed (exit {0}): {1}" -f $code, ($stderr + "`n" + $stdout).Trim())
    }

    # Clean output: return last meaningful non-banner line
    $skip = '^(load_backend:|Loading model\.\.\.|build\s*:|model\s*:|modalities\s*:|available commands:|/exit|/regen|/clear|/read|\[ Prompt:|llama_memory_|Exiting\.\.\.|>$)'
    $clean = @()
    foreach ($line in ($stdout -split "`r?`n")) {
      $t = $line.Trim()
      if (-not $t) { continue }
      if ($t -match $skip) { continue }
      $clean += $t
    }

    if ($clean.Count -gt 0) { return $clean[-1] }
    return $stdout.Trim()
  }
  finally {
    Remove-Item -Force -ErrorAction SilentlyContinue $stdoutFile, $stderrFile | Out-Null
  }
}
