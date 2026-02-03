
# AI Save State System (patched)


  param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][string]$Objective,
    [string]$Notes = ''
  )

  $RepoRoot = Join-Path $HOME 'src\work\Work'
  $LogsRoot = Join-Path $RepoRoot 'logs'
  $Index    = Join-Path $LogsRoot 'state_index.json'

  if (-not (Test-Path $Index)) {
    New-Item -ItemType File -Force -Path $Index | Out-Null
    '[]' | Set-Content -Encoding utf8 -Path $Index
  }

  $ts   = Get-Date
  $slug = $Name -replace '[^a-zA-Z0-9\-]', '-'
  $log  = Join-Path $LogsRoot ("AI_STATE_{0}_{1}.log" -f $slug, $ts.ToString('yyyy-MM-dd_HHmm'))

  $state = [ordered]@{
    Name       = $Name
    Objective  = $Objective
    Notes      = $Notes
    Timestamp  = $ts.ToString('o')
    User       = $env:USERNAME
    Computer   = $env:COMPUTERNAME
    Windows    = (Get-ComputerInfo WindowsProductName,WindowsVersion,OsBuildNumber)
    PowerShell = $PSVersionTable.PSVersion.ToString()
    GitBranch  = (git branch --show-current)
    GitCommit  = (git rev-parse HEAD)
    GitStatus  = (git status -sb)
  }

  $state.GetEnumerator() | ForEach-Object {
    "$($_.Key): $($_.Value)"
  } | Set-Content -Encoding utf8 $log

  $indexData = Get-Content $Index | ConvertFrom-Json
  $indexData += [ordered]@{
    name      = $Name
    slug      = $slug
    log       = (Split-Path $log -Leaf)
    commit    = $state.GitCommit
    branch    = $state.GitBranch
    timestamp = $state.Timestamp
  }

  $indexData | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 $Index

  Push-Location $RepoRoot
  try {
    git add -f -- logs/state_index.json logs/AI_STATE_*.log | Out-Null
    git commit -m "ai(state): $Name" | Out-Host
    git tag "ai-state/$slug" | Out-Null
    git push --follow-tags | Out-Host
  }
  finally {
    Pop-Location
  }

  "Save state '$Name' created and pushed." | Out-Host




# AI Save State System (hardened, no-editor tags)


  param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][string]$Objective,
    [string]$Notes = ''
  )

  $RepoRoot = Join-Path $HOME 'src\work\Work'
  $LogsRoot = Join-Path $RepoRoot 'logs'
  $Index    = Join-Path $LogsRoot 'state_index.json'

  if (-not (Test-Path $RepoRoot)) { throw "Repo missing: $RepoRoot" }
  New-Item -ItemType Directory -Force -Path $LogsRoot | Out-Null

  if (-not (Test-Path $Index)) {
    New-Item -ItemType File -Force -Path $Index | Out-Null
    '[]' | Set-Content -Encoding utf8 -Path $Index
  }

  $ts   = Get-Date
  $slug = ($Name -replace '[^a-zA-Z0-9\-]', '-') -replace '-+', '-'
  $log  = Join-Path $LogsRoot ("AI_STATE_{0}_{1}.log" -f $slug, $ts.ToString('yyyy-MM-dd_HHmm'))

  Push-Location $RepoRoot
  try {
    $branch = (git branch --show-current); if ($LASTEXITCODE -ne 0) { throw "git branch failed" }
    $head   = (git rev-parse HEAD);       if ($LASTEXITCODE -ne 0) { throw "git rev-parse failed" }
    $status = (git status -sb);           if ($LASTEXITCODE -ne 0) { throw "git status failed" }

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
      GitCommit  = $head
      GitStatus  = ($status -join "`n")
    }

    $state.GetEnumerator() | ForEach-Object { "$($_.Key): $($_.Value)" } |
      Set-Content -Encoding utf8 $log

    $indexData = Get-Content $Index | ConvertFrom-Json
    $indexData += [ordered]@{
      name      = $Name
      slug      = $slug
      log       = (Split-Path $log -Leaf)
      commit    = $head
      branch    = $branch
      timestamp = $state.Timestamp
    }
    $indexData | ConvertTo-Json -Depth 6 | Set-Content -Encoding utf8 $Index

    git add -f -- logs/state_index.json logs/AI_STATE_*.log | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "git add failed" }

    git commit -m "ai(state): $Name" | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "git commit failed" }

    # Explicit annotated tag WITH message (never opens editor)
    git tag -a "ai-state/$slug" -m "AI save state: $Name"
    if ($LASTEXITCODE -ne 0) { throw "git tag failed" }

    git push --follow-tags | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "git push --follow-tags failed" }

    "Save state '$Name' created, tagged, and pushed." | Out-Host
  }
  finally {
    Pop-Location
  }




