Local LLM – Quick Start (Windows PowerShell 5.1)



This repository provides a repo-backed, recovery-safe local LLM runtime powered by llama.cpp, plus a simple PowerShell launcher.



This system is hardened and state-driven. Follow the rules below exactly.



🚨 HARD RULES (DO NOT VIOLATE)



These rules are based on real breakages that caused hangs, garbage output, or total runtime failure.



❌ NEVER re-add --chat-template qwen



❌ NEVER combine --chat-template with --simple-io



❌ Do NOT mix stdin (--simple-io) with prompt flags (-p)



❌ Do NOT assume llama-cli exits cleanly on its own



❌ Do NOT change LLM-related config without a baseline test + save-state



✔ After any LLM-related change, always validate with this exact prompt:



Say LLM OK and nothing else.



Expected output (exact):



LLM OK



If this fails, STOP and roll back immediately.



Prerequisites



Windows 10 / 11



Windows PowerShell 5.1



Repository cloned to:



%USERPROFILE%\\src\\work\\Work



llama.cpp binary and model paths configured in:



config\\llm.json



Simple LLM Launcher



Launcher script location:



scripts\\llm\\Invoke-LLM.ps1



This is the only supported human entrypoint for running the LLM.



One-Shot Prompt (Recommended)



Open PowerShell and run:



cd %USERPROFILE%\\src\\work\\Work

powershell -NoProfile -ExecutionPolicy Bypass -File scripts\\llm\\Invoke-LLM.ps1 --nohistory --prompt "Say LLM OK and nothing else."



Expected output:



LLM OK



REPL Mode (Interactive)



Start an interactive session:



powershell -NoProfile -ExecutionPolicy Bypass -File scripts\\llm\\Invoke-LLM.ps1 --repl



REPL commands:



/exit — quit the session



/clear — clear the screen only



Example:



You> Hello

LLM> Hello! How can I help you today?



Provider Selection (Optional)



You can explicitly choose a provider:



powershell -NoProfile -ExecutionPolicy Bypass -File scripts\\llm\\Invoke-LLM.ps1 --provider local-llamacpp --prompt "Hello"



If omitted, the provider defined in config\\llm.json is used.



Disable History Logging (Sensitive Prompts)



Use the --nohistory flag to prevent prompt logging:



--nohistory



Strongly recommended for credentials, tokens, or testing.



Baseline Health Check (Manual)



You can always verify system health manually:



Load the functions:



. %USERPROFILE%\\src\\work\\Work\\scripts\\ai-functions.ps1



Run the baseline:



Invoke-LLMChat -Provider local-llamacpp -NoHistory -Prompt "Say LLM OK and nothing else."



The result must be:



LLM OK



Troubleshooting

LLM hangs or produces no output



Kill any stuck processes:



Get-Process llama-cli -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue



Then rerun the baseline test.



PowerShell 5.1 stderr behavior



Windows PowerShell 5.1 may treat native stderr output as terminating errors when:



$ErrorActionPreference = 'Stop'



Tooling scripts explicitly guard against this behavior.

Do not remove those safeguards.



Recovery (Last Resort)



If anything breaks and debugging is unclear, roll back to the last known-good state:



git fetch --all --tags

git reset --hard ai-state/llm-llamacpp-stable-simple-io



Then immediately rerun the baseline prompt.



Final Notes



Base Model v1 is frozen



Protected files must not be modified during tooling work



Tooling extensions must be additive only



When in doubt: rollback first, debug second

