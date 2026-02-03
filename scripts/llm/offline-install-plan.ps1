Set-StrictMode -Version Latest

function Get-LLMOfflineLayout {
  [CmdletBinding()]
  param()

  [pscustomobject]@{
    ToolsDir      = 'C:\tools\llama.cpp'
    ExePreferred  = 'llama-cli.exe'
    ExeFallback   = 'main.exe'
    ModelsDir     = (if (Test-Path 'D:\') { 'D:\models\llm' } else { 'C:\models\llm' })
    ModelExt      = '.gguf'
    DefaultExe    = 'C:\tools\llama.cpp\llama-cli.exe'
    DefaultModel  = 'D:\models\llm\model.gguf'
  }
}

function Test-LLMOfflineLayout {
  [CmdletBinding()]
  param()

  $l = Get-LLMOfflineLayout

  $exe1 = Join-Path $l.ToolsDir $l.ExePreferred
  $exe2 = Join-Path $l.ToolsDir $l.ExeFallback

  $modelsOk = Test-Path $l.ModelsDir
  $exeOk    = (Test-Path $exe1) -or (Test-Path $exe2)

  $foundExe = $null
  if (Test-Path $exe1) { $foundExe = $exe1 }
  elseif (Test-Path $exe2) { $foundExe = $exe2 }

  $ggufs = @()
  if (Test-Path $l.ModelsDir) {
    $ggufs = Get-ChildItem -Path $l.ModelsDir -Filter "*.gguf" -File -ErrorAction SilentlyContinue |
      Sort-Object LastWriteTime -Descending |
      Select-Object -ExpandProperty FullName
  }

  [pscustomobject]@{
    ToolsDirExists   = (Test-Path $l.ToolsDir)
    ModelsDirExists  = $modelsOk
    ExeFound         = $foundExe
    ModelCount       = $ggufs.Count
    ModelNewest      = ($ggufs | Select-Object -First 1)
    Ok_Exe           = $exeOk
    Ok_ModelsDir     = $modelsOk
    Notes            = @(
      "Expected tools dir: $($l.ToolsDir)"
      "Expected models dir: $($l.ModelsDir)"
      "Preferred exe: $exe1"
      "Fallback exe:  $exe2"
    )
  }
}

function Get-LLMModelInventory {
  [CmdletBinding()]
  param(
    [string]$ModelsDir = (Get-LLMOfflineLayout).ModelsDir
  )

  if (-not (Test-Path $ModelsDir)) { return @() }

  Get-ChildItem -Path $ModelsDir -Filter "*.gguf" -File -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object Name,FullName,Length,LastWriteTime
}

function Select-LLMModel {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$NameOrPath,
    [string]$ModelsDir = (Get-LLMOfflineLayout).ModelsDir
  )

  if (Test-Path $NameOrPath) { return (Resolve-Path $NameOrPath).Path }

  $hit = Get-ChildItem -Path $ModelsDir -Filter "*.gguf" -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -ieq $NameOrPath } |
    Select-Object -First 1

  if (-not $hit) { throw "Model not found by name in ${ModelsDir}: $NameOrPath" }
  return $hit.FullName
}

function Set-LLMOfflineDefaults {
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [string]$ConfigPath = (Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) 'config\llm.json')
  )

  $l = Get-LLMOfflineLayout
  $exe = $l.DefaultExe
  $model = $l.DefaultModel

  # If preferred exe missing but fallback exists, use fallback
  $fallback = Join-Path $l.ToolsDir $l.ExeFallback
  if (-not (Test-Path $exe) -and (Test-Path $fallback)) { $exe = $fallback }

  if ($PSCmdlet.ShouldProcess($ConfigPath, "Set local-llamacpp defaults (exe/model paths)")) {
    Set-LLMLocalLlamaCppPaths -ExePath $exe -ModelPath $model -ConfigPath $ConfigPath | Out-Null
  }

  return [pscustomobject]@{ ExePath=$exe; ModelPath=$model }
}

function Set-LLMModelPath {
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [Parameter(Mandatory)][string]$NameOrPath,
    [string]$ConfigPath = (Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) 'config\llm.json')
  )

  $path = Select-LLMModel -NameOrPath $NameOrPath
  if ($PSCmdlet.ShouldProcess($ConfigPath, "Update local-llamacpp modelPath -> $path")) {
    Set-LLMLocalLlamaCppPaths -ModelPath $path -ConfigPath $ConfigPath | Out-Null
  }
  return $path
}


