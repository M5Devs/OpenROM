@echo off
echo === Building OpenROM Core (Dart CLI) ===
cd core
call dart pub get
call dart compile exe bin/openrom.dart -o ..\openrom-core.exe
cd ..

echo === Building OpenROM Flutter UI ===
cd openrom_flutter
call flutter pub get
call flutter build windows --release
cd ..

echo === Build Complete ===
