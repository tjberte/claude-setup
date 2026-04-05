#!/bin/bash
set -e

CONFIG_DIR="$HOME/.claude-setup"
CONFIG_FILE="$CONFIG_DIR/config"
PROJECTS_FILE="$CONFIG_DIR/projects"

# Load or prompt for base projects directory
if [ -f "$CONFIG_FILE" ] && grep -q '^BASE_DIR=' "$CONFIG_FILE" 2>/dev/null; then
  BASE_DIR=$(grep '^BASE_DIR=' "$CONFIG_FILE" | cut -d= -f2-)
  echo "Using saved projects directory: $BASE_DIR"
else
  read -p "Enter your projects directory (e.g., $HOME/projects): " BASE_DIR
  if [[ -z "$BASE_DIR" ]]; then
    echo "Error: Projects directory cannot be empty."
    exit 1
  fi
  # Expand ~ if used
  BASE_DIR="${BASE_DIR/#\~/$HOME}"
  mkdir -p "$CONFIG_DIR"
  echo "BASE_DIR=$BASE_DIR" > "$CONFIG_FILE"
  echo "Saved projects directory to $CONFIG_FILE"
fi

# Ask for project name
read -p "Enter project name: " PROJECT_NAME

if [[ -z "$PROJECT_NAME" ]]; then
  echo "Error: Project name cannot be empty."
  exit 1
fi

PROJECT_DIR="$BASE_DIR/$PROJECT_NAME"

# Create project directory
if [ -d "$PROJECT_DIR" ]; then
  echo "Project directory already exists: $PROJECT_DIR"
else
  mkdir -p "$PROJECT_DIR"
  echo "Created project directory: $PROJECT_DIR"
fi

# Initialize git repo if not already one
if [ ! -d "$PROJECT_DIR/.git" ]; then
  git init "$PROJECT_DIR"
  echo "Initialized git repository in $PROJECT_DIR"
fi

# Run all setup-*.sh scripts in this directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

for script in "$SCRIPT_DIR"/setup-*.sh; do
  [ -f "$script" ] || continue
  echo ""
  echo "Running $(basename "$script")..."
  bash "$script" "$PROJECT_DIR"
done

# Register project for future updates
touch "$PROJECTS_FILE"
RESOLVED_DIR="$(cd "$PROJECT_DIR" && pwd)"
if ! grep -qxF "$RESOLVED_DIR" "$PROJECTS_FILE" 2>/dev/null; then
  echo "$RESOLVED_DIR" >> "$PROJECTS_FILE"
  echo ""
  echo "Registered $RESOLVED_DIR for future updates."
fi

# Create initial commit so hooks have a baseline to diff against
if [ -z "$(git -C "$PROJECT_DIR" log --oneline -1 2>/dev/null)" ]; then
  echo ""
  echo "Creating initial commit..."
  git -C "$PROJECT_DIR" add -A
  git -C "$PROJECT_DIR" commit -m "Initial project setup via claude-setup"
  echo "  Initial commit created."
fi

echo ""
echo "Setup complete for $PROJECT_DIR"
