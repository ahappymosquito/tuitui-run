"""Launch / screenshot Tuitui Run by process handle, not by fuzzy title."""
from __future__ import annotations

import ctypes
import ctypes.wintypes as wt
import subprocess
import sys
import time
from pathlib import Path

from PIL import ImageGrab

user32 = ctypes.windll.user32
SW_RESTORE = 9


def shot_hwnd(hwnd: int, path: Path, x: int = 80, y: int = 80, w: int = 1296, h: int = 759) -> Path:
    if not hwnd:
        raise SystemExit("empty hwnd")
    user32.ShowWindow(hwnd, SW_RESTORE)
    user32.SetForegroundWindow(hwnd)
    user32.SetWindowPos(hwnd, 0, x, y, w, h, 0x0040)
    time.sleep(0.4)
    rect = wt.RECT()
    user32.GetWindowRect(hwnd, ctypes.byref(rect))
    img = ImageGrab.grab(bbox=(rect.left, rect.top, rect.right, rect.bottom), all_screens=True)
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)
    print(f"hwnd={hwnd} rect=({rect.left},{rect.top},{rect.right},{rect.bottom}) {img.size} -> {path}")
    return path


def wait_hwnd(pid: int, timeout: float = 8.0) -> int:
    class PROCESSENTRY(ctypes.Structure):
        pass

    GetWindowThreadProcessId = user32.GetWindowThreadProcessId
    WNDENUMPROC = ctypes.WINFUNCTYPE(ctypes.c_bool, wt.HWND, wt.LPARAM)
    deadline = time.time() + timeout
    while time.time() < deadline:
        found = []

        def cb(hwnd: int, _lp: int) -> bool:
            if not user32.IsWindowVisible(hwnd):
                return True
            proc = wt.DWORD()
            GetWindowThreadProcessId(hwnd, ctypes.byref(proc))
            if proc.value == pid and user32.GetWindow(hwnd, 4) == 0:
                n = user32.GetWindowTextLengthW(hwnd)
                if n > 0:
                    found.append(hwnd)
            return True

        user32.EnumWindows(WNDENUMPROC(cb), 0)
        if found:
            return found[0]
        time.sleep(0.15)
    raise SystemExit(f"no window for pid {pid}")


if __name__ == "__main__":
    out = Path(sys.argv[1])
    if len(sys.argv) >= 3:
        shot_hwnd(int(sys.argv[2]), out)
    else:
        raise SystemExit("usage: gui_capture.py out.png [hwnd]")
