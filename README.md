# Jessica

Jessica is a modular site management and automation suite designed for a multi-site Linux server environment. She’s designed to be human, memorable, and safe — not just fast. Everything you touch is centralized, auditable, and reversible.

## Why

Human names serve two purposes here: identity and safety. Naming modules after people makes them easier to remember, reason about, and talk to. It also adds a thin layer of ambiguity — security through obscurity — that deters casual snooping without harming real security practices.

* **Humanized operations:** Code that reads like a story reduces cognitive load during on-call moments.
* **Centralized controls:** All knobs and levers live in one config file, so changes happen once and propagate.
* **Emotional safety:** Excluded names are scrubbed at generation time, so accidental reintroduction doesn’t happen.
* **Operational safety:** Audit trails, idempotent patterns, and safe defaults prevent foot-guns.

---
## Features and Modules

| Module    | Role                           | Entrypoint              | Notes                                            |
| :-------- | :----------------------------- | :---------------------- | :----------------------------------------------- |
| **Amanda** | **Main Menu & Orchestrator** | **`amanda.sh`** | **Primary entry point for the suite.** First-run setup. |
| Phoebe    | Site Creation & Destruction    | `clara/phoebe.sh`       | Nginx + Certbot + systemd; uses Coralie for names. |
| Selene    | System Update Cycle            | `clara/selene.sh`       | OS updates, Git pull (via Clio), cleanup, restarts. |
| Clio      | Git Operations                 | `clara/clio.sh`         | Pull, push, status, branch; bootstraps config.   |
| Marina    | Backup & Restore               | `clara/marina.sh`       | Creates and restores backups of critical directories. |
| Iris      | Logs & Monitoring              | `clara/iris.sh`         | View logs, check service status, monitor system. |
| Thalia    | Remote & Local Utilities       | `clara/thalia.sh`       | Misc. tools, runs commands on remote servers.    |
| Helena    | Honeypot & Router Rotation     | `clara/helena.sh`       | Deploys decoys and rotates site folder names.    |
| Kristyn   | Household Wellness             | `clara/kristyn.sh`      | Crew check-in and introductions.                 |
| Coralie   | Name Generation                | `junia/coralie.sh`      | Generates names for infrastructure and narratives. |
| Lavinia   | Name Sanitizer                 | `junia/list/lavinia.sh` | Scrubs excluded names from source lists.         |
| **Paige** | **Documentation Hub** | **`paige/man/`** | **Stores all man page source files.** |
| **Allison** | **Man Page Installer** | **`allison.sh`** | **Installs the man pages from Paige.** |
| Solène    | Greeter & MOTD                 | `solene/solene.py`      | Provides a dynamic greeting on login.            |

> Sources: All paths are relative to the Jessica root at `$HOME/jessica`.

---
## Architecture and Layout