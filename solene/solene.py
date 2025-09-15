#!/usr/bin/env python3
#
# Solène — Environment-Aware Greeter & Desktop Manager
# DESCRIPTION:
#   A full-featured, portable script that provides two functions:
#   1. On a KDE Plasma desktop, it sets the color scheme, Konsole profile,
#      and wallpaper based on the time of day, season, and holidays.
#   2. On a headless server, it provides a warm, seasonal, and holiday-aware
#      greeting as part of the Message of the Day (MOTD).
#
#   Reads all settings from the central `dorian` config file.
#
#   This script has optional dependencies for richer greetings and GUI control.
#   One-time setup for full functionality:
#     sudo apt-get install python3-pip ncurses-bin
#     pip3 install suntime pytz holidays
#     # On KDE, ensure 'konsole' and 'plasma-desktop' are installed for GUI control.

from datetime import datetime, date, timedelta
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError
import os
import re
import sys
import subprocess
import shutil

# === Configuration ===
# Default values will be used if the dorian config file is not found.
LAT = 36.94
LON = -76.27
TIMEZONE = "America/New_York"
AMBER_SCHEME = "Morning Amber"
SALACIA_SCHEME = "Salacia's Lantern"
AMBER_PROFILE = "Amber"
SALACIA_PROFILE = "Salacia"
YELLOW, NC = '', '' # Default to no color

# --- Smart Color Configuration Function ---
def supports_color() -> bool:
    """
    Check if the terminal supports color. This is a robust check
    that queries the terminal directly via `tput`.
    """
    if not sys.stdout.isatty():
        return False
    try:
        result = subprocess.run(['tput', 'colors'], capture_output=True, text=True)
        if result.returncode == 0:
            num_colors = int(result.stdout.strip())
            return num_colors >= 8
    except (ValueError, FileNotFoundError):
        pass
    if os.environ.get("TERM") in ["xterm", "xterm-256color", "screen"]:
        return True
    return False

# --- Optional Dependency Checks ---
try:
    from suntime import Sun
    SUNTIME_AVAILABLE = True
except ImportError:
    SUNTIME_AVAILABLE = False

try:
    import holidays
    HOLIDAYS_AVAILABLE = True
except ImportError:
    HOLIDAYS_AVAILABLE = False

# --- Config File Parsing ---
def parse_dms_coords(coord_str: str) -> tuple[float, float] | None:
    """Parses a DMS coordinate string from Google Maps into decimal degrees."""
    pattern = re.compile(r"""
        (\d+)\s*°\s*(\d+)\s*'\s*([\d.]+)"\s*([NS])\s*,?\s+
        (\d+)\s*°\s*(\d+)\s*'\s*([\d.]+)"\s*([WE])
    """, re.VERBOSE)
    match = pattern.search(coord_str)
    if not match: return None
    lat_deg, lat_min, lat_sec, lat_dir, lon_deg, lon_min, lon_sec, lon_dir = match.groups()
    lat_dd = float(lat_deg) + float(lat_min) / 60 + float(lat_sec) / 3600
    if lat_dir == 'S': lat_dd *= -1
    lon_dd = float(lon_deg) + float(lon_min) / 60 + float(lon_sec) / 3600
    if lon_dir == 'W': lon_dd *= -1
    return lat_dd, lon_dd

# --- Date Calculation Helpers ---
def easter_date(year: int) -> date:
    a, b, c = year % 19, year // 100, year % 100
    d, e = b // 4, b % 4
    f = (b + 8) // 25
    g = (b - f + 1) // 3
    h = (19 * a + b - d - g + 15) % 30
    i, k = c // 4, c % 4
    l = (32 + 2 * e + 2 * i - h - k) % 7
    m = (a + 11 * h + 22 * l) // 451
    month = (h + l - 7 * m + 114) // 31
    day = ((h + l - 7 * m + 114) % 31) + 1
    return date(year, month, day)

def nth_weekday(year: int, month: int, weekday: int, n: int) -> date:
    d = date(year, month, 1)
    offset = (weekday - d.weekday() + 7) % 7
    return d + timedelta(days=offset + 7 * (n - 1))

def last_weekday(year: int, month: int, weekday: int) -> date:
    next_month = date(year, month + 1, 1) if month < 12 else date(year + 1, 1, 1)
    last = next_month - timedelta(days=1)
    offset = (last.weekday() - weekday + 7) % 7
    return last - timedelta(days=offset)

