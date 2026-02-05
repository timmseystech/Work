Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Optional arg: RepoRoot as first argument
$RepoRoot = if ($args.Count -ge 1 -and $args[0]) { [string]$args[0] } else { Join-Path $HOME 'src\work\Work' }
if (-not (Test-Path $RepoRoot)) { throw "RepoRoot not found: $RepoRoot" }

$protected = @(
  'config/llm.json',
  'scripts/llm/providers/local-llamacpp.ps1',
  'docs/OPERATING_DIRECTIVE_LLM_HARDENED.md',
  'logs/state_index.json'
)

Push-Location $RepoRoot
try {
  # Changed tracked files (unstaged + staged)
  $changed = @(git diff --name-only 2>$null) | Where-Object { $_ }
  $staged  = @(git diff --cached --name-only 2>$null) | Where-Object { $_ }

  $all = @($changed + $staged) | Select-Object -Unique

  $hits = @()
  foreach ($p in $protected) {
    if ($all -contains $p) { $hits += $p }
  }

  if ($hits.Count -gt 0) {
    $msg  = "❌ BASE MODEL V1 VIOLATION: Protected files modified:`n - " + ($hits -join "`n - ")
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