# AI Save State System (array-safe patch)


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

    $state.GetEnumerator() | ForEach-Object {
      "$($_.Key): $($_.Value)"
    } | Set-Content -Encoding utf8 $log

    # ---- FORCE ARRAY ----
    $raw = Get-Content $Index -Raw | ConvertFrom-Json
    if ($null -eq $raw) {
      $indexData = @()
    }
    elseif ($raw -is [System.Array]) {
      $indexData = $raw
    }
    else {
      $indexData = @($raw)
    }

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




# AI Save State Restore + Index Helpers


  [CmdletBinding()]
  param(
    [string]$RepoRoot = (Join-Path $HOME 'src\work\Work')
  )

  $ErrorActionPreference = 'Stop'
  $LogsRoot = Join-Path $RepoRoot 'logs'
  $Index    = Join-Path $LogsRoot 'state_index.json'
  if (-not (Test-Path $Index)) { throw "Missing index: $Index" }

  $raw = Get-Content $Index -Raw | ConvertFrom-Json
  if ($null -eq $raw) { return @() }
  if ($raw -is [System.Array]) { return $raw }
  return @($raw)


  [CmdletBinding()]
  param(
    [string]$RepoRoot = (Join-Path $HOME 'src\work\Work'),
    [switch]$DedupBySlugKeepLatest
  )

  $ErrorActionPreference = 'Stop'
  $LogsRoot = Join-Path $RepoRoot 'logs'
  $Index    = Join-Path $LogsRoot 'state_index.json'
  if (-not (Test-Path $Index)) { throw "Missing index: $Index" }

  $states = Get-AISaveStates -RepoRoot $RepoRoot

  if ($DedupBySlugKeepLatest) {
    $states =
      $states |
      Sort-Object { [datetime]$_.timestamp } |
      Group-Object slug |
      ForEach-Object { $_.Group[-1] } |
      Sort-Object { [datetime]$_.timestamp }
  }

  # Write as a real JSON array (stable)
  ($states | ConvertTo-Json -Depth 6) | Set-Content -Encoding utf8 $Index

  Push-Location $RepoRoot
  try {
    git add -f -- logs/state_index.json | Out-Null
    if (git diff --cached --name-only) {
      git commit -m "ai(state): normalize state index" | Out-Host
      git push | Out-Host
    } else {
      "Index already normalized; nothing to commit." | Out-Host
    }
  }
  finally { Pop-Location }


  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Slug,
    [string]$RepoRoot = (Join-Path $HOME 'src\work\Work'),
    [switch]$CreateBranch,
    [string]$BranchName
  )

  $ErrorActionPreference = 'Stop'
  Push-Location $RepoRoot
  try {
    # Safety: block if dirty
    $dirty = git status --porcelain
    if ($dirty) { throw "Working tree is NOT clean. Commit/stash first before restore." }

    $tag = "ai-state/$Slug"

    # Ensure we have tags from origin
    git fetch --tags | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "git fetch --tags failed" }

    $exists = git tag --list $tag
    if (-not $exists) { throw "Tag not found: $tag" }

    if ($CreateBranch) {
      if (-not $BranchName) { $BranchName = "restore/$Slug" }
      git switch -c $BranchName $tag | Out-Host
      if ($LASTEXITCODE -ne 0) { throw "git switch -c failed" }
      "Restored to branch: $BranchName (from $tag)" | Out-Host
    }
    else {
      git checkout $tag | Out-Host
      if ($LASTEXITCODE -ne 0) { throw "git checkout failed" }
      "Restored to detached HEAD at tag: $tag" | Out-Host
    }
  }
  finally { Pop-Location }




