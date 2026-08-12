# create-deploy-zip.ps1
# Run from the wacrm project root after `npm run build`.
# Creates a ready-to-upload zip containing the standalone Next.js output.

$ProjectRoot = $PSScriptRoot
$ZipPath = Join-Path $ProjectRoot "wacrm-deploy.zip"

# Remove old zip if exists
if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }

# The standalone build is in .next/standalone
# It contains everything needed to run: server.js + node_modules tree
$StandalonePath = Join-Path $ProjectRoot ".next\standalone"

if (-not (Test-Path $StandalonePath)) {
    Write-Error "Standalone build not found at $StandalonePath. Run 'npm run build' first."
    exit 1
}

Write-Host "Packaging standalone build..." -ForegroundColor Cyan

# Create a temp staging dir
$TempDir = Join-Path $env:TEMP "wacrm-deploy-$(Get-Random)"
New-Item -ItemType Directory -Path $TempDir | Out-Null

# Copy standalone server
Copy-Item -Recurse "$StandalonePath\*" $TempDir

# Copy static assets (required — standalone doesn't include these)
$StaticDest = Join-Path $TempDir ".next\static"
New-Item -ItemType Directory -Path $StaticDest -Force | Out-Null
Copy-Item -Recurse (Join-Path $ProjectRoot ".next\static\*") $StaticDest

# Copy public folder
$PublicDest = Join-Path $TempDir "public"
New-Item -ItemType Directory -Path $PublicDest -Force | Out-Null
Copy-Item -Recurse (Join-Path $ProjectRoot "public\*") $PublicDest

# Zip it
Write-Host "Compressing to $ZipPath..." -ForegroundColor Cyan
Compress-Archive -Path "$TempDir\*" -DestinationPath $ZipPath -Force

# Cleanup temp
Remove-Item -Recurse -Force $TempDir

$ZipSize = [math]::Round((Get-Item $ZipPath).Length / 1MB, 1)
Write-Host "Done! $ZipPath ($ZipSize MB)" -ForegroundColor Green
Write-Host ""
Write-Host "To run the standalone build locally:" -ForegroundColor Yellow
Write-Host "  node server.js" -ForegroundColor Yellow
