#!/usr/bin/env bash
# uninstall-nix.sh — Remove Determinate Nix 3.x from macOS when the
# official uninstaller fails (e.g. /nix volume unmounted, receipt.json missing).
#
# Safe to re-run: every step is guarded and idempotent.
#
# Requires: sudo (will prompt for password), macOS with APFS.
#
# Usage:
#   ./uninstall-nix.sh          # interactive — asks for confirmation
#   ./uninstall-nix.sh --yes    # non-interactive (use only if you know what you're doing)

set -u
trap 'echo; echo "[ERROR] line $LINENO — see output above"; exit 1' ERR

# ---------------------------------------------------------------------------
# Colors
# ---------------------------------------------------------------------------
if [[ -t 1 ]]; then
  B='\033[1m'; G='\033[32m'; Y='\033[33m'; R='\033[31m'; C='\033[36m'; N='\033[0m'
else
  B=''; G=''; Y=''; R=''; C=''; N=''
fi

step()  { echo -e "\n${B}${C}▸ $*${N}"; }
ok()    { echo -e "  ${G}✓${N} $*"; }
warn()  { echo -e "  ${Y}!${N} $*"; }
skip()  { echo -e "  ${Y}·${N} $* (skipped — not present)"; }
fail()  { echo -e "  ${R}✗${N} $*"; }

# ---------------------------------------------------------------------------
# Pre-flight
# ---------------------------------------------------------------------------
if [[ "${1:-}" != "--yes" ]]; then
  cat <<EOF
${B}${R}This will PERMANENTLY remove Determinate Nix from this Mac.${N}

What will be done:
  1. Stop and remove Determinate launch daemons
  2. Delete the "Nix Store" APFS volume (disk3s7) — 6.3 GB of nix store data
  3. Remove /etc/fstab entry for /nix
  4. Restore /etc/zshrc and /etc/bashrc from .backup-before-nix
  5. Remove /etc/nix/
  6. Remove /usr/local/bin/determinate-nixd
  7. Delete users _nixbld1..32 and group nixbld
  8. Remove /var/log/determinate-nix-daemon.log*
  9. Remove Keychain entry for "Nix Store" encrypted volume password
 10. Remove 'nix' entry from /etc/synthetic.conf (REBOOT required to unmount /nix)

You have a config backup at ~/.config-backup-*/ from the earlier step.

EOF
  read -r -p "Type 'yes' to proceed: " confirm
  [[ "$confirm" == "yes" ]] || { echo "Aborted."; exit 1; }
fi

step "Authenticating (sudo)"
sudo -v || { fail "sudo failed"; exit 1; }
# Keep sudo alive while the script runs
( while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done ) 2>/dev/null &
SUDO_KEEPALIVE_PID=$!
trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT

# ---------------------------------------------------------------------------
# 1. Bootout launch daemons
# ---------------------------------------------------------------------------
step "Stopping Determinate launch daemons"
for label in \
  systems.determinate.nix-daemon \
  systems.determinate.nix-store \
  systems.determinate.nix-installer.nix-hook
do
  if sudo launchctl print "system/$label" &>/dev/null; then
    if sudo launchctl bootout "system/$label" 2>/dev/null; then
      ok "bootout $label"
    else
      warn "bootout $label returned non-zero (may already be stopped)"
    fi
  else
    skip "$label"
  fi
done

# ---------------------------------------------------------------------------
# 2. Remove plist files
# ---------------------------------------------------------------------------
step "Removing launch daemon plists"
for plist in \
  /Library/LaunchDaemons/systems.determinate.nix-daemon.plist \
  /Library/LaunchDaemons/systems.determinate.nix-store.plist \
  /Library/LaunchDaemons/systems.determinate.nix-installer.nix-hook.plist
do
  if [[ -f "$plist" ]]; then
    sudo rm -f "$plist" && ok "removed $plist"
  else
    skip "$plist"
  fi
done

