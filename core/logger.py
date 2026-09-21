import datetime
import os

from core.config import get_config_dir


class Logger:
    _instance = None

    def __init__(self):
        # Save logs next to config — proper OS location, not cwd
        log_dir = os.path.join(get_config_dir(), "logs")
        os.makedirs(log_dir, exist_ok=True)

        timestamp = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        self.log_filepath = os.path.join(log_dir, f"openrom_{timestamp}.log")
        self.listeners = []

        self.log_file = open(self.log_filepath, "a", encoding="utf-8")
        self._write_raw(f"=== OpenROM v2.0 Log Started at {timestamp} ===\n")

    @classmethod
    def get_instance(cls):
        if cls._instance is None:
            cls._instance = Logger()
        return cls._instance

    def add_listener(self, callback):
        if callback not in self.listeners:
            self.listeners.append(callback)

    def remove_listener(self, callback):
        if callback in self.listeners:
            self.listeners.remove(callback)

    def log(self, msg: str):
        print(msg, flush=True)
        self._write_raw(msg + "\n")
        for listener in list(self.listeners):
            try:
                listener(msg)
            except Exception:
                pass

    def _write_raw(self, text: str):
        try:
            self.log_file.write(text)
            self.log_file.flush()
        except Exception:
            pass

    def close(self):
        try:
            self.log_file.close()
        except Exception:
            pass


def get_logger() -> Logger:
    return Logger.get_instance()


def log(msg: str):
    get_logger().log(msg)
