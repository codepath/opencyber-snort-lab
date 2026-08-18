# docker/Dockerfile — opencyber-snort-lab (CYB102 U3)
# Snort 3 NIDS lab. The headline win of containerizing: the current VM lab makes students
# do a 30–60 minute from-source Snort build (unit3_lab.sh). Here that build happens ONCE, at
# image-build time, in a multi-stage builder — students get Snort instantly and spend their
# time writing rules, not fighting snort.lua/ethtool/PulledPork.
#
# Versions are pinned to match the VM setup script (cyb102-vm-setup/Scripts/unit3_lab.sh).
# NOTE: the upstream download URLs below are the most fragile part of this build — a few
# (boost jfrog, snort.org libdaq, sourceforge pcre) rot over time. Verify/refresh them when
# the image is first built; boost has been repointed to archives.boost.io already.

# ─────────────────────────── Stage 1: builder ───────────────────────────
FROM ubuntu:22.04 AS snort-builder
ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /snort_src

# Build parallelism. Local/native builds use all cores (fast). The multi-arch push
# overrides this to 1 (--build-arg MAKE_JOBS=1): emulated (QEMU) amd64 cross-compiles
# segfault cc1 under parallel make, so the published image is built single-threaded.
ARG MAKE_JOBS

# Snort 3 build prerequisites (from unit3_lab.sh)
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential autotools-dev libdumbnet-dev libluajit-5.1-dev libpcap-dev \
      zlib1g-dev pkg-config libhwloc-dev cmake liblzma-dev openssl libssl-dev cpputest \
      libsqlite3-dev libtool uuid-dev git autoconf bison flex libfl-dev libcmocka-dev \
      libnetfilter-queue-dev libunwind-dev libmnl-dev libdaq-dev google-perftools \
      libgoogle-perftools-dev wget ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Make all downloads resilient to transient network blips (SourceForge/colm.net are flaky).
RUN printf 'tries=3\ntimeout=30\nretry_connrefused=on\nwaitretry=5\n' > /etc/wgetrc

# safec — runtime bounds checks for some legacy C-lib calls
RUN wget -q https://github.com/rurban/safeclib/releases/download/v02092020/libsafec-02092020.tar.gz && \
    tar xzf libsafec-02092020.tar.gz && cd libsafec-02092020.0-g6d921f && \
    ./configure && make -j"${MAKE_JOBS:-$(nproc)}" && make install

# PCRE 8.45
RUN wget -q https://sourceforge.net/projects/pcre/files/pcre/8.45/pcre-8.45.tar.gz && \
    tar xzf pcre-8.45.tar.gz && cd pcre-8.45 && \
    ./configure && make -j"${MAKE_JOBS:-$(nproc)}" && make install

# gperftools 2.15
RUN wget -q https://github.com/gperftools/gperftools/releases/download/gperftools-2.15/gperftools-2.15.tar.gz && \
    tar xzf gperftools-2.15.tar.gz && cd gperftools-2.15 && \
    ./configure && make -j"${MAKE_JOBS:-$(nproc)}" && make install

# Ragel 6.10
RUN wget -q http://www.colm.net/files/ragel/ragel-6.10.tar.gz && \
    tar xzf ragel-6.10.tar.gz && cd ragel-6.10 && \
    ./configure && make -j"${MAKE_JOBS:-$(nproc)}" && make install

# NOTE: Hyperscan (and its Boost dependency) are intentionally OMITTED. Hyperscan is x86-only
# (needs SSSE3/AVX) and fails to configure on arm64; it is an OPTIONAL fast-pattern-matcher, not
# required by Snort 3. Dropping it lets this image build natively on both arm64 and amd64 and has
# no effect on rule-writing (Snort uses its default matcher). Confirmed 2026-07-23: the arm64
# build failed only at the Hyperscan cmake step. Re-add under `--platform=linux/amd64` only if
# production-fidelity pattern matching is ever needed.

# flatbuffers 23.5.26
RUN wget -q https://github.com/google/flatbuffers/archive/refs/tags/v23.5.26.tar.gz -O flatbuffers-23.5.26.tar.gz && \
    tar xzf flatbuffers-23.5.26.tar.gz && mkdir flatbuffers-build && cd flatbuffers-build && \
    cmake ../flatbuffers-23.5.26 && make -j"${MAKE_JOBS:-$(nproc)}" && make install

# libdaq 3.0.14 (Snort Data Acquisition library)
RUN wget -q https://www.snort.org/downloads/snortplus/libdaq-3.0.14.tar.gz && \
    tar xzf libdaq-3.0.14.tar.gz && cd libdaq-3.0.14 && \
    ./bootstrap && ./configure && make -j"${MAKE_JOBS:-$(nproc)}" && make install && ldconfig

