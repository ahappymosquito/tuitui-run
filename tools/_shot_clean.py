from __future__ import annotations
import ctypes
import ctypes.wintypes as wt
import subprocess
import time
from pathlib import Path
from PIL import ImageGrab, Image

user32 = ctypes.windll.user32
SW_RESTORE = 9

exe = Path(r"D:\code\tuitui\tuitui_run\builds\TuituiRun.exe")
out = Path(r"D:\code\tuitui\tuitui_run\tools\shots\82_v151_clean.png")
log = Path(r"D:\code\tuitui\tuitui_run\tools\shots\82_verbose.txt")

proc = subprocess.Popen(
    [str(exe), "--verbose"],
    stdout=open(log, "w", encoding="utf-8", errors="replace"),
    stderr=subprocess.STDOUT,
    cwd=str(exe.parent),
)

def wait_hwnd(pid: int, timeout: float = 12.0) -> int:
    GetWindowThreadProcessId = user32.GetWindowThreadProcessId
    WNDENUMPROC = ctypes.WINFUNCTYPE(ctypes.c_bool, wt.HWND, wt.LPARAM)
    deadline = time.time() + timeout
    while time.time() < deadline:
        found = []
        def cb(hwnd: int, _lp: int) -> bool:
            if not user32.IsWindowVisible(hwnd):
                return True
            p = wt.DWORD()
            GetWindowThreadProcessId(hwnd, ctypes.byref(p))
            if p.value == pid and user32.GetWindow(hwnd, 4) == 0:
                n = user32.GetWindowTextLengthW(hwnd)
                if n > 0:
                    found.append(hwnd)
            return True
        user32.EnumWindows(WNDENUMPROC(cb), 0)
        if found:
            return found[0]
        time.sleep(0.1)
    raise SystemExit(f"no window for pid {pid}")

hwnd = wait_hwnd(proc.pid)
print(f"pid={proc.pid} hwnd={hwnd}")
user32.ShowWindow(hwnd, SW_RESTORE)
user32.SetForegroundWindow(hwnd)
time.sleep(2.4)
rect = wt.RECT()
user32.GetWindowRect(hwnd, ctypes.byref(rect))
print(f"rect=({rect.left},{rect.top},{rect.right},{rect.bottom})")
img = ImageGrab.grab(bbox=(rect.left, rect.top, rect.right, rect.bottom), all_screens=True)
out.parent.mkdir(parents=True, exist_ok=True)
img.save(out)
w, h = img.size
samples = {
    "tl": img.getpixel((20, 40)),
    "tr": img.getpixel((w-20, 40)),
    "c": img.getpixel((w//2, h//2)),
    "bl": img.getpixel((20, h-20)),
    "br": img.getpixel((w-20, h-20)),
}
print(f"size={img.size} samples={samples}")
# unique-ish colors
cols = set()
for y in range(0, h, max(1, h//12)):
    for x in range(0, w, max(1, w//16)):
        cols.add(img.getpixel((x, y)))
print(f"unique_grid={len(cols)}")
print("saved", out)
