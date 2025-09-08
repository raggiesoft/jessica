#!/bin/bash
cd ~/jessica-suite

# 1. Run Solène immediately
/usr/bin/python3 solene.py

# 2. Get today's sunrise/sunset
read SUNRISE SUNSET <<< $(python3 - <<'PY'
from datetime import date
from suntime import Sun
LAT, LON = 36.84681, -76.28522
sun = Sun(LAT, LON)
print(sun.get_local_sunrise_time(date.today()).strftime("%H:%M"),
      sun.get_local_sunset_time(date.today()).strftime("%H:%M"))
PY
)

# 3. Current time in HH:MM
NOW=$(date +%H:%M)

# 4. Schedule remaining events
if [[ "$NOW" < "$SUNRISE" ]]; then
    systemd-run --user --on-calendar="today ${SUNRISE}" ~/jessica-suite/solene.py
fi

if [[ "$NOW" < "$SUNSET" ]]; then
    systemd-run --user --on-calendar="today ${SUNSET}" ~/jessica-suite/solene.py
fi
