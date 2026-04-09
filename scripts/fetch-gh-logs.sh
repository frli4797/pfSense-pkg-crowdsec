#!/bin/sh
set -euo pipefail

REPO=${REPO:-${GITHUB_REPOSITORY:-"frli4797/pfSense-pkg-crowdsec"}}
RUN_ID=${1:-}
USED_LATEST=0

if ! command -v gh >/dev/null 2>&1; then
    echo "Error: GitHub CLI (gh) is not installed." >&2
    exit 1
fi

if [ -z "$RUN_ID" ]; then
    RUN_ID=$(gh run list --repo "$REPO" -L 1 --json databaseId -q '.[0].databaseId')
    if [ -z "$RUN_ID" ]; then
        echo "Error: Unable to determine latest workflow run for $REPO." >&2
        exit 1
    fi
    echo "Using latest run ID: $RUN_ID"
    USED_LATEST=1
fi

OUT_DIR="debug-logs/run-${RUN_ID}"
mkdir -p "$OUT_DIR"

echo "Downloading combined log to $OUT_DIR/all-jobs.log"
gh run view "$RUN_ID" --repo "$REPO" --log > "$OUT_DIR/all-jobs.log"

JOB_DATA=$(gh run view "$RUN_ID" --repo "$REPO" --json jobs)
JOB_LINES=$(printf '%s' "$JOB_DATA" | jq -r '.jobs[] | @tsv "\(.name)\t\(.databaseId)"' || true)

if [ -n "$JOB_LINES" ]; then
    printf '%s\n' "$JOB_LINES" | while IFS=$'\t' read -r job_name job_id; do
        [ -z "$job_id" ] && continue
        safe_name=$(printf '%s' "$job_name" | tr ' ' '_' | tr -cd 'A-Za-z0-9._-')
        echo "Downloading log for job '$job_name' (ID $job_id) -> $OUT_DIR/${safe_name}.log"
        gh run view "$RUN_ID" --repo "$REPO" --log --job "$job_id" > "$OUT_DIR/${safe_name}.log"
    done
fi

echo "Logs saved under $OUT_DIR"

if [ "$USED_LATEST" -eq 1 ]; then
    ln -sfn "$(basename "$OUT_DIR")" debug-logs/latest
    echo "Symlinked debug-logs/latest -> $(basename "$OUT_DIR")"
fi