# ---------------------------------------------------------------------------
# 3. Delete APFS volume "Nix Store"
# ---------------------------------------------------------------------------
step "Deleting APFS volume 'Nix Store'"
# `diskutil list` output has the disk identifier as the last column on the
# volume's row, e.g. "  7:  APFS Volume  Nix Store  6.3 GB  disk3s7".
# We match the volume name and grab $NF on that same line — robust across
# container indices and macOS versions.
NIX_DISK=$(diskutil list 2>/dev/null | awk '
  /APFS Volume[[:space:]]+Nix Store/ { print $NF; exit }
')

if [[ -n "$NIX_DISK" ]]; then
  # Ensure unmounted first (ignore error if already unmounted)
  sudo diskutil unmount force "/dev/$NIX_DISK" 2>/dev/null || true
  if sudo diskutil apfs deleteVolume "$NIX_DISK"; then
    ok "APFS volume $NIX_DISK deleted"
  else
    fail "deleteVolume on $NIX_DISK failed — you may need to delete it manually via Disk Utility (right-click → Delete APFS Volume)"
  fi
else
  skip "APFS volume 'Nix Store' not found"
fi

# ---------------------------------------------------------------------------
# 4. Remove /etc/fstab entry
# ---------------------------------------------------------------------------
step "Removing /etc/fstab entry for /nix"
if grep -q "Added by the Determinate Nix Installer" /etc/fstab 2>/dev/null; then
  sudo cp /etc/fstab "/etc/fstab.bak.$(date +%s)"
  sudo sed -i '' '/Added by the Determinate Nix Installer/d' /etc/fstab
  ok "removed fstab line (backup saved as /etc/fstab.bak.*)"
else
  skip "no fstab entry for Determinate Nix"
fi

# ---------------------------------------------------------------------------
# 5. Restore shell backups
# ---------------------------------------------------------------------------
step "Restoring /etc/zshrc and /etc/bashrc from .backup-before-nix"
for f in zshrc bashrc; do
  backup="/etc/$f.backup-before-nix"
  target="/etc/$f"
  if [[ -f "$backup" ]]; then
    sudo chmod 644 "$backup"
    sudo mv "$backup" "$target"
    ok "restored $target"
  else
    skip "$backup"
  fi
done

# ---------------------------------------------------------------------------
# 6. Remove /etc/nix
# ---------------------------------------------------------------------------
step "Removing /etc/nix"
if [[ -d /etc/nix ]]; then
  sudo rm -rf /etc/nix && ok "removed /etc/nix"
else
  skip "/etc/nix"
fi

# ---------------------------------------------------------------------------
# 7. Remove determinate-nixd binary
# ---------------------------------------------------------------------------
step "Removing /usr/local/bin/determinate-nixd"
if [[ -f /usr/local/bin/determinate-nixd ]]; then
  sudo rm -f /usr/local/bin/determinate-nixd && ok "removed determinate-nixd"
else
  skip "determinate-nixd"
fi

# ---------------------------------------------------------------------------
# 8. Delete _nixbld users and nixbld group
# ---------------------------------------------------------------------------
step "Deleting _nixbld1..32 users"
removed_users=0
for i in $(seq 1 32); do
  user="_nixbld$i"
  if dscl . -read "/Users/$user" &>/dev/null; then
    sudo dscl . -delete "/Users/$user" 2>/dev/null && removed_users=$((removed_users + 1)) || warn "failed to delete $user"
  fi
done
if [[ "$removed_users" -gt 0 ]]; then
  ok "deleted $removed_users _nixbld users"
else
  skip "no _nixbld users present"
fi

step "Deleting group nixbld"
if dscl . -read /Groups/nixbld &>/dev/null; then
  sudo dscl . -delete /Groups/nixbld && ok "removed group nixbld"
else
  skip "group nixbld"
fi

# ---------------------------------------------------------------------------
# 9. Remove logs
# ---------------------------------------------------------------------------
step "Removing determinate-nix-daemon logs"
if compgen -G "/var/log/determinate-nix-daemon.log*" >/dev/null; then
  sudo rm -f /var/log/determinate-nix-daemon.log* && ok "removed logs"
else
  skip "no logs present"
fi

# ---------------------------------------------------------------------------
# 10. Remove Keychain entry for Nix Store volume password
# ---------------------------------------------------------------------------
step "Removing Keychain entry for 'Nix Store' volume password"
# APFS volume passwords live in the System keychain — run as root
if sudo security find-generic-password -l "Nix Store" &>/dev/null; then
  sudo security delete-generic-password -l "Nix Store" &>/dev/null && ok "deleted Keychain entry 'Nix Store'" || warn "could not delete Keychain entry — open Keychain Access and remove 'Nix Store' manually"
else
  skip "Keychain entry 'Nix Store' not found"
fi

# ---------------------------------------------------------------------------
# 11. Remove /nix synthetic entry (requires reboot to take effect)
# ---------------------------------------------------------------------------
# On macOS Catalina+ the root volume is sealed read-only, so `/nix` is a
# *synthetic* directory declared in /etc/synthetic.conf — you can't `rm` it,
# you remove the declaration and reboot.
step "Removing 'nix' entry from /etc/synthetic.conf"
NEEDS_REBOOT=0
if [[ -f /etc/synthetic.conf ]] && sudo grep -Eq '^nix([[:space:]]|$)' /etc/synthetic.conf; then
  sudo cp /etc/synthetic.conf "/etc/synthetic.conf.bak.$(date +%s)"
  sudo sed -i '' '/^nix[[:space:]]*$/d; /^nix$/d' /etc/synthetic.conf
  ok "removed 'nix' line (backup saved as /etc/synthetic.conf.bak.*)"
  NEEDS_REBOOT=1
else
  skip "no 'nix' entry in /etc/synthetic.conf"
fi

# ---------------------------------------------------------------------------
# Verification
# ---------------------------------------------------------------------------
step "Post-uninstall verification"

check() {
  local label="$1" ; shift
  if "$@" &>/dev/null; then
    fail "$label — still present"
    return 1
  else
    ok "$label — gone"
    return 0
  fi
}

fail_count=0

check "determinate-nixd binary"   test -f /usr/local/bin/determinate-nixd     || fail_count=$((fail_count+1))
check "/etc/nix"                  test -d /etc/nix                             || fail_count=$((fail_count+1))
check "fstab entry"               grep -q "Determinate Nix Installer" /etc/fstab || fail_count=$((fail_count+1))
check "_nixbld1 user"             dscl . -read /Users/_nixbld1                 || fail_count=$((fail_count+1))
check "nixbld group"              dscl . -read /Groups/nixbld                  || fail_count=$((fail_count+1))
check "nix-daemon launch daemon"  sudo launchctl print system/systems.determinate.nix-daemon || fail_count=$((fail_count+1))

echo
if [[ "$fail_count" -eq 0 ]]; then
  echo -e "${B}${G}✓ Determinate Nix fully removed.${N}"
  if [[ "$NEEDS_REBOOT" -eq 1 ]]; then
    echo -e "${B}${Y}⚠ Reboot required${N} — /nix is a synthetic dir, it disappears at next boot."
    echo -e "${B}Next:${N}"
    echo "    sudo reboot"
    echo "    # After reboot:"
    echo "    cd /Users/horacio/Projects/Tools/Horacio.Dots && ./install.sh"
  else
    echo -e "${B}Next:${N} open a NEW terminal (so restored /etc/zshrc and /etc/bashrc take effect), then run:"
    echo "    cd /Users/horacio/Projects/Tools/Horacio.Dots && ./install.sh"
  fi
else
  echo -e "${B}${Y}Uninstall completed with $fail_count residual(s) — review the ✗ lines above.${N}"
  exit 2
fi
