#!/usr/bin/env bash
set -euo pipefail

echo "STABLE_GIT_COMMIT $(git rev-parse HEAD)"
echo "STABLE_GIT_BRANCH $(git rev-parse --abbrev-ref HEAD)"
echo "STABLE_GIT_REMOTE_URL $(git ls-remote --get-url)"
