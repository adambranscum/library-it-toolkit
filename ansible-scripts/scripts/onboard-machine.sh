#!/usr/bin/env bash
# Interactive helper: add a new Windows machine to the inventory,
# test the connection, and optionally run the onboarding playbook.
# Run from the repo root:  ./scripts/onboard-machine.sh
set -euo pipefail

INV="inventories/production/hosts.ini"
DOMAIN_SUFFIX="${DOMAIN_SUFFIX:-example.local}"

if [[ ! -f "$INV" ]]; then
  echo "Run this from the repo root (inventory not found: $INV)" >&2
  exit 1
fi

read -rp "Machine name (short name, e.g. a-pub-03): " NAME
NAME="${NAME,,}"
if [[ ! "$NAME" =~ ^[a-z0-9-]+$ ]]; then
  echo "Use letters, numbers, and dashes only." >&2
  exit 1
fi
FQDN="${NAME}.${DOMAIN_SUFFIX}"

if grep -qiE "^${FQDN}\s*$" "$INV"; then
  echo "$FQDN is already in the inventory." >&2
  exit 1
fi

# Offer every plain [group] (skips [x:children] and [x:vars])
mapfile -t GROUPS_LIST < <(grep -E '^\[[A-Za-z0-9_]+\]$' "$INV" | tr -d '[]')
echo "Which group does it belong to?"
select GROUP in "${GROUPS_LIST[@]}"; do
  [[ -n "${GROUP:-}" ]] && break
done

echo
echo "Add $FQDN to [$GROUP]?"
read -rp "Type yes to continue: " OK
[[ "$OK" == "yes" ]] || { echo "Cancelled."; exit 0; }

cp "$INV" "$INV.bak"
awk -v grp="[$GROUP]" -v host="$FQDN" \
  '{ print } $0 == grp && !done { print host; done = 1 }' "$INV.bak" > "$INV"
echo "Added. Backup saved as $INV.bak"

echo
echo "Testing connection..."
if ansible "$FQDN" -m ansible.windows.win_ping; then
  echo "Connection OK."
else
  echo "Connection failed. Check DNS, the WinRM GPO, and that the machine is on." >&2
  exit 1
fi

echo
read -rp "Run the onboarding playbook now? (yes/no): " RUN
if [[ "$RUN" == "yes" ]]; then
  ansible-playbook playbooks/onboard-new-machine.yml -e "target=$FQDN"
fi
