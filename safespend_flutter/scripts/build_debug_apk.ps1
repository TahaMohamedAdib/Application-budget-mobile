$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $repoRoot '.env.local'

if (-not (Test-Path -LiteralPath $envFile)) {
  throw 'Missing .env.local. Debug APKs need it so SafeSpend AI has its Gemini/Supabase configuration.'
}

$requiredKeys = @(
  'GEMINI_API_KEY',
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

Push-Location $repoRoot
try {
  Write-Host 'Building debug APK with .env.local so SafeSpend AI is configured...'
  $previousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  $buildOutput = & flutter build apk --debug --dart-define-from-file=.env.local 2>&1
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
