#!/bin/bash
# Setup memory-update enforcement hook for any Claude Code project
# Usage: ./setup-memory-hook.sh /path/to/project

set -e

PROJECT="${1:-.}"
PROJECT="$(cd "$PROJECT" && pwd)"
CLAUDE_DIR="$PROJECT/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"
RULES_DIR="$CLAUDE_DIR/rules"
SETTINGS="$CLAUDE_DIR/settings.local.json"
HOOK_SCRIPT="$HOOKS_DIR/check-memory.sh"

echo "Setting up memory hook for: $PROJECT"

# Create directory structure
SKILLS_DIR="$RULES_DIR/skills"
mkdir -p "$HOOKS_DIR" "$RULES_DIR" "$SKILLS_DIR"

# Create memory files if they don't exist
for file in memory-sessions.md memory-decisions.md memory-preferences.md memory-profile.md; do
  if [ ! -f "$RULES_DIR/$file" ]; then
    name=$(echo "$file" | sed 's/memory-//' | sed 's/\.md//')
    capitalized=$(echo "$name" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')
    echo "# $capitalized" > "$RULES_DIR/$file"
    echo "  Created $RULES_DIR/$file"
  fi
done

# Create skill files if they don't exist
if [ ! -f "$SKILLS_DIR/git-flow.md" ]; then
  cat > "$SKILLS_DIR/git-flow.md" << 'SKILLEOF'
# Skill: Git Workflow
- Use concise, imperative commit messages.
- Run `git status` before committing to verify changes.
SKILLEOF
  echo "  Created $SKILLS_DIR/git-flow.md"
fi

if [ ! -f "$SKILLS_DIR/meta-add-skill.md" ]; then
  cat > "$SKILLS_DIR/meta-add-skill.md" << 'SKILLEOF'
# Skill: Create New Skills (addskill)
When the user says "addskill [name]" or "create skill [name]":
1. Create a new file: `.claude/rules/skills/[name].md`.
2. Use this template:
   # Skill: [Name]
   ## Trigger
   [When should this skill be used?]
   ## Steps
   1. [Step 1]
   2. [Step 2]
3. If we just completed a task, automatically fill in the steps based on what worked.
4. Confirm: "New skill '[name]' has been added to your library."
SKILLEOF
  echo "  Created $SKILLS_DIR/meta-add-skill.md"
fi

if [ ! -f "$SKILLS_DIR/cpm.md" ]; then
  cat > "$SKILLS_DIR/cpm.md" << 'SKILLEOF'
# Skill: CPM (Clean, Commit, Push)

## Trigger
When the user says "cpm", "clean commit push", or "commit push review".

## Steps
1. Read `CLAUDE.md` in the project root.
2. Review its contents for:
   - Redundant or duplicated instructions
   - Outdated references (files, commands, paths that no longer exist)
   - Unnecessary or stale entries
3. Clean up `CLAUDE.md`: remove redundancies, delete stale content, tighten wording. Do not add new content.
4. If `CLAUDE.md` had no issues, confirm it's clean and skip editing.
5. Run `git status` to verify all changes.
6. Stage all relevant changed files.
7. Create a concise, imperative commit message.
8. Commit the changes.
9. Push to the current branch.
10. Confirm what was cleaned, committed, and pushed.
SKILLEOF
  echo "  Created $SKILLS_DIR/cpm.md"
fi

if [ ! -f "$SKILLS_DIR/newfeature.md" ]; then
  cat > "$SKILLS_DIR/newfeature.md" << 'SKILLEOF'
# Skill: New Feature

## Trigger
When the user says "newfeature [description]" or "new feature [description]".

## Steps

### Phase 1: Alignment
1. Ask the user: "What feature would you like to build?"
2. After receiving the description, ask up to 10 clarifying questions — one at a time — to reach near-100% shared understanding of what they want built. Cover scope, behavior, edge cases, UI/UX expectations, and any integration points.
3. After each answer, decide if another question is needed or if alignment is sufficient. Stop early if fully aligned before 10 questions.
4. Summarize the agreed spec before moving to implementation.

### Phase 2: Implementation
5. Create a feature branch: `git checkout -b feature/[short-name]`.
6. Implement the feature based on the aligned spec.
7. Follow existing UI/UX patterns in the project if applicable.
8. Build and verify: `docker compose build && docker compose up -d`.
9. Stage and commit with a concise, imperative message.
10. Push the branch: `git push -u origin feature/[short-name]`.
11. Update `memory-sessions.md` with what was built.
SKILLEOF
  echo "  Created $SKILLS_DIR/newfeature.md"
fi

# Write the hook script (always overwrite to pick up updates)
cat > "$HOOK_SCRIPT" << 'HOOKEOF'
#!/bin/bash
# Stop hook: remind Claude to update memory files if code was changed but memory wasn't

# Find the project root via git
DIR="$(git -C "$(dirname "$0")" rev-parse --show-toplevel 2>/dev/null)" || exit 0
cd "$DIR" || exit 0

# Get list of modified/new files (staged + unstaged)
# Handle empty repos where HEAD doesn't exist yet
changed=$(git diff --name-only HEAD 2>/dev/null || git diff --name-only --cached 2>/dev/null; git diff --name-only 2>/dev/null; git ls-files --others --exclude-standard 2>/dev/null)

# Were any non-memory files changed? (code, config, etc.)
code_changed=$(echo "$changed" | grep -v '^\.claude/rules/memory-' | grep -v '^$' | head -1)

# Were memory files updated?
memory_changed=$(echo "$changed" | grep '^\.claude/rules/memory-' | head -1)

if [ -n "$code_changed" ] && [ -z "$memory_changed" ]; then
  echo "MEMORY UPDATE REQUIRED: Code was changed but memory files were not updated. Update .claude/rules/memory-sessions.md (and memory-decisions.md if applicable) NOW before continuing." >&2
  exit 2
fi
HOOKEOF

chmod +x "$HOOK_SCRIPT"
echo "  Created $HOOK_SCRIPT"

# Build the hook config using portable $CLAUDE_PROJECT_DIR
HOOK_CMD="\$CLAUDE_PROJECT_DIR/.claude/hooks/check-memory.sh"

# Add hook to settings.local.json
if [ -f "$SETTINGS" ]; then
  # Settings file exists — check if hook is already registered
  if grep -q "check-memory.sh" "$SETTINGS" 2>/dev/null; then
    # Update the existing command path to use portable variable
    PYTHON_CMD=$(command -v python3 || command -v python) || { echo "Error: Python is required but not found."; exit 1; }
    "$PYTHON_CMD" -c "
import json, sys

settings_path = sys.argv[1]
hook_cmd = sys.argv[2]

with open(settings_path) as f:
    cfg = json.load(f)

# Walk through all hook events and update any check-memory.sh references
for event, entries in cfg.get('hooks', {}).items():
    for entry in entries:
        for hook in entry.get('hooks', []):
            if 'check-memory.sh' in hook.get('command', ''):
                hook['command'] = hook_cmd

with open(settings_path, 'w') as f:
    json.dump(cfg, f, indent=2)
    f.write('\n')
" "$SETTINGS" "$HOOK_CMD"
    echo "  Updated hook path in settings.local.json"
  else
    # Merge new hook into existing settings
    PYTHON_CMD=$(command -v python3 || command -v python) || { echo "Error: Python is required but not found."; exit 1; }
    "$PYTHON_CMD" -c "
import json, sys

settings_path = sys.argv[1]
hook_cmd = sys.argv[2]

with open(settings_path) as f:
    cfg = json.load(f)

cfg.setdefault('hooks', {}).setdefault('Stop', []).append({
    'matcher': '',
    'hooks': [{'type': 'command', 'command': hook_cmd}]
})

with open(settings_path, 'w') as f:
    json.dump(cfg, f, indent=2)
    f.write('\n')
" "$SETTINGS" "$HOOK_CMD"
    echo "  Added hook to existing settings.local.json"
  fi
else
  # Create new settings file with portable path
  cat > "$SETTINGS" << 'SETEOF'
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/check-memory.sh"
          }
        ]
      }
    ]
  }
}
SETEOF
  echo "  Created $SETTINGS with hook config"
fi

echo ""
echo "Done. Memory hook is active for $PROJECT"
echo "  Hook script: $HOOK_SCRIPT"
echo "  Settings:    $SETTINGS"
echo "  Skills:      $SKILLS_DIR/"
