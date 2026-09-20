# Working on SafeSpend

## Living app map

The user wants a persistent map of the app that stays current as tasks finish.

- Read [docs/APP_MAP.md](docs/APP_MAP.md) before starting an app task. Verify the relevant code; the map is a guide, not a substitute for the source.
- Before closing any task that adds, changes, removes, or discovers app behavior, update the affected map sections in the same task. This includes screens, navigation, financial rules, models, integrations, storage, settings, localization, shared UI, and testing.
- Update the map's `Last updated` date and append a concise task-history entry: date, outcome, affected areas/files, and actual validation results or limitations. Never claim tests passed unless they ran.
- Describe the current app in the main map. Replace stale statements instead of only appending corrections. Distinguish implemented code, reachable UI, scaffolding, and verified runtime behavior.
- For a task with no app impact or new app knowledge, no map edit is needed. Avoid duplicate entries for unchanged work.
- Maintain relative file links when files move. Never include credentials, personal financial records, or private user data.
- Mention the map update briefly in the final response when it changed. Updating it is part of completing the task and needs no separate permission.

## Existing work

Preserve unrelated working-tree changes. The map may describe uncommitted code; do not imply that code is committed, deployed, or tested merely because it exists locally.
