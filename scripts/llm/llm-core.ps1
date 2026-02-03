Set-StrictMode -Version Latest

function Get-LLMConfig {
  [CmdletBinding()]
  param(
    [string]$Path = (Join-Path (Split-Path $PSScriptRoot -Parent | Split-Path -Parent) 'config\llm.json')
  )
  if (-not (Test-Path $Path)) { throw "LLM config missing: $Path" }
  (Get-Content -Raw -Path $Path | ConvertFrom-Json)
}

function Save-LLMHistory {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Text,
    [Parameter(Mandatory)][string]$Role,
    [string]$HistoryDir = 'C:\AI_Logs\chat_history'
  )
  New-Item -ItemType Directory -Force -Path $HistoryDir | Out-Null
  $ts = Get-Date -Format 'yyyy-MM-dd_HHmmss'
  $path = Join-Path $HistoryDir ("chat_{0}_{1}.log" -f $Role,$ts)
  $Text | Set-Content -Encoding utf8 $path
  return $path
}

function Get-LLMProvider {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Name
  )
  switch ($Name) {
    'openai'         { return 'openai' }
    'local-llamacpp' { return 'local-llamacpp' }
    default { throw "Unknown provider: $Name" }
  }
}

function Invoke-LLMChat {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Prompt,
    [string]$Provider,
    [switch]$NoHistory
  )

  $cfg = Get-LLMConfig
  if (-not $Provider) { $Provider = $cfg.provider }

  $resolved = Get-LLMProvider -Name $Provider

  if (-not $NoHistory -and $cfg.ui.saveHistory) {
    Save-LLMHistory -Text $Prompt -Role 'user' -HistoryDir $cfg.ui.historyDir | Out-Null
  }

  switch ($resolved) {
    'openai' {
      return Invoke-LLMProviderOpenAI -Prompt $Prompt -Config $cfg
    }
    'local-llamacpp' {
      return Invoke-LLMProviderLocalLlamaCpp -Prompt $Prompt -Config $cfg
    }
    default {
      throw "Provider not implemented: $resolved"
    }
  }
}
