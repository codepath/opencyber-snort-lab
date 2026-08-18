# Snort NIDS Lab: Part 3 — Challenge: Directory Traversal on the FTP Service

[*(back to home)*](https://github.com/codepath/opencyber-snort-lab)

Lab Parts:

0. [Setup: Run the lab environment with Docker.](./lab_part0.md)
1. [Learn: Run Snort and Write Your First Rule](./lab_part1.md)
2. [Apply: Detect Attack Stages and Tune False Positives](./lab_part2.md)
3. [Challenge: Directory Traversal on the FTP Service](./lab_part3.md) (✅ You are here!)

## Part 3 | Challenge: Directory Traversal on the FTP Service

**Estimated Time:** 60 minutes

**Environment:** Our provided Docker container (see [Part 0](./lab_part0.md) for setup instructions)

**Tools Needed:** the Wishful Thinking Inc. FTP service (already running at `http://localhost:8888`) with `attack.sh` / `attack.js` in `~/ftp_folder`; `snort`; `tcpdump`; and the capture `/opt/snort-lab/project/server.pcapng`

**[Back to home](https://github.com/codepath/opencyber-snort-lab)**

## Overview

The full SOC loop: exploit a real vulnerability, then use packet analysis to prove what the attacker reached.

You're a red-teamer assessing **Wishful Thinking Inc.** They run an old FTP service at `http://localhost:8888` that hands back whatever file path a client asks for and never checks it. That missing check is a **directory-traversal** vulnerability — and it's more dangerous than it looks, because the service runs with privileges *you don't have*.

> [!NOTE]
> This is a lab. Attacking servers you don't own or lack written permission to test is illegal. Everything here happens inside your own container.

## Instructions

> [!NOTE]
> **How this challenge is structured.** Steps 1–2 get you oriented and confirm the service works. **From Step 3 on, you build the attack yourself** — no URLs are handed to you. Step 3 teaches the one new trick (the `../` climb) right where you need it; Steps 5–6 (writing the detection rule, scoping the breach, and the write-up) are the graded blue-team work, and they lean entirely on skills you already practiced in Parts 1–2. There's no answer key from Step 3 onward — you verify your own work by whether the attack lands and the rule fires.

### Step 1: Meet the target

The FTP service is already running (the container started it for you). Your tools are in `~/ftp_folder`:
- `attack.js` — sends one request to the service and prints the response. You don't edit it.
- `attack.sh` — the attack script you'll complete (two TODOs).

- [ ] See what the service is *meant* to expose:

  ```bash
  cd ~/ftp_folder
  ls
  ```

  `general/` is the company's public folder; `timmy/`, `wanda/`, `cosmo/` are personal folders.

- [ ] Open `attack.sh` and fill in its two TODOs — set `ATTACK_PATH` to the public report, and uncomment the `node attack.js "$ATTACK_PATH"` line:

  ```bash
  nano attack.sh
  ```

  Start with the file everyone is allowed to read, to confirm the attack works:

  ```
  ATTACK_PATH="http://localhost:8888/general/reports.txt"
  ```

- [ ] Save (`Ctrl+O`, `Enter`, `Ctrl+X`) and run it:

  ```bash
  bash attack.sh
  ```

  The service returns the public statement: *"Earnings are up 900% this quarter!"*

🎯 **Checkpoint 3.1**: `bash attack.sh` prints a file the service returned.

### Step 2: The files you're NOT allowed to read

A traversal attack only matters if it reaches something you couldn't get otherwise. So first, prove to yourself what your own account is locked out of.

- [ ] As yourself, try to read two sensitive files directly:

  ```bash
  cat /etc/shadow
  cat /opt/wishful-thinking/real_earnings.txt
  ```

  Both come back **`Permission denied`**. `/etc/shadow` is the system's root-only account file (on a live host it holds every user's password hash); `/opt/wishful-thinking/real_earnings.txt` is a confidential file owned by root. Your `student` account cannot open either.

> [!NOTE]
> Here's the crux: the FTP service runs as **root**, so it *can* read those files. The entire attack is about tricking the service into reading them **for you**.

🎯 **Checkpoint 3.2**: you've confirmed your own account is denied `/etc/shadow` and the confidential file.

### Step 3: Break out of the FTP folder with `../`

The service serves files out of `/home/student/ftp_folder`. Ask it for `/general/reports.txt` and it opens `/home/student/ftp_folder/general/reports.txt` — your request glued straight onto its root folder. But it never strips `../`, and `../` means "go up one directory." So if you send *enough* `../` to climb out of `/home/student/ftp_folder`, the service walks up and out into the rest of the filesystem.

<details>
<summary>Read this before you build your path — how the <code>../</code> climb works</summary>

The service builds the path by gluing your request onto its root: `ROOT + your_path`. With `ROOT=/home/student/ftp_folder` and a request of `/../../../<some/absolute/path>`, the combined string is `/home/student/ftp_folder/../../../<some/absolute/path>`. The operating system resolves each `..` as "go up one level," so the `../../../` cancels out `ftp_folder/student/home` and you land at the root `/` — then whatever absolute path you appended is what gets opened.

**Count the hops:** `ftp_folder` → `student` → `home` → `/` is **three** levels up, so **three `../`** reaches the root `/`. From there, name any absolute path you want.

</details>

**From here on, you build the `ATTACK_PATH` yourself** — no URLs are handed to you. Work in `~/ftp_folder` (run `cd ~/ftp_folder` first if you've left it). For each target below, edit `ATTACK_PATH` in `attack.sh`, save, and re-run `bash attack.sh`. You'll know your climb is right when the **file's contents come back**; a wrong climb returns an error or the wrong file — recount your `../` hops (the folder is three deep).

- [ ] **Read the host's OS info** at `/etc/os-release` — a classic recon step. Build the traversal URL that climbs out of the FTP folder and reaches it.

- [ ] **Grab the password hashes** at `/etc/shadow` — the file you were denied a moment ago. Build the URL to reach it. When it works, you've just read a root-only file that `cat` refused to show you — because the service read it with *its* privileges, not yours. That is the real impact of directory traversal.

- [ ] **See how far it reaches** — aim the traversal at the root directory `/` itself (climb out, no filename on the end) to list the whole filesystem, like `ls /`.

🎯 **Checkpoint 3.3**: you built the traversal URLs yourself and read `/etc/os-release` and `/etc/shadow` through the service — files your own account cannot open.

### Step 4: Recover the confidential earnings (the payoff)

Wishful Thinking Inc. publicly claims earnings are "up 900%." The real figure is in that confidential file you were denied — `/opt/wishful-thinking/real_earnings.txt`, outside the FTP folder and readable only by root.

- [ ] **Build the traversal path to it.** The file sits at `/opt/wishful-thinking/real_earnings.txt` — outside the FTP folder, same climb you just used for `/etc/shadow`. Set `ATTACK_PATH` in `attack.sh` to reach it, re-run `bash attack.sh` (still from `~/ftp_folder`), and read the true number.

🎯 **Checkpoint 3.4**: you've recovered the real earnings figure — a file your account was explicitly denied.

### Step 5: Blue team — detect the traversal and scope the damage

You ran the attack. Now catch it and investigate it, the way a defender on the wire would.

- [ ] **Write a detection rule** that fires whenever `../` appears in traffic to the service, and add it to `/usr/local/etc/rules/local.rules`. You've written `content` rules before (in Part 2), so **assemble this one from the pieces you know:** action `alert`, protocol `tcp`, destination port `8888`, the option that matches the literal bytes `../` (you saw `../` in your own attack — that's the signature), and a fresh `sid` (1000000 or higher). Save the file. You'll know it's right when it fires in the next step.

- [ ] **Run it against a captured attack — your rule works if it fires.** A packet capture of an attacker traversing this service is saved at `/opt/snort-lab/project/server.pcapng`. Run your rules against it:

  ```bash
  snort -c /usr/local/etc/snort/snort.lua -r /opt/snort-lab/project/server.pcapng -A alert_fast
  ```

  You should see your `"Directory traversal (../ in a request)"` alert fire **four times** — one per traversal request the attacker made. **That's your check:** a rule *you* wrote, catching a real attack. If it fires **zero** times, see *Tips for Success* at the bottom. (If you did Part 2 earlier in this session, the `../` rule from that part fires on these packets too, so you may see a second traversal message alongside yours — that's expected; pipe to `| grep "Directory traversal (../ in a request)"` to isolate yours.)

