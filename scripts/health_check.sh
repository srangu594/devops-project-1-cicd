#!/bin/bash
set -euo pipefail
PORT=$1
MAX=5
WAIT=10
for i in $(seq 1 $MAX); do
    CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:${PORT}/health" || true)
    if [ "$CODE" = "200" ]; then
        echo "Health check PASSED (attempt ${i})"
        exit 0
    fi
    echo "Attempt ${i}/${MAX} got HTTP ${CODE} - retrying in ${WAIT}s..."
    sleep $WAIT
done
echo "Health check FAILED after ${MAX} attempts"
exit 1
