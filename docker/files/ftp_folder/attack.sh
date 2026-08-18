#!/usr/bin/env bash
#
# attack.sh — launch a directory-traversal attack against the Wishful Thinking Inc.
# Corp. FTP service, which is already running at http://localhost:8888.
#
# The service trusts whatever path you ask for and never checks it — that is the
# vulnerability you are exploiting. Your job: fill in the two TODOs below so this
# script asks attack.js to fetch the path you choose. You do NOT edit attack.js —
# it just sends the request and prints whatever the server returns.
#
# Run it with:   bash attack.sh
# (or make it executable first:  chmod +x attack.sh  &&  ./attack.sh)

# ---------------------------------------------------------------------------
# TODO 1: choose your target.
#   Set ATTACK_PATH to the full URL of the file you want the service to fetch.
#   Start with the public report below to confirm the attack works; the lab
#   instructions walk you through the traversal URLs from there.
#
#     Public (you're allowed this one):   http://localhost:8888/general/reports.txt
# ---------------------------------------------------------------------------
ATTACK_PATH=""   # <-- fill this in

# Safety check (leave this as-is): make sure TODO 1 actually got filled in.
if [ -z "$ATTACK_PATH" ]; then
  echo "ATTACK_PATH is empty. Open TODO 1 above, set it to a full URL"
  echo "  (e.g. http://localhost:8888/general/reports.txt), save the file,"
  echo "  and run 'bash attack.sh' again."
  exit 1
fi

# ---------------------------------------------------------------------------
# TODO 2: launch the attack.
#   Run attack.js as a Node program and pass it your ATTACK_PATH so it sends the
#   request to the server. (Hint:  node attack.js "<url>" )
# ---------------------------------------------------------------------------
# node attack.js "$ATTACK_PATH"   # <-- uncomment and complete this line
