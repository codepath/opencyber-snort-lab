# Snort NIDS Lab: Part 0 — Setup

[*(back to home)*](https://github.com/codepath/opencyber-snort-lab)

Lab Parts:

0. [Setup: Run the lab environment with Docker.](./lab_part0.md) (✅ You are here!)
1. [Learn: Run Snort and Write Your First Rule](./lab_part1.md)
2. [Apply: Detect Attack Stages and Tune False Positives](./lab_part2.md)
3. [Challenge: Directory Traversal on the FTP Service](./lab_part3.md)

## Part 0 | Setup: Run the lab environment with Docker

**Estimated Time:** 15 minutes

**Environment:** Your own computer (Docker)

**Tools Needed:** Docker


## Overview

Snort 3 ships **pre-installed and pre-configured** in this container, so you spend your time writing detection rules instead of building and configuring Snort. This part gets the container running and shows you where the rules file, the lab pcaps (packet-capture files — saved recordings of network traffic), and the FTP target live.

## What you'll learn

By the end of this lab you'll be able to:

- Explain what a signature-based NIDS (network intrusion detection system) is and how Snort matches traffic against rules.
- Write and tune your own Snort rules — and cut down the false positives that bury a real alert.
- Exploit a directory-traversal vulnerability and then detect it on the wire with a `content:"../"` rule.
- Scope a breach from a packet capture — prove exactly which files an attacker read.

## Instructions

### Step 1: Install and start Docker

- [ ] Make sure Docker is installed and running on your computer.
  - **Mac**: [Download Docker Desktop for Mac](https://docs.docker.com/desktop/install/mac-install/)
  - **Windows**: [Download Docker Desktop for Windows](https://docs.docker.com/desktop/install/windows-install/)
  - **Linux**: [Install Docker Engine](https://docs.docker.com/engine/install/) (or [Docker Desktop for Linux](https://docs.docker.com/desktop/install/linux/))
  - Once installed, open Docker Desktop and confirm it's running before continuing.

- [ ] Open a terminal on your computer:
  - **Mac**: Open **Terminal** (search "Terminal" in Spotlight with ⌘+Space)
  - **Windows**: Open **Command Prompt** or **PowerShell** (search either in the Start menu)
  - **Linux**: Open your system's terminal emulator

### Step 2: Run the lab container

- [ ] Run the lab container with:

  ```bash
  docker run -it --rm ghcr.io/codepath/opencyber-snort-lab:latest
  ```

  The first run downloads the image (about 800 MB), so give it a minute. When it finishes you'll see a welcome banner and land at a `student@...` shell prompt.

> [!TIP]
> If you cloned this repository, you can use the Makefile shortcuts instead: `make ghcr` runs the published image, and `make student` followed by `make run` builds and runs it locally.

> [!TIP]
> If you have trouble pulling the image, you can build it yourself. The image compiles Snort 3 from source in a builder stage, so the **first** build takes a while (grab a coffee); after that it is cached.
>
> ```bash
> git clone https://github.com/codepath/opencyber-snort-lab.git
> cd opencyber-snort-lab
> docker build -t opencyber-snort-lab:local -f docker/Dockerfile .
> docker run -it --rm opencyber-snort-lab:local
> ```

🎯 **Checkpoint 0.1**: You land at the lab's welcome banner and a `student@` shell prompt.

### Step 3: Confirm Snort is pre-configured

- [ ] Confirm Snort is installed and reports its version:

  ```bash
  snort -V
  ```

  You should see `Snort++` version `3.1.81.0`.

- [ ] (Optional) Confirm the configuration loads cleanly:

  ```bash
  snort -c /usr/local/etc/snort/snort.lua --warn-all
  ```

  Snort validates the config and prints `Snort successfully validated the configuration`. A couple of harmless `WARNING` lines (for example, about `appid`) are expected — you can ignore them.

### Step 4: Where things live

The container is already set up. You only ever edit **one** file: `local.rules`.

- [ ] Skim the file locations you'll use throughout the lab. **You don't need to memorize or write these down** — each part reminds you of the exact path when you need it. This is just a map so nothing feels out of nowhere later:
  - Rules file you edit: `/usr/local/etc/rules/local.rules`
  - Pre-tuned config (read-only): `/usr/local/etc/snort/snort.lua`
  - Practice pcaps (Parts 1–2): `/opt/snort-lab/pcaps/`
  - FTP target (Part 3): `~/ftp_folder`
  - Part 3 packet trace: `/opt/snort-lab/project/server.pcapng`

The config file (`snort.lua`) is already pointed at your rules file, so anything you add to `local.rules` is loaded automatically the next time you run Snort. You never need to open `snort.lua`.

> [!IMPORTANT]
> Keep your terminal open for the entire lab — closing it stops the container.

> [!NOTE]
> This container starts fresh every time you run it. If you stop it and start again, any rules you added to `local.rules` are reset to the starter file. Finish a part in one sitting, or copy your rules somewhere safe before you exit.

When you can run the container and see the welcome banner, you are ready to [**proceed to Part 1**](./lab_part1.md).