# AI Auto-Checkpoint Helper


  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Task,
    [Parameter(Mandatory)][string]$Objective,
    [string]$Notes = '',
    [switch]$IncludeDateInName
  )

  $ErrorActionPreference = 'Stop'

  # Build deterministic name
  $ts = Get-Date
  $date = $ts.ToString('yyyy-MM-dd')
  $name =
    if ($IncludeDateInName) {
      "$Task-$date"
    } else {
      $Task
    }

  New-AISaveState `
    -Name $name `
    -Objective $Objective `
    -Notes $Notes




# AI Auto-Checkpoint Helper


  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Task,
    [Parameter(Mandatory)][string]$Objective,
    [string]$Notes = '',
    [switch]$IncludeDateInName
  )

  $ErrorActionPreference = 'Stop'

  # Build deterministic name
  $ts = Get-Date
  $date = $ts.ToString('yyyy-MM-dd')
  $name =
    if ($IncludeDateInName) {
      "$Task-$date"
    } else {
      $Task
    }

  New-AISaveState `
    -Name $name `
    -Objective $Objective `
    -Notes $Notes




# AI Auto-Checkpoint Helper (CANONICAL)
function Invoke-AIAutoCheckpoint {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Task,
    [Parameter(Mandatory)][string]$Objective,
    [string]$Notes = '',
    [switch]$IncludeDateInName
  )

  $ErrorActionPreference = 'Stop'

  $ts = Get-Date
  $date = $ts.ToString('yyyy-MM-dd')

  $name = if ($IncludeDateInName) { "$Task-$date" } else { $Task }

  New-AISaveState -Name $name -Objective $Objective -Notes $Notes
}


# AI Task Log Sync Helper (CANONICAL)


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

  # Distinct selection rules
  $header = Get-ChildItem $SrcLogs -Filter "AI_${Task}_*.log" -File |
    Where-Object { $_.Name -notmatch '_SUMMARY_' } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

  $summary = Get-ChildItem $SrcLogs -Filter "AI_${Task}_SUMMARY_*.log" -File |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

  if (-not $header)  { throw "Missing header log for task '$Task' in $SrcLogs" }
  if (-not $summary) { throw "Missing summary log for task '$Task' in $SrcLogs" }

  # Copy into repo logs
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


  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Task,
    [string]$RepoRoot = (Join-Path $HOME 'src\work\Work'),
    [string]$SrcLogs  = 'C:\AI_Logs'
  )

  Sync-AITaskLogsToGitHub -Task $Task -RepoRoot $RepoRoot -SrcLogs $SrcLogs




# AI Session Summary Log (CANONICAL: _SUMMARY_ filename)


  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Task,
    [Parameter(Mandatory)][string]$ActionsPerformed,
    [Parameter(Mandatory)][string]$SystemChanges,
    [Parameter(Mandatory)][string]$RisksIntroduced,
    [Parameter(Mandatory)][string]$RollbackNotes,
    [Parameter(Mandatory)][string]$NextSteps,
    [string]$LogDir = 'C:\AI_Logs'
  )

  $ErrorActionPreference = 'Stop'
  New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

  $ts = Get-Date -Format 'yyyy-MM-dd_HHmm'
  $path = Join-Path $LogDir ("AI_{0}_SUMMARY_{1}.log" -f $Task, $ts)

  @"
TASK: $Task (SUMMARY)
ACTIONS: $ActionsPerformed
CHANGES: $SystemChanges
RISKS: $RisksIntroduced
ROLLBACK: $RollbackNotes
NEXT: $NextSteps
END: $(Get-Date -Format o)
"@ | Set-Content -Encoding utf8 $path

  "Summary log written: $path" | Out-Host
  return $path




