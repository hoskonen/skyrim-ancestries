# Skyrim Ancestries

This repository documents my Skyrim mod list.

## Source of truth

The live Mod Organizer 2 installation is authoritative.

`state/modlist.txt`, `state/plugins.txt`, `state/loadorder.txt`, and
`state/comments-notes.md` are synchronized snapshots of MO2 state.
Do not modify them unless explicitly asked.

## Documentation

Maintain:

- `README.md` — repository front page and human-readable overview of the installed mod list.
- `docs/diary.md` — chronological record of changes, testing and observations.

When I tell you that I installed, removed, configured or tested something,
update the appropriate documentation.

Use information from `state/modlist.txt` when checking which mods are installed.

Organize installed mods in `README.md` to mirror the actual MO2 left-pane
section order from `state/modlist.txt`. Main separators use whole numeric IDs
such as `800`, `850`, and `900`.

Sub-separators use hierarchical IDs such as `850.1` and belong under the main
separator sharing the number before the decimal. Render sub-separators in
`README.md` as collapsed `<details>` sections with a `<summary>`, underneath
their parent main section. For example, `850 ANIMATION` with
`850.1 Animation Tools` should render as `## 850 Animation`, then:

`<details>`
`<summary><strong>850.1 Animation Tools</strong></summary>`

Do not collapse main sections or turn sub-separators into independent top-level
README sections.

Mods between separators belong to the currently active main/sub-section
according to `state/modlist.txt`. Preserve MO2 ordering in `README.md`.

Do not invent test results, compatibility conclusions or configuration choices.

Do not mark something as tested unless I explicitly say that I tested it.

Metadata tags in MO2 mod names are intentional searchable metadata, not part of
the mod's actual title. Preserve them in synchronized state; do not remove or
rename them.

- `[SKSE]` means an SKSE-based or SKSE-requiring mod.
- `[FOMOD]` means the mod has a FOMOD installer with selectable options or patches.
- `[O]` means a generated-output or override-container mod. Treat these as
  implementation/maintenance containers, not normal user-facing mods.
- `[C]` custom made patch, should be visible always

For `[O]` mods:
- do not list them in the main README mod list unless explicitly asked;
- do not infer gameplay functionality from them;
- they may still be mentioned in the diary when created, rebuilt, or relevant to troubleshooting.

When referring to the actual mod name in prose, metadata tags may be omitted
unless they are relevant.

During sync, export only non-empty MO2 `comments` and `notes` fields from
installed mod `meta.ini` files into `state/comments-notes.md`. Do not export
Nexus descriptions or unrelated metadata. README entries may include these when
present: treat comments as concise mod context and notes as
installation/technical reminders. Preserve uncertainty and intent from the
original notes; do not embellish or invent details. Blank fields should produce
no README output. Format README comment/note values as inline code.

## Style

Keep documentation concise and practical.

Do not turn routine mod installations into lengthy descriptions.

When asked to "sync", "update" always keep README.md and Diary.md in sync, especially important that diary has exact dates of the edits listed.

## Conventions

When syncing, update `state/modlist.txt`, `state/plugins.txt`,
`state/loadorder.txt`, `state/comments-notes.md`, `README.md`, and
`docs/diary.md`.
Diary date headings may include the enabled listed mod count.
Exclude `[O]`, separators, DLC lines, and Creation Club detail lines from that count.

## Git

Prefer small commits representing logical changes to the mod list.

## Tools
When I ask to sync or refresh the MO2 state, run `tools/sync-mo2.ps1`.
