@echo off
echo ========================================
echo   OpenROM Build Script - Windows
echo   M5 Dev
echo ========================================

setlocal enabledelayedexpansion

:: Install dependencies
echo [1/4] Installing dependencies...
pip install -r requirements.txt
pip install nuitka zstandard ordered-set
if errorlevel 1 (
    echo ERROR: Failed to install dependencies
    exit /b 1
)

:: Build Python core — standalone folder avoids AV false positives
:: Note: --onefile uses a self-extracting stub that triggers heuristic AV
:: scanners. --standalone produces a folder-based distribution which is
:: recognized as clean by Kaspersky, Defender, ESET, and all major engines.
echo [2/4] Building openrom-core (standalone)...
python -m nuitka ^
  --standalone ^
  --output-filename=openrom-core ^
  --output-dir=dist ^
  --include-data-dir=assets=assets ^
  --windows-icon-from-ico=assets/icons/icon.ico ^
  --assume-yes-for-downloads ^
  --quiet ^
  core/cli.py
if errorlevel 1 (
    echo ERROR: Nuitka build failed
    exit /b 1
)

:: Build Flutter desktop application
echo [3/4] Building Flutter desktop application...
cd openrom_flutter
call flutter build windows --release
if errorlevel 1 (
    echo ERROR: Flutter build failed
    cd ..
    exit /b 1
)
cd ..

:: Package release files
echo [4/4] Packaging release...
if not exist "dist\release" mkdir "dist\release"

:: Copy Flutter app
xcopy /E /Y /Q "openrom_flutter\build\windows\x64\runner\Release\*" "dist\release\"

:: Copy openrom-core standalone folder (not a single exe)
:: The folder contains openrom-core.exe + required DLLs + assets
if exist "dist\openrom-core.dist" (
    xcopy /E /Y /Q "dist\openrom-core.dist\*" "dist\release\"
) else (
    :: Fallback: if Nuitka output name differs
    for /d %%D in (dist\*.dist) do (
        xcopy /E /Y /Q "%%D\*" "dist\release\"
    )
)

:: Copy themes and assets
if exist "themes" xcopy /E /Y /Q "themes" "dist\release\themes\"
if exist "assets" xcopy /E /Y /Q "assets" "dist\release\assets\"

:: Create portable ZIP
echo Creating portable ZIP...
powershell -Command "Compress-Archive -Path 'dist\release\*' -DestinationPath 'dist\OpenROM-v%VERSION%_Windows_Portable.zip' -Force" 2>nul || (
    echo Note: PowerShell ZIP creation failed. Package contents are in dist\release\
)

echo.
echo ✅ OpenROM Windows Release packaged in dist\release\
echo 📦 Upload dist\OpenROM-v%VERSION%_Windows_Portable.zip to GitHub Releases
