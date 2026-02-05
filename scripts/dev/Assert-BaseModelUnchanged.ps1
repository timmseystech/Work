Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

<#
  Assert-BaseModelUnchanged.ps1
  Purpose: hard-fail if protected "base model v1" files are modified in the working tree.
  Usage: .\scripts\dev\Assert-BaseModelUnchanged.ps1 -RepoRoot <path>
#>

[CmdletBinding()]
param(
  [string]$RepoRoot = (Join-Path $HOME 'src\work\Work')
)

if (-not (Test-Path $RepoRoot)) { throw "RepoRoot not found: $RepoRoot" }

$protected = @(
  'config/llm.json',
  'scripts/llm/providers/local-llamacpp.ps1',
  'docs/OPERATING_DIRECTIVE_LLM_HARDENED.md',
  'logs/state_index.json'
)

Push-Location $RepoRoot
try {
  # List changed files (tracked)
  $changed = @(git diff --name-only)
  $staged  = @(git diff --cached --name-only)

  $all = @($changed + $staged) | Where-Object { $_ } | Select-Object -Unique

  $hits = @()
  foreach ($p in $protected) {
    if ($all -contains $p) { $hits += $p }
  }

  if ($hits.Count -gt 0) {
    $msg = "❌ BASE MODEL V1 VIOLATION: Protected files modified:`n - " + ($hits -join "`n - ")
    $msg += "`n`nRollback options:"
    $msg += "`n  git restore --staged --worktree -- " + ($hits -join ' ')
    $msg += "`n  OR: git reset --hard ai-state/operating-directive-llm-hardened-v1"
    throw $msg
  }

  "✅ Base model v1 protected files untouched." | Out-Host
}
finally {
  Pop-Location
}
