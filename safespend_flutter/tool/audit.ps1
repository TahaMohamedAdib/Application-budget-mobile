[CmdletBinding()]
param(
  [switch]$SkipBundle
)

$ErrorActionPreference = 'Stop'

flutter pub get
flutter analyze
flutter test

if (-not $SkipBundle) {
  flutter build appbundle --release
}

Write-Host 'Audit checks completed.'
