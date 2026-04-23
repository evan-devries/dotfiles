#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
COST=$(echo "$input" | jq -r '.cost.total_cost_usd')
ADDED=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
REMOVED=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')

# Git info
BRANCH=$(cd "$DIR" 2>/dev/null && git branch --show-current 2>/dev/null)
if [ -n "$BRANCH" ]; then
  DIRTY=$(cd "$DIR" && git diff --quiet 2>/dev/null && git diff --cached --quiet 2>/dev/null || echo "*")
  GIT=" \033[33m${BRANCH}${DIRTY}\033[0m |"
else
  GIT=""
fi

# Short dir (last 2 components)
SHORT_DIR=$(echo "$DIR" | awk -F/ '{if(NF>2) print $(NF-1)"/"$NF; else print $0}')

echo -e "\033[36m${MODEL}\033[0m |${GIT} \033[34m${SHORT_DIR}\033[0m | ctx ${PCT}% | \$${COST} | +${ADDED}/-${REMOVED}"
