# Custom Status Line

This project includes a custom Claude Code status line that displays real-time context and session metrics.

## What It Shows

```
Ctx: 73k (40%) | Cache: 100% | Branch: main | Session: 31m (80k tokens)
Model: Sonnet 4.6
```

### Line 1: Metrics
- **Ctx: 73k (40%)** — Context window usage
  - `73k` = tokens used out of 200k conversation limit
  - `40%` = percentage of context window filled
  - Colors: 🟢 Green (<70%), 🟡 Yellow (70-85%), 🔴 Red (>85% with ⚠️)

- **Cache: 100%** — Prompt caching efficiency
  - Shows percentage of tokens that hit the cache (reused from previous messages)
  - Colors: 🟢 Green (>80%), 🟡 Yellow (60-80%), 🔴 Red (<60%)
  - High cache = good prompt reuse

- **Branch: main** — Current git branch

- **Session: 31m (80k tokens)** — Time and tokens used in this session
  - Useful for understanding session length vs. token consumption
  - Helps identify if a feature step is token-heavy

### Line 2: Model
- Shows the active Claude model (e.g., Sonnet 4.6, Opus 4.6)

## Installation

The status line is **pre-configured** for all clones. No setup needed.

If you need to reconfigure it:
```bash
npm install -g ccusage  # one-time dependency
```

## When to Pay Attention

### Context Window
- **Green (0-70%)**: Safe, plenty of room
- **Yellow (70-85%)**: Consider trimming context or using `/trim-context` soon
- **Red (>85%)**: Trim context now with `/trim-context` before it hits the limit

### Cache Hit %
- **High (>80%)**: Excellent! Prompt caching is working well
- **Low (<60%)**: Each message is recreating context from scratch
  - Normal for starting a new feature
  - Increases over time as Claude Code reuses cached context

## Implementation

- **Location:** `.claude/statusline/statusline.sh`
- **Config:** `.claude/settings.json` → `statusLine` key
- **Data source:** Claude Code's stdin JSON (real-time session metrics)
- **Performance:** Runs every command, minimal overhead

## For Max Plan Users

This status line is optimized for Max plan users. The key metrics are:
1. **Context window %** — Most important (prevents hitting conversation limits)
2. **Cache efficiency** — Shows prompt reuse quality
3. **Session metrics** — Helps understand token consumption patterns

Cost and weekly usage limits are not shown (since Max plan doesn't track them). For those metrics, check claude.ai/settings/usage.

## Future Enhancements

Requested from Anthropic:
- Session/weekly usage percentages (currently not exposed in statusline JSON)
- See: `.claude/STATUSLINE.md` for details
