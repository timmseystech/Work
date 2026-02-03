# AI Functions Loader (canonical)
# Keep this file parse-clean. Profile should only dot-source this.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function End-AITask {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Task,
    [string]$RepoRoot = (Join-Path $HOME 'src\work\Work'),
    [string]$SrcLogs  = 'C:\AI_Logs'
  )
  Sync-AITaskLogsToGitHub -Task $Task -RepoRoot $RepoRoot -SrcLogs $SrcLogs
}

function Sync-AITaskLogsToGitHub {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Task,
    [string]$RepoRoot = (Join-Path $HOME 'src\work\Work'),
    [string]$SrcLogs  = 'C:\AI_Logs',
    [string]$CommitMessage
  )

  $ErrorActionPreference = 'Stop'
  if (-not (Test-Path $RepoRoot)) { throw "Repo missing: $RepoRoot" }
  if (-not (Test-Path $SrcLogs))  { throw "Source logs missing: $SrcLogs" }

  $RepoLogs = Join-Path $RepoRoot 'logs'
  New-Item -ItemType Directory -Force -Path $RepoLogs | Out-Null

  # STRICT: newest SUMMARY first
  $summary = Get-ChildItem $SrcLogs -Filter "AI_${Task}_SUMMARY_*.log" -File |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
  if (-not $summary) { throw "Missing summary log for task '$Task' in $SrcLogs" }

  # STRICT: headers excluding SUMMARY
  $headers = Get-ChildItem $SrcLogs -Filter "AI_${Task}_*.log" -File |
    Where-Object { $_.Name -notmatch '_SUMMARY_' } |
    Sort-Object LastWriteTime -Descending

  if (-not $headers) {
    throw "Missing header logs for task '$Task' in $SrcLogs (no non-SUMMARY matches found)."
  }

  # STRICT: closest HEADER <= SUMMARY
  $header = $headers |
    Where-Object { $_.LastWriteTime -le $summary.LastWriteTime } |
    Select-Object -First 1

  if (-not $header) {
    $hint = ($headers | Select-Object -First 1).Name
    throw "No HEADER <= SUMMARY for task '$Task'. Newest header is after summary. Example header: $hint"
  }

  "Using HEADER:  $($header.Name)  ($($header.LastWriteTime))" | Out-Host
  "Using SUMMARY: $($summary.Name) ($($summary.LastWriteTime))" | Out-Host

  Copy-Item -Force $header.FullName  (Join-Path $RepoLogs $header.Name)
  Copy-Item -Force $summary.FullName (Join-Path $RepoLogs $summary.Name)

  if (-not $CommitMessage) { $CommitMessage = "chore: $Task logs" }

  Push-Location $RepoRoot
  try {
    git add -f -- (Join-Path $RepoLogs $header.Name) (Join-Path $RepoLogs $summary.Name) | Out-Null

    if (-not (git diff --cached --name-only)) {
      "Nothing staged; $Task header+summary already synced." | Out-Host
      return
    }

    git commit -m $CommitMessage | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "git commit failed" }

    git push | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "git push failed" }

    "Synced $Task header+summary logs to GitHub." | Out-Host
  }
  finally { Pop-Location }
}
function New-AISaveState {
  param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][string]$Objective,
    [string]$Notes = ''
  )

  $ErrorActionPreference = 'Stop'

  $RepoRoot = Join-Path $HOME 'src\work\Work'
  $LogsRoot = Join-Path $RepoRoot 'logs'
  $Index    = Join-Path $LogsRoot 'state_index.json'

  if (-not (Test-Path $RepoRoot)) { throw "Repo missing: $RepoRoot" }
  New-Item -ItemType Directory -Force -Path $LogsRoot | Out-Null

  if (-not (Test-Path $Index)) {
    '[]' | Set-Content -Encoding utf8 $Index
  }

  $ts   = Get-Date
  $slug = ($Name -replace '[^a-zA-Z0-9\-]', '-') -replace '-+', '-'
  $log  = Join-Path $LogsRoot ("AI_STATE_{0}_{1}.log" -f $slug, $ts.ToString('yyyy-MM-dd_HHmm'))

  Push-Location $RepoRoot
  try {
    $branch = git branch --show-current
    $commit = git rev-parse HEAD
    $status = git status -sb

    $state = [ordered]@{
      Name       = $Name
      Objective  = $Objective
      Notes      = $Notes
      Timestamp  = $ts.ToString('o')
      User       = $env:USERNAME
      Computer   = $env:COMPUTERNAME
      Windows    = (Get-ComputerInfo WindowsProductName,WindowsVersion,OsBuildNumber)
      PowerShell = $PSVersionTable.PSVersion.ToString()
      GitBranch  = $branch
      GitCommit  = $commit
      GitStatus  = ($status -join "`n")
    }

    $state.GetEnumerator() | ForEach-Object { "$($_.Key): $($_.Value)" } |
      Set-Content -Encoding utf8 $log

    # ---- FORCE ARRAY ----
    $raw = Get-Content $Index -Raw | ConvertFrom-Json
    if ($null -eq $raw) { $indexData = @() }
    elseif ($raw -is [System.Array]) { $indexData = $raw }
    else { $indexData = @($raw) }

    $indexData += [ordered]@{
      name      = $Name
      slug      = $slug
      log       = (Split-Path $log -Leaf)
      commit    = $commit
      branch    = $branch
      timestamp = $state.Timestamp
    }

    $indexData | ConvertTo-Json -Depth 6 | Set-Content -Encoding utf8 $Index

    git add -f -- logs/state_index.json logs/AI_STATE_*.log | Out-Null
    git commit -m "ai(state): $Name" | Out-Host
    git tag -a "ai-state/$slug" -m "AI save state: $Name"
    git push --follow-tags | Out-Host

    "Save state '$Name' created, indexed, tagged, and pushed." | Out-Host
  }
  finally {
    Pop-Location
  }
}