# --- Greeting & GUI Logic ---
def get_holiday_greeting(today: date) -> str | None:
    y = today.year; parts = []
    us_holidays = holidays.country_holidays('US', years=y) if HOLIDAYS_AVAILABLE else {}
    ca_holidays = holidays.country_holidays('CA', prov='QC', years=y) if HOLIDAYS_AVAILABLE else {}
    us_holiday_name = us_holidays.get(today); ca_holiday_name = ca_holidays.get(today)
    if us_holiday_name and "Memorial Day" in us_holiday_name: parts.append("Memorial Day — Flags ripple in the breeze — we remember, we honor.")
    if today == date(y, 7, 4): parts.append("Independence Day — The night sky blooms in color — a celebration of light and liberty.")
    if us_holiday_name and "Thanksgiving" in us_holiday_name: parts.append("Thanksgiving (US) — The table is full, the air is warm, and gratitude lingers like the scent of cinnamon.")
    if ca_holiday_name and "National Patriots' Day" in ca_holiday_name: parts.append("Journée nationale des patriotes / Victoria Day — Le printemps est officiellement arrivé. / Spring has officially arrived.")
    if today == date(y, 6, 24): parts.append("Fête nationale du Québec — Les feux de joie illuminent la nuit. / Saint-Jean-Baptiste Day — Bonfires light up the night.")
    if today == date(y, 9, 30): parts.append("Journée nationale de la vérité et de la réconciliation / National Day for Truth and Reconciliation.")
    if today == date(y, 1, 1): parts.append("Jour de l'An / New Year’s Day — The first light of the year spills across the floor.")
    if today == date(y, 2, 14): parts.append("La Saint-Valentin / Valentine’s Day — The air hums with quiet affections.")
    if today == easter_date(y) - timedelta(days=2): parts.append("Vendredi Saint / Good Friday — A quiet moment of reflection.")
    if today == date(y, 10, 31): parts.append("Halloween — Lanterns glow with mischief, and the night hums with whispers.")
    if today == date(y, 11, 11): parts.append("Jour du Souvenir / Remembrance Day — Nous faisons une pause, nous nous souvenons. / We pause, we remember.")
    if today == date(y, 12, 24): parts.append("Le Réveillon de Noël — La nuit s’anime de festin et de famille, la fête danse après minuit. / Christmas Eve — The house is hushed, the tree aglow — tomorrow’s joy waits just beyond midnight.")
    if today == date(y, 12, 25): parts.append("Noël / Christmas Day — The morning bursts with ribbon and laughter.")
    if today == date(y, 12, 26): parts.append("Lendemain de Noël / Boxing Day — The day after the feast — quiet and content.")
    if today == date(y, 12, 31): parts.append("Le Réveillon du Nouvel An / New Year’s Eve — The old year exhales, the new one waits.")
    if ca_holiday_name and "Labour Day" in ca_holiday_name: parts.append("Fête du Travail / Labor Day — The shore takes a deep breath — summer’s last long weekend drifts into memory.")
    if ca_holiday_name and "Thanksgiving" in ca_holiday_name: parts.append("Action de grâce / Thanksgiving (CA) — La récolte est rentrée, le foyer brille de gratitude. / The harvest is gathered, the hearth glows with thanks.")
    return " | ".join(parts) if parts else None

def get_seasonal_greeting(today: date, seasonal_markers: dict) -> str:
    if seasonal_markers['HARBOR_AWAKENING'] <= today < seasonal_markers['BACK_TO_SCHOOL']: return "Summer hums at full tide, and the air tastes of salt and laughter."
    elif seasonal_markers['BACK_TO_SCHOOL'] <= today < seasonal_markers['NEPTUNE_FESTIVAL']: return "The mornings are quieter now, though the sun still lingers."
    elif today >= seasonal_markers['NEPTUNE_FESTIVAL']: return "The season exhales — the days grow softer, the nights more curious."
    else: return "The lanterns glow in the off‑season hush, and the sea keeps her secrets."

def get_daily_greeting(is_day: bool, today: date, seasonal_markers: dict) -> str:
    if is_day:
        if seasonal_markers['HARBOR_AWAKENING'] <= today < seasonal_markers['BACK_TO_SCHOOL']: return "The sun’s high and the breeze is warm — perfect for open windows."
        if seasonal_markers['BACK_TO_SCHOOL'] <= today < seasonal_markers['NEPTUNE_FESTIVAL']: return "The day feels crisp, the kind that makes you linger outside."
        return "The day is calm, the streets unhurried."
    else:
        if seasonal_markers['HARBOR_AWAKENING'] <= today < seasonal_markers['BACK_TO_SCHOOL']: return "The night carries the scent of salt and far‑off music."
        if seasonal_markers['BACK_TO_SCHOOL'] <= today < seasonal_markers['NEPTUNE_FESTIVAL']: return "The night invites a sweater and a slow walk."
        return "The night is quiet, the lights warm against the chill."

def get_boot_greeting(today: date) -> str:
    m = today.month
    if 3 <= m <= 5: return "Solène stretches into the soft light of spring."
    if 6 <= m <= 8: return "Solène rises with the summer tide."
    if 9 <= m <= 11: return "Solène wakes to the crisp breath of autumn."
    return "Solène stirs beneath the hush of winter."

def choose_wallpaper(is_day: bool, today: date) -> str:
    m = today.month
    base_dir = os.path.join(os.path.dirname(__file__), "wallpapers")
    theme = "amber" if is_day else "salacia"
    if 3 <= m <= 5: season = "spring"
    elif 6 <= m <= 8: season = "summer"
    elif 9 <= m <= 11: season = "autumn"
    else: season = "winter"
    return os.path.join(base_dir, f"{theme}-{season}.png")

