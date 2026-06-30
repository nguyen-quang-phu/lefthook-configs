#!/usr/bin/env bash
set -uo pipefail

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$repo_root" ]]; then
  echo >&2 "run-with-repo-node.sh: not a git repository"
  exit 1
fi
cd "$repo_root"

nvmrc_version=""
if [[ -f .nvmrc ]]; then
  nvmrc_version=$(tr -d ' \t\r\n' <.nvmrc)
  nvmrc_version="${nvmrc_version#v}"
fi

if command -v fnm >/dev/null 2>&1; then
  # shellcheck disable=SC1090
  eval "$(fnm env)"
  fnm use >/dev/null 2>&1 || true
else
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    # shellcheck disable=SC1090
    source "$NVM_DIR/nvm.sh"
    if [[ -n "$nvmrc_version" ]]; then
      nvm use "$nvmrc_version" >/dev/null 2>&1 || true
    else
      nvm use >/dev/null 2>&1 || true
    fi
  fi
  if [[ -n "$nvmrc_version" && -x "$NVM_DIR/versions/node/v${nvmrc_version}/bin/node" ]]; then
    export PATH="$NVM_DIR/versions/node/v${nvmrc_version}/bin:$PATH"
  fi
  if ! command -v node >/dev/null 2>&1 && command -v mise >/dev/null 2>&1; then
    _mise_node_bin="$(mise where node 2>/dev/null)/bin"
    if [[ -d "$_mise_node_bin" ]]; then
      export PATH="$_mise_node_bin:$PATH"
    fi
  fi
fi

if ! command -v node >/dev/null 2>&1; then
  echo >&2 "run-with-repo-node.sh: node not found. Install Node ${nvmrc_version:-22} (see .nvmrc) with fnm or nvm, or put Node 22+ first on PATH."
  exit 1
fi

major="$(node -p "parseInt(process.versions.node, 10)" 2>/dev/null || echo 0)"
if ((major < 22)); then
  echo >&2 "run-with-repo-node.sh: Node.js 22+ required (.nvmrc). Got $(node -v) at $(command -v node)."
  exit 1
fi

exec "$@"
