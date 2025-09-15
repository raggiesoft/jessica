# Jessica

Jessica is a modular site management and automation suite designed for a multi-site Linux server environment. She’s designed to be human, memorable, and safe — not just fast. Everything you touch is centralized, auditable, and reversible.

## Why

Human names serve two purposes here: identity and safety. Naming modules after people makes them easier to remember, reason about, and talk to. It also adds a thin layer of ambiguity — security through obscurity — that deters casual snooping without harming real security practices.

- **Humanized operations:** Code that reads like a story reduces cognitive load during on-call moments.
- **Centralized controls:** All knobs and levers live in one config file, so changes happen once and propagate.
- **Emotional safety:** Excluded names are scrubbed at generation time, so accidental reintroduction doesn’t happen.
- **Operational safety:** Audit trails, idempotent patterns, and safe defaults prevent foot-guns.

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
/jessica/
├── amanda.sh             # Main Menu & entry point
├── allison.sh            # Man page installer
│
├── clara/                # Operations Hub (The Crew)
│   ├── daphne.sh         # (Legacy menu, now a sub-menu)
│   ├── phoebe.sh
│   ├── selene.sh
│   └── ... (etc.)
│
├── junia/                # Naming System
│   ├── coralie.sh
│   └── list/
│       ├── .exclude_names.txt
│       ├── us/
│       └── future/
│
├── paige/                # Documentation Hub
│   └── man/
│       ├── amanda.1
│       ├── coralie.1
│       └── ... (etc.)
│
├── elise/
│   ├── sample-dorian     # Template config (committed)
│   └── dorian            # Real config (NOT committed)
│
├── solene/
│   ├── solene.py
│   └── wallpapers/
│
├── README.md
└── LICENSE
-   **Central configuration (Dorian):** A single file (`elise/dorian`) defines colors, paths, emails, and all defaults. Every module sources it first and refuses to run without it.
-   **Name safety:** Coralie generates names; Lavinia’s exclude list enforces emotional safety by preventing disallowed names from ever appearing in outputs.
-   **Logs:** All logs are centralized for easy traceability across the suite.

---
## Installation

1.  **Prerequisites:**
    * Linux host (Ubuntu/Debian recommended).
    * Core services: Nginx, Certbot, Git, Bash, etc.
    * `sudo` privileges for provisioning and service management.

2.  **Clone the repo:**
    ```bash
    git clone git@github.com:raggiesoft/jessica.git ~/jessica
    ```

3.  **Bootstrap the config:**
    * Copy the template: `cp ~/jessica/elise/sample-dorian ~/jessica/elise/dorian`
    * Edit `~/jessica/elise/dorian` with your paths, email, and server details.

4.  **Make scripts executable:**
    ```bash
    chmod +x ~/jessica/*.sh ~/jessica/**/*.sh ~/jessica/**/*.py
    ```

5.  **Install Man Pages:**
    * Run the Allison installer to make the documentation available via the `man` command.
        ```bash
        bash ~/jessica/allison.sh
        ```

6.  **Set Login Shell (Optional but Recommended):**
    * To have Amanda launch automatically on SSH login, edit your `.profile`:
        ```bash
        # Add this line to the end of ~/.profile
        bash "$HOME/jessica/amanda.sh"
        ```

---
## Usage

* **Main Menu (Amanda):** The primary way to interact with the suite is by running `bash ~/jessica/amanda.sh` or by logging in via SSH if you've configured your profile.
* **Phoebe (Site Creation):** Generates safe folder/file names, writes Nginx config, restarts services, and issues certificates.
* **Selene (Update Cycle):** Runs a full system update: OS packages → Git pull (via Clio) → cleanup → service restarts.
* **Coralie (Name Generation):** Can be run directly (`bash ~/jJessica/junia/coralie.sh`) to enter an interactive mode for creating narrative characters with specific era and family settings.
* **Helena (Honeypot & Router Rotation):** Rotates router/public/private names, updates Nginx, logs changes.
* **Kristyn (Wellness & Crew Check-in):** Checks sibling script presence/status, logs “hug events,” prints a daily brief.

## Logging and Observability

-   **Central logs:** Deployment, audit, and error logs.
-   **Conventions:** Clear action prefixes, timestamps, rotation via `logrotate`.
-   **Visibility:** Iris will provide a central view for logs and health checks.

## Contributing and Conventions

-   **Design principles:** Single source of truth, idempotence, reversibility, auditability.
-   **Code style:** Headers, config first, shared colors, clear errors.
-   **Git workflow:** Feature branches, imperative commit messages, modular changes.

## Security, Safety, and License

