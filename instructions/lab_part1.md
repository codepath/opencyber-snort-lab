# Snort NIDS Lab: Part 1 — Learn

[*(back to home)*](https://github.com/codepath/opencyber-snort-lab)

Lab Parts:

0. [Setup: Run the lab environment with Docker.](./lab_part0.md)
1. [Learn: Run Snort and Write Your First Rule](./lab_part1.md) (✅ You are here!)
2. [Apply: Detect Attack Stages and Tune False Positives](./lab_part2.md)
3. [Challenge: Directory Traversal on the FTP Service](./lab_part3.md)

## Part 1 | Learn: Run Snort and Write Your First Rule

**Estimated Time:** 30 minutes

**Environment:** Our provided Docker container (see [Part 0](./lab_part0.md) for setup instructions)

**Tools Needed:** `snort` (Snort 3, pre-installed), the practice pcaps in `/opt/snort-lab/pcaps/`

**[Back to home](https://github.com/codepath/opencyber-snort-lab)**

## Overview

Signature-based network intrusion detection (NIDS) matches traffic against known-bad patterns. In this part you run Snort against a captured pcap, learn how a rule is put together, watch alerts fire, and write your first rule.

## Instructions

### Step 1: What signature-based NIDS is

A **NIDS** (Network Intrusion Detection System) watches network traffic and raises an alert when it sees something suspicious. Snort is the classic example.

Snort is **signature-based**: it compares each packet against a list of **rules**, where every rule describes a specific pattern of known-bad traffic — a byte sequence, a port, a protocol quirk. If the traffic matches a rule, Snort fires an alert. If nothing matches, Snort stays quiet.

That is both its strength and its limit:

- It is **fast and precise** at catching attacks that someone has already written a signature for.
- It is **blind to anything new** — a novel attack with no matching signature sails straight through.

This is why signature-based detection is only half of a defender's toolkit. The other half is **threat hunting** (which we cover in another OpenCyber lab — the Threat Hunt lab): instead of waiting for a known signature to match, a hunter proactively digs through logs and traffic looking for the *unknown* — the attack no rule was written for yet. Signatures catch the known; hunting catches the rest.

> **An analogy.** Picture a bouncer at a club. **Signature-based** detection is a bouncer holding a stack of mugshots — they check each face against the photos and stop anyone that matches. Fast and certain, but blind to any troublemaker whose photo isn't in the stack. **Threat hunting** is a bouncer who instead walks the floor watching for anyone *acting* wrong — no photo needed, but slower and more of a judgment call. Snort is the mugshot bouncer, and in this lab you build its stack of photos.

In this lab you play the signature side: you write the rules.

- [ ] Read the explanation above and make sure you can state, in one sentence, the difference between signature-based detection and threat hunting.

### Step 2: Run Snort against a pcap

Instead of watching a live network, in this lab you run Snort against **pcaps** — packet capture files that were recorded earlier. Reading a saved capture means everyone sees the exact same traffic every time, so your rules behave predictably.

The `icmp.pcap` file contains a handful of ICMP packets (the kind a `ping` produces).

- [ ] Run Snort against it:

  ```bash
  snort -c /usr/local/etc/snort/snort.lua -r /opt/snort-lab/pcaps/icmp.pcap -A alert_fast
  ```

  Here is what each part means:
  - `-c /usr/local/etc/snort/snort.lua` — the pre-tuned config (it already loads your rules for you)
  - `-r <file>` — **r**ead this capture file instead of a live interface
  - `-A alert_fast` — print each **a**lert as a single, easy-to-read line

- [ ] Read the alert output. The alert lines (they begin with `[**]`) print **just above** the statistics block — *not* at the very bottom, where Snort ends with its stats and `Snort exiting`. You should see several `"LAB ICMP packet seen"` alerts. Tip: to see only the alerts, add `| grep -F "[**]"` to the end of the command.

🎯 **Checkpoint 1.1**: You can run Snort against a pcap and see its alert summary.

<details>
<summary>✅ Check your result</summary>

You should see **8** `LAB ICMP packet seen` alerts — one for each ICMP packet in the capture (four pings, each with a request and a reply). Snort also prints a statistics block; the line `total rules loaded` confirms your rules file was read. (That number is in the hundreds because the pre-tuned config bundles many built-in rules — a large count is normal, not an error.)

</details>

### Step 3: Read a Snort rule (header + options)

Those alerts came from a rule that already ships in your rules file. Open it and read it.

- [ ] Open the rules file in `nano` (a simple terminal text editor):

  ```bash
  nano /usr/local/etc/rules/local.rules
  ```

  <details>
  <summary>New to <code>nano</code>? (how to move, edit, save, and exit — worth reading first)</summary>

  `nano` is a beginner-friendly terminal text editor. The parts that trip people up:

  - **Move the cursor** with the **arrow keys** only — you can't click to place it.
  - **Type** to insert text at the cursor; **Backspace/Delete** removes it. That's all editing is.
  - **Save** (nano calls it "Write Out"): **`Ctrl+O`**, then **`Enter`** to confirm the filename.
  - **Exit**: **`Ctrl+X`**. If you have unsaved changes, it asks `Y`/`N` first.
  - **Jump to a line number**: `Ctrl+_` — handy when Snort points you at `local.rules:12`.
  - **Made a mess by accident?** Exit *without* saving — **`Ctrl+X`, then `N`** — and the file is left untouched. Re-open it and start over. (Or reset the whole box: `exit`, then re-run the container.)

  The bottom two rows of the nano screen list these shortcuts; `^O` there means `Ctrl+O`.

  </details>

- [ ] Find the starter rule:

  ```
  alert icmp any any -> any any ( msg:"LAB ICMP packet seen"; sid:1000001; rev:1; )
  ```

Every Snort rule has two parts: a **header** and a set of **options**.

- [ ] Identify the header vs. the options in the rule above.

<details>
<summary>✅ Check your answer: which part is the header, which are the options?</summary>

The **header** is everything before the opening parenthesis. It answers *who* and *where*:

```
alert   icmp    any any    ->    any any
  |       |        |        |       |
action  protocol source   direction destination
                  ip port            ip port
```

- **action** — what to do on a match (`alert`, `log`, `drop`, ...). `alert` logs it and moves on.
- **protocol** — `icmp`, `tcp`, `udp`, or `ip`.
- **source / destination** — the IP and port on each side. `any` means "match anything".
- **direction** — `->` means "from source to destination". (`<>` means either direction.)

So `alert icmp any any -> any any` reads: *"alert on ICMP traffic from anywhere to anywhere."*

The **options** live inside the parentheses and answer *what to match* and *what to say*:

- `msg:"..."` — the text printed when the rule fires.
- `sid:1000001` — the **s**ignature **id**, a unique number for this rule. Use `sid` values of **1000000 or higher** for your own rules; that range is reserved for local rules.
- `rev:1` — the revision number; bump it when you edit a rule.

</details>

### Step 4: Watch alerts fire on replayed traffic

The ICMP rule has no `content` option, so it matches *every* ICMP packet — that is why it fired 8 times. Rules get useful when the header and options narrow things down to traffic you actually care about.

- [ ] Run Snort against the second practice capture, `web-attack.pcap`, which contains web/FTP traffic:

  ```bash
  snort -c /usr/local/etc/snort/snort.lua -r /opt/snort-lab/pcaps/web-attack.pcap -A alert_fast
  ```

- [ ] Notice that the ICMP rule produces **no** alerts this time — there are no ICMP packets in this capture, only TCP. A rule only fires on traffic that matches its header.

🎯 **Checkpoint 1.2**: You understand that a rule fires only on traffic matching its header and options.

### Step 5: Build your first rule

The `web-attack.pcap` traffic is aimed at a web/FTP server on **port 8888**. Using the rule anatomy you just read, here's a rule that alerts on any TCP traffic headed to that port. **In Part 2 you'll write rules like this yourself — here we build one together first, so you've seen every piece.**

- [ ] Add a new line to `/usr/local/etc/rules/local.rules` (below the starter rule):

  ```
  alert tcp any any -> any 8888 ( msg:"Traffic to the FTP web server"; sid:1000002; rev:1; )
  ```

  Read the header: *alert on TCP traffic, from any address/port, going to any address on port 8888.* Note the new `sid` — every rule needs its own.

- [ ] Save the file (in `nano`: `Ctrl+O`, `Enter`, then `Ctrl+X`).

- [ ] Re-run Snort against the web capture and confirm your rule fires. **This is the exact same command from Step 4** — press the **up arrow** to pull it back up instead of retyping it:

  ```bash
  snort -c /usr/local/etc/snort/snort.lua -r /opt/snort-lab/pcaps/web-attack.pcap -A alert_fast
  ```

🎯 **Checkpoint 1.3**: Your first rule produces an alert on the practice traffic.

<details>
<summary>✅ Check your result</summary>

You should see a **burst** of `"Traffic to the FTP web server"` alerts — around **48**. A header-only rule with no `content` matches *every packet* going to port 8888 (the connection setup, the `GET`, the ACKs), not just the 8 requests — that's why the count is far higher than 8. You'll narrow this down to one-per-request in Part 2 with `content` and `flow`. If you see **nothing**, check that:

- you saved the file,
- the `sid` is different from every other rule, and
- the port in the header is `8888`.

</details>

- [ ] **Before you move on, think it through:** you just made Snort flag *every* packet to that FTP server — dozens of alerts for a handful of real requests. Which of those requests do you think actually matter to a defender, and what might you want to catch a real attacker *doing* on this server? (Nothing to write down — you'll act on this in Part 2.)

When your rule fires, you are ready to [**proceed to Part 2**](./lab_part2.md) — where you'll write the rules yourself.
