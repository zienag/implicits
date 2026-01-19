#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"
while [ ! -d "$REPO_ROOT/.git" ] && [ "$REPO_ROOT" != "/" ]; do
  REPO_ROOT="$(dirname "$REPO_ROOT")"
done

if [ ! -d "$REPO_ROOT/.git" ]; then
  echo "error: not a git repository"
  exit 1
fi

if [ ! -x "$SCRIPT_DIR/pre-commit" ]; then
  echo "error: pre-commit hook not found or not executable"
  exit 1
fi

ln -sf "$SCRIPT_DIR/pre-commit" "$REPO_ROOT/.git/hooks/pre-commit"
echo "Pre-commit hook installed"
