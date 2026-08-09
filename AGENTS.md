# Skyrim Ancestries

This repository documents my Skyrim mod list.

## Source of truth

The live Mod Organizer 2 installation is authoritative.

Files under `state/` are synchronized snapshots of MO2 state.
Do not modify them unless explicitly asked.

## Documentation

Maintain:

- `docs/diary.md` — chronological record of changes, testing and observations.
- `docs/mods.md` — human-readable overview of the installed mod list.

When I tell you that I installed, removed, configured or tested something,
update the appropriate documentation.

Use information from `state/modlist.txt` when checking which mods are installed.

Do not invent test results, compatibility conclusions or configuration choices.

Do not mark something as tested unless I explicitly say that I tested it.

## Style

Keep documentation concise and practical.

Do not turn routine mod installations into lengthy descriptions.

## Git

Prefer small commits representing logical changes to the mod list.

## Tools
When I ask to sync or refresh the MO2 state, run `tools/sync-mo2.ps1`.