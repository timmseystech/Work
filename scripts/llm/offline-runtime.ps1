Set-StrictMode -Version Latest

function Get-LLMLlamaCppCandidatePaths {
  [CmdletBinding()]
  param()

  $candidates = New-Object System.Collections.Generic.List[string]

  # Common operator-managed locations (NO downloads performed)
  $candidates.Add("C:\tools\llama.cpp\llama-cli.exe")
  $candidates.Add("C:\tools\llama.cpp\main.exe")
  $candidates.Add((Join-Path $HOME "tools\llama.cpp\llama-cli.exe"))
  $candidates.Add((Join-Path $HOME "tools\llama.cpp\main.exe"))

  # Also check PATH for any llama-cli/main
  foreach ($name in @('llama-cli.exe','main.exe')) {
    try {
      $cmd = Get-Command $name -ErrorAction SilentlyContinue
      if ($cmd -and $cmd.Source -and (Test-Path $cmd.Source)) { $candidates.Add($cmd.Source) }
    } catch { }
  }

  # Unique + existing
  $candidates |
    Where-Object { $_ -and $_.Trim().Length -gt 0 } |
    Select-Object -Unique
}

function Find-LLMLlamaCppExe {
  [CmdletBinding()]
  param()

  foreach ($p in (Get-LLMLlamaCppCandidatePaths)) {
    if (Test-Path $p) { return $p }
  }
  return $null
}

function Set-LLMLocalLlamaCppPaths {
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [string]$ExePath,
    [string]$ModelPath,
    [string]$ConfigPath = (Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) 'config\llm.json')
  )

  if (-not (Test-Path $ConfigPath)) { throw "LLM config missing: $ConfigPath" }

  $cfg = Get-Content -Raw -Path $ConfigPath | ConvertFrom-Json

  if (-not $cfg.providers.'local-llamacpp') {
    throw "config missing providers.local-llamacpp"
  }

  if ($ExePath)   { $cfg.providers.'local-llamacpp'.exePath = $ExePath }
  if ($ModelPath) { $cfg.providers.'local-llamacpp'.modelPath = $ModelPath }

  $json = $cfg | ConvertTo-Json -Depth 20
  if ($PSCmdlet.ShouldProcess($ConfigPath, "Update local-llamacpp paths")) {
    $json | Set-Content -Encoding utf8 -Path $ConfigPath
  }

  return $cfg.providers.'local-llamacpp'
}

function Test-LLMOfflineRuntimePlan {
  [CmdletBinding()]
  param(
    [string]$Provider = 'local-llamacpp'
  )

  $cfg = Get-LLMConfig
  $resolved = Get-LLMProvider -Name $Provider

  $r = [ordered]@{
    Provider = $resolved
    ConfigProviderDefault = [string]$cfg.provider
    LlamaExe_Config = $null
    LlamaExe_Found  = $null
    Model_Config    = $null
    Ok_Exe          = $false
    Ok_Model        = $false
    Notes           = @()
  }

  if ($resolved -ne 'local-llamacpp') {
    $r.Notes += "This check is for local-llamacpp only."
    return [pscustomobject]$r
  }

  $r.LlamaExe_Config = [string]$cfg.providers.'local-llamacpp'.exePath
  $r.Model_Config    = [string]$cfg.providers.'local-llamacpp'.modelPath

  if ($r.LlamaExe_Config -and (Test-Path $r.LlamaExe_Config)) {
    $r.Ok_Exe = $true
    $r.Notes += "Exe present at configured path."
  } else {
    $found = Find-LLMLlamaCppExe
    if ($found) {
      $r.LlamaExe_Found = $found
      $r.Notes += "Exe not at configured path, but found candidate: $found"
    } else {
      $r.Notes += "Exe missing (expected until you manually provide llama.cpp build)."
    }
  }

  if ($r.Model_Config -and (Test-Path $r.Model_Config)) {
    $r.Ok_Model = $true
    $r.Notes += "Model present at configured path."
  } else {
    $r.Notes += "Model missing (expected until you manually place a GGUF)."
  }

  [pscustomobject]$r
}
