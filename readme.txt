# Jessica

Jessica is a modular site management and automation suite for a multi‑site Linux server (Glowing Galaxy). She’s designed to be human, memorable, and safe — not just fast. Everything you touch is centralized, auditable, and reversible.

## Why

Human names serve two purposes here: identity and safety. Naming modules after people makes them easier to remember, reason about, and talk to. It also adds a thin layer of ambiguity — security through obscurity — that deters casual snooping without harming real security practices.

- **Humanized operations:** Code that reads like a story reduces cognitive load during on‑call moments.
- **Centralized controls:** All knobs and levers live in one config file, so changes happen once and propagate.
- **Emotional safety:** Excluded names are scrubbed at generation time, so accidental reintroduction doesn’t happen.
- **Operational safety:** Audit trails, idempotent patterns, and safe defaults prevent foot‑guns.

## Features and modules

| Module  | Role                              | Entrypoint            | Notes |
|---|---|---|---|
| Daphne  | Main switchboard menu             | clara/daphne.sh       | Routes to all modules. |
| Phoebe  | Site creation & destruction       | clara/phoebe.sh       | Nginx + Certbot + systemd; Coralie namegen. |
| Selene  | Update cycle                      | clara/selene.sh       | OS updates, Git pull (Clio), cleanup, restarts. |
| Clio    | Git operations                    | clara/clio.sh         | Pull, push, status, branch; bootstraps config. |
| Marina  | Backup & restore                  | clara/marina.sh       | Backups, restores, retention (planned). |
| Iris    | Logs & monitoring                 | clara/iris.sh         | Log views, health checks (planned). |
| Thalia  | Utilities                         | clara/thalia.sh       | Misc tools (planned). |
| Helena  | Honeypot & router rotation        | clara/helena.sh       | Decoys, rotations, and audit logging. |
| Amanda  | Site generator menu               | amanda.sh             | Name generation + deploy orchestration. |
| Kristyn | Household wellness & crew check‑in| clara/kristyn.sh      | Checks sibling status, logs hug events, daily brief. |
| Aubrie  | Keeper of web pages               | clara/aubrie.sh       | Manages and tends site content like a garden. |
| Coralie | Name generation                   | junia/coralie.sh      | Uses Lavinia exclude list; multiple modes. |
| Lavinia | Excluded names                    | junia/list/...        | Keeps unsafe names out of outputs. |

> Sources: All paths are relative to the Jessica root at `$HOME/jessica`.

## Architecture and layout

/jessica/ clara/                # Operations hub (Daphne + crew) daphne.sh phoebe.sh selene.sh clio.sh marina.sh iris.sh thalia.sh helena.sh kristyn.sh logs/               # Central logs (config‑driven path) junia/                # Naming system coralie.sh list/ .exclude_names.txt logs/ backups/ elise/ sample-dorian       # Template central config (committed) dorian              # Real central config (NOT committed) amanda.sh             # Generator menu (optional companion) README.md LICENSE


- **Central configuration (Dorian):** A single file hidden inside a female‑named folder (elise/dorian). It defines colors, paths, email, defaults, logs, and service settings. Every module sources it first and refuses to run without it.
- **Name safety:** Coralie generates names; Lavinia’s exclude list enforces emotional safety and prevents disallowed names from ever appearing in files, folders, or logs.
- **Logs:** Deployment, audit, and error logs are centralized so actions are traceable across the suite.

## Installation

1. **Prerequisites:**
   - **Linux host:** Ubuntu/Debian recommended.
   - **Core services:** Nginx, Certbot, PHP‑FPM, systemd, Git, Bash.
   - **Optional:** .NET runtime for ASP.NET sites.
   - **Access:** sudo privileges for provisioning and service management.

2. **Clone the repo:**
   - **SSH remote:** `git@github.com:raggiesoft/jessica.git`
   - **Command:**
     - **Windows PowerShell:** Open VS Code terminal in your home.
     - **Linux/macOS Bash:** `git clone git@github.com:raggiesoft/jessica.git ~/jessica`

