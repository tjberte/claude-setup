#!/bin/bash
# Setup CLAUDE.md and .gitignore for a Claude Code project
# Usage: ./setup-project-base.sh /path/to/project

set -e

PROJECT="${1:-.}"
PROJECT="$(cd "$PROJECT" && pwd)"
PROJECT_NAME="$(basename "$PROJECT")"

echo "Setting up project base for: $PROJECT"

# Create .gitignore if it doesn't exist
if [ ! -f "$PROJECT/.gitignore" ]; then
  cat > "$PROJECT/.gitignore" << 'EOF'
# Dependencies
node_modules/
vendor/
.venv/
venv/
__pycache__/

# Environment & secrets
.env
.env.*
!.env.example
*.pem
*.key

# OS files
.DS_Store
Thumbs.db

# IDE
.idea/
.vscode/
*.swp
*.swo

# Build output
dist/
build/
*.o
*.pyc

# Claude Code local settings (machine-specific, not shared)
.claude/settings.local.json
EOF
  echo "  Created .gitignore"
else
  # Ensure settings.local.json is gitignored
  if ! grep -q 'settings.local.json' "$PROJECT/.gitignore" 2>/dev/null; then
    echo "" >> "$PROJECT/.gitignore"
    echo "# Claude Code local settings (machine-specific, not shared)" >> "$PROJECT/.gitignore"
    echo ".claude/settings.local.json" >> "$PROJECT/.gitignore"
    echo "  Added settings.local.json to existing .gitignore"
  fi
fi

# Create CLAUDE.md if it doesn't exist
if [ ! -f "$PROJECT/CLAUDE.md" ]; then
  cat > "$PROJECT/CLAUDE.md" << EOF
# $PROJECT_NAME

## Overview
<!-- Brief description of what this project does -->

## Tech Stack
<!-- Languages, frameworks, and key dependencies -->

## Getting Started
\`\`\`bash
# How to install dependencies and run the project
\`\`\`

## Project Structure
<!-- Key directories and their purpose -->

## Development
- Run tests: <!-- e.g., npm test, pytest -->
- Build: <!-- e.g., npm run build, make -->
- Lint: <!-- e.g., npm run lint, ruff check -->

## Conventions
- Follow existing code style and patterns
- Write concise, imperative commit messages
EOF
  echo "  Created CLAUDE.md"
else
  echo "  CLAUDE.md already exists, skipping"
fi

echo ""
echo "Done. Project base files ready for $PROJECT"
