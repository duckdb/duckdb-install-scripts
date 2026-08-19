#!/bin/bash -e

set -o pipefail

: "${DUCKDB_STAGED:?DUCKDB_STAGED must be set}"

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
STAGED_VERSION="${DUCKDB_STAGED#*/}"
ALPHA_INST="${HOME}/.duckdb/cli/${STAGED_VERSION}"

cd "${REPO_ROOT}"

bash install.sh
test -x "${ALPHA_INST}/duckdb"
test "$(readlink "${HOME}/.duckdb/cli/latest")" = "${ALPHA_INST}"
"${HOME}/.duckdb/cli/latest/duckdb" -c "select 42"

unset DUCKDB_STAGED
unset DUCKDB_VERSION
cat install.sh | bash
test "$(readlink "${HOME}/.duckdb/cli/latest")" != "${ALPHA_INST}"
"${HOME}/.duckdb/cli/latest/duckdb" -c "select 42"
