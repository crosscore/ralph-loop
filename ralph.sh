#!/usr/bin/env bash
set -e

# Configuration
MAX_ITERATIONS=${MAX_ITERATIONS:-10}
AGENT_NAME="$1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Check for jq dependency
if ! command -v jq &> /dev/null; then
  echo "❌ Error: jq is required but not installed."
  echo "   Install with: brew install jq"
  exit 1
fi

# Agent command mapping
declare -A AGENTS
AGENTS["claude"]="claude -p --permission-mode bypassPermissions --verbose --output-format stream-json"
AGENTS["gemini"]="gemini --model gemini-3-flash-preview --yolo --debug"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Function to display context window usage bar
display_context_bar() {
  local used=$1
  local total=$2
  local width=40

  if [ "$total" -gt 0 ]; then
    local percent=$((used * 100 / total))
    local filled=$((used * width / total))
    local empty=$((width - filled))

    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done

    local color=$GREEN
    if [ $percent -gt 70 ]; then color=$YELLOW; fi
    if [ $percent -gt 90 ]; then color=$RED; fi

    echo -e "${BOLD}📊 Context Window:${NC} [${color}${bar}${NC}] ${percent}% (${used}/${total} tokens)"
  fi
}

# Function to display thinking process
display_thinking() {
  local thinking="$1"
  if [ -n "$thinking" ] && [ "$thinking" != "null" ]; then
    echo -e "\n${BOLD}${CYAN}💭 Thinking Process:${NC}"
    echo -e "${GRAY}────────────────────────────────────────${NC}"
    echo -e "${GRAY}${thinking}${NC}" | head -50
    if [ $(echo "$thinking" | wc -l) -gt 50 ]; then
      echo -e "${GRAY}... (truncated)${NC}"
    fi
    echo -e "${GRAY}────────────────────────────────────────${NC}"
  fi
}

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

echo ""
echo -e "${BOLD}${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║                    🚀 RALPH LOOP                          ║${NC}"
echo -e "${BOLD}${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}📦 Agent:${NC} $AGENT_CMD"
echo -e "${BOLD}📂 Working directory:${NC} $(pwd)"
echo -e "${BOLD}🔄 Max iterations:${NC} $MAX_ITERATIONS"

for i in $(seq 1 $MAX_ITERATIONS); do
  echo ""
  echo -e "${BOLD}═══════════════════════════════════════════════════════════${NC}"
  echo -e "${BOLD}  🔄 Iteration $i/$MAX_ITERATIONS${NC}"
  echo -e "${BOLD}═══════════════════════════════════════════════════════════${NC}"

  PROMPT_CONTENT=$(cat "$SCRIPT_DIR/prompt.md")

  echo -e "\n${BLUE}🤖 Agent running...${NC}"

  # Run agent and capture output
  if [[ "$AGENT_NAME" == "claude" ]]; then
    # Claude with stream-json output for real-time display
    TEMP_OUTPUT=$(mktemp)
    TEMP_TEXT=$(mktemp)

    echo -e "${GRAY}────────────────────────────────────────${NC}"

    # Stream and display output in real-time using process substitution
    # This runs in current shell to avoid subshell variable scope issues
    while IFS= read -r line; do
      echo "$line" >> "$TEMP_OUTPUT"

      # Try to parse each line as JSON
      if echo "$line" | jq -e . > /dev/null 2>&1; then
        TYPE=$(echo "$line" | jq -r '.type // empty')

        case "$TYPE" in
          "assistant")
            # Extract and display text content
            CONTENT=$(echo "$line" | jq -r '.message.content[]? | select(.type=="text") | .text // empty' 2>/dev/null)
            if [ -n "$CONTENT" ]; then
              echo -ne "$CONTENT"
              echo -ne "$CONTENT" >> "$TEMP_TEXT"
            fi
            ;;
          "content_block_delta")
            # Streaming text delta
            DELTA=$(echo "$line" | jq -r '.delta.text // empty' 2>/dev/null)
            if [ -n "$DELTA" ]; then
              echo -ne "$DELTA"
              echo -ne "$DELTA" >> "$TEMP_TEXT"
            fi
            ;;
          "result")
            # Final result - extract the text
            RESULT_TEXT=$(echo "$line" | jq -r '.result // empty' 2>/dev/null)
            if [ -n "$RESULT_TEXT" ] && [ "$RESULT_TEXT" != "null" ]; then
              echo -ne "$RESULT_TEXT"
              echo -ne "$RESULT_TEXT" >> "$TEMP_TEXT"
            fi
            ;;
        esac
      fi
    done < <(echo "$PROMPT_CONTENT" | $AGENT_CMD 2>/dev/null) || true

    echo ""
    echo -e "${GRAY}────────────────────────────────────────${NC}"

    # Process final output for metadata
    INPUT_TOKENS=0
    OUTPUT_TOKENS=0
    CONTEXT_SIZE=200000
    TOTAL_COST="N/A"
    DURATION=0

    if [ -f "$TEMP_OUTPUT" ]; then
      # Get the last "result" type line for metadata
      RESULT_LINE=$(grep '"type":"result"' "$TEMP_OUTPUT" 2>/dev/null | tail -1 || true)

      if [ -n "$RESULT_LINE" ]; then
        INPUT_TOKENS=$(echo "$RESULT_LINE" | jq -r '.context_window.current_usage.input_tokens // 0' 2>/dev/null || echo "0")
        OUTPUT_TOKENS=$(echo "$RESULT_LINE" | jq -r '.context_window.current_usage.output_tokens // 0' 2>/dev/null || echo "0")
        CONTEXT_SIZE=$(echo "$RESULT_LINE" | jq -r '.context_window.context_window_size // 200000' 2>/dev/null || echo "200000")
        TOTAL_COST=$(echo "$RESULT_LINE" | jq -r '.cost_usd // "N/A"' 2>/dev/null || echo "N/A")
        DURATION=$(echo "$RESULT_LINE" | jq -r '.duration_ms // 0' 2>/dev/null || echo "0")
      fi

      # Display context window usage
      TOTAL_TOKENS=$((INPUT_TOKENS + OUTPUT_TOKENS))
      echo ""
      display_context_bar "$TOTAL_TOKENS" "$CONTEXT_SIZE"

      # Display additional stats
      echo -e "${BOLD}💰 Cost:${NC} \$${TOTAL_COST} | ${BOLD}⏱️ Duration:${NC} ${DURATION}ms | ${BOLD}📤 Output:${NC} ${OUTPUT_TOKENS} tokens"

      rm -f "$TEMP_OUTPUT"
    fi

    # Use captured text for completion check
    if [ -f "$TEMP_TEXT" ]; then
      OUTPUT=$(cat "$TEMP_TEXT")
      rm -f "$TEMP_TEXT"
    else
      OUTPUT=""
    fi
  else
    # Other agents (gemini, etc.) - use original method
    OUTPUT=$(echo "$PROMPT_CONTENT" | $AGENT_CMD 2>&1 | tee /dev/stderr) || true
  fi

  if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
    echo ""
    echo -e "${BOLD}${GREEN}✅ Done! All stories completed.${NC}"
    exit 0
  fi

  echo -e "\n${YELLOW}⏳ Iteration $i finished. Sleeping for 2 seconds...${NC}"
  sleep 2
done

echo ""
echo -e "${BOLD}${RED}⚠️ Max iterations reached without completion signal.${NC}"
exit 1
