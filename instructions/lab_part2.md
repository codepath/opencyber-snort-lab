# Snort NIDS Lab: Part 2 — Apply

[*(back to home)*](https://github.com/codepath/opencyber-snort-lab)

Lab Parts:

0. [Setup: Run the lab environment with Docker.](./lab_part0.md)
1. [Learn: Run Snort and Write Your First Rule](./lab_part1.md)
2. [Apply: Detect Attack Stages and Tune False Positives](./lab_part2.md) (✅ You are here!)
3. [Challenge: Directory Traversal on the FTP Service](./lab_part3.md)

## Part 2 | Apply: Detect Attack Stages and Tune False Positives

**Estimated Time:** 40 minutes

**Environment:** Our provided Docker container (see [Part 0](./lab_part0.md) for setup instructions)

**Tools Needed:** `snort` (Snort 3, pre-installed), `tcpdump`, the practice pcaps in `/opt/snort-lab/pcaps/`

**[Back to home](https://github.com/codepath/opencyber-snort-lab)**

## Overview

In Part 1 you matched on the header (protocol and port). Real detection needs the **options** — especially `content`, which matches a byte string anywhere in the packet. In this part you write rules that catch specific stages of an attack in `web-attack.pcap`, then tune them so they detect the attack without drowning you in false positives.

The `web-attack.pcap` capture is a recording of an attacker probing the same "Wishful Thinking Inc." FTP web server you'll attack yourself in Part 3. It mixes a few normal, allowed requests in with the malicious ones — exactly like real traffic.

## Instructions

> [!NOTE]
> **Two things before you start.**
> 1. **Clear your Part 1 rules first.** The broad `"Traffic to the FTP web server"` rule from Part 1 fires on *every* packet — leave it in and it buries your new alerts in noise. Open `nano /usr/local/etc/rules/local.rules`, delete that line (and the `LAB ICMP` starter rule too, if you like), and save.
> 2. **Each part stands on its own.** Your rule edits live in `local.rules` and persist while the container is running, but reset to a clean file if you `exit` and re-run the box. Part 2 needs nothing you wrote in Part 1 — you build its rules fresh here.

### Step 1: Identify the attack stages in the traffic

Before you can detect an attack, you have to see it. The requests in the capture are plain HTTP `GET` lines, so you can read them straight out of the pcap with `tcpdump` (a command-line tool that prints the packets inside a capture file).

- [ ] List every request in the capture:

  ```bash
  tcpdump -qns 0 -A -r /opt/snort-lab/pcaps/web-attack.pcap | grep "GET "
  ```

- [ ] Read the list and decide which requests are normal browsing and which are an attacker poking at things they shouldn't.

- [ ] Now confirm which of those requests the server actually **served**. Re-run with the response status lines included, and match each `GET` to the `HTTP/1.1` status that follows it a few packets later:

  ```bash
  tcpdump -qns 0 -A -r /opt/snort-lab/pcaps/web-attack.pcap | grep -E "GET |HTTP/1.1 [0-9]"
  ```

  A `200 OK` means the file was served; a `404` means it wasn't. (You'll reuse this request-to-status correlation in Part 3 to scope a real breach — so get comfortable reading it here.)

🎯 **Checkpoint 2.1**: You can list the requests in the capture, match each to its response status, and describe what the attacker did.

<details>
<summary>✅ Check your result</summary>

You should see eight requests, in this order:

| # | Request | What it is |
|---|---------|------------|
| 1 | `GET /general/reports.txt` | normal — the public report |
| 2 | `GET /general/budget.txt` | normal — a public file |
| 3 | `GET /general/reports.txt` | normal — the public report again |
| 4 | `GET /` | **recon** — listing the whole server |
| 5 | `GET /wanda/passwords.txt` | **credential theft** — a password file |
| 6 | `GET /timmy/passwords.txt` | **credential theft** — another password file |
| 7 | `GET /wanda/reports_original.txt` | **data theft** — a hidden report |
| 8 | `GET /../../../etc/passwd` | **directory traversal** — escaping the server's folder |

Requests 1–3 are benign. Requests 4–8 are the attack. Your job below is to write rules that flag the attack **without** flagging the benign traffic.

</details>

### Step 2: Write rules to catch specific attack stages

The key option here is `content`, which matches a byte string anywhere in the packet payload. You'll also use `flow:to_server,established`, which restricts the rule to packets going *to* the server on an established connection — a good habit that avoids matching stray replies.

> 📚 **Want to go beyond the options shown here?** The full catalog of Snort rule options (`content`, `flow`, `pcre`, `nocase`, and many more) lives in the official Snort documentation at [snort.org/documents](https://www.snort.org/documents). You never *need* to leave this lab, but skim it if you want to experiment — especially when you tune the rule in Step 3.

- [ ] **Stage 1 — credential theft.** Look back at your Step 1 request list. Two of the attacker's requests are stealing credentials — what filename do they share that *never* shows up in the normal browsing traffic? **Write a rule** whose `content` matches that string (to port `8888`, with `flow:to_server,established`, a `msg`, and a fresh `sid` of 1000000 or higher), and add it to `local.rules`.

  <details>
  <summary>💡 Stuck? Reveal the rule</summary>

  ```
  alert tcp any any -> any 8888 ( msg:"Credential file access"; flow:to_server,established; content:"passwords.txt"; sid:1000010; rev:1; )
  ```

  </details>

- [ ] **Stage 2 — directory traversal.** Which single request is the attacker using to climb *out* of the server's folder? What short byte sequence is the signature of that move? **Write a rule** that matches it (same shape as above, a new `sid`).

  <details>
  <summary>💡 Stuck? Reveal the rule</summary>

  ```
  alert tcp any any -> any 8888 ( msg:"Directory traversal attempt"; flow:to_server,established; content:"../"; sid:1000011; rev:1; )
  ```

  </details>

- [ ] Save `local.rules` and re-run Snort:

  ```bash
  snort -c /usr/local/etc/snort/snort.lua -r /opt/snort-lab/pcaps/web-attack.pcap -A alert_fast
  ```

- [ ] Confirm each new rule fires.

> [!NOTE]
> **Rule fires zero times? Check for a typo first.** A missing `;` or `)` in `local.rules` doesn't skip one rule — it makes Snort **quit with 0 alerts**. Snort prints the offending file and line (e.g. `local.rules:12`); open that line and check the punctuation. If the syntax is fine but you still see nothing, make sure you **saved** the file and gave the rule a **unique `sid`** (≥ 1000000).

🎯 **Checkpoint 2.2**: Each attack stage produces its own alert.

<details>
<summary>✅ Check your result</summary>

- `Credential file access` fires **twice** — once for `/wanda/passwords.txt` and once for `/timmy/passwords.txt`.
- `Directory traversal attempt` fires **once** — for `/../../../etc/passwd`.

Both rules ignore the benign requests, because `passwords.txt` and `../` never appear in the normal browsing traffic.

</details>

### Step 3: Tune out false positives

Now for the hard part of real detection. You want to catch the attacker stealing the hidden `reports_original.txt` file (request #7). A first attempt might be to alert whenever anyone reads a "report":

- [ ] Add this deliberately **too-broad** rule:

  ```
  alert tcp any any -> any 8888 ( msg:"Report access (too broad)"; flow:to_server,established; content:"reports"; sid:1000020; rev:1; )
  ```

- [ ] Re-run Snort and count how many times it fires.

You'll find it fires **three** times — but only **one** of those is the attack. The other two are the benign public-report reads (requests 1 and 3). Those two alerts are **false positives**: the rule is crying wolf on traffic that is completely normal. In a real **SOC** (Security Operations Center — the team that watches these alerts), a rule like this buries the one real alert under noise, and analysts start ignoring it.

The fix is to make the `content` match more **specific** — match a string that appears *only* in the malicious request, not in the benign one. Look closely at the two report filenames in your Step 1 list: the public report and the hidden one differ by a few characters. Which characters are unique to the hidden file?

- [ ] **Tighten your rule's `content`** so it matches *only* the hidden report, and bump its `rev` to `2` (you changed the rule, so you bump the revision).

  <details>
  <summary>💡 Stuck? Reveal the tightened rule</summary>

  ```
  alert tcp any any -> any 8888 ( msg:"Hidden report exfiltration"; flow:to_server,established; content:"reports_original"; sid:1000020; rev:2; )
  ```

  </details>

- [ ] Re-run Snort and confirm the false positives are gone.

<details>
<summary>Hint: too many alerts?</summary>

When a rule is too noisy, tighten it. In order of usefulness:

- **More specific `content`.** The more unique your byte string, the fewer false positives — match something that appears *only* in the malicious request, not in the benign one.
- **Direction and flow.** `flow:to_server,established` drops matches on replies and half-open connections.
- **Header narrowing.** Pinning the port (`-> any 8888`) or protocol keeps the rule off unrelated traffic.
- **Thresholds** (`event_filter`) can cap how often a rule fires, but that's a last resort — fix the match first.

The goal is always the same: catch every real event (don't *miss*), with as little *noise* as possible.

</details>

🎯 **Checkpoint 2.3**: Your rules detect every attack stage with no false positives on benign traffic.

<details>
<summary>✅ Check your result</summary>

With the tuned rule (`content:"reports_original"`), `Hidden report exfiltration` fires exactly **once** — on request #7 — and never on the benign `reports.txt` reads. Together your three rules now flag credential theft, directory traversal, and the hidden-report theft, and stay silent on the normal traffic.

</details>

> [!TIP]
> **Stretch (optional) — detect by *location*, not filename.** Every rule you wrote so far matches on a *filename* (`passwords.txt`, `reports_original`). That's brittle: the attacker only has to rename the file. Write a rule that instead flags **any** request into a personal user folder — match the path `content:"/wanda/"` (give it a fresh `sid`). Re-run Snort: it should fire on **every** request into that folder — both of the attacker's `wanda` requests — while staying completely silent on the public `/general/` reads. Matching on *where* a request goes rather than *what* it names is often a more durable signature, and it's a different mechanic than the filename matches above. (Bonus: extend it to `/timmy/` and `/cosmo/` and think about why one rule per folder is clumsier than you'd like — a limitation you'll meet again in real detection engineering.)

When your rules are tuned, you are ready to [**proceed to Part 3**](./lab_part3.md).