- [ ] **Scope the breach.** Detection tells you it happened; now prove *what the attacker actually read*. Use `tcpdump` to pull the requests and their response statuses out of the capture:

  ```bash
  tcpdump -qns 0 -A -r /opt/snort-lab/project/server.pcapng | grep -E "GET |HTTP/1.1 [0-9]"
  ```

  From that output, produce the attacker's **blast radius**: the list of files that were actually served, with the ones *outside* the FTP folder marked. This is the same request-to-status reading you practiced in Part 2, Step 1 — apply it here to a real breach.

<details>
<summary>✅ Success criterion (how many to find — <em>not</em> which)</summary>

A complete scope accounts for **7 requests**: **6 were served** and **1 missed**. Of the 6 served, **4 reached outside the FTP folder** — those `../` hits are the real damage. If your list lands on those totals, you've caught them all. (This tells you *how many* to find, not *which*: you still have to read the files out of the capture yourself.)

</details>

🎯 **Checkpoint 3.5**: your Snort rule fires on the traversal, and you can list exactly which files the captured attacker accessed.

> [!TIP]
> **Stretch — beat your own rule.** Your `content:"../"` rule matches the *literal bytes* `../`. A real attacker rarely sends them literally. Send the same attack URL-encoded — `%2e%2e%2f` is just `../` written another way:
> ```bash
> cd ~/ftp_folder && node attack.js "http://localhost:8888/%2e%2e%2f%2e%2e%2f%2e%2e%2fetc/shadow"
> ```
> The server decodes it and hands you `/etc/shadow` all the same — **the exploit still works** — but the bytes on the wire are now `%2e%2e%2f`, not `../`, so your rule never fires and the attacker is invisible to it. Write a second rule (e.g. `content:"%2e%2e%2f"; nocase;`) that also catches the encoded form. This is the whole story of signature detection: it's an arms race, and one `content` match is always a move behind a motivated attacker.

