''
  #!/usr/bin/env bash
  # Ensemble - spawn parallel Claude workers
  #
  # Usage:
  #   ensemble.sh --workers=N "task"                        # N workers, same task (REQUIRED)
  #   ensemble.sh --workers=5 --worker-1="special" "task"   # Mix: worker-1 gets special, others get default
  #   ensemble.sh --worker-1="task1" --worker-2="task2"     # Custom per-worker tasks (count inferred)
  #
  # Note: This script handles Claude workers only. For multi-backend ensembles
  # (Codex, Gemini, etc.), the orchestrator calls this + MCP tools in parallel.

  set -eo pipefail

  MODEL="claude-haiku-4-5"
  NUM_WORKERS=""  # No default - must be explicit
  TIMEOUT=300

  SYSTEM_PROMPT="You are a worker in a parallel ensemble swarm.

  CONTEXT:
  - You are one of several workers processing this task simultaneously
  - Each worker may approach the problem differently
  - Your output will be synthesized with other workers by an orchestrator

  GUIDELINES:
  - Be concise and focused
  - Provide actionable insights
  - Don't hedge excessively - commit to your analysis
  - If exploring code, be specific about file paths and line numbers

  Focus on delivering value. The orchestrator will handle synthesis."

  # Parse arguments
  declare -A WORKER_TASKS
  DEFAULT_TASK=""

  while [[ $# -gt 0 ]]; do
    case $1 in
      --workers=*)
        NUM_WORKERS="''${1#*=}"
        shift
        ;;
      --worker-*=*)
        # Extract worker number and task
        worker_num="''${1#--worker-}"
        worker_num="''${worker_num%%=*}"
        task="''${1#*=}"
        WORKER_TASKS[$worker_num]="$task"
        shift
        ;;
      --model=*)
        MODEL="''${1#*=}"
        shift
        ;;
      --help|-h)
        echo "Usage: ensemble.sh --workers=N [options] \"task\""
        echo ""
        echo "Options:"
        echo "  --workers=N           Number of workers (REQUIRED)"
        echo "  --worker-N=\"task\"     Custom task for worker N"
        echo "  --model=MODEL         Model to use (default: claude-haiku-4-5)"
        echo ""
        echo "Examples:"
        echo "  ensemble.sh --workers=3 \"analyze this codebase\""
        echo "  ensemble.sh --workers=5 \"find bugs\""
        echo "  ensemble.sh --worker-1=\"security\" --worker-2=\"performance\" --worker-3=\"style\""
        echo ""
        echo "Note: For multi-backend ensembles, orchestrator combines this with MCP calls."
        exit 0
        ;;
      *)
        DEFAULT_TASK="$1"
        shift
        ;;
    esac
  done

  # Validate task
  if [[ -z "$DEFAULT_TASK" ]] && [[ ''${#WORKER_TASKS[@]} -eq 0 ]]; then
    echo "Error: No task provided" >&2
    echo "Usage: ensemble.sh --workers=N \"task\"" >&2
    exit 1
  fi

  # Determine worker count - either explicit or inferred from custom tasks
  if [[ -z "$NUM_WORKERS" ]]; then
    if [[ ''${#WORKER_TASKS[@]} -gt 0 ]]; then
      # Infer from max worker number in custom tasks
      max_custom=0
      for key in "''${!WORKER_TASKS[@]}"; do
        if [[ $key -gt $max_custom ]]; then
          max_custom=$key
        fi
      done
      NUM_WORKERS=$max_custom
    else
      echo "Error: --workers=N is required (no default)" >&2
      echo "Usage: ensemble.sh --workers=N \"task\"" >&2
      exit 1
    fi
  else
    # If custom tasks exceed explicit count, expand
    if [[ ''${#WORKER_TASKS[@]} -gt 0 ]]; then
      max_custom=0
      for key in "''${!WORKER_TASKS[@]}"; do
        if [[ $key -gt $max_custom ]]; then
          max_custom=$key
        fi
      done
      if [[ $max_custom -gt $NUM_WORKERS ]]; then
        NUM_WORKERS=$max_custom
      fi
    fi
  fi

  echo "[ensemble] Starting $NUM_WORKERS Claude workers with model $MODEL..." >&2

  # Create temp directory for outputs
  TMPDIR=$(mktemp -d)
  trap "rm -rf $TMPDIR" EXIT

  # Spawn workers in parallel
  for i in $(seq 1 $NUM_WORKERS); do
    task="''${WORKER_TASKS[$i]:-$DEFAULT_TASK}"
    (
      claude --print --model "$MODEL" --system-prompt "$SYSTEM_PROMPT" "$task" \
        > "$TMPDIR/worker-$i.out" 2> "$TMPDIR/worker-$i.err" \
        && echo "success" > "$TMPDIR/worker-$i.status" \
        || echo "error" > "$TMPDIR/worker-$i.status"
    ) &
  done

  # Wait for all workers
  wait

  # Collect results
  success_count=0
  echo "<ensemble-output workers=\"$NUM_WORKERS\" model=\"$MODEL\">"
  for i in $(seq 1 $NUM_WORKERS); do
    status=$(cat "$TMPDIR/worker-$i.status" 2>/dev/null || echo "error")
    output=$(cat "$TMPDIR/worker-$i.out" 2>/dev/null || echo "")
    task="''${WORKER_TASKS[$i]:-$DEFAULT_TASK}"

    if [[ "$status" == "success" ]]; then
      ((success_count++)) || true
    fi

    # Escape XML special chars
    output=$(echo "$output" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
    task_escaped=$(echo "$task" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g')

    echo "  <worker id=\"$i\" status=\"$status\" task=\"$task_escaped\">"
    echo "$output"
    echo "  </worker>"
  done
  echo "</ensemble-output>"

  echo "[ensemble] Completed: $success_count/$NUM_WORKERS workers succeeded" >&2
''
