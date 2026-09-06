"""Capture an exported Godot HWND via PrintWindow (no resize)."""
from __future__ import annotations

import ctypes
import ctypes.wintypes as wt
import subprocess
import sys
import time
from pathlib import Path

from PIL import Image

user32 = ctypes.windll.user32
gdi32 = ctypes.windll.gdi32
PW_RENDERFULLCONTENT = 2
try:
    ctypes.windll.shcore.SetProcessDpiAwareness(2)
except Exception:
    user32.SetProcessDPIAware()


class BITMAPINFOHEADER(ctypes.Structure):
    _fields_ = [
        ("biSize", wt.DWORD),
        ("biWidth", wt.LONG),
        ("biHeight", wt.LONG),
        ("biPlanes", wt.WORD),
        ("biBitCount", wt.WORD),
        ("biCompression", wt.DWORD),
        ("biSizeImage", wt.DWORD),
        ("biXPelsPerMeter", wt.LONG),
        ("biYPelsPerMeter", wt.LONG),
        ("biClrUsed", wt.DWORD),
        ("biClrImportant", wt.DWORD),
    ]


class BITMAPINFO(ctypes.Structure):
    _fields_ = [("bmiHeader", BITMAPINFOHEADER)]


def wait_hwnd(pid: int, timeout: float = 15.0) -> int:
    GetWindowThreadProcessId = user32.GetWindowThreadProcessId
    WNDENUMPROC = ctypes.WINFUNCTYPE(ctypes.c_bool, wt.HWND, wt.LPARAM)
    deadline = time.time() + timeout
    while time.time() < deadline:
        found: list[int] = []

        def cb(hwnd: int, _lp: int) -> bool:
            if not user32.IsWindowVisible(hwnd):
                return True
            p = wt.DWORD()
            GetWindowThreadProcessId(hwnd, ctypes.byref(p))
            if p.value == pid and user32.GetWindow(hwnd, 4) == 0:
                if user32.GetWindowTextLengthW(hwnd) > 0:
                    found.append(hwnd)
            return True

        user32.EnumWindows(WNDENUMPROC(cb), 0)
        if found:
            return found[0]
        time.sleep(0.1)
    raise SystemExit(f"no window for pid {pid}")


def printwindow(hwnd: int) -> Image.Image:
    rect = wt.RECT()
    user32.GetClientRect(hwnd, ctypes.byref(rect))
    w = int(rect.right - rect.left)
    h = int(rect.bottom - rect.top)
    if w < 8 or h < 8:
        raise SystemExit(f"client too small {w}x{h}")
    hdc_win = user32.GetDC(hwnd)
    hdc_mem = gdi32.CreateCompatibleDC(hdc_win)
    hbmp = gdi32.CreateCompatibleBitmap(hdc_win, w, h)
    gdi32.SelectObject(hdc_mem, hbmp)
    ok = user32.PrintWindow(hwnd, hdc_mem, PW_RENDERFULLCONTENT)
    bmi = BITMAPINFO()
    bmi.bmiHeader.biSize = ctypes.sizeof(BITMAPINFOHEADER)
    bmi.bmiHeader.biWidth = w
    bmi.bmiHeader.biHeight = -h
    bmi.bmiHeader.biPlanes = 1
    bmi.bmiHeader.biBitCount = 32
    bmi.bmiHeader.biCompression = 0
    buf = (ctypes.c_ubyte * (w * h * 4))()
    gdi32.GetDIBits(hdc_mem, hbmp, 0, h, buf, ctypes.byref(bmi), 0)
    gdi32.DeleteObject(hbmp)
    gdi32.DeleteDC(hdc_mem)
    user32.ReleaseDC(hwnd, hdc_win)
    img = Image.frombuffer("RGBX", (w, h), bytes(buf), "raw", "BGRX", 0, 1)
    img = img.convert("RGB")
    print(f"PrintWindow ok={ok} {w}x{h}")
    return img


def sample(img: Image.Image) -> dict:
    w, h = img.size
    pts = {
        "tl": img.getpixel((24, 48)),
        "tr": img.getpixel((w - 24, 48)),
        "c": img.getpixel((w // 2, h // 2)),
        "bl": img.getpixel((24, h - 24)),
        "br": img.getpixel((w - 24, h - 24)),
    }
    cols: set[tuple] = set()
    for y in range(0, h, max(1, h // 10)):
        for x in range(0, w, max(1, w // 14)):
            cols.add(img.getpixel((x, y)))
    return {"size": (w, h), "pts": pts, "unique": len(cols)}


def is_grayish(rgb: tuple) -> bool:
    r, g, b = rgb[:3]
    if max(r, g, b) - min(r, g, b) > 18:
        return False
    return 20 <= r <= 55


def main() -> None:
    exe = Path(r"D:\code\tuitui\tuitui_run\builds\TuituiRun.exe")
    tag = sys.argv[1] if len(sys.argv) > 1 else "default"
    extra = sys.argv[2:]
    out = Path(rf"D:\code\tuitui\tuitui_run\tools\shots\83_{tag}.png")
    log = Path(rf"D:\code\tuitui\tuitui_run\tools\shots\83_{tag}.log")
    lf = open(log, "w", encoding="utf-8", errors="replace")
    cmd = [str(exe), "--verbose", *extra]
    print("launch", cmd)
    proc = subprocess.Popen(cmd, stdout=lf, stderr=subprocess.STDOUT, cwd=str(exe.parent))
    try:
        hwnd = wait_hwnd(proc.pid)
        print(f"pid={proc.pid} hwnd={hwnd}")
        user32.ShowWindow(hwnd, 9)
        user32.SetForegroundWindow(hwnd)
        time.sleep(3.2)
        img = printwindow(hwnd)
        out.parent.mkdir(parents=True, exist_ok=True)
        img.save(out)
        info = sample(img)
        gray_n = sum(1 for v in info["pts"].values() if is_grayish(v))
        print("printwindow", info, "gray_corners", gray_n, "path", out)
        grab_path = out.with_name(out.stem + "_dwm.png")
        try:
            from PIL import ImageGrab
            wr = wt.RECT()
            user32.GetWindowRect(hwnd, ctypes.byref(wr))
            print(f"windowrect=({wr.left},{wr.top},{wr.right},{wr.bottom})")
            dwm = ImageGrab.grab(bbox=(wr.left, wr.top, wr.right, wr.bottom), all_screens=True)
            dwm.save(grab_path)
            dinfo = sample(dwm)
            dgray = sum(1 for v in dinfo["pts"].values() if is_grayish(v))
            print("dwm", dinfo, "gray_corners", dgray, "path", grab_path)
        except Exception as e:
            print("dwm_fail", type(e).__name__, e)
        if info["unique"] < 8 and gray_n >= 3:
            print("VERDICT GRAY")
        else:
            print("VERDICT COLOR")
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=4)
        except subprocess.TimeoutExpired:
            proc.kill()
        lf.close()


if __name__ == "__main__":
    main()
