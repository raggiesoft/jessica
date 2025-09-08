#!/usr/bin/env python3
# ~/jessica-suite/solene.py
# Solène — day/night colors, seasonal poetry, holiday-aware greetings, and daily warmth
# Now with seasonal boot greetings

from datetime import datetime, date, timedelta
from suntime import Sun
from zoneinfo import ZoneInfo
import subprocess
import sys
import os

# Location: Norfolk, VA
LAT = 36.84681
LON = -76.28522

# KDE Color Scheme names (must match your .colors files)
AMBER_SCHEME = "Morning Amber"
SALACIA_SCHEME = "Salacia's Lantern"

# Konsole profile names
AMBER_PROFILE = "Amber"
SALACIA_PROFILE = "Salacia"

# Seasonal markers
HARBOUR_AWAKENING = (5, 1)
BACK_TO_SCHOOL = (8, 25)
NEPTUNE_FESTIVAL = (9, 28)

# Chinese zodiac animals
ZODIAC_ANIMALS = [
    "Rat", "Ox", "Tiger", "Rabbit", "Dragon", "Snake",
    "Horse", "Goat", "Monkey", "Rooster", "Dog", "Pig"
]

# --- Holiday & seasonal helpers ---
def chinese_zodiac(cny_date: date) -> str:
    base_year = 2020  # Year of the Rat
    idx = (cny_date.year - base_year) % 12
    return ZODIAC_ANIMALS[idx]

def chinese_new_year(year: int):
    known = {
        2025: date(2025, 1, 29),  # Snake
        2026: date(2026, 2, 17),  # Horse
        2027: date(2027, 2, 6),   # Goat
    }
    return known.get(year)

def easter_date(year: int) -> date:
    a = year % 19
    b = year // 100
    c = year % 100
    d = b // 4
    e = b % 4
    f = (b + 8) // 25
    g = (b - f + 1) // 3
    h = (19*a + b - d - g + 15) % 30
    i = c // 4
    k = c % 4
    l = (32 + 2*e + 2*i - h - k) % 7
    m = (a + 11*h + 22*l) // 451
    month = (h + l - 7*m + 114) // 31
    day = ((h + l - 7*m + 114) % 31) + 1
    return date(year, month, day)

def nth_weekday(year: int, month: int, weekday: int, n: int) -> date:
    d = date(year, month, 1)
    offset = (weekday - d.weekday()) % 7
    return d + timedelta(days=offset + 7*(n-1))

def last_weekday(year: int, month: int, weekday: int) -> date:
    if month == 12:
        last = date(year + 1, 1, 1) - timedelta(days=1)
    else:
        last = date(year, month + 1, 1) - timedelta(days=1)
    offset = (last.weekday() - weekday) % 7
    return last - timedelta(days=offset)

# --- Debug & argument parsing ---
force_mode = None
debug_mode = False
preview_mode = False
boot_mode = False
test_date = None

if len(sys.argv) > 1:
    if sys.argv[1] != "--debug":
        print("⚠️ Switches are ignored without the --debug key. Running normal routine.")
    else:
        debug_mode = True
        for arg in sys.argv[2:]:
            if arg == "--force-day":
                force_mode = "day"
            elif arg == "--force-night":
                force_mode = "night"
            elif arg == "--preview":
                preview_mode = True
            elif arg == "--boot":
                boot_mode = True
            else:
                try:
                    test_date = datetime.strptime(arg, "%Y-%m-%d").date()
                except ValueError:
                    print(f"Invalid date format: {arg}. Use YYYY-MM-DD.")
                    sys.exit(1)

if test_date:
    now = datetime.combine(test_date, datetime.now(ZoneInfo("US/Eastern")).time(), tzinfo=ZoneInfo("US/Eastern"))
else:
    now = datetime.now(ZoneInfo("US/Eastern"))

today = now.date()

if force_mode and not debug_mode:
    print("Error: --force-day or --force-night requires --debug.")
    sys.exit(1)

