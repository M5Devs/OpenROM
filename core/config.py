import os
import json
import platform

APP_NAME = "OpenROM"

def get_config_dir() -> str:
    """
    Returns the correct OS-specific config directory:
      Windows : %APPDATA%\OpenROM
      macOS   : ~/Library/Application Support/OpenROM
      Linux   : ~/.config/openrom
    """
    system = platform.system()
    if system == "Windows":
        base = os.environ.get("APPDATA", os.path.expanduser("~"))
        path = os.path.join(base, APP_NAME)
    elif system == "Darwin":
        path = os.path.join(os.path.expanduser("~"), "Library", "Application Support", APP_NAME)
    else:  # Linux + fallback
        xdg = os.environ.get("XDG_CONFIG_HOME", os.path.join(os.path.expanduser("~"), ".config"))
        path = os.path.join(xdg, APP_NAME.lower())
    os.makedirs(path, exist_ok=True)
    return path

CONFIG_FILE = os.path.join(get_config_dir(), "config.json")

def get_default_bundled_path(tool: str) -> str:
    """
    Returns the bundled binary path for the given tool.
    Windows : assets/windows/<tool>.exe
    macOS   : assets/macos/<arch>/<tool>  (arm64 or x86_64)
    Linux   : assets/linux/<tool>
    """
    system = platform.system()
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    win_names = {
        "chdman":       "chdman.exe",
        "ecm":          "ecm.exe",
        "unecm":        "unecm.exe",
        "maxcso":       "maxcso.exe",
        "extract-xiso": "extract-xiso.exe",
        "nodtool":      "nodtool.exe",
        "xdelta3":      "xdelta3.exe",      # ← جديد
    }
    unix_names = {
        "chdman":       "chdman",
        "ecm":          "ecm",
        "unecm":        "unecm",
        "maxcso":       "maxcso",
        "extract-xiso": "extract-xiso",
        "nodtool":      "nodtool",
        "xdelta3":      "xdelta3",          # ← جديد
    }

    if system == "Windows":
        fname  = win_names.get(tool, tool + ".exe")
        folder = "windows"
        bundled = os.path.join(base, "assets", folder, fname)

    elif system == "Darwin":
        fname = unix_names.get(tool, tool)
        # macOS: try arch-specific folder first (arm64 / x86_64)
        import struct
        arch = "arm64" if struct.calcsize("P") * 8 == 64 and platform.machine() == "arm64" else "x86_64"
        bundled = os.path.join(base, "assets", "macos", arch, fname)
        # fallback to flat macos/ folder (non-arch-split tools)
        if not os.path.isfile(bundled):
            bundled = os.path.join(base, "assets", "macos", fname)

    else:  # Linux
        fname   = unix_names.get(tool, tool)
        folder  = "linux"
        bundled = os.path.join(base, "assets", folder, fname)

    if os.path.isfile(bundled):
        return bundled

    # Not bundled — fall back to system PATH
    return unix_names.get(tool, tool) if system != "Windows" else win_names.get(tool, tool)


DEFAULT_CONFIG = {
    "chdman":       "",
    "maxcso":       "",
    "ecm":          "",
    "unecm":        "",
    "extract-xiso": "",
    "nodtool":      "",
    "xdelta3":      "",   # ← جديد
}

def load_config() -> dict:
    if os.path.exists(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, "r", encoding="utf-8") as f:
                config = json.load(f)
            for k in DEFAULT_CONFIG:
                if k not in config:
                    config[k] = ""
            return config
        except Exception:
            pass
    return DEFAULT_CONFIG.copy()

def save_config(config: dict):
    try:
        with open(CONFIG_FILE, "w", encoding="utf-8") as f:
            json.dump(config, f, indent=4)
    except Exception:
        pass

def get_tool_path(tool: str) -> str:
    config = load_config()
    val = config.get(tool, "")
    if val and (os.path.exists(val) or os.path.isabs(val)):
        return val
    return get_default_bundled_path(tool)
