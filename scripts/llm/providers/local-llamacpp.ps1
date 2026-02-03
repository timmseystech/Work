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

  $args = @()
  $args += @('-m', $model)
  if ($p.defaultArgs) { $args += $p.defaultArgs }
  $args += @('-p', $Prompt)

  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = $exe
  $psi.Arguments = ($args -join ' ')
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError  = $true
  $psi.UseShellExecute = $false
  $psi.CreateNoWindow  = $true

  $proc = New-Object System.Diagnostics.Process
  $proc.StartInfo = $psi
  [void]$proc.Start()

  $stdout = $proc.StandardOutput.ReadToEnd()
  $stderr = $proc.StandardError.ReadToEnd()
  $proc.WaitForExit()

  if ($proc.ExitCode -ne 0) {
    throw ("llama.cpp failed (exit {0}): {1}" -f $proc.ExitCode, $stderr)
  }

  return $stdout.Trim()
}
