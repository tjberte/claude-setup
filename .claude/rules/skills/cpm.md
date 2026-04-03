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
