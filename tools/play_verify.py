"""Launch the Godot project by PID and screenshot home + first run."""
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
KEYEVENTF_KEYUP = 0x0002
VK_RETURN = 0x0D
VK_SPACE = 0x20
WM_KEYDOWN = 0x0100
WM_KEYUP = 0x0101
MOUSEEVENTF_LEFTDOWN = 0x0002
MOUSEEVENTF_LEFTUP = 0x0004

GODOT = Path(r"C:\Tools\Godot\4.7.2\godot-4.7.2.exe")
PROJECT = Path(r"D:\code\tuitui\tuitui_run")
SHOTS = PROJECT / "tools" / "shots"


def tap(vk: int) -> None:
    user32.keybd_event(vk, 0, 0, 0)
    time.sleep(0.05)
    user32.keybd_event(vk, 0, KEYEVENTF_KEYUP, 0)


def tap_hwnd(hwnd: int, vk: int) -> None:
    user32.PostMessageW(hwnd, WM_KEYDOWN, vk, 0)
    time.sleep(0.04)
    user32.PostMessageW(hwnd, WM_KEYUP, vk, 0)


def click_screen(x: int, y: int) -> None:
    user32.SetCursorPos(int(x), int(y))
    time.sleep(0.05)
    user32.mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0)
    time.sleep(0.04)
    user32.mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, 0)


def shot_hwnd(hwnd: int, path: Path, x: int = 40, y: int = 40, w: int = 1296, h: int = 759) -> Path:
    user32.ShowWindow(hwnd, SW_RESTORE)
    user32.SetForegroundWindow(hwnd)
    user32.SetWindowPos(hwnd, 0, x, y, w, h, 0x0040)
    time.sleep(0.35)
    rect = wt.RECT()
    user32.GetWindowRect(hwnd, ctypes.byref(rect))
    img = ImageGrab.grab(bbox=(rect.left, rect.top, rect.right, rect.bottom), all_screens=True)
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)
    print(f"hwnd={hwnd} rect=({rect.left},{rect.top},{rect.right},{rect.bottom}) {img.size} -> {path}")
    return path


def wait_hwnd(pid: int, timeout: float = 16.0) -> int:
    GetWindowThreadProcessId = user32.GetWindowThreadProcessId
    WNDENUMPROC = ctypes.WINFUNCTYPE(ctypes.c_bool, wt.HWND, wt.LPARAM)
    deadline = time.time() + timeout
    while time.time() < deadline:
        found: list[int] = []

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


def main() -> None:
    proc = subprocess.Popen(
        [str(GODOT), "--path", str(PROJECT)],
        cwd=str(PROJECT),
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    try:
        hwnd = wait_hwnd(proc.pid, 18.0)
        time.sleep(3.2)
        shot_hwnd(hwnd, SHOTS / "30_home.png")
        rect = wt.RECT()
        user32.GetWindowRect(hwnd, ctypes.byref(rect))
        # 开始游戏 button, bottom-right of 1280x720 client
        click_screen(rect.left + 1100, rect.top + 700)
        time.sleep(1.4)
        shot_hwnd(hwnd, SHOTS / "31_intro.png")
        tap_hwnd(hwnd, VK_SPACE)
        time.sleep(0.28)
        shot_hwnd(hwnd, SHOTS / "33_jump.png")
        time.sleep(2.2)
        shot_hwnd(hwnd, SHOTS / "32_run.png")
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=4)
        except subprocess.TimeoutExpired:
            proc.kill()


if __name__ == "__main__":
    sys.exit(main())