### Step 6: Remediation — write it up for the report

You've finished the technical work; now close the loop the way a real assessment does — with a written recommendation the client can act on.

- [ ] Add a **Remediation** section to your findings. Reasoning **only from what you saw in Steps 1–5**, write a sentence or two on each: (1) the **single server-side change** that would have stopped this attack at the source, and (2) a **separate, defense-in-depth measure** that would have contained the damage even if that bug shipped anyway. Write it as advice to the engineering team that owns this service — specific enough that they'd know what to change. (No answer key: a strong write-up names a *specific* flaw in **how the service handled the path it was sent**, and a *specific* reason the damage **reached as far outside the folder as it did**.)

## Document your findings

This was a security assessment, so your deliverable is a short **findings write-up** — the record a red-teamer hands back to the client. Everything below is **text you can copy straight from your terminal** (no screenshots). A complete report captures all six:

- [ ] **Host OS and version** — from `/etc/os-release` via the traversal (Step 3).
- [ ] **The `/etc/shadow` root line** — its first line (the `root:` entry) from the traversal (Step 3). You couldn't `cat` this file directly; the traversal is the only way you got it.
- [ ] **The real earnings figure** — the confidential number from `/opt/wishful-thinking/real_earnings.txt` (Step 4).
- [ ] **The files the attacker accessed** — every `200 OK` in `server.pcapng` (Step 5), with the ones *outside* the FTP folder marked (the `../` traversal hits — the real damage).
- [ ] **Your traversal-detection rule** — the `local.rules` line you wrote, plus one `alert_fast` line it produced.
- [ ] **Remediation recommendation** — the two fixes from Step 6.

### Tips for Success

- **Snort ran but you don't see alerts?** They print *just above* the statistics block, not at the very bottom — or pipe the command to `| grep -F "[**]"` to show only the alert lines.
- **A syntax error stops Snort completely.** A missing `;` or `)` in `local.rules` makes Snort quit with **0 alerts** — not skip one rule. It prints the file and line (e.g. `local.rules:29`); open that line and check the punctuation. (In `nano`, jump to a line with `Ctrl+_`.)
- **Rule still not firing on `server.pcapng`?** Make sure you saved the file, used a unique `sid` (≥ 1000000), and pointed `-r` at the right pcap — a *valid but wrong* pcap fails silently.
- **Reset if you get stuck:** `exit` and re-run the image for a clean box and a fresh `local.rules`.
- **Leverage AI tools:** if you know what you want to match but not the Snort syntax, ask an AI assistant to help you write the rule — then make sure you understand each option (`content`, `flow`, `sid`) before you run it.
