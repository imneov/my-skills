---
name: example
description: An example skill demonstrating the plugin structure. Use this as a template to create your own skills.
user-invocable: true
---

# Example Skill

This is a template skill. Replace this content with your own skill instructions.

## How to Create a New Skill

1. Create a new directory under `skills/` with your skill name
2. Add a `SKILL.md` file with YAML frontmatter and instructions
3. Update the plugin version in `plugin.json` if distributing

## Frontmatter Reference

Common fields:
- `name` - Skill identifier (defaults to directory name)
- `description` - When Claude should use this skill
- `user-invocable` - Whether users can invoke via `/` menu (default: true)
- `allowed-tools` - Tools Claude can use freely (e.g., `Read, Grep, Glob`)
- `model` - Model override (e.g., `claude-opus-4-6`)
- `context` - `inline` (default) or `fork` (runs as subagent)

## Arguments

Use `$ARGUMENTS` to access all arguments passed to the skill.
Use `$0`, `$1`, etc. for specific positional arguments.