if preview_mode and not debug_mode:
    print("Error: --preview requires --debug.")
    sys.exit(1)
# --- Greetings ---
def holiday_greeting(today: date) -> str | None:
    y = today.year
    parts: list[str] = []

    # Fixed-date US
    if today == date(y, 1, 1):
        parts.append("New Year’s Day — The first light of the year spills across the floor — a clean page, a fresh tide.")
    if today == date(y, 2, 14):
        parts.append("Valentine’s Day — The air hums with quiet affections and bright, blooming hearts.")
    if today == date(y, 5, 5):
        parts.append("Cinco de Mayo — The day dances with color and music — ¡Feliz Cinco de Mayo!")
    if today == date(y, 7, 4):
        parts.append("Independence Day — The night sky blooms in color — a celebration of light and liberty.")
    if today == date(y, 10, 31):
        parts.append("Halloween — Lanterns glow with mischief, and the night hums with whispers and laughter.")
    if today == date(y, 12, 24):
        parts.append("Christmas Eve — The house is hushed, the tree aglow — tomorrow’s joy waits just beyond midnight.")
        parts.append("Réveillon — La nuit s’anime de festin et de famille, la fête danse après minuit. / Réveillon — The night is alive with feast and family — a celebration that dances past midnight.")
    if today == date(y, 12, 25):
        parts.append("Christmas Day — The morning bursts with ribbon and laughter — the day is wrapped in warmth.")
    if today == date(y, 12, 31):
        parts.append("New Year’s Eve — The old year exhales, the new one waits — the clock holds its breath.")

    # Fixed-date Canada
    if today == date(y, 7, 1):
        parts.append("Fête du Canada — La feuille d’érable danse dans le vent d’été. / Canada Day — The maple leaf dances in the summer wind.")
    if today == date(y, 12, 26):
        parts.append("Lendemain de Noël — Jour des Boîtes — Calme et comblé, baigné d’une douce lumière. / Boxing Day — The day after the feast — quiet, content, and warmly aglow.")

    # Nov 11: US + Canada
    if today == date(y, 11, 11):
        parts.append("Veterans Day — We honor the service, the sacrifice, and the steadfast hearts.")
        parts.append("Jour du Souvenir — Nous faisons une pause, nous nous souvenons. / Remembrance Day — We pause, we remember.")

    # Easter (secular)
    if today == easter_date(y):
        parts.append("Easter — The world wakes in blossoms and bells — the bunny has been here.")

    # Chinese New Year
    cny = chinese_new_year(y)
    if cny and today == cny:
        parts.append(f"Nouvel An lunaire — Année du {chinese_zodiac(cny)}. / Chinese New Year — Year of the {chinese_zodiac(cny)}: Lanterns and laughter light the way.")

    # Floating: US Memorial Day
    if today == last_weekday(y, 5, 0):
        parts.append("Memorial Day — Flags ripple in the breeze — we remember, we honor.")

    # Floating: Labor/Labour Day
    labor = nth_weekday(y, 9, 0, 1)
    if today == labor:
        parts.append("Labor Day — The shore takes a deep breath — summer’s last long weekend drifts into memory.")
        parts.append("Fête du Travail — Le rivage reprend son souffle — le dernier long week‑end de l’été s’efface en souvenir. / Labour Day — The shore takes a deep breath — summer’s last long weekend drifts into memory.")

    # Floating: Canadian Thanksgiving
    can_thanks = nth_weekday(y, 10, 0, 2)
    if today == can_thanks:
        parts.append("Action de grâce — La récolte est rentrée, le foyer brille d’histoires et de gratitude. / Thanksgiving — The harvest is gathered, and the hearth glows with stories and thanks.")

    # Floating: US Thanksgiving + Black Friday
    us_thanks = nth_weekday(y, 11, 3, 4)
    if today == us_thanks:
        parts.append("Thanksgiving — The table is full, the air is warm, and gratitude lingers like the scent of cinnamon.")
    if today == us_thanks + timedelta(days=1):
        parts.append("Black Friday — The lights begin to twinkle — the season’s first spark catches in the heart.")

    return " | ".join(parts) if parts else None

