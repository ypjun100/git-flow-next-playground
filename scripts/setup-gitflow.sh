#!/bin/bash
#
# setup-gitflow.sh
#
# Run this script once after cloning the repository to set up
# git-flow-next with the project's branching conventions.
#
# Usage: bash scripts/setup-gitflow.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}⚠${NC}  $*"; }
fail() { echo -e "${RED}✗${NC} $*"; exit 1; }

echo ""
echo "Setting up git-flow-next for this repository..."
echo ""

# ── 1. Check dependencies ────────────────────────────────────────────────────

if ! command -v git-flow &>/dev/null; then
  fail "git-flow-next is not installed.\n  Install it with: brew install git-flow-next"
fi
ok "git-flow-next: $(git-flow version 2>/dev/null | head -1)"

if ! command -v gh &>/dev/null; then
  warn "'gh' CLI not found. GitHub PR merge detection will be skipped on release finish."
  warn "Install it with: brew install gh"
else
  ok "gh: $(gh --version | head -1)"
fi

# ── 2. Configure git hooks path ──────────────────────────────────────────────

git config core.hooksPath .githooks
chmod +x .githooks/*
ok "Git hooks configured at .githooks/"

# ── 3. Initialize git-flow ───────────────────────────────────────────────────

git flow init \
  --main=main \
  --feature=feature/ \
  --release=release/ \
  --hotfix=hotfix/ \
  --bugfix=fix/ \
  --force \
  --no-create-branches \
  2>/dev/null

# ── 4. Configure branch types ────────────────────────────────────────────────

# Remove develop if present
git flow config delete base develop 2>/dev/null || true

# Remove topic types that will be re-added with correct settings
for TYPE in fix feature release support bugfix; do
  git flow config delete topic "$TYPE" 2>/dev/null || true
done

# Re-add with correct parent (main) and settings
git flow config add topic feature main \
  --prefix=feature/ \
  --upstream-strategy=merge \
  --downstream-strategy=rebase \
  2>/dev/null
ok "topic branch configured: feature (parent: main, prefix: feature/)"

git flow config add topic fix main \
  --prefix=fix/ \
  --upstream-strategy=merge \
  --downstream-strategy=rebase \
  2>/dev/null
ok "topic branch configured: fix (parent: main, prefix: fix/)"

git flow config add topic release main \
  --prefix=release/ \
  --upstream-strategy=merge \
  --downstream-strategy=merge \
  --tag \
  --starting-point=main \
  2>/dev/null
ok "topic branch configured: release (parent: main, prefix: release/, tags: yes)"

git flow config add topic hotfix main \
  --prefix=hotfix/ \
  --upstream-strategy=merge \
  --downstream-strategy=rebase \
  --tag \
  --starting-point=main \
  2>/dev/null
ok "topic branch configured: hotfix (parent: main, prefix: hotfix/, tags: yes)"

# ── 5. Done ──────────────────────────────────────────────────────────────────

echo ""
echo "Setup complete! Branch conventions:"
echo ""
echo "  git flow release start v1.2.0                      # branch from latest main"
echo "  git flow feature start <name> release/v1.2.0      # branch from release branch"
echo "  git flow fix start <name> release/v1.2.0          # branch from release branch"
echo "  git flow hotfix start <name> [base]               # branch from main or release"
echo "  git flow release finish v1.2.0                    # merge to main + tag (or tag-only if PR-merged)"
echo ""
