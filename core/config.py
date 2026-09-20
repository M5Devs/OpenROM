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

_config_cache: dict | None = None

def get_default_bundled_path(tool: str) -> str:
    """
    Returns the bundled binary path for the given tool.
    Windows : assets/windows/<tool>.exe
    macOS   : assets/macos/<arch>/<tool>  (arm64 or x86_64)
    Linux   : assets/linux/<arch>/<tool>  (x86_64 or arm64)
              Falls back to assets/linux/<tool> if arch subfolder is missing.
    """
    system = platform.system()
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    # Special case: nkit lives in its own subfolder
    if tool == "nkit":
        machine     = platform.machine()
        arch_folder = "arm64" if machine == "aarch64" else ("arm64" if machine == "arm64" else "x86_64")
        if system == "Windows":
            return os.path.join(base, "assets", "windows", "nkit", "nkit.exe")
        elif system == "Darwin":
            return os.path.join(base, "assets", "macos", arch_folder, "nkit", "nkit")
        else:
            return os.path.join(base, "assets", "linux", arch_folder, "nkit", "nkit")

    win_names = {
        "chdman":         "chdman.exe",
        "ecm":            "ecm.exe",
        "unecm":          "unecm.exe",
        "maxcso":         "maxcso.exe",
        "extract-xiso":   "extract-xiso.exe",
        "nodtool":        "nodtool.exe",
        "xdelta3":        "xdelta3.exe",      # ← جديد
        "nkit":           "nkit.exe",
        "saturn-patcher": "saturn-patcher.exe",
    }
    unix_names = {
        "chdman":         "chdman",
        "ecm":            "ecm",
        "unecm":          "unecm",
        "maxcso":         "maxcso",
        "extract-xiso":   "extract-xiso",
        "nodtool":        "nodtool",
        "xdelta3":        "xdelta3",          # ← جديد
        "nkit":           "nkit",
        "saturn-patcher": "saturn-patcher",
    }

    if system == "Windows":
        fname  = win_names.get(tool, tool + ".exe")
        folder = "windows"
        bundled = os.path.join(base, "assets", folder, fname)

    elif system == "Darwin":
        fname = unix_names.get(tool, tool)
        # macOS: try arch-specific folder first (arm64 / x86_64)
        arch = platform.machine()  # "arm64" on Apple Silicon, "x86_64" on Intel
        if arch not in ("arm64", "x86_64"):
            arch = "x86_64"  # safe fallback for unknown architectures
        bundled = os.path.join(base, "assets", "macos", arch, fname)
        # fallback to flat macos/ folder (non-arch-split tools)
        if not os.path.isfile(bundled):
            bundled = os.path.join(base, "assets", "macos", fname)

    else:  # Linux
        fname        = unix_names.get(tool, tool)
        machine      = platform.machine()                        # "x86_64" or "aarch64"
        arch_folder  = "arm64" if machine == "aarch64" else "x86_64"
        bundled      = os.path.join(base, "assets", "linux", arch_folder, fname)
        # Fallback: if arch-specific binary doesn't exist, try the flat linux/ folder
        # (supports older installs or partial bundles)
        if not os.path.isfile(bundled):
            bundled = os.path.join(base, "assets", "linux", fname)

    if os.path.isfile(bundled):
        return bundled

    # Not bundled — fall back to system PATH
    return unix_names.get(tool, tool) if system != "Windows" else win_names.get(tool, tool)


DEFAULT_CONFIG = {
    "chdman":         "",
    "maxcso":         "",
    "ecm":            "",
    "unecm":          "",
    "extract-xiso":   "",
    "nodtool":        "",
    "xdelta3":        "",   # ← جديد
    "nkit":           "",
    "saturn-patcher": "",
}

def load_config() -> dict:
    global _config_cache
    if _config_cache is not None:
        return _config_cache
    if os.path.exists(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, "r", encoding="utf-8") as f:
                config = json.load(f)
            for k in DEFAULT_CONFIG:
                if k not in config:
                    config[k] = ""
            _config_cache = config
            return _config_cache
        except Exception:
            pass
    _config_cache = DEFAULT_CONFIG.copy()
    return _config_cache

def save_config(config: dict):
    global _config_cache
    try:
        with open(CONFIG_FILE, "w", encoding="utf-8") as f:
            json.dump(config, f, indent=4)
        _config_cache = None  # invalidate cache after save
    except Exception:
        pass

def get_tool_path(tool: str) -> str:
    config = load_config()
    val = config.get(tool, "")
    if val and (os.path.exists(val) or os.path.isabs(val)):
        return val
    return get_default_bundled_path(tool)