# --- Seasonal greetings ---
def seasonal_greeting(is_day: bool, today: date) -> str:
    m, d = today.month, today.day
    if (m, d) >= HARBOUR_AWAKENING and (m, d) < (5, 27):
        return "The harbour stirs — the first wheels hum along the shore."
    elif (m, d) >= (5, 27) and (m, d) < BACK_TO_SCHOOL:
        return "Summer hums at full tide, and the air tastes of salt and laughter."
    elif (m, d) >= BACK_TO_SCHOOL and (m, d) < (9, 1):
        return "The mornings are quieter now, though the sun still lingers."
    elif (m, d) >= (9, 1) and (m, d) < NEPTUNE_FESTIVAL:
        return "The season exhales — the days grow softer, the nights more curious."
    else:
        return "The lanterns glow in the off‑season hush, and the sea keeps her secrets."

# --- Daily greetings ---
def daily_greeting(is_day: bool, today: date) -> str:
    m, d = today.month, today.day
    if (m, d) >= HARBOUR_AWAKENING and (m, d) < (5, 27):
        return "Good morning — the water’s already busy." if is_day else "Evening settles over a harbour still humming from the day."
    elif (m, d) >= (5, 27) and (m, d) < BACK_TO_SCHOOL:
        return "The sun’s high and the breeze is warm — perfect for open windows." if is_day else "The night carries the scent of salt and far‑off music."
    elif (m, d) >= BACK_TO_SCHOOL and (m, d) < (9, 1):
        return "The air feels slower now, but the light still lingers." if is_day else "A soft night, with just a hint of autumn in the breeze."
    elif (m, d) >= (9, 1) and (m, d) < NEPTUNE_FESTIVAL:
        return "The day feels crisp, the kind that makes you linger outside." if is_day else "The night invites a sweater and a slow walk."
    else:
        return "The day is calm, the streets unhurried." if is_day else "The night is quiet, the lights warm against the chill."

# --- Theme switching helpers ---
def set_kde_colorscheme(scheme_name: str):
    subprocess.run(["plasma-apply-colorscheme", scheme_name])

def set_konsole_profile(profile_name: str):
    # Change profile for new Konsole sessions
    subprocess.run(["konsoleprofile", f"profile={profile_name}"])

    try:
        # --- Fallback 1: Inside Konsole, session path provided ---
        service_env = os.environ.get("KONSOLE_DBUS_SERVICE")
        session_env = os.environ.get("KONSOLE_DBUS_SESSION")
        window_env = os.environ.get("KONSOLE_DBUS_WINDOW")

        if service_env and session_env:
            subprocess.run([
                "qdbus", service_env, session_env, "setProfile", profile_name
            ])
            print(f"✔ Updated current Konsole session {session_env} in service {service_env} to profile '{profile_name}'")
            return

        # --- Fallback 2: Inside Konsole, only window path provided ---
        if service_env and window_env:
            # Get the first session ID from this window
            session_list = subprocess.run(
                ["qdbus", service_env, window_env, "sessionList"],
                capture_output=True, text=True, check=True
            ).stdout.splitlines()
            if session_list:
                session_path = f"/Sessions/{session_list[0]}"
                subprocess.run([
                    "qdbus", service_env, session_path, "setProfile", profile_name
                ])
                print(f"✔ Updated Konsole session {session_path} in service {service_env} to profile '{profile_name}'")
                return

        # --- Fallback 3: Outside Konsole, scan all instances ---
        services_output = subprocess.run(
            ["qdbus"],
            capture_output=True, text=True, check=True
        ).stdout.splitlines()

        konsole_services = [s for s in services_output if s.startswith("org.kde.konsole")]
        if not konsole_services:
            print("ℹ No running Konsole instance found — skipping live profile refresh.")
            return

        for service in konsole_services:
            windows_output = subprocess.run(
                ["qdbus", service],
                capture_output=True, text=True, check=True
            ).stdout.splitlines()

            for path in windows_output:
                if path.startswith("/Windows/"):
                    session_list = subprocess.run(
                        ["qdbus", service, path, "sessionList"],
                        capture_output=True, text=True, check=True
                    ).stdout.splitlines()
                    for sid in session_list:
                        session_path = f"/Sessions/{sid}"
                        subprocess.run([
                            "qdbus", service, session_path, "setProfile", profile_name
                        ])
                        print(f"✔ Updated Konsole session {session_path} in service {service} to profile '{profile_name}'")

    except subprocess.CalledProcessError as e:
        print(f"⚠ Could not query Konsole via D-Bus: {e}")
    except Exception as e:
        print(f"⚠ Unexpected error during Konsole D-Bus refresh: {e}")




