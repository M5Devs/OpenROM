@echo off
echo ========================================
echo   OpenROM Build Script - Windows
echo   M5 Dev
echo ========================================

:: Install dependencies
echo [1/4] Installing dependencies...
pip install -r requirements.txt
pip install pyinstaller>=6.0.0

:: Build Python core executable
echo [2/4] Building openrom-core executable...
pyinstaller ^
  --noconfirm ^
  --onefile ^
  --name "openrom-core" ^
  --add-data "assets;assets" ^
  --icon "assets/icon.ico" ^
  core/cli.py

:: Build Flutter desktop executable
echo [3/4] Building Flutter desktop application...
cd openrom_flutter
call flutter build windows --release
cd ..

:: Package release files
echo [4/4] Packaging release...
if not exist "dist\release" mkdir "dist\release"
xcopy /E /Y "openrom_flutter\build\windows\x64\runner\Release\*" "dist\release\"
copy /Y "dist\openrom-core.exe" "dist\release\"
if exist "themes" xcopy /E /Y "themes" "dist\release\themes\"
if exist "assets" xcopy /E /Y "assets" "dist\release\assets\"

echo.
echo ✅ OpenROM Windows Release packaged in dist\release\
