#!/bin/bash
# Re-apply claude-setup to all registered projects (or a specific one)
# Usage:
#   ./update.sh              # update all registered projects
#   ./update.sh /path/to/proj # update a specific project

set -e

CONFIG_DIR="$HOME/.claude-setup"
PROJECTS_FILE="$CONFIG_DIR/projects"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

update_project() {
  local project="$1"

  if [ ! -d "$project" ]; then
    echo "SKIP: $project (directory not found)"
    return
  fi

  if [ ! -d "$project/.claude" ]; then
    echo "SKIP: $project (no .claude/ directory — not a claude-setup project)"
    return
  fi

  echo "Updating: $project"

  for script in "$SCRIPT_DIR"/setup-*.sh; do
    [ -f "$script" ] || continue
    bash "$script" "$project"
  done

  echo "  Done."
  echo ""
}

# Specific project passed as argument
if [ -n "$1" ]; then
  TARGET="$(cd "$1" && pwd)"
  update_project "$TARGET"

  # Register it if not already tracked
  mkdir -p "$CONFIG_DIR"
  touch "$PROJECTS_FILE"
  if ! grep -qxF "$TARGET" "$PROJECTS_FILE" 2>/dev/null; then
    echo "$TARGET" >> "$PROJECTS_FILE"
    echo "Registered $TARGET for future updates."
  fi
  exit 0
fi

# No argument — update all registered projects
if [ ! -f "$PROJECTS_FILE" ] || [ ! -s "$PROJECTS_FILE" ]; then
  echo "No projects registered yet."
  echo "Run install.sh to set up a new project, or:"
  echo "  ./update.sh /path/to/existing/project"
  exit 0
fi

echo "Updating all registered projects..."
echo ""

updated=0
while IFS= read -r project; do
  [ -z "$project" ] && continue
  update_project "$project"
  updated=$((updated + 1))
done < "$PROJECTS_FILE"

echo "Updated $updated project(s)."
