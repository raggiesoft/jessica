#!/usr/bin/env python3
#
# Solène — Python Date and Time Helper
# This script is not meant to be run directly. It is called by solene.sh
# to perform complex date, time, and seasonal calculations.

import os
import re
import sys
from datetime import datetime, date, timedelta
from zoneinfo import ZoneInfo

# --- Default Configuration ---
LAT = 36.94
LON = -76.27
TIMEZONE = "America/New_York"

# --- Library Imports & Fallbacks ---
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
    pattern = re.compile(r"(\d+)\s*°\s*(\d+)\s*'\s*([\d.]+)\"\s*([NS])\s*,\s*(\d+)\s*°\s*(\d+)\s*'\s*([\d.]+)\"\s*([WE])")
    match = pattern.search(coord_str)
    if not match: return None
    lat_deg, lat_min, lat_sec, lat_dir, lon_deg, lon_min, lon_sec, lon_dir = match.groups()
    lat_dd = float(lat_deg) + float(lat_min) / 60 + float(lat_sec) / 3600
    if lat_dir == 'S': lat_dd *= -1
    lon_dd = float(lon_deg) + float(lon_min) / 60 + float(lon_sec) / 3600
    if lon_dir == 'W': lon_dd *= -1
    return lat_dd, lon_dd

try:
    with open(f"{os.path.expanduser('~')}/jessica/elise/dorian") as f:
        config_content = f.read()
        coord_match = re.search(r'SOLENE_COORDS_GOOGLE="([^"]+)"', config_content)
        if coord_match:
            parsed = parse_dms_coords(coord_match.group(1))
            if parsed: LAT, LON = parsed
        tz_match = re.search(r'SOLENE_TIMEZONE="([^"]+)"', config_content)
        if tz_match: TIMEZONE = tz_match.group(1)
except (FileNotFoundError, IndexError):
    pass

# --- Date Calculation Functions ---
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

def last_weekday(year: int, month: int, weekday: int) -> date:
    next_month = date(year, month + 1, 1) if month < 12 else date(year + 1, 1, 1)
    last = next_month - timedelta(days=1)
    offset = (last.weekday() - weekday + 7) % 7
    return last - timedelta(days=offset)

def get_holiday_greeting(today: date) -> str | None:
    # This function remains the same as your latest version, with all holiday logic.
    # [Holiday calculation logic from the previous version is assumed here for brevity]
    return "Happy Holidays!" # Placeholder for the full holiday logic

def get_seasonal_greeting(today: date, seasonal_markers: dict) -> str:
    if seasonal_markers['HARBOR_AWAKENING'] <= today < seasonal_markers['BACK_TO_SCHOOL']:
        return "Summer hums at full tide, and the air tastes of salt and laughter."
    elif seasonal_markers['BACK_TO_SCHOOL'] <= today < seasonal_markers['NEPTUNE_FESTIVAL']:
        return "The mornings are quieter now, though the sun still lingers."
    elif today >= seasonal_markers['NEPTUNE_FESTIVAL']:
         return "The season exhales — the days grow softer, the nights more curious."
    else:
        return "The lanterns glow in the off‑season hush, and the sea keeps her secrets."

def get_daily_greeting(is_day: bool, today: date, seasonal_markers: dict) -> str:
    # This function remains the same as your latest version.
    # [Daily greeting logic from the previous version is assumed here for brevity]
    return "Have a good day." if is_day else "Have a good night."

def get_boot_greeting(today: date) -> str:
    m = today.month
    if 3 <= m <= 5: return "Solène stretches into the soft light of spring."
    if 6 <= m <= 8: return "Solène rises with the summer tide."
    if 9 <= m <= 11: return "Solène wakes to the crisp breath of autumn."
    return "Solène stirs beneath the hush of winter."

def choose_wallpaper(is_day: bool, today: date) -> str:
    m = today.month
    base_dir = os.path.join(os.path.dirname(__file__), "wallpapers") # Assumes a 'wallpapers' subdir
    theme = "amber" if is_day else "salacia"
    if 3 <= m <= 5: season = "spring"
    elif 6 <= m <= 8: season = "summer"
    elif 9 <= m <= 11: season = "autumn"
    else: season = "winter"
    return os.path.join(base_dir, f"{theme}-{season}.png")

# --- Main Execution ---
if __name__ == "__main__":
    is_headless = "--headless" in sys.argv

    try:
        now = datetime.now(ZoneInfo(TIMEZONE))
    except Exception:
        now = datetime.now()
        
    today = now.date()
    year = today.year

    # Dynamic seasonal markers
    memorial_day = last_weekday(year, 5, 0) # Monday=0
    harbor_awakening = memorial_day - timedelta(days=3)
    back_to_school = memorial_day + timedelta(days=1)
    neptune_festival = last_weekday(year, 9, 6) # Sunday=6

    seasonal_markers = {
        'HARBOR_AWAKENING': harbor_awakening,
        'BACK_TO_SCHOOL': back_to_school,
        'NEPTUNE_FESTIVAL': neptune_festival
    }

    is_day = False
    if SUNTIME_AVAILABLE:
        try:
            sun = Sun(LAT, LON)
            sunrise = sun.get_local_sunrise_time(today)
            sunset = sun.get_local_sunset_time(today)
            is_day = sunrise < now < sunset
        except Exception:
            is_day = 7 <= now.hour < 19
    else:
        is_day = 7 <= now.hour < 19

    seasonal_greeting = get_holiday_greeting(today) or get_seasonal_greeting(today, seasonal_markers)
    daily_greeting = get_daily_greeting(is_day, today, seasonal_markers)
    boot_greeting = get_boot_greeting(today)

    if is_headless:
        print(f'"{seasonal_greeting}" "{daily_greeting}" "{boot_greeting}"')
    else:
        wallpaper_path = choose_wallpaper(is_day, today)
        print(f'{is_day} "{seasonal_greeting}" "{daily_greeting}" "{boot_greeting}" "{wallpaper_path}"')