def set_kde_wallpaper(image_path: str):
    subprocess.run(["plasma-apply-wallpaperimage", image_path])

def choose_wallpaper(is_day: bool, today: date) -> str:
    m = today.month
    base_dir = os.path.join(os.path.dirname(__file__), "wallpapers")

    if is_day:
        if 3 <= m <= 5:
            return os.path.join(base_dir, "amber-spring.png")
        elif 6 <= m <= 8:
            return os.path.join(base_dir, "amber-summer.png")
        elif 9 <= m <= 11:
            return os.path.join(base_dir, "amber-autumn.png")
        else:
            return os.path.join(base_dir, "amber-winter.png")
    else:
        if 3 <= m <= 5:
            return os.path.join(base_dir, "salacia-spring.png")
        elif 6 <= m <= 8:
            return os.path.join(base_dir, "salacia-summer.png")
        elif 9 <= m <= 11:
            return os.path.join(base_dir, "salacia-autumn.png")
        else:
            return os.path.join(base_dir, "salacia-winter.png")
# --- Main execution ---
sun = Sun(LAT, LON)
sunrise = sun.get_local_sunrise_time(today)
sunset = sun.get_local_sunset_time(today)

# Determine day/night
if force_mode == "day":
    is_day = True
elif force_mode == "night":
    is_day = False
else:
    is_day = sunrise < now < sunset

# Build base greeting
msg = holiday_greeting(today) or seasonal_greeting(is_day, today)
msg = f"{msg} {daily_greeting(is_day, today)}"

# If this is a boot run, prepend a seasonal boot greeting
if boot_mode:
    m = today.month
    if 3 <= m <= 5:
        boot_greeting = "Solène stretches into the soft light of spring."
    elif 6 <= m <= 8:
        boot_greeting = "Solène rises with the summer tide."
    elif 9 <= m <= 11:
        boot_greeting = "Solène wakes to the crisp breath of autumn."
    else:
        boot_greeting = "Solène stirs beneath the hush of winter."
    msg = f"{boot_greeting} {msg}"

# Pick wallpaper
wallpaper = choose_wallpaper(is_day, today)

# Output and apply
if is_day:
    print(f"🌞 Solène observes: '{msg} Amber, it’s your time to shine.'")
    if preview_mode:
        print(f"[Preview] Would apply color scheme: {AMBER_SCHEME}")
        print(f"[Preview] Would set wallpaper: {wallpaper}")
        print(f"[Preview] Would set Konsole profile: {AMBER_PROFILE}")
    else:
        set_kde_colorscheme(AMBER_SCHEME)
        set_kde_wallpaper(wallpaper)
        set_konsole_profile(AMBER_PROFILE)
else:
    print(f"🌙 Solène observes: '{msg} Salacia, the night is yours to keep.'")
    if preview_mode:
        print(f"[Preview] Would apply color scheme: {SALACIA_SCHEME}")
        print(f"[Preview] Would set wallpaper: {wallpaper}")
        print(f"[Preview] Would set Konsole profile: {SALACIA_PROFILE}")
    else:
        set_kde_colorscheme(SALACIA_SCHEME)
        set_kde_wallpaper(wallpaper)
        set_konsole_profile(SALACIA_PROFILE)
