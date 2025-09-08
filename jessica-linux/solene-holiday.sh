#!/usr/bin/env bash
# solene-holiday-parade.sh
# Run Solène in --debug --preview across key holidays with short pauses

set -euo pipefail

# Go to the script directory so relative paths work
cd "$(dirname "$0")"

# Configurable year and pause (seconds)
YEAR="${1:-2025}"
SLEEP_SECS="${2:-2}"
export YEAR

run() {
  local label="$1"
  local date="$2"
  local mode="$3"   # "day" or "night"
  local force_flag="--force-day"
  [[ "$mode" == "night" ]] && force_flag="--force-night"

  echo
  echo "=== $label — $date — $mode ==="
  python3 solene.py --debug "$date" --preview "$force_flag"
  sleep "$SLEEP_SECS"
}

# Compute floating holidays via inline Python (same logic as Solène)
eval "$(
python3 - <<PY
import os
from datetime import date, timedelta

y = int(os.environ.get("YEAR", "2025"))

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
        last = date(y + 1, 1, 1) - timedelta(days=1)
    else:
        last = date(y, month + 1, 1) - timedelta(days=1)
    offset = (last.weekday() - weekday) % 7
    return last - timedelta(days=offset)

easter = easter_date(y)
memorial = last_weekday(y, 5, 0)         # Monday=0
labour  = nth_weekday(y, 9, 0, 1)        # First Monday in Sept
can_thx = nth_weekday(y, 10, 0, 2)       # Second Monday in Oct
us_thx  = nth_weekday(y, 11, 3, 4)       # Fourth Thursday in Nov
black_friday = us_thx + timedelta(days=1)

print(f"EASTER={easter.isoformat()}")
print(f"MEMORIAL={memorial.isoformat()}")
print(f"LABOUR={labour.isoformat()}")
print(f"CAN_THX={can_thx.isoformat()}")
print(f"US_THX={us_thx.isoformat()}")
print(f"BLACK_FRIDAY={black_friday.isoformat()}")
PY
)"

# Fixed-date holidays and special days
run "New Year's Day"          "${YEAR}-01-01" day
run "Valentine's Day"         "${YEAR}-02-14" day
run "Chinese New Year"        "2025-01-29"    day       # per your known table
run "Easter (secular)"        "${EASTER}"     day
run "Cinco de Mayo"           "${YEAR}-05-05" day
run "Memorial Day (US)"       "${MEMORIAL}"   day
run "Canada Day"              "${YEAR}-07-01" day
run "Independence Day (US)"   "${YEAR}-07-04" day
run "Labour Day (US/CA)"      "${LABOUR}"     day
run "Canadian Thanksgiving"   "${CAN_THX}"    day
run "Halloween"               "${YEAR}-10-31" night
run "US Thanksgiving"         "${US_THX}"     day
run "Black Friday"            "${BLACK_FRIDAY}" day
run "Remembrance/Veterans"    "${YEAR}-11-11" day
run "Christmas Eve"           "${YEAR}-12-24" night
run "Christmas Day"           "${YEAR}-12-25" day
run "Boxing Day"              "${YEAR}-12-26" day
run "New Year's Eve"          "${YEAR}-12-31" night

echo
echo "Parade complete for YEAR=${YEAR} (slept ${SLEEP_SECS}s between each)."
