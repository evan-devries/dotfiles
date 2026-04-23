#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# zsh profile — pull ~/.zshrc back to repo
zsh_dst="$repo_root/macos/zshrc"
if [ -f "$HOME/.zshrc" ]; then
  cp "$HOME/.zshrc" "$zsh_dst"
  echo "Pulled: $zsh_dst"
fi

# Ghostty config — pull back
ghostty_src="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
ghostty_dst="$repo_root/macos/ghostty-config"
if [ -f "$ghostty_src" ]; then
  cp "$ghostty_src" "$ghostty_dst"
  echo "Pulled: $ghostty_dst"
fi

# VS Code settings — split shared vs private, mirroring install.sh merge
vscode_src="$HOME/Library/Application Support/Code/User/settings.json"
vscode_shared="$repo_root/vscode/settings.json"
vscode_local="$repo_root/vscode/settings.local.json"
# Private keys are any settings whose name matches one of these prefixes.
private_prefixes=("remote.SSH." "python.defaultInterpreterPath" "protobuf.")

if [ -f "$vscode_src" ]; then
  python3 - "$vscode_src" "$vscode_shared" "$vscode_local" "${private_prefixes[@]}" <<'PY'
import json, sys, os
src, shared_path, local_path, *prefixes = sys.argv[1:]
with open(src, encoding="utf-8-sig") as f:
    raw = json.load(f)
shared, private = {}, {}
for k, v in raw.items():
    if any(k.startswith(p) for p in prefixes):
        private[k] = v
    else:
        shared[k] = v
with open(shared_path, "w") as f:
    json.dump(shared, f, indent=4)
print(f"Pulled: {shared_path} ({len(shared)} public keys)")
if private:
    with open(local_path, "w") as f:
        json.dump(private, f, indent=4)
    print(f"Local:  {local_path} ({len(private)} private keys, gitignored)")
elif os.path.exists(local_path):
    os.remove(local_path)
PY
fi
