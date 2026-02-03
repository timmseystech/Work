# Standalone LLM Terminal (V1)

## Goal
A PowerShell-native terminal UI that can:
- Run offline local models (future) on this Windows machine
- Optionally call OpenAI when online
- Avoid browser dependency
- Keep everything auditable in the Work repo

## Entry
- Function: Invoke-LLMTerminal

## Config
- File: config\llm.json
- provider: "local-llamacpp" (default) or "openai"

## Providers
- local-llamacpp: placeholder for llama.cpp CLI execution
- openai: minimal REST adapter using env var OPENAI_API_KEY

## Usage
In any PowerShell session:
  . "$HOME\src\work\Work\scripts\ai-functions.ps1"
  Invoke-LLMTerminal

Switch provider:
  /provider openai
  /provider local-llamacpp

## Notes
- No model downloads or external installs are performed by this scaffold.
- Offline runtime (llama.cpp) and model acquisition will be a separate task.
