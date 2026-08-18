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
    macOS   : assets/macos/<tool>   (falls back to PATH / brew)
    Linux   : assets/linux/<tool>   (falls back to PATH / apt)
    """
    system = platform.system()
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    win_names = {
        "chdman": "chdman.exe",
        "ecm":    "ecm.exe",
        "unecm":  "unecm.exe",
        "maxcso": "maxcso.exe",
        "xiso":   "extract-xiso.exe",
    }
    unix_names = {
        "chdman": "chdman",
        "ecm":    "ecm",
        "unecm":  "unecm",
        "maxcso": "maxcso",
        "xiso":   "extract-xiso",
    }

    if system == "Windows":
        fname  = win_names.get(tool, tool + ".exe")
        folder = "windows"
    elif system == "Darwin":
        fname  = unix_names.get(tool, tool)
        folder = "macos"
    else:  # Linux
        fname  = unix_names.get(tool, tool)
        folder = "linux"

    bundled = os.path.join(base, "assets", folder, fname)
    if os.path.isfile(bundled):
        return bundled

    # Not bundled — fall back to system PATH (brew / apt / pacman …)
    return unix_names.get(tool, tool) if system != "Windows" else win_names.get(tool, tool)


DEFAULT_CONFIG = {
    "chdman": "",
    "maxcso": "",
    "ecm":    "",
    "unecm":  "",
    "xiso":   "",
    "output_dir": "",
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
