# Architecture Freeze — v1.0

Date: 2026-02-03T18:03:42.4417654+10:00
Repo: Work (timmseystech/Work)
Branch: main
Commit (at freeze start): 84a6dbb80a449720b401b7290426b43f7d1a99a9
Git: git version 2.52.0.windows.1

## Purpose
This repository is the canonical source-of-truth for:
- Git identity scoping (personal/work)
- AI logs synced to GitHub
- Save-state system (logs + index + tags)
- Restore workflow + auto-checkpoint helper

## Invariants (DO NOT BREAK)
### Repo layout
- logs/ holds all AI_* logs and AI_STATE_* save-state logs
- logs/state_index.json is the authoritative save-state index (must remain a JSON array)
- docs/ holds auditing docs (e.g. profile snapshot)

### Git requirements
- Work repos use work identity (timmseystech@gmail.com) via includeIf scoping
- Save states are tagged as: ai-state/<slug>
- Tagging uses annotated tags with -m (no editor)

### Logging requirements
- Session header + summary logs must exist per task
- Logs must be committed/pushed to GitHub (force-add if global *.log ignore exists)
- New-AISaveState must:
  - Self-heal index file
  - Enforce array semantics
  - Commit logs + index
  - Create annotated tag
  - Push with tags

### Restore requirements
- Restore blocks if working tree is dirty
- Restore supports:
  - Detached checkout at tag
  - Optional restore branch (restore/<slug>)

### Auto-checkpoint
- Invoke-AIAutoCheckpoint is canonical (single definition)
- It wraps New-AISaveState with deterministic naming

## Operational Commands
### List states
Get-AISaveStates | Sort-Object { [datetime]$_.timestamp } -Descending | Select name,slug,commit,timestamp,log

### Create save state
New-AISaveState -Name "<label>" -Objective "<what>" -Notes "<context>"

### Auto-checkpoint
Invoke-AIAutoCheckpoint -Task "<TASK>" -Objective "<what>" -Notes "<context>" -IncludeDateInName

### Restore
Restore-AISaveState -Slug "<slug>" -CreateBranch

## Notes
If the PowerShell profile becomes large, migrate functions into a versioned script:
scripts/ai-functions.ps1 and dot-source once from profile.
