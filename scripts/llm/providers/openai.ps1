Set-StrictMode -Version Latest

function Invoke-LLMProviderOpenAI {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Prompt,
    [Parameter(Mandatory)]$Config
  )

  $p = $Config.providers.openai
  if (-not $p) { throw "OpenAI provider config missing in config\llm.json" }

  $envName = [string]$p.apiKeyEnv
  $apiKey = [Environment]::GetEnvironmentVariable($envName, 'User')
  if (-not $apiKey) { $apiKey = [Environment]::GetEnvironmentVariable($envName, 'Machine') }
  if (-not $apiKey) { $apiKey = [Environment]::GetEnvironmentVariable($envName, 'Process') }
  if (-not $apiKey) { throw "Missing API key env var: $envName (set it before using openai provider)" }

  # NOTE: This is intentionally minimal and can be upgraded later (chat history, tools, etc.)
  $uri = ($p.baseUrl.TrimEnd('/') + '/responses')
  $body = @{
    model = $p.model
    input = $Prompt
  } | ConvertTo-Json -Depth 10

  $headers = @{
    Authorization = "Bearer $apiKey"
    "Content-Type" = "application/json"
  }

  try {
    $resp = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
    # Response shape can vary by model; keep conservative:
    if ($resp.output_text) { return [string]$resp.output_text }
    return ($resp | ConvertTo-Json -Depth 10)
  }
  catch {
    throw ("OpenAI request failed: " + $_.Exception.Message)
  }
}