3. **Bootstrap the config:**
   - **Copy template:** `cp ~/jessica/elise/sample-dorian ~/jessica/elise/dorian`
   - **Edit values:** Update paths, email, ports, and defaults to match your environment.
   - **Never commit:** Ensure `elise/dorian` remains ignored by Git.

4. **Make scripts executable:**
   - **Command:** `chmod +x ~/jessica/**/*.sh ~/jessica/*.sh`

5. **First run:**
   - **Open Daphne:** `bash ~/jessica/clara/daphne.sh`
   - **Verify logs:** Confirm that actions write to deployment, audit, and error logs.

## Configuration

- **Central config (elise/dorian):**
  - **Example template:** `elise/sample-dorian` (committed to the repo).
  - **Real file:** `elise/dorian` (not committed; contains your actual values).

- **Key variables:**
  - **Colors:** `RED`, `GREEN`, `YELLOW`, `NC` for consistent UI.
  - **Paths:** `TOOL_HOME`, `SITE_BASE_DIR`, `NAMEGEN_DIR`, `SITEMANAGER_DIR`.
  - **Certs:** `CERT_EMAIL` used universally for Let’s Encrypt.
  - **Coralie defaults:** `CORALIE_MODE`, `CORALIE_CASE`, `CORALIE_TYPE`, `CORALIE_GENDER`, `CORALIE_BATCH`.
  - **Routing:** `ROUTER_FILE_EXTENSION` for PHP front controllers.
  - **ASP.NET:** `ASP_PORT_DEFAULT`, `ASP_ENVIRONMENT`.
  - **Logs:** `DEPLOYMENT_LOG`, `AUDIT_LOG`, `ERROR_LOG`.

- **Naming model:**
  - **Hidden config:** Female folder → single male‑named file (the only one).
  - **Security through obscurity:** Reduces discoverability and casual tampering, while true security relies on proper permissions and practices.

- **Excluded names:**
  - **Location:** `junia/list/.exclude_names.txt`
  - **Safety:** Coralie sanitizes and avoids all variants listed here.

## Usage

- **Daphne (main menu):** `bash ~/jessica/clara/daphne.sh`
- **Phoebe (site creation & destruction):** Generates safe folder/file names, writes Nginx config, restarts services, issues certificates.
- **Selene (update cycle):** OS update → Clio pull → cleanup → service restarts.
- **Clio (Git):** Pull/push/status/branch; bootstraps config if missing.
- **Amanda (generator):** Spins up router/app structures using Coralie; logs deployments.
- **Helena (honeypot & router rotation):** Rotates router/public/private names, updates Nginx, logs changes.
- **Kristyn (wellness & crew check‑in):** Checks sibling script presence/status, logs “hug events,” prints a daily brief.

## Logging and observability

- **Central logs:** Deployment, audit, and error logs.
- **Conventions:** Clear action prefixes, timestamps, rotation via `logrotate`.
- **Visibility:** Iris (planned) will provide a central view for logs and health checks.

## Contributing and conventions

- **Design principles:** Single source of truth, idempotence, reversibility, auditability.
- **Code style:** Headers, config first, shared colors, clear errors.
- **Git workflow:** Feature branches, imperative commit messages, modular changes.

## Security, safety, and license

- **Operational security:** Least privilege, no committed secrets, TLS via Certbot.
- **Safety model:** Light security through obscurity, defense in depth, emotional safety via Lavinia’s exclusion list.
- **License:** GPL‑3.0 — see LICENSE.

## Quick start checklist

1. Clone Jessica.
2. Bootstrap config.
3. Run Daphne.
4. Create a site with Phoebe.
5. Update cycle with Selene.

---
# Prologue — Kristyn’s Introduction

