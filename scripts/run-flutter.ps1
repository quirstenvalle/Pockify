$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..\flutter_app")
flutter pub get
$devices = flutter devices 2>&1 | Out-String
if ($devices -match "(?i)\bedge\b") {
  flutter run -d edge
} else {
  flutter run -d chrome
}
