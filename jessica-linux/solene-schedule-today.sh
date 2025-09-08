#!/bin/bash
cd ~/jessica-suite

# Get today's sunrise/sunset from Solène's own logic
SUNRISE=$(python3 - <<'PY'
from datetime import date
from suntime import Sun
LAT, LON = 36.84681, -76.28522
sun = Sun(LAT, LON)
print(sun.get_local_sunrise_time(date.today()).strftime("%H:%M"))
PY
)

SUNSET=$(python3 - <<'PY'
from datetime import date
from suntime import Sun
LAT, LON = 36.84681, -76.28522
sun = Sun(LAT, LON)
print(sun.get_local_sunset_time(date.today()).strftime("%H:%M"))
PY
)

# Schedule systemd timers for today
systemd-run --user --on-calendar="today ${SUNRISE}" ~/jessica-suite/solene-run.sh
systemd-run --user --on-calendar="today ${SUNSET}" ~/jessica-suite/solene-run.sh
