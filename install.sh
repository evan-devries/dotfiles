#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
backup_dir="$repo_root/.backup/$(date +%Y%m%d-%H%M%S)"
backup_used=0

backup_and_write() {
  local dst="$1" content="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -f "$dst" ]; then
    mkdir -p "$backup_dir"
    cp "$dst" "$backup_dir/$(basename "$dst")"
    backup_used=1
  fi
  printf '%s\n' "$content" > "$dst"
  echo "Installed: $dst"
}

# zsh profile
zsh_src="$repo_root/macos/zshrc"
if [ -f "$zsh_src" ]; then
  backup_and_write "$HOME/.zshrc" "$(cat "$zsh_src")"
fi

# Ghostty config
ghostty_src="$repo_root/macos/ghostty-config"
ghostty_dst="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
if [ -f "$ghostty_src" ]; then
  backup_and_write "$ghostty_dst" "$(cat "$ghostty_src")"
fi

# VS Code settings (merge shared + local overlay)
vscode_shared="$repo_root/vscode/settings.json"
vscode_local="$repo_root/vscode/settings.local.json"
vscode_dst="$HOME/Library/Application Support/Code/User/settings.json"
if [ -f "$vscode_shared" ]; then
  merged="$(python3 - "$vscode_shared" "$vscode_local" <<'PY'
import json, sys, os
shared_path, local_path = sys.argv[1], sys.argv[2]
with open(shared_path, encoding="utf-8-sig") as f:
    merged = json.load(f)
if os.path.exists(local_path):
    with open(local_path, encoding="utf-8-sig") as f:
        merged.update(json.load(f))
    print("Merged VS Code private keys from local overlay", file=sys.stderr)
print(json.dumps(merged, indent=4))
PY
)"
  backup_and_write "$vscode_dst" "$merged"
fi

# Claude Code statusline script
claude_script_src="$repo_root/claude/statusline.sh"
claude_script_dst="$HOME/.claude/statusline.sh"
if [ -f "$claude_script_src" ]; then
  backup_and_write "$claude_script_dst" "$(cat "$claude_script_src")"
  chmod +x "$claude_script_dst"
fi

# Claude Code settings — merge managed keys (statusLine, tui) into existing file
claude_settings_src="$repo_root/claude/settings.json"
claude_settings_dst="$HOME/.claude/settings.json"
if [ -f "$claude_settings_src" ]; then
  merged="$(python3 - "$claude_settings_src" "$claude_settings_dst" <<'PY'
import json, sys, os
src, dst = sys.argv[1], sys.argv[2]
with open(src, encoding="utf-8-sig") as f:
    managed = json.load(f)
existing = {}
if os.path.exists(dst):
    with open(dst, encoding="utf-8-sig") as f:
        existing = json.load(f)
existing.update(managed)
print(json.dumps(existing, indent=2))
PY
)"
  backup_and_write "$claude_settings_dst" "$merged"
fi

if [ "$backup_used" -eq 1 ]; then
  echo ""
  echo "Previous files backed up to: $backup_dir"
fi
