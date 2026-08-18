# Snort Intrusion Detection Lab

This is the README documentation for the Snort Intrusion Detection Lab, produced and maintained by [CodePath.org](https://codepath.org).

## Quick Start

Want to jump into the lab? Navigate to the [Part 0 Instructions](./instructions/lab_part0.md) to get started!

## About this Lab

<img src="https://i.imgur.com/Hx44oDJ.png" style="width: 75%; min-width: 350px;" alt="Screenshot of provided Docker Container printing welcome message for Snort Intrusion Detection Lab"></img>

The Snort Intrusion Detection Lab is designed to teach you how a signature-based network intrusion detection system (NIDS) spots an attack on the wire. You'll run Snort 3 against realistic captured traffic, write and tune your own detection rules, and cut down the false positives that bury a real alert. Then you'll switch sides: launch a genuine directory-traversal attack against a vulnerable FTP service, detect it with a rule you write, and use packet analysis to prove exactly which files the attacker read. Snort is pre-compiled in the container, so you spend your time on the skill — not a 30–60 minute build.

### Learning Objectives

- Explain what a signature-based NIDS is and how Snort matches traffic against rules
- Write and tune your own Snort rules — and cut down the false positives that hide a real alert
- Exploit a directory-traversal vulnerability, then detect it on the wire with a `content:"../"` rule
- Scope a breach from a packet capture — prove exactly which files an attacker accessed

### Lab Activities

0. [Setup: Run the lab environment with Docker](./instructions/lab_part0.md)
1. [Learn: Run Snort and Write Your First Rule](./instructions/lab_part1.md)
2. [Apply: Detect Attack Stages and Tune False Positives](./instructions/lab_part2.md)
3. [Challenge: Directory Traversal on the FTP Service](./instructions/lab_part3.md)

## Technical Details

### Provided Tools

In the provided Docker container, you will find all the necessary tools and dependencies pre-installed. This includes:

- `snort` - Snort 3, pre-compiled and pre-configured (the main focus of this lab)
- A starter rule set and practice packet captures in `/opt/snort-lab/`
- `tcpdump` and `tcpreplay` - for inspecting and replaying captured traffic
- A vulnerable FTP service - the directory-traversal target you'll attack and then detect

The lab runs with **no outbound network** — everything it needs is inside the container.
