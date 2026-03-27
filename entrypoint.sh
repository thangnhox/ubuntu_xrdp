#!/bin/bash

# --- 0. PRESERVE ENVIRONMENT VARIABLES ---
# XRDP strips environment variables when creating a new desktop session.
# We dump the initial udocker environment here so X11 can load it later.
export -p > /root/.container_env
chmod 600 /root/.container_env

# --- 1. SET SUBREAPER ---
# Use Python to hit the prctl(PR_SET_CHILD_SUBREAPER, 1) syscall.
# This tells the kernel: "I am the new parent for any orphans in this tree."
python3 -c 'import ctypes; libc = ctypes.CDLL("libc.so.6"); libc.prctl(24, 1, 0, 0, 0)'

# --- 2. CLEANUP ---
# Remove stale PID files that prevent XRDP from starting after a crash.
rm -f /var/run/xrdp/xrdp.pid /var/run/xrdp/xrdp-sesman.pid
mkdir -p /var/run/xrdp

# --- 3. SIGNAL HANDLING ---
# Define a cleanup function to gracefully shut down background processes
cleanup() {
    echo "Received termination signal. Shutting down XRDP processes..."

    # Send SIGTERM to the background processes if their PIDs were captured
    if [ -n "$SESMAN_PID" ]; then
        kill $SESMAN_PID 2>/dev/null
    fi

    if [ -n "$XRDP_PID" ]; then
        kill $XRDP_PID 2>/dev/null
    fi

    echo "Cleanup complete. Exiting."
    exit 0
}

# Trap SIGTERM (default signal from `docker stop`) and SIGINT (Ctrl+C)
trap cleanup SIGTERM SIGINT

# --- 4. LAUNCH PROCESSES ---
# Start the Session Manager in the background and capture its exact PID.
/usr/sbin/xrdp-sesman --nodaemon > /var/log/xrdp-sesman.log 2>&1 &
SESMAN_PID=$!

# Start the XRDP Server in the background and capture its exact PID.
/usr/sbin/xrdp --nodaemon > /var/log/xrdp.log 2>&1 &
XRDP_PID=$!

echo "XRDP Server is running with Subreaper enabled..."
echo "Login with user: root | password: password123"
echo "Monitoring PIDs - Sesman: $SESMAN_PID | XRDP: $XRDP_PID"

# --- 5. REAP ORPHANS & KEEP CONTAINER ALIVE ---
# 'wait' pauses the script here. If the script receives a SIGTERM from Docker,
# the `trap` interrupts this wait, runs the `cleanup` function, and exits cleanly.
wait
