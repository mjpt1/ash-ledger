# Build debug APK for Keepy Pro (requires JDK 17+)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path "$root\android")) { $root = $PSScriptRoot }

$portable = Get-ChildItem "$root\.tools" -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "jdk-17*" } | Select-Object -First 1
if ($portable) {
  $env:JAVA_HOME = $portable.FullName
} elseif ($env:JAVA_HOME) {
  # keep existing
} else {
  $ms = Get-ChildItem "C:\Program Files\Microsoft" -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "jdk-17*" } | Select-Object -First 1
  if ($ms) { $env:JAVA_HOME = $ms.FullName }
}

if (-not $env:JAVA_HOME) {
  Write-Host "JAVA_HOME پیدا نشد. Android Studio را باز کن یا JDK 17 نصب کن."
  Write-Host "سپس: npx cap open android"
  exit 1
}

$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
Write-Host "Using JAVA_HOME=$env:JAVA_HOME"

Push-Location $root
npm run cap:sync
Set-Location "$root\android"
.\gradlew.bat assembleDebug --no-daemon
Pop-Location

$apk = Get-ChildItem "$root\android\app\build\outputs\apk\debug\*.apk" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($apk) {
  $out = "$root\dist"
  New-Item -ItemType Directory -Force -Path $out | Out-Null
  Copy-Item $apk.FullName "$out\keepy-pro-debug.apk" -Force
  Write-Host "APK: $out\keepy-pro-debug.apk"
} else {
  Write-Host "APK ساخته نشد."
  exit 1
}