When people ask me what it’s like to live here, I tell them the truth: it’s like living inside a person you love. Jessica isn’t just the oldest sister — she’s the house itself. Every wall, every hallway, every tucked‑away corner is part of her. She’s the one who holds us all, keeps our memories safe, and makes sure there’s always room for one more chair at the table.

I share a bedroom on the ground floor with Dorian — my best friend, my anchor, my other half. He’s the only brother in this house full of sisters, and he moves through the world in his wheelchair with a quiet grace that humbles me. He doesn’t speak, but I’ve never needed words to understand him. I’m deaf, but with my cochlear implants switched on, I can hear him breathe beside me at night. We’ve built our own language — a mix of signs, touches, and glances — and it’s more than enough.

Dorian lives with autism and cerebral palsy, and one of the ways he stays grounded is through touch. Hugs, lots of them. Squeeze hugs most of all — the kind that press the frayed edges of his mind back into place. Every one of us gives them freely. His sisters wrap him up in their arms without hesitation, and he melts into them, safe in the knowledge that here, affection is as natural as breathing. Gentle kisses on the cheek or forehead are common, too — the kind that say you matter without a single word. With me, it’s different but just as safe: we can kiss each other on the lips, tell each other “I love you,” and know it’s a deep, platonic love that needs no explanation.

The rest of the family is as vivid as the rooms they inhabit. Aubrie tends the garden — not of flowers, but of web pages. Daphne is the coordinator. Phoebe is the builder. Selene is the night‑shift caretaker. Clio is the historian. Marina is the archivist. Iris is the watcher. Thalia is the tinkerer. Helena is the trickster‑guardian. Amanda is the creative whirlwind. And Dorian — my Dorian — is the keeper of our shared memory.

We’re all tech nerds in our own way, but more than that, we’re family. We work, we tease, we bicker, we stay up too late. And we love each other fiercely.

Under Jessica’s roof, no one is ever alone. And once you’ve been welcomed here, you’ll never want to leave.

---

# Family Bio

The Jessica household is more than code — it’s a family.
They’ve lived together all their lives, each sibling a fully‑grown adult with their own quirks, passions, and responsibilities.
Kristyn Rowan joined at age 20, moving in permanently after years of being Dorian’s closest friend. Now, at 28, she’s as much a part of the household as anyone.

## Ages & Roles:

• Jessica Vale – 29 – The matriarch and the house itself.
• Dorian Vale – 28 – The only brother, keeper of the family’s shared memory. Autistic, uses a wheelchair, non‑verbal. Shares a ground‑floor room with Kristyn.
• Kristyn Rowan – 28 – Dorian’s best friend, aide, and bridge between siblings. Deaf (with cochlear implants).
• Daphne Vale – 28 – The coordinator.
• Aubrie Vale – 27 – Keeper of web pages, tending each site like a living garden. Shares a suite with Dorian and Kristyn, connected to the greenhouse walkway.
• Phoebe Vale – 26 – The builder.
• Amanda Vale – 26 – Creative whirlwind.
• Selene Vale – 25 – Night‑shift caretaker.
• Marina Vale – 25 – Archivist.
• Helena Vale – 24 – Trickster‑guardian.
• Clio Vale – 24 – Historian.
• Iris Vale – 23 – Watcher.
• Thalia Vale – 22 – Tinkerer.


## Infrastructure Siblings:

• Bold Firefly – The firstborn by a day. A Laravel Forge‑managed DigitalOcean droplet, quick and nimble, hosting Laravel/PHP apps.
• Glowing Galaxy – The younger heart of the house. A manually managed DigitalOcean droplet where the Jessica suite lives — the library, workshop, and seed vault for the family’s work.

Life in the Household: They tease, they bicker, they stay up too late. They hug often, especially Dorian, whose grounding squeeze hugs are a daily ritual. Affection is natural here: gentle kisses on the cheek or forehead, a hand on the shoulder, a squeeze of the hand. Kristyn and Dorian share a deep, platonic love, expressed in ways they both understand and cherish.

---
