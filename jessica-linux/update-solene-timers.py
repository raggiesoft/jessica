# ~/jessica-suite/update-solene-timers.py
from suntime import Sun
from datetime import datetime
from pathlib import Path
import subprocess

LAT = 36.84681
LON = -76.28522
sun = Sun(LAT, LON)
today = datetime.now().date()

sunrise = sun.get_local_sunrise_time(today).strftime("%H:%M")
sunset = sun.get_local_sunset_time(today).strftime("%H:%M")

timers_dir = Path.home() / ".config/systemd/user"
timers_dir.mkdir(parents=True, exist_ok=True)

# Path to Solène's runner service
service_name = "solene-run.service"
service_path = timers_dir / service_name

# Ensure the runner service exists
if not service_path.exists():
    service_content = f"""[Unit]
Description=Run Solène Theme Switcher

[Service]
Type=oneshot
ExecStart={Path.home()}/jessica-env/bin/python {Path.home()}/jessica-suite/solene.py
"""
    service_path.write_text(service_content)

def write_timer(name, time_str):
    timer_content = f"""[Unit]
Description=Run Solène at {name}

[Timer]
OnCalendar=*-*-* {time_str}
Persistent=true

[Install]
WantedBy=timers.target
"""
    (timers_dir / f"solene-{name}.timer").write_text(timer_content)

# Write today's timers
write_timer("sunrise", sunrise)
write_timer("sunset", sunset)

# Reload systemd so it sees the new/updated units
subprocess.run(["systemctl", "--user", "daemon-reload"])

# Enable timers so they run today
subprocess.run(["systemctl", "--user", "enable", "--now", "solene-sunrise.timer"])
subprocess.run(["systemctl", "--user", "enable", "--now", "solene-sunset.timer"])
