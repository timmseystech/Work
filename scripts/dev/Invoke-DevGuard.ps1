Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

[CmdletBinding()]
param(
  [string]$RepoRoot = (Join-Path $HOME 'src\work\Work')
)

& (Join-Path $RepoRoot 'scripts\dev\Assert-BaseModelUnchanged.ps1') -RepoRoot $RepoRoot
