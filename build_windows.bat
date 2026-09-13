@echo off
echo ========================================
echo   OpenROM Build Script - Windows
echo   M5 Dev
echo ========================================

:: Install dependencies
echo [1/4] Installing dependencies...
pip install -r requirements.txt
pip install nuitka zstandard ordered-set

:: Build Python core executable
echo [2/4] Building openrom-core executable...
python -m nuitka ^
  --onefile ^
  --output-filename=openrom-core ^
  --output-dir=dist ^
  --include-data-dir=assets=assets ^
  --windows-icon-from-ico=assets/icon.ico ^
  --assume-yes-for-downloads ^
  --quiet ^
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
