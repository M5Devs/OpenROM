@echo off
if exist bins (
    echo === Verifying OpenROM-bins checksums ===
    cd bins
    powershell -Command "Get-Content checksums.sha256 | ForEach-Object { $line = $_; $parts = $line -split '  '; if ($parts.Length -eq 2) { $hash = $parts[0].Trim(); $file = $parts[1].Trim(); if (Test-Path $file) { $actual = (Get-FileHash -Algorithm SHA256 $file).Hash.ToLower(); if ($actual -ne $hash) { Write-Error 'Checksum mismatch'; throw 'Checksum error' } } } }"
    if errorlevel 1 goto fail
    cd ..
)
echo === Building OpenROM Core (Dart CLI) ===
cd core
call dart pub get
call dart compile exe bin/openrom.dart -o ..\openrom-core.exe
cd ..

echo === Building OpenROM Flutter UI ===
cd gui
call flutter pub get
call flutter build windows --release
cd ..

echo === Build Complete ===

goto ok
:fail
call
:ok