# AI Task Log Sync Helper (PATCH: recovered header if missing)


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

  # Header must EXCLUDE SUMMARY
  $header = Get-ChildItem $SrcLogs -Filter "AI_${Task}_*.log" -File |
    Where-Object { $_.Name -notmatch '_SUMMARY_' } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

  $summary = Get-ChildItem $SrcLogs -Filter "AI_${Task}_SUMMARY_*.log" -File |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

  # Self-heal: if header missing but summary exists, create a recovered header now
  if (-not $header -and $summary) {
    $ts = Get-Date -Format 'yyyy-MM-dd_HHmm'
    $win = Get-ComputerInfo -Property WindowsProductName,WindowsVersion,OsBuildNumber
    $newHeaderPath = Join-Path $SrcLogs ("AI_{0}_{1}.log" -f $Task, $ts)

    @"
TASK: $Task
OBJECTIVE: (Recovered) Header missing at sync time; created automatically so GitHub mirror stays consistent.
CONSTRAINTS: PowerShell-only. Logs mirrored from C:\AI_Logs to repo\logs.
WINDOWS: $($win.WindowsProductName) $($win.WindowsVersion) (Build $($win.OsBuildNumber))
POWERSHELL: $($PSVersionTable.PSVersion)
GIT: $(git --version)
START: $(Get-Date -Format o)
"@ | Set-Content -Encoding utf8 $newHeaderPath

    $header = Get-Item $newHeaderPath
  }

  if (-not $header)  { throw "Missing header log for task '$Task' in $SrcLogs" }
  if (-not $summary) { throw "Missing summary log for task '$Task' in $SrcLogs" }

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


  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Task,
    [string]$RepoRoot = (Join-Path $HOME 'src\work\Work'),
    [string]$SrcLogs  = 'C:\AI_Logs'
  )
  Sync-AITaskLogsToGitHub -Task $Task -RepoRoot $RepoRoot -SrcLogs $SrcLogs




# AI Task Log Sync Helper (CANONICAL: paired header<=summary)


  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Task,
    [string]$RepoRoot = (Join-Path $HOME 'src\work\Work'),
    [string]$SrcLogs  = 'C:\AI_Logs',
    [string]$CommitMessage
  )

  if (-not (Test-Path $RepoRoot)) { throw "Repo missing: $RepoRoot" }
  if (-not (Test-Path $SrcLogs))  { throw "Source logs missing: $SrcLogs" }

  $RepoLogs = Join-Path $RepoRoot 'logs'
  New-Item -ItemType Directory -Force -Path $RepoLogs | Out-Null

  # Pick newest SUMMARY first (authoritative end marker)
  $summary = Get-ChildItem $SrcLogs -Filter "AI_${Task}_SUMMARY_*.log" -File |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
  if (-not $summary) { throw "Missing summary log for task '$Task' in $SrcLogs" }

  # Now pick the closest HEADER at or before the summary time (best pairing)
  $headers = Get-ChildItem $SrcLogs -Filter "AI_${Task}_*.log" -File |
    Where-Object { $_.Name -notmatch '_SUMMARY_' } |
    Sort-Object LastWriteTime -Descending

  $header =
    $headers | Where-Object { $_.LastWriteTime -le $summary.LastWriteTime } | Select-Object -First 1

  # If no earlier header exists, fall back to newest header
  if (-not $header) { $header = $headers | Select-Object -First 1 }

  # If still missing, recover/create one
  if (-not $header) {
    $ts = Get-Date -Format 'yyyy-MM-dd_HHmm'
    $win = Get-ComputerInfo -Property WindowsProductName,WindowsVersion,OsBuildNumber
    $newHeaderPath = Join-Path $SrcLogs ("AI_{0}_{1}.log" -f $Task, $ts)

@"
TASK: $Task
OBJECTIVE: (Recovered) Header missing at sync time; created automatically so GitHub mirror stays consistent.
CONSTRAINTS: PowerShell-only. Logs mirrored from C:\AI_Logs to repo\logs.
WINDOWS: $($win.WindowsProductName) $($win.WindowsVersion) (Build $($win.OsBuildNumber))
POWERSHELL: $($PSVersionTable.PSVersion)
GIT: $(git --version)
START: $(Get-Date -Format o)
"@ | Set-Content -Encoding utf8 $newHeaderPath

    $header = Get-Item $newHeaderPath
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


  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Task,
    [string]$RepoRoot = (Join-Path $HOME 'src\work\Work'),
    [string]$SrcLogs  = 'C:\AI_Logs'
  )
  Sync-AITaskLogsToGitHub -Task $Task -RepoRoot $RepoRoot -SrcLogs $SrcLogs



