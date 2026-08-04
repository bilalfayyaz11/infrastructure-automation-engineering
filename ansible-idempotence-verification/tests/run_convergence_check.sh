#!/usr/bin/env bash
set -u

usage() {
  echo "Usage: $0 <playbook_path>"
}

if [ "$#" -ne 1 ]; then
  usage
  exit 2
fi

playbook_path="$1"

if [ ! -f "$playbook_path" ]; then
  echo "ERROR: playbook not found: $playbook_path"
  exit 2
fi

timestamp="$(
  date +%s%N 2>/dev/null || date +%s
)"

results_dir="/tmp/convergence_${timestamp}_$$"
mkdir -p "$results_dir" || exit 2

changed_counts=""

echo "Results directory: $results_dir"

run_number=1

while [ "$run_number" -le 3 ]; do
  log_file="$results_dir/run_${run_number}.log"

  echo "===== RUN $run_number: $playbook_path ====="

  ansible-playbook "$playbook_path" >"$log_file" 2>&1
  playbook_exit="$?"

  cat "$log_file"

  if [ "$playbook_exit" -ne 0 ]; then
    echo "ERROR: playbook execution failed on run $run_number"
    echo "Log: $log_file"
    exit 2
  fi

  changed_count="$(
    awk '
      /^[[:alnum:]_.-]+[[:space:]]*:/ {
        for (field = 1; field <= NF; field++) {
          if ($field ~ /^changed=[0-9]+$/) {
            split($field, parts, "=")
            print parts[2]
            exit
          }
        }
      }
    ' "$log_file"
  )"

  if [ -z "$changed_count" ]; then
    echo "ERROR: unable to parse changed count from run $run_number"
    echo "Log: $log_file"
    exit 2
  fi

  changed_counts="${changed_counts}${run_number}:${changed_count} "
  echo "Parsed run $run_number changed count: $changed_count"

  if [ "$run_number" -ge 2 ] && [ "$changed_count" -ne 0 ]; then
    convergence_failed=1
  fi

  run_number=$((run_number + 1))
done

echo "Changed counts: $changed_counts"

if [ "${convergence_failed:-0}" -eq 1 ]; then
  echo "FAIL: $playbook_path did not converge by the second run."
  exit 1
fi

echo "PASS: $playbook_path converged with changed=0 on runs 2 and 3."
exit 0