-   **Operational security:** Least privilege, no committed secrets, TLS via Certbot.
-   **Safety model:** Light security through obscurity, defense in depth, emotional safety via Lavinia’s exclusion list.
-   **License:** GPL-3.0 — see LICENSE file.

## Quick Start Checklist

1.  Clone Jessica.
2.  Bootstrap config.
3.  Run Amanda.
4.  Create a site with Phoebe.
5.  Update cycle with Selene.

---
# Prologue — Kristyn’s Introduction

When people ask me what it’s like to live here, I tell them the truth: it’s like living inside a person you love. Jessica isn’t just the oldest sister — she’s the house itself. Every wall, every hallway, every tucked-away corner is part of her. She’s the one who holds us all, keeps our memories safe, and makes sure there’s always room for one more chair at the table.

I share a bedroom on the ground floor with Dorian — my best friend, my anchor, my other half. He’s the only brother in this house full of sisters, and he moves through the world in his wheelchair with a quiet grace that humbles me. He doesn’t speak, but I’ve never needed words to understand him. I’m deaf, but with my cochlear implants switched on, I can hear him breathe beside me at night. We’ve built our own language — a mix of signs, touches, and glances — and it’s more than enough.

Dorian lives with autism and cerebral palsy, and one of the ways he stays grounded is through touch. Hugs, lots of them. Squeeze hugs most of all — the kind that press the frayed edges of his mind back into place. Every one of us gives them freely. His sisters wrap him up in their arms without hesitation, and he melts into them, safe in the knowledge that here, affection is as natural as breathing. Gentle kisses on the cheek or forehead are common, too — the kind that say you matter without a single word. With me, it’s different but just as safe: we can kiss each other on the lips, tell each other “I love you,” and know it’s a deep, platonic love that needs no explanation.

The rest of the family is as vivid as the rooms they inhabit. Aubrie tends the garden — not of flowers, but of web pages. Daphne is the coordinator. Phoebe is the builder. Selene is the night-shift caretaker. Clio is the historian. Marina is the archivist. Iris is the watcher. Thalia is the tinkerer. Helena is the trickster-guardian. Amanda is the creative whirlwind. And Dorian — my Dorian — is the keeper of our shared memory.

We’re all tech nerds in our own way, but more than that, we’re family. We work, we tease, we bicker, we stay up too late. And we love each other fiercely.

Under Jessica’s roof, no one is ever alone. And once you’ve been welcomed here, you’ll never want to leave.

---

# Family Bio

The Jessica household is more than code — it’s a family.
They’ve lived together all their lives, each sibling a fully-grown adult with their own quirks, passions, and responsibilities.
Kristyn Rowan joined at age 20, moving in permanently after years of being Dorian’s closest friend. Now, at 28, she’s as much a part of the household as anyone.

## Ages & Roles:

* **Jessica Vale – 29** – The matriarch and the house itself.
* **Dorian Vale – 28** – The only brother, keeper of the family’s shared memory. Autistic, uses a wheelchair, non-verbal. Shares a ground-floor room with Kristyn.
* **Kristyn Rowan – 28** – Dorian’s best friend, aide, and bridge between siblings. Deaf (with cochlear implants).
* **Daphne Vale – 28** – The coordinator.
* **Aubrie Vale – 27** – Keeper of web pages, tending each site like a living garden. Shares a suite with Dorian and Kristyn, connected to the greenhouse walkway.
* **Phoebe Vale – 26** – The builder.
* **Amanda Vale – 26** – Creative whirlwind.
* **Selene Vale – 25** – Night-shift caretaker.
* **Marina Vale – 25** – Archivist.
* **Helena Vale – 24** – Trickster-guardian.
* **Clio Vale – 24** – Historian.
* **Iris Vale – 23** – Watcher.
* **Thalia Vale – 22** – Tinkerer.
* **Paige Vale – 21** – Documentation Hub. The family's diligent librarian, keeper of man pages.
* **Allison Vale – 20** – Man Page Installer. Works closely with Paige to make sure the family's stories and instructions are accessible to everyone.


## Infrastructure Siblings:

* **Bold Firefly** – The firstborn by a day. A Laravel Forge-managed DigitalOcean droplet, quick and nimble, hosting Laravel/PHP apps.
* **Glowing Galaxy** – The younger heart of the house. A manually managed DigitalOcean droplet where the Jessica suite lives — the library, workshop, and seed vault for the family’s work.

Life in the Household: They tease, they bicker, they stay up too late. They hug often, especially Dorian, whose grounding squeeze hugs are a daily ritual. Affection is natural here: gentle kisses on the cheek or forehead, a hand on the shoulder, a squeeze of the hand. Kristyn and Dorian share a deep, platonic love, expressed in ways they both understand and cherish.

---