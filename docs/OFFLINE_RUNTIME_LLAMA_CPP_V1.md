# OFFLINE_RUNTIME_LLAMA_CPP_V1 (Plan + Operator Notes)

## Goal
Enable fully offline local inference on Windows using a CLI runtime (llama.cpp), while keeping:
- PowerShell-only operation
- No browser dependency
- Repo-backed, auditable configuration + tooling

## This task does NOT install anything
No downloads. No installers. No model acquisition. Only scaffolding + detection + docs.

## Runtime Choice: llama.cpp CLI (GGUF)
We standardize on:
- `llama-cli.exe` (preferred) or `main.exe`
- GGUF model files

## Canonical Paths (operator-managed)
Default config expects:
- Exe: `C:\tools\llama.cpp\llama-cli.exe`
- Model: `D:\models\llm\model.gguf`

You can change these without editing code:
- `config\llm.json` via PowerShell helper: `Set-LLMLocalLlamaCppPaths`

## What we added (repo-backed)
- `scripts\llm\offline-runtime.ps1`
  - `Test-LLMOfflineRuntimePlan` : checks exe/model presence + hints
  - `Find-LLMLlamaCppExe`        : searches common locations + PATH
  - `Set-LLMLocalLlamaCppPaths`  : updates config safely (ShouldProcess)

## Operator workflow (later task: installs/builds)
When you are ready (separate approved task):
1) Obtain/build llama.cpp (operator action, offline/online as you choose)
2) Place `llama-cli.exe` under `C:\tools\llama.cpp\`
3) Place a GGUF model under `D:\models\llm\`
4) Run:
   - `. "$HOME\src\work\Work\scripts\ai-functions.ps1"`
   - `Test-LLMOfflineRuntimePlan | Format-List`
   - `Invoke-LLMTerminal`

## Notes
- No background services are required.
- This approach remains terminal-first and browserless.
