#!/bin/bash
# Claude Code custom status line (Max plan optimized)
# Shows: Context usage with warning | Cache efficiency | Session duration | Branch
#
# Requires: jq, git

input=$(cat)

# --- ANSI colors ---
RED='\033[91m'
YELLOW='\033[93m'
GREEN='\033[92m'
BLUE='\033[94m'
GRAY='\033[90m'
CYAN='\033[96m'
BOLD='\033[1m'
RESET='\033[0m'

# --- Extract session data ---
session_id=$(echo "$input" | jq -r '.session_id // "unknown"')
model=$(echo "$input" | jq -r '.model.display_name // "unknown"')

# Context window data
ctx_limit=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
ctx_percent=$(echo "$input" | jq -r '.context_window.used_percentage // 0')

# Calculate actual context used from percentage (more reliable than total_input_tokens)
# Since used_percentage is what Claude Code calculates, derive actual tokens from it
ctx_used=$(awk "BEGIN { printf \"%.0f\", ($ctx_percent / 100) * $ctx_limit }")

# Current session token counts
session_input=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
session_output=$(echo "$input" | jq -r '.context_window.current_usage.output_tokens // 0')
session_cache_read=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')
session_cache_create=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')

# Session duration
session_duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
session_duration_min=$(( session_duration_ms / 60000 ))
session_hours=$(( session_duration_min / 60 ))
session_mins=$(( session_duration_min % 60 ))

# --- Context warning color ---
ctx_color=$GREEN
ctx_indicator=""
if (( ${ctx_percent%.*} > 85 )); then
  ctx_color=$RED
  ctx_indicator=" ⚠️"
elif (( ${ctx_percent%.*} > 70 )); then
  ctx_color=$YELLOW
  ctx_indicator=" ⚡"
fi

# --- Cache efficiency ---
# Cache read / (cache read + input) = cache hit rate
cache_denominator=$(( session_cache_read + session_input ))
if (( cache_denominator > 0 )); then
  cache_hit=$(awk "BEGIN { printf \"%.0f\", ($session_cache_read / $cache_denominator) * 100 }")
else
  cache_hit=0
fi

# Cache color: green if >80%, yellow if >60%, red otherwise
cache_color=$GREEN
if (( cache_hit < 60 )); then
  cache_color=$RED
elif (( cache_hit < 80 )); then
  cache_color=$YELLOW
fi

# --- Git branch ---
branch=$(git -C "$(pwd)" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "?")

# --- Format displays ---
ctx_fmt=$(awk "BEGIN { printf \"%.0f\", $ctx_used / 1000 }")
session_fmt=$(awk "BEGIN { printf \"%.0f\", ($session_input + $session_output + $session_cache_create + $session_cache_read) / 1000 }")

if (( session_hours > 0 )); then
  duration_display="${session_hours}h ${session_mins}m"
else
  duration_display="${session_mins}m"
fi

# --- Output (two lines) ---
# Line 1: Context | Cache | Branch | Session Duration
printf "${ctx_color}${BOLD}Ctx: %sk${RESET}${ctx_color} (%s%%)${ctx_indicator}${RESET} | ${cache_color}Cache: %s%%${RESET} | ${GRAY}Branch: %s${RESET} | ${CYAN}Session: %s (%sk tokens)${RESET}\n" \
  "$ctx_fmt" "${ctx_percent%.*}" "$cache_hit" "$branch" "$duration_display" "$session_fmt"

# Line 2: Model indicator
printf "${GRAY}Model: %s${RESET}\n" "$model"
