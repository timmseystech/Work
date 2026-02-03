# OFFLINE_RUNTIME_LLAMA_CPP_INSTALL_V1 (Manual Install/Placement Plan)

## Goal
Enable fully offline inference on this Windows machine using llama.cpp CLI + GGUF models, without any browser dependency during runtime.

## Non-goals (this doc does NOT automate)
- No automated downloads
- No installers
- No PATH changes
- No background services

## Canonical layout (operator-managed)
### Runtime
- Tools dir: `C:\tools\llama.cpp\`
- Preferred binary: `llama-cli.exe`
- Fallback binary: `main.exe`

### Models
- Models dir: `D:\models\llm\`
- Model format: `*.gguf`

## Configuration (repo-backed)
- `config\llm.json`:
  - `providers.local-llamacpp.exePath`
  - `providers.local-llamacpp.modelPath`

Use PowerShell helpers to set these (no manual JSON edits required):
- `Set-LLMOfflineDefaults`
- `Set-LLMLocalLlamaCppPaths`
- `Set-LLMModelPath`

## Verification commands
- `Test-LLMOfflineLayout | Format-List`
- `Test-LLMOfflineRuntimePlan | Format-List`
- `Test-LLMSetup | Format-List`

## Operator procedure (manual)
1) Obtain/build llama.cpp (your choice: online/offline/source/binary) **outside** this repo automation.
2) Place binary:
   - `C:\tools\llama.cpp\llama-cli.exe` (preferred) OR `C:\tools\llama.cpp\main.exe`
3) Place models:
   - Put one or more `*.gguf` in `D:\models\llm\`
4) In PowerShell:
   - `. "$HOME\src\work\Work\scripts\ai-functions.ps1"`
   - `Set-LLMOfflineDefaults -WhatIf` then run without `-WhatIf`
   - `Get-LLMModelInventory | Format-Table -AutoSize`
   - `Set-LLMModelPath -NameOrPath "<your-model.gguf>" -WhatIf` then run without `-WhatIf`
   - `Invoke-LLMTerminal`

## Notes
- This stays fully terminal-first.
- No browser is needed once runtime + model are placed.
