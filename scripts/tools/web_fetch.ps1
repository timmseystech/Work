Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\tools\web_fetch.ps1 "https://example.com/page"

if ($args.Count -lt 1) { throw "Missing URL argument." }
$url = [string]$args[0]

# ---- Hard block dangerous schemes ----
if ($url -match '^(?i)(file|ftp|data|javascript):') { throw "Blocked URL scheme." }

# Parse URI
try { $u = [Uri]$url } catch { throw "Invalid URL: $url" }
if (-not $u.Scheme -or ($u.Scheme -notin @('http','https'))) { throw "Only http/https allowed." }

# Block localhost + private IPs (best-effort)
$host = $u.Host
if ($host -match '^(?i)(localhost|127\.|0\.0\.0\.0|::1)$') { throw "Blocked host: $host" }
if ($host -match '^\d{1,3}(\.\d{1,3}){3}$') {
  if ($host -match '^(10\.|192\.168\.|172\.(1[6-9]|2\d|3[0-1])\.)') { throw "Blocked private IP: $host" }
}

# ---- Allowlist domains (edit as needed) ----
$allow = @(
  'wikipedia.org',
  'docs.microsoft.com',
  'learn.microsoft.com',
  'github.com',
  'raw.githubusercontent.com'
)

$ok = $false
foreach ($d in $allow) {
  if ($host -ieq $d -or $host.EndsWith("." + $d)) { $ok = $true; break }
}
if (-not $ok) { throw "Host not allowlisted: $host" }

# Logging
New-Item -ItemType Directory -Force -Path C:\AI_Logs | Out-Null
$ts = Get-Date -Format "yyyy-MM-dd_HHmmss"
$log = "C:\AI_Logs\web_fetch_${ts}.log"
"URL: $url`nHOST: $host`nTIME: $(Get-Date -Format o)" | Set-Content -Encoding utf8 $log

# ---- Fetch with limits ----
$timeoutSec = 15
$maxBytes   = 2MB

$wc = New-Object System.Net.Http.HttpClient
$wc.Timeout = [TimeSpan]::FromSeconds($timeoutSec)

try {
  $resp = $wc.GetAsync($u).Result
  if (-not $resp.IsSuccessStatusCode) {
    throw ("HTTP {0} {1}" -f [int]$resp.StatusCode, $resp.ReasonPhrase)
  }

  $bytes = $resp.Content.ReadAsByteArrayAsync().Result
  if ($bytes.Length -gt $maxBytes) { throw "Response too large: $($bytes.Length) bytes" }

  $html = [System.Text.Encoding]::UTF8.GetString($bytes)

  # Very simple HTML strip (good enough for now)
  $text = $html -replace '(?s)<script.*?</script>', '' -replace '(?s)<style.*?</style>', ''
  $text = $text -replace '<[^>]+>', ' '
  $text = $text -replace '&nbsp;',' ' -replace '&amp;','&' -replace '&lt;','<' -replace '&gt;','>'
  $text = ($text -split '\r?\n' | ForEach-Object { $_.Trim() } | Where-Object { $_ }) -join "`n"
  $text = $text.Trim()

  # Save a copy for audit
  $out = "C:\AI_Logs\web_fetch_${ts}.txt"
  $text | Set-Content -Encoding utf8 $out

  $text
}
finally {
  $wc.Dispose()
}
