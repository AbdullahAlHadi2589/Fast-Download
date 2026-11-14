# Test script for fast-download skill
# Run this to verify the skill works correctly

# Import the module
Import-Module "C:\Users\abdul\.config\opencode\skill\fast-download\FastDownload.psm1" -Force

Write-Host "=== Fast Download Skill Test ===" -ForegroundColor Green

# Test 1: Initialize and check tools
Write-Host "`n1. Checking tools..." -ForegroundColor Cyan
Initialize-FastDownload

# Test 2: Download a small file with aria2
Write-Host "`n2. Testing aria2 download (small file)..." -ForegroundColor Cyan
$testFile = "$env:TEMP\test-aria2-small.zip"
$result = Invoke-FastDownload -Url "https://github.com/aria2/aria2/releases/download/release-1.37.0/aria2-1.37.0-win-64bit-build1.zip" -OutputPath $testFile
if ($result) {
    Write-Host "SUCCESS: File downloaded" -ForegroundColor Green
    $size = (Get-Item $testFile).Length
    Write-Host "Size: $([math]::Round($size/1MB, 2)) MB" -ForegroundColor Gray
    Remove-Item $testFile -Force
}
else {
    Write-Host "FAILED" -ForegroundColor Red
}

# Test 3: Download with curl fallback
Write-Host "`n3. Testing curl fallback..." -ForegroundColor Cyan
$testFile = "$env:TEMP\test-curl-small.zip"
$result = Invoke-FastDownload -Url "https://github.com/aria2/aria2/releases/download/release-1.37.0/aria2-1.37.0-win-64bit-build1.zip" -OutputPath $testFile -ForceCurl
if ($result) {
    Write-Host "SUCCESS: File downloaded with curl" -ForegroundColor Green
    $size = (Get-Item $testFile).Length
    Write-Host "Size: $([math]::Round($size/1MB, 2)) MB" -ForegroundColor Gray
    Remove-Item $testFile -Force
}
else {
    Write-Host "FAILED" -ForegroundColor Red
}

# Test 4: Git shallow clone
Write-Host "`n4. Testing Git shallow clone..." -ForegroundColor Cyan
$testDir = "$env:TEMP\git-shallow-test"
if (Test-Path $testDir) { Remove-Item $testDir -Recurse -Force }
$result = Invoke-GitClone -Url "https://github.com/git/git.git" -OutputPath $testDir -Shallow
if ($result) {
    Write-Host "SUCCESS: Repository cloned (shallow)" -ForegroundColor Green
    $count = (Get-ChildItem $testDir -Recurse -File).Count
    Write-Host "Files: $count" -ForegroundColor Gray
    Remove-Item $testDir -Recurse -Force
}
else {
    Write-Host "FAILED" -ForegroundColor Red
}

# Test 5: Checksum verification
Write-Host "`n5. Testing checksum verification..." -ForegroundColor Cyan
$testFile = "$env:TEMP\checksum-test.txt"
"Hello, World!" | Set-Content $testFile
$hash = (Get-FileHash -Path $testFile -Algorithm SHA256).Hash
$result = Test-FileChecksum -FilePath $testFile -ExpectedHash $hash -Algorithm SHA256
Remove-Item $testFile -Force

Write-Host "`n=== All Tests Complete ===" -ForegroundColor Green