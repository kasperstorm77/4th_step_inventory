# Build Windows Release and create ZIP distribution
# Usage: .\scripts\build_windows_release.ps1

$ErrorActionPreference = "Stop"

Write-Host "Building Windows release..." -ForegroundColor Cyan

# Build the release
flutter build windows --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Build successful!" -ForegroundColor Green

# Get version from pubspec.yaml
$pubspec = Get-Content "pubspec.yaml" -Raw
if ($pubspec -match 'version:\s*(\d+\.\d+\.\d+)\+(\d+)') {
    $version = $matches[1]
    $buildNumber = $matches[2]
    $versionString = "$version+$buildNumber"
} else {
    $versionString = "unknown"
}

# Create output directory if it doesn't exist
$outputDir = "build\releases"
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

# Create ZIP filename with version
$zipName = "twelvestepsapp-windows-$versionString.zip"
$zipPath = "$outputDir\$zipName"

# Remove existing ZIP if present
if (Test-Path $zipPath) {
    Remove-Item $zipPath
}

Write-Host "Creating ZIP: $zipName" -ForegroundColor Cyan

# Create the ZIP
Compress-Archive -Path "build\windows\x64\runner\Release\*" -DestinationPath $zipPath

if ($LASTEXITCODE -eq 0 -or (Test-Path $zipPath)) {
    $size = [math]::Round((Get-Item $zipPath).Length / 1MB, 2)
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Windows release ready!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "File: $zipPath" -ForegroundColor White
    Write-Host "Size: $size MB" -ForegroundColor White
    Write-Host "Version: $versionString" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "Failed to create ZIP!" -ForegroundColor Red
    exit 1
}
