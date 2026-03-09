#!/bin/bash
# Claude Code custom status line
# Reads JSON from stdin (Claude Code hook data) + ccusage for token breakdown
#
# Requires: ccusage (npm install -g ccusage), jq

input=$(cat)

# --- Helpers ---
fmt_k() {
  local n=$1
  if (( n >= 1000 )); then
    local result
    result=$(awk "BEGIN { printf \"%.1f\", $n / 1000 }")
    printf "%sk" "$result"
  else
    printf "%d" "$n"
  fi
}

# --- ANSI colors (approximate the HTML theme) ---
GRAY='\033[90m'
PINK='\033[35m'
GREEN='\033[92m'
YELLOW='\033[93m'
BLUE='\033[94m'
PURPLE='\033[95m'
BOLD='\033[1m'
RESET='\033[0m'

# --- Context window data (from Claude Code stdin JSON) ---
ctx_used=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
ctx_limit=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
ctx_percent=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
model=$(echo "$input" | jq -r '.model.display_name // "unknown"')
session_id=$(echo "$input" | jq -r '.session_id // "unknown"')

# --- Token data from ccusage (cached to avoid slowdown) ---
cache_file="/tmp/claude-sl-tokens-${session_id}.json"
now=$(date +%s)
cache_mtime=$(stat -c %Y "$cache_file" 2>/dev/null || echo 0)
cache_age=$(( now - cache_mtime ))

if [[ $cache_age -gt 30 ]] || [[ ! -f "$cache_file" ]]; then
  ccusage session --json --since "$(date +%Y%m%d)" 2>/dev/null > "${cache_file}.tmp" && \
    mv "${cache_file}.tmp" "$cache_file"
fi

in_tokens=0; out_tokens=0; cached_tokens=0; total_tokens=0
if [[ -f "$cache_file" ]]; then
  in_tokens=$(jq '[.sessions[].inputTokens] | add // 0' "$cache_file" 2>/dev/null || echo 0)
  out_tokens=$(jq '[.sessions[].outputTokens] | add // 0' "$cache_file" 2>/dev/null || echo 0)
  cached_tokens=$(jq '[.sessions[].cacheReadTokens] | add // 0' "$cache_file" 2>/dev/null || echo 0)
  total_tokens=$(jq '[.sessions[].totalTokens] | add // 0' "$cache_file" 2>/dev/null || echo 0)
fi

# --- Session duration ---
session_start_file="/tmp/claude-session-start-${session_id}"
if [[ ! -f "$session_start_file" ]]; then
  echo "$now" > "$session_start_file"
fi
start=$(cat "$session_start_file")
elapsed=$(( now - start ))
hours=$(( elapsed / 3600 ))
mins=$(( (elapsed % 3600) / 60 ))
if (( hours > 0 )); then
  duration="${hours}hr ${mins}m"
else
  duration="${mins}m"
fi

# --- Model display name ---
case "$model" in
  *opus*4*6*|*opus-4-6*) model_display="Opus 4.6" ;;
  *sonnet*4*6*|*sonnet-4-6*) model_display="Sonnet 4.6" ;;
  *haiku*4*5*|*haiku-4-5*) model_display="Haiku 4.5" ;;
  *opus*) model_display="Opus" ;;
  *sonnet*) model_display="Sonnet" ;;
  *haiku*) model_display="Haiku" ;;
  *) model_display="$model" ;;
esac

# --- Format context percent without trailing zeros ---
ctx_pct_fmt=$(awk "BEGIN { printf \"%.1f\", $ctx_percent }")

# --- Output ---
printf "${GRAY}In:${RESET} %s | ${PINK}Out: %s${RESET} | ${GREEN}Cached: %s${RESET} | ${YELLOW}Total: %s${RESET} | ${BLUE}Ctx: %s${RESET} | ${PURPLE}Ctx: %s%%${RESET}\n" \
  "$(fmt_k "$in_tokens")" "$(fmt_k "$out_tokens")" "$(fmt_k "$cached_tokens")" "$(fmt_k "$total_tokens")" \
  "$(fmt_k "$ctx_used")" "$ctx_pct_fmt"
printf "${BOLD}Session: %s${RESET} | ${BOLD}Model: %s${RESET}\n" "$duration" "$model_display"
