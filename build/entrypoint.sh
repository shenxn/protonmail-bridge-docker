#!/bin/bash

set -euo pipefail

PTY_TOOL="${PTY_TOOL:-dtach}"
BRIDGE_SOCK=/protonmail/bridge.sock
BRIDGE_PID_FILE=/protonmail/bridge.pid

# Validate PTY_TOOL early and ensure the selected binary is present.
case "${PTY_TOOL}" in
    dtach|abduco|reptyr)
        if ! command -v "${PTY_TOOL}" &>/dev/null; then
            echo "ERROR: PTY_TOOL=${PTY_TOOL} but '${PTY_TOOL}' was not found in PATH." >&2
            exit 1
        fi
        ;;
    *)
        echo "ERROR: PTY_TOOL=${PTY_TOOL} is not supported. Valid values: dtach, abduco, reptyr." >&2
        exit 1
        ;;
esac

# Clean stale gpg-agent sockets left from a previous run
rm -f /root/.gnupg/S.gpg-agent* 2>/dev/null || true

# --- PTY helpers (only used by: init, manage, attach) ---

pty_start() {
    case "${PTY_TOOL}" in
        dtach)  dtach -n "${BRIDGE_SOCK}" "$@" ;;
        abduco) abduco -n bridge "$@" ;;
        # reptyr re-attaches existing PIDs; use nohup+setsid to launch headlessly instead
        reptyr) setsid "$@" </dev/null &>/dev/null & echo $! > "${BRIDGE_PID_FILE}" ;;
        *)      echo "ERROR: pty_start: unsupported PTY_TOOL=${PTY_TOOL}" >&2; exit 1 ;;
    esac
}

pty_attach() {
    case "${PTY_TOOL}" in
        dtach)  exec dtach -a "${BRIDGE_SOCK}" -e '^\' ;;
        abduco) exec abduco -a bridge ;;
        reptyr) exec reptyr "$(cat "${BRIDGE_PID_FILE}")" ;;
        *)      echo "ERROR: pty_attach: unsupported PTY_TOOL=${PTY_TOOL}" >&2; exit 1 ;;
    esac
}

detach_hint() {
    case "${PTY_TOOL}" in
        dtach|abduco) echo "Ctrl+\\" ;;
        reptyr)       echo "Ctrl+C" ;;
        *)            echo "(unknown)" ;;
    esac
}

# True if the abduco session named 'bridge' is listed as running.
abduco_session_alive() {
    abduco -l 2>/dev/null | grep -qw 'bridge'
}

# Wait up to $1 seconds for the bridge session (socket or PID file) to appear.
wait_for_session() {
    local timeout="${1:-10}"
    local elapsed=0
    while [[ "${elapsed}" -lt "${timeout}" ]]; do
        case "${PTY_TOOL}" in
            dtach)  [[ -S "${BRIDGE_SOCK}" ]]  && return 0 ;;
            abduco) abduco_session_alive        && return 0 ;;
            reptyr) [[ -f "${BRIDGE_PID_FILE}" ]] && return 0 ;;
            *)      echo "ERROR: wait_for_session: unsupported PTY_TOOL=${PTY_TOOL}" >&2; exit 1 ;;
        esac
        sleep 1
        (( elapsed++ )) || true
    done
    echo "ERROR: bridge session did not start within ${timeout}s." >&2
    return 1
}

# --- Commands ---

CMD="${1:-run}"

