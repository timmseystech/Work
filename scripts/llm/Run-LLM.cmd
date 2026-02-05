@echo off
setlocal

REM Run-LLM.cmd - Double-click launcher for the repo LLM
REM Uses repo scripts\llm\Invoke-LLM.ps1 (REPL by default).
REM Optional: pass args, e.g.:
REM   Run-LLM.cmd --nohistory --prompt "Say LLM OK and nothing else."
REM   Run-LLM.cmd --repl --nohistory

set "REPO=%~dp0..\.."
for %%I in ("%REPO%") do set "REPO=%%~fI"

powershell -NoProfile -ExecutionPolicy Bypass -File "%REPO%\scripts\llm\Invoke-LLM.ps1" %*
if errorlevel 1 (
  echo.
  echo LLM launcher exited with errorlevel %errorlevel%.
  pause
)
endlocal