def run_command(command: list):
    """A simple wrapper for running external commands."""
    try:
        subprocess.run(command, check=True, capture_output=True, text=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        pass

# --- Main Execution ---
if __name__ == "__main__":
    
    args = sys.argv[1:]

    # --- Manual Color Override ---
    force_color = "--force-color" in args
    if force_color:
        args.remove("--force-color")

    if force_color or supports_color():
        YELLOW, NC = '\033[1;33m', '\033[0m'
    
    # --- Load Config (which may override colors if supported) ---
    try:
        with open(f"{os.path.expanduser('~')}/jessica/elise/dorian") as f:
            config_content = f.read()
            for line in config_content.splitlines():
                if line.startswith("SOLENE_COORDS_GOOGLE="):
                    parsed = parse_dms_coords(line.split('=', 1)[1].strip('"'))
                    if parsed: LAT, LON = parsed
                elif line.startswith("SOLENE_TIMEZONE="):
                    TIMEZONE = line.split('=', 1)[1].strip('"')
                elif line.startswith("AMBER_SCHEME="): AMBER_SCHEME = line.split('=', 1)[1].strip('"')
                elif line.startswith("SALACIA_SCHEME="): SALACIA_SCHEME = line.split('=', 1)[1].strip('"')
                elif line.startswith("AMBER_PROFILE="): AMBER_PROFILE = line.split('=', 1)[1].strip('"')
                elif line.startswith("SALACIA_PROFILE="): SALACIA_PROFILE = line.split('=', 1)[1].strip('"')
                elif line.startswith("YELLOW=") and (force_color or supports_color()):
                    YELLOW = line.split('=', 1)[1].strip("'").replace('\\033', '\033')
                elif line.startswith("NC=") and (force_color or supports_color()):
                    NC = line.split('=', 1)[1].strip("'").replace('\\033', '\033')
    except (FileNotFoundError, IndexError):
        pass

    # --- Debug Flag Parsing ---
    force_mode = None
    boot_mode = False
    test_date = None
    
    is_debug = "--debug" in args
    if is_debug:
        args.remove("--debug")
        if "--boot" in args: boot_mode = True; args.remove("--boot")
        if "--force-day" in args: force_mode = "day"; args.remove("--force-day")
        elif "--force-night" in args: force_mode = "night"; args.remove("--force-night")
        if args:
            try:
                test_date = datetime.strptime(args[0], "%Y-%m-%d").date()
            except ValueError:
                print(f"{YELLOW}Error:{NC} Invalid date format: {args[0]}. Use YYYY-MM-DD.")
                sys.exit(1)

    tz = None
    try:
        tz = ZoneInfo(TIMEZONE)
    except ZoneInfoNotFoundError:
        pass

    if test_date:
        current_time = datetime.now(tz).time() if tz else datetime.now().time()
        now = datetime.combine(test_date, current_time, tzinfo=tz)
    else:
        now = datetime.now(tz) if tz else datetime.now()
        
    today = now.date()
    year = today.year

    memorial_day = last_weekday(year, 5, 0)
    harbor_awakening = memorial_day - timedelta(days=3)
    labor_day = nth_weekday(year, 9, 0, 1)
    back_to_school = labor_day + timedelta(days=1)
    neptune_festival = last_weekday(year, 9, 6)

    seasonal_markers = {
        'HARBOR_AWAKENING': harbor_awakening,
        'BACK_TO_SCHOOL': back_to_school,
        'NEPTUNE_FESTIVAL': neptune_festival
    }

    is_day = False
    if force_mode:
        is_day = (force_mode == "day")
    elif SUNTIME_AVAILABLE and tz:
        try:
            sun = Sun(LAT, LON); sunrise = sun.get_sunrise_time(today, tz); sunset = sun.get_sunset_time(today, tz)
            is_day = sunrise < now < sunset
        except Exception: is_day = 7 <= now.hour < 19
    else: is_day = 7 <= now.hour < 19

    base_greeting = get_holiday_greeting(today) or get_seasonal_greeting(today, seasonal_markers)
    daily_greeting = get_daily_greeting(is_day, today, seasonal_markers)
    final_msg = f"{base_greeting} {daily_greeting}"
    
    is_gui = os.environ.get('DISPLAY') and shutil.which('plasma-apply-colorscheme')

    if is_gui and not is_debug:
        wallpaper_path = choose_wallpaper(is_day, today)
        if is_day:
            run_command(["plasma-apply-colorscheme", AMBER_SCHEME])
            run_command(["konsoleprofile", f"profile={AMBER_PROFILE}"])
        else:
            run_command(["plasma-apply-colorscheme", SALACIA_SCHEME])
            run_command(["konsoleprofile", f"profile={SALACIA_PROFILE}"])
        
        if os.path.exists(wallpaper_path):
             run_command(["plasma-apply-wallpaperimage", wallpaper_path])

    if boot_mode or (is_gui and not is_debug):
        boot_greeting = get_boot_greeting(today)
        final_msg = f"{boot_greeting} {final_msg}"
    
    print()
    print(f"{YELLOW}Solène observes:{NC} '{final_msg}'")
    print()

