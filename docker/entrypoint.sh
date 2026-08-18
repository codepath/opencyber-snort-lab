#!/usr/bin/env bash
set -e

g='\033[0;32m'; n='\033[0m'

echo
echo -e "   __   __   __   ___ "
echo -e "  /  \` /  \ |  \ |__  "
echo -e "  \__, \__/ |__/ |___ "
echo -e "   __       ___       "
echo -e "  |__)  /\   |   |__|  "
echo -e "  |    /--\  |   |  |  "
echo -e "        __   __   ___  "
echo -e "  ${g}\|/  ${n}/  \ |__) / _   "
echo -e "  ${g}/|\  ${n}\__/ |  \ \__/  "
echo
echo -e "Welcome to the ${g}Snort NIDS Lab${n} environment!"
echo
echo "GETTING STARTED:"
echo -e " ${g}*${n} Snort 3 is pre-installed and pre-configured — you write rules, not configs."
echo -e " ${g}*${n} Edit rules:   /usr/local/etc/rules/local.rules  (snort.lua loads it automatically)"
echo -e " ${g}*${n} Read a pcap:  snort -c /usr/local/etc/snort/snort.lua -r <file.pcap> -A alert_fast"
echo -e " ${g}*${n} Lab pcaps are in /opt/snort-lab/pcaps/"
echo -e " ${g}*${n} The vulnerable FTP service is already running at http://localhost:8888 (Part 3 target)"
echo -e " ${g}*${n} Follow along with the instructions at:"
echo -e "\thttps://github.com/codepath/opencyber-snort-lab"
echo

# Start the deliberately vulnerable "Wishful Thinking Inc." FTP service AS ROOT. Running it as
# root is what makes the Part 3 directory-traversal meaningful: the student's own shell
# cannot read root-only files (e.g. /etc/shadow, the confidential earnings), but this
# root-run service can — and the traversal bug makes it read them on the student's behalf.
FTP_ROOT=/home/student/ftp_folder node /opt/snort-lab/vuln-server.js >/var/log/vuln-ftp.log 2>&1 &

# Wait until the service is actually listening on :8888 before handing over the shell,
# so a fast student in Part 3 never races a not-yet-ready server. Best-effort (~5s cap);
# uses bash's /dev/tcp so it needs no extra tools. NOTE: the probe runs in a SUBSHELL so
# its redirections never touch this script's fds — an `exec ... 2>/dev/null` here would
# permanently drop the shell's stderr and make `su - student` start NON-interactive
# (no prompt, since .bashrc skips PS1 for non-interactive shells).
for _ in $(seq 1 25); do
  (echo > /dev/tcp/127.0.0.1/8888) >/dev/null 2>&1 && break
  sleep 0.2
done

# NOTE: reading a pcap with `-r` needs no special privileges. Live capture on an interface
# would need --cap-add=NET_RAW (and ethtool gro/lro off); the lab leans on `-r` for determinism.

exec su - student
