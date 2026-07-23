$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $repoRoot '.env.local'

if (-not (Test-Path -LiteralPath $envFile)) {
  throw 'Missing .env.local. Debug APKs need it for SafeSpend public Supabase and feature configuration.'
}

$requiredKeys = @(
  'SUPABASE_URL',
  'SUPABASE_ANON_KEY',
  'SUPABASE_AUTH_CALLBACK'
)

$envValues = @{}
Get-Content -LiteralPath $envFile | ForEach-Object {
  if ($_ -match '^\s*#' -or $_ -notmatch '=') {
    return
  }

  $parts = $_ -split '=', 2
  $key = $parts[0].Trim()
  $value = $parts[1].Trim()
  if ($key) {
    $envValues[$key] = $value
  }
}

$missing = $requiredKeys | Where-Object {
  -not $envValues.ContainsKey($_) -or [string]::IsNullOrWhiteSpace($envValues[$_])
}

if ($missing.Count -gt 0) {
  throw "Missing required debug APK env value(s): $($missing -join ', ')"
}

$clientDefineKeys = @(
  'SUPABASE_URL',
  'SUPABASE_ANON_KEY',
  'SUPABASE_AUTH_CALLBACK',
  'AI_ALLOWED_EMAILS',
  'AI_OPEN_TO_ALL'
)
$clientDefines = [ordered]@{}
foreach ($key in $clientDefineKeys) {
  if ($envValues.ContainsKey($key) -and -not [string]::IsNullOrWhiteSpace($envValues[$key])) {
    $clientDefines[$key] = $envValues[$key]
  }
}

$defineFile = New-TemporaryFile
try {
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText(
    $defineFile.FullName,
    ($clientDefines | ConvertTo-Json -Compress),
    $utf8NoBom
  )

  Push-Location $repoRoot
  try {
    Write-Host 'Building debug APK with whitelisted public Supabase and feature configuration from .env.local...'
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $buildOutput = & flutter build apk --debug "--dart-define-from-file=$($defineFile.FullName)" 2>&1
    $ErrorActionPreference = $previousErrorActionPreference
    if ($LASTEXITCODE -ne 0) {
      $safeOutput = $buildOutput | ForEach-Object {
        ($_ -replace '-Pdart-defines=[^\s"]+', '-Pdart-defines=<hidden>')
      }
      $safeOutput | Write-Error
      throw "flutter build failed with exit code $LASTEXITCODE"
    }
    Write-Host 'Built build\app\outputs\flutter-apk\app-debug.apk'
  } finally {
    Pop-Location
  }
} finally {
  Remove-Item -LiteralPath $defineFile.FullName -Force -ErrorAction SilentlyContinue
}
