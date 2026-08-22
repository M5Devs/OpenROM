#!/bin/bash
# OpenROM Flatpak launcher
export PYTHONPATH="/app/lib/openrom:$PYTHONPATH"
export PATH="/app/bin:$PATH"
cd /app/lib/openrom
exec python3 main.py "$@"