# Snort 3.1.81.0
RUN wget -q https://github.com/snort3/snort3/archive/refs/tags/3.1.81.0.tar.gz -O snort3-3.1.81.0.tar.gz && \
    tar xzf snort3-3.1.81.0.tar.gz && cd snort3-3.1.81.0 && \
    ./configure_cmake.sh --prefix=/usr/local --enable-tcmalloc && \
    cd build && make -j"${MAKE_JOBS:-$(nproc)}" && make install

# ─────────────────────────── Stage 2: runtime ───────────────────────────
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# Runtime shared libraries for Snort 3, plus the project's tooling:
#   nodejs/npm + hftp  → the directory-traversal FTP target (project "Off Limits")
#   tcpreplay          → replay authored attack pcaps for the rule-writing practice
#   tcpdump            → read/inspect the Part 3 trace (server.pcapng) and any pcap
#   iputils-ping       → generate ICMP for the Part 1 first-rule walkthrough
RUN apt-get update && apt-get install -y --no-install-recommends \
      libpcap0.8 libluajit-5.1-2 libdumbnet1 zlib1g liblzma5 libhwloc15 libnuma1 libunwind8 \
      libmnl0 libnetfilter-queue1 libgoogle-perftools4 libssl3 uuid \
      tcpreplay tcpdump iputils-ping nodejs npm ca-certificates less nano vim-tiny && \
    rm -rf /var/lib/apt/lists/*

# Bring over everything the builder installed to /usr/local (snort, libdaq, hyperscan,
# flatbuffers, pcre, safec, gperftools, and the default snort config tree).
COPY --from=snort-builder /usr/local /usr/local
RUN ldconfig

# The directory-traversal target is a small server WE control (docker/files/vuln-server.js,
# copied to /opt/snort-lab/ below and started AS ROOT by the entrypoint). We deliberately do
# NOT use the old `hftp` npm package — it was an abandoned 0.0.x dependency with quirky `../`
# handling. `nodejs` (installed above) is all the server + attack.js need.

RUN useradd -m -s /bin/bash student

# Pre-configured Snort so students edit ONLY rules (authored in build phase — see docker/files/):
#   snort/snort.lua           — pre-tuned config (ips section pointed at local.rules)
#   snort/rules/local.rules   — starter rules file the student edits
#   pcaps/                     — authored attack traffic for Parts 1–2 (read with `snort -r`)
#   ftp_folder/                — the "Wishful Thinking Inc." tree + attack.sh/attack.js scaffold
#   project/server.pcapng      — the Part 3 trace
COPY docker/files/ /opt/snort-lab/

# Install the pre-tuned Snort config + starter rules at the canonical paths the
# instructions reference. snort.lua overwrites the stock template (its only change
# is the enabled `ips` section pointing at local.rules). local.rules is owned by
# `student` so it is the one file they edit.
RUN cp /opt/snort-lab/snort/snort.lua /usr/local/etc/snort/snort.lua && \
    mkdir -p /usr/local/etc/rules && \
    cp /opt/snort-lab/snort/rules/local.rules /usr/local/etc/rules/local.rules && \
    chown -R student:student /usr/local/etc/rules

# Place the student-facing assets in their home
RUN cp -r /opt/snort-lab/ftp_folder /home/student/ 2>/dev/null || true && \
    chown -R student:student /home/student

# Stash the confidential "real earnings" OUTSIDE the FTP root, readable ONLY by root.
# The student's own shell is denied it; the directory-traversal (via the root-run FTP
# service) is the only way to read it — that is the graded payoff for Part 3.
RUN mkdir -p /opt/wishful-thinking && \
    base64 -d < /opt/snort-lab/wishful-thinking_real_earnings.txt.gz.b64 | gunzip > /opt/wishful-thinking/real_earnings.txt && \
    chown root:root /opt/wishful-thinking/real_earnings.txt && \
    chmod 600 /opt/wishful-thinking/real_earnings.txt && \
    # The confidential earnings ship gzip+base64-encoded (docker/files/*.gz.b64) so the plaintext
    # answer is NOT visible in the public repo; it's decoded here at build time into a root-only file
    # OUTSIDE the FTP root. Remove the encoded source so the payoff is only reachable via the Part 3
    # traversal, and make the lab pcaps/assets student-readable (some source dirs were mode 700).
    rm -f /opt/snort-lab/wishful-thinking_real_earnings.txt.gz.b64 && \
    chmod -R a+rX /opt/snort-lab

COPY --chmod=755 docker/entrypoint.sh /usr/local/bin/entrypoint.sh
WORKDIR /home/student
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash"]
