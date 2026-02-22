# neov-skills

Personal Claude Code plugin marketplace.

## Usage

### Register Marketplace

```bash
/plugin marketplace add imneov/neov-skills
```

### Install Plugin

```bash
/plugin install neov-skills@neov-skills
```

### Local Development

```bash
claude --plugin-dir ./plugins/neov-skills
```

## Repository Structure

```
neov-skills/
├── .claude-plugin/
│   └── marketplace.json           # Marketplace catalog
├── plugins/
│   └── neov-skills/                 # Plugin: neov-skills
│       ├── .claude-plugin/
│       │   └── plugin.json        # Plugin manifest
│       ├── skills/                # Skill definitions
│       │   └── example/
│       │       └── SKILL.md
│       ├── commands/              # Slash commands
│       ├── agents/                # Agent definitions
│       └── hooks/                 # Hook configurations
└── README.md
```

## Adding a New Skill

1. Create directory `plugins/neov-skills/skills/<skill-name>/`
2. Add `SKILL.md` with YAML frontmatter and instructions
3. Bump `version` in `plugins/neov-skills/.claude-plugin/plugin.json`

## Adding a New Plugin

1. Create directory `plugins/<plugin-name>/.claude-plugin/`
2. Add `plugin.json` manifest
3. Add entry to `.claude-plugin/marketplace.json` in `plugins` array

## License

MIT
