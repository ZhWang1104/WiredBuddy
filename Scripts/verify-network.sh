#!/bin/zsh
set -euo pipefail

repository_dir=${0:A:h:h}
checks_dir=$(mktemp -d "${TMPDIR:-/tmp}/wiredbuddy-network-checks.XXXXXX")
architecture=$(uname -m)

swiftc \
  -parse-as-library \
  -target "${architecture}-apple-macosx13.0" \
  "$repository_dir/Wired Buddy/Network/NetMon.swift" \
  "$repository_dir/Tests/NetworkMonitorChecks.swift" \
  -o "$checks_dir/network-monitor-checks"

"$checks_dir/network-monitor-checks"
