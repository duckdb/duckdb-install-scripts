# DuckDB install scripts for Linux/OSX and Windows

This Repo contains the scripts that power the DuckDB CLI installer, e.g. `curl install.duckdb.org | bash`

## Versions

By default, the installers download the latest stable DuckDB release. Set `DUCKDB_VERSION` to install a specific version, or set it to `alpha` to install the latest alpha build:

```bash
curl https://install.duckdb.org | DUCKDB_VERSION=alpha bash
```

Alpha builds are resolved through `https://duckdb-staging.duckdb.org/latest_alpha_version.txt`. You can install a specific staged build directly with its `<commit>/<version>` identifier:

```bash
curl https://install.duckdb.org | DUCKDB_STAGED=c99ade5cb6/v2.0.0-alpha38367 bash
```

When both variables are set, `DUCKDB_STAGED` takes precedence. On Linux and macOS, a staged install updates `~/.duckdb/cli/latest` to point to the staged version.

On Windows, set the corresponding environment variable before running `install.ps1`:

```powershell
$env:DUCKDB_VERSION = "alpha"
# Or pin a staged build:
$env:DUCKDB_STAGED = "c99ade5cb6/v2.0.0-alpha38367"
./install.ps1
```
