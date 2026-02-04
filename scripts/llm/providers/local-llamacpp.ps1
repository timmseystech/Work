Set-StrictMode -Version Latest

function Invoke-LLMProviderLocalLlamaCpp {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Prompt,
    [Parameter(Mandatory)]$Config
  )

  $p = $Config.providers.'local-llamacpp'
  if (-not $p) { throw "local-llamacpp provider config missing in config\llm.json" }

  $exe   = [string]$p.exePath
  $model = [string]$p.modelPath

  if (-not (Test-Path $exe))   { throw "llama.cpp exe not found: $exe (offline runtime not installed yet)" }
  if (-not (Test-Path $model)) { throw "model file not found: $model (GGUF not present yet)" }

  $args = @()
  $args += @('-m', $model)
  if ($p.defaultArgs) { $args += $p.defaultArgs }
  $args += @('-p', $Prompt)

  function Join-Win32CmdLine {
    param([string[]]$Args)

    # Windows CreateProcess command-line quoting rules (similar to Python subprocess list2cmdline)
    $out = foreach ($a in $Args) {
      if ($null -eq $a) { '""'; continue }

      $s = [string]$a
      if ($s -notmatch '[\s"]') { $s; continue }

      $sb = New-Object System.Text.StringBuilder
      [void]$sb.Append('"')

      $bs = 0
      foreach ($ch in $s.ToCharArray()) {
        if ($ch -eq '\') {
          $bs++
          continue
        }
        if ($ch -eq '"') {
          # escape backslashes + quote
          [void]$sb.Append('\'.PadLeft($bs * 2 + 1, '\'))
          [void]$sb.Append('"')
          $bs = 0
          continue
        }
        if ($bs -gt 0) { [void]$sb.Append('\'.PadLeft($bs, '\')); $bs = 0 }
        [void]$sb.Append($ch)
      }
      if ($bs -gt 0) { [void]$sb.Append('\'.PadLeft($bs * 2, '\')) }

      [void]$sb.Append('"')
      $sb.ToString()
    }

    return ($out -join ' ')
  }

  $stdoutFile = Join-Path $env:TEMP ("llama_stdout_{0}.txt" -f ([guid]::NewGuid().ToString('N')))
  $stderrFile = Join-Path $env:TEMP ("llama_stderr_{0}.txt" -f ([guid]::NewGuid().ToString('N')))

  try {
    # IMPORTANT: pass a SINGLE properly-quoted command line string
    $argLine = Join-Win32CmdLine -Args $args

    $proc = Start-Process -FilePath $exe -ArgumentList $argLine -NoNewWindow -Wait -PassThru `
      -RedirectStandardOutput $stdoutFile -RedirectStandardError $stderrFile

    $stdout = Get-Content -Raw -Path $stdoutFile -ErrorAction SilentlyContinue
    $stderr = Get-Content -Raw -Path $stderrFile -ErrorAction SilentlyContinue

    if ($proc.ExitCode -ne 0) {
      throw ("llama.cpp failed (exit {0}): {1}" -f $proc.ExitCode, ($stderr.Trim()))
    }

    return ($stdout.Trim())
  }
  finally {
    Remove-Item -Force -ErrorAction SilentlyContinue $stdoutFile, $stderrFile | Out-Null
  }
}



