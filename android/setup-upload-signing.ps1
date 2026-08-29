$ErrorActionPreference = "Stop"

$keyPath = Join-Path $env:USERPROFILE "upload-keystore.jks"
if (-not (Test-Path $keyPath)) {
  Write-Host "No upload keystore found at $keyPath"
  Write-Host "Create one first with keytool, then run this script again."
  exit 1
}

$password = Read-Host "Enter upload keystore password"
$content = @"
storePassword=$password
keyPassword=$password
keyAlias=upload
storeFile=$($keyPath.Replace('\', '\\'))
"@

$outPath = Join-Path $PSScriptRoot "key.properties"
Set-Content -LiteralPath $outPath -Value $content -Encoding ASCII
Write-Host "Wrote $outPath"
Write-Host "Now build with: flutter build appbundle"
