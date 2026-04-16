#!/usr/bin/env bash
# Optional: publish this skill globally so it's available in every project.
# You don't need this to use the skill — just open this folder in Claude Code.
#
# Usage: ./install.sh

set -e

SKILL_DIR="$HOME/.claude/skills/market-recon"
SRC=".claude/skills/market-recon"

echo "Publishing /market-recon skill globally..."

if [ -d "$SKILL_DIR" ]; then
  echo "Existing global installation found at $SKILL_DIR"
  read -p "Overwrite? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
  fi
fi

mkdir -p "$SKILL_DIR/_prompts" "$SKILL_DIR/_templates"

cp "$SRC/SKILL.md" "$SKILL_DIR/"
cp "$SRC/player-classification.md" "$SKILL_DIR/"
cp "$SRC/procurement-criteria.md" "$SKILL_DIR/"
cp "$SRC/_prompts/"*.md "$SKILL_DIR/_prompts/"
cp "$SRC/_templates/"*.md "$SKILL_DIR/_templates/"

if [ -d "$SRC/_validation" ]; then
  mkdir -p "$SKILL_DIR/_validation"
  cp "$SRC/_validation/"*.md "$SKILL_DIR/_validation/"
fi

echo ""
echo "Done. /market-recon is now available in all projects."
echo "To use it project-scoped only, just open this folder instead."
