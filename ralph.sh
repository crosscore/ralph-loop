#!/usr/bin/env bash
set -e

# Configuration
MAX_ITERATIONS=${MAX_ITERATIONS:-10}
AGENT_NAME="$1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Agent command mapping
declare -A AGENTS
AGENTS["claude"]="claude --permission-mode bypassPermissions --verbose"
AGENTS["gemini"]="gemini --model gemini-3-flash-preview --yolo --debug"

if [ -z "$AGENT_NAME" ]; then
  echo "Usage: ./ralph-loop/ralph.sh <agent> [max_iterations]"
  echo ""
  echo "Available agents:"
  for key in "${!AGENTS[@]}"; do
    echo "  $key -> ${AGENTS[$key]}"
  done
  echo ""
  echo "Examples:"
  echo "  ./ralph-loop/ralph.sh claude"
  echo "  ./ralph-loop/ralph.sh gemini"
  echo "  ./ralph-loop/ralph.sh claude 5"
  echo ""
  echo "Environment variables:"
  echo "  MAX_ITERATIONS (default: 10)"
  exit 1
fi

# Resolve agent command
if [ -n "${AGENTS[$AGENT_NAME]}" ]; then
  AGENT_CMD="${AGENTS[$AGENT_NAME]}"
else
  # Allow custom command as fallback
  AGENT_CMD="$AGENT_NAME"
fi

if [ -n "$2" ]; then
  MAX_ITERATIONS=$2
fi

echo "🚀 Starting Ralph with agent: '$AGENT_CMD'"
echo "📂 Working directory: $(pwd)"
echo "🔄 Max iterations: $MAX_ITERATIONS"

for i in $(seq 1 $MAX_ITERATIONS); do
  echo "═══ Iteration $i/$MAX_ITERATIONS ═══"

  PROMPT_CONTENT=$(cat "$SCRIPT_DIR/prompt.md")

  echo "🤖 Agent running..."
  OUTPUT=$(echo "$PROMPT_CONTENT" | $AGENT_CMD 2>&1 | tee /dev/stderr) || true

  if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
    echo "✅ Done! All stories completed."
    exit 0
  fi

  echo "⏳ Iteration $i finished. Sleeping for 2 seconds..."
  sleep 2
done

echo "⚠️ Max iterations reached without completion signal."
exit 1