case "${CMD}" in

    init)
        # One-time setup: generate GPG key, init password store, interactive login.
        # Run as: docker run -it <image> init
        gpg --generate-key --batch /protonmail/gpgparams
        pass init pass-key
        exec /protonmail/proton-bridge --cli
        ;;

    manage)
        # Open an interactive --cli session for account management (add/remove accounts etc).
        # Run as: docker run -it --rm -v <data-volume> <image> manage
        # NOTE: Stop the running daemon container first to avoid port/lock conflicts.
        CONTAINER_ID=$(hostname)
        echo "  Starting management session... [PTY_TOOL=${PTY_TOOL}]"
        pty_start /protonmail/proton-bridge --cli

        # Wait for the session socket/pid to appear before printing attach instructions
        wait_for_session 10

        echo "  Management session ready."
        echo "  Attach:  docker exec -it ${CONTAINER_ID} /protonmail/entrypoint.sh attach"
        echo "  Detach:  $(detach_hint)"

        # Block so the container stays alive for `docker exec attach`.
        # If stdin is a tty (docker run -it), jump straight into the session.
        if [[ -t 0 ]]; then
            pty_attach
        else
            # No tty: wait until the bridge session disappears then exit cleanly.
            while true; do
                case "${PTY_TOOL}" in
                    dtach)  [[ -S "${BRIDGE_SOCK}" ]] || break ;;
                    abduco) abduco_session_alive       || break ;;
                    reptyr) kill -0 "$(cat "${BRIDGE_PID_FILE}" 2>/dev/null)" 2>/dev/null || break ;;
                    *)      echo "ERROR: manage loop: unsupported PTY_TOOL=${PTY_TOOL}" >&2; exit 1 ;;
                esac
                sleep 2
            done
        fi
        ;;

    attach)
        # Reattach to a running manage session.
        case "${PTY_TOOL}" in
            dtach)
                if [[ ! -S "${BRIDGE_SOCK}" ]]; then
                    echo "ERROR: No active dtach session found (${BRIDGE_SOCK} does not exist)." >&2
                    echo "       Start one first: docker exec -it <container> /protonmail/entrypoint.sh manage" >&2
                    exit 1
                fi
                ;;
            abduco)
                if ! abduco_session_alive; then
                    echo "ERROR: No active abduco session 'bridge' found." >&2
                    echo "       Start one first: docker exec -it <container> /protonmail/entrypoint.sh manage" >&2
                    exit 1
                fi
                ;;
            reptyr)
                if [[ ! -f "${BRIDGE_PID_FILE}" ]]; then
                    echo "ERROR: No active session found (${BRIDGE_PID_FILE} does not exist)." >&2
                    echo "       Start one first: docker exec -it <container> /protonmail/entrypoint.sh manage" >&2
                    exit 1
                fi
                ;;
            *)
                echo "ERROR: attach: unsupported PTY_TOOL=${PTY_TOOL}" >&2
                exit 1
                ;;
        esac
        pty_attach
        ;;

    run)
        # Daemon mode: --noninteractive runs headless, output goes directly to docker logs.
        CONTAINER_ID=$(hostname)

        # Cleanup handler: forward SIGTERM/SIGINT and reap child processes cleanly.
        # As PID 1, without this Docker's SIGTERM would leave children running until
        # the kill timeout expires.
        BRIDGE_PID=
        SOCAT_SMTP_PID=
        SOCAT_IMAP_PID=
        _cleanup_done=0
        cleanup() {
            [[ "${_cleanup_done}" -eq 1 ]] && return
            _cleanup_done=1
            echo "  Shutting down bridge and port-forwards..." >&2
            [[ -n "${BRIDGE_PID:-}" ]]     && kill "${BRIDGE_PID}"     2>/dev/null || true
            [[ -n "${SOCAT_SMTP_PID:-}" ]] && kill "${SOCAT_SMTP_PID}" 2>/dev/null || true
            [[ -n "${SOCAT_IMAP_PID:-}" ]] && kill "${SOCAT_IMAP_PID}" 2>/dev/null || true
            wait 2>/dev/null || true
        }
        trap cleanup EXIT SIGTERM SIGINT

        echo "========================================"
        echo "  ProtonMail Bridge daemon starting..."
        echo "  Container: ${CONTAINER_ID}"
        echo ""
        echo "  Available commands:"
        echo "    First-time setup:"
        echo "      docker run -it <image> init"
        echo ""
        echo "    Manage accounts (stop daemon first):"
        echo "      docker run -it --rm -v <data-volume> <image> manage"
        echo ""
        echo "    Attach to a running manage session:"
        echo "      docker exec -it <container> /protonmail/entrypoint.sh attach"
        echo ""
        echo "    View logs:"
        echo "      docker logs -f ${CONTAINER_ID}"
        echo "========================================"

        # Start bridge in background so we can wait for it to bind its ports
        # before socat begins accepting connections.
        /protonmail/proton-bridge --noninteractive &
        BRIDGE_PID=$!

        # Wait for bridge to open its local SMTP and IMAP ports (up to 60s).
        # Abort immediately if the bridge process exits before the port is ready.
        echo "  Waiting for bridge ports 1025/1143..."
        for port in 1025 1143; do
            elapsed=0
            until socat -u OPEN:/dev/null TCP:127.0.0.1:${port} 2>/dev/null; do
                if ! kill -0 "${BRIDGE_PID}" 2>/dev/null; then
                    echo "ERROR: bridge process (pid ${BRIDGE_PID}) exited before port ${port} became ready." >&2
                    exit 1
                fi
                sleep 1
                (( elapsed++ )) || true
                if [[ "${elapsed}" -ge 60 ]]; then
                    echo "ERROR: bridge port ${port} did not open within 60s." >&2
                    exit 1
                fi
            done
            echo "  Port ${port} ready."
        done

        # socat forwards standard ports to bridge's localhost-only listener ports.
        # retry=30,interval=2 handles transient bridge restarts without dropping connections.
        socat TCP-LISTEN:25,fork,reuseaddr  TCP:127.0.0.1:1025,nodelay,retry=30,interval=2 &
        SOCAT_SMTP_PID=$!
        socat TCP-LISTEN:143,fork,reuseaddr TCP:127.0.0.1:1143,nodelay,retry=30,interval=2 &
        SOCAT_IMAP_PID=$!

        # Verify both socat processes started
        sleep 1
        for pid in "${SOCAT_SMTP_PID}" "${SOCAT_IMAP_PID}"; do
            if ! kill -0 "${pid}" 2>/dev/null; then
                echo "ERROR: socat port-forward (pid ${pid}) failed to start." >&2
                exit 1
            fi
        done

        # Wait on bridge; EXIT trap will bring down socat when bridge exits.
        wait "${BRIDGE_PID}"
        ;;

    *)
        echo "Usage: entrypoint.sh [init|manage|attach|run]" >&2
        exit 1
        ;;

esac
