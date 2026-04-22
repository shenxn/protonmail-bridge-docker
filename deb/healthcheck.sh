#!/bin/bash
set -euo pipefail

# Proton Bridge healthcheck — probes all 4 ports in parallel.
# Exit 0 = healthy, 1 = unhealthy (Docker HEALTHCHECK contract).

TIMEOUT=5  # seconds per probe

check_smtp() {
    local port=$1
    echo 'QUIT' | socat -T${TIMEOUT} - TCP4:localhost:${port} 2>/dev/null \
        | grep -q '^220'
}

check_imap() {
    local port=$1
    printf 'A1 LOGOUT\r\n' | socat -T${TIMEOUT} - TCP4:localhost:${port} 2>/dev/null \
        | grep -q '^\* OK'
}

# Fire all probes in parallel, capture PIDs
check_smtp  25  & PID_SMTP_25=$!
check_imap 143  & PID_IMAP_143=$!
check_smtp 1025 & PID_SMTP_1025=$!
check_imap 1143 & PID_IMAP_1143=$!

# Collect results — || prevents set -e from exiting early on probe failure
FAIL=0
wait $PID_SMTP_25   || { echo "FAIL smtp:25";   FAIL=1; }
wait $PID_IMAP_143  || { echo "FAIL imap:143";  FAIL=1; }
wait $PID_SMTP_1025 || { echo "FAIL smtp:1025"; FAIL=1; }
wait $PID_IMAP_1143 || { echo "FAIL imap:1143"; FAIL=1; }

if [[ $FAIL -eq 0 ]]; then
    echo "OK smtp:25 imap:143 smtp:1025 imap:1143"
fi

exit $FAIL
