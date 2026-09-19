# Skyrim Ancestries

This repository documents my Skyrim mod list.

## Source of truth

The live Mod Organizer 2 installation is authoritative.

`state/modlist.txt`, `state/plugins.txt`, `state/loadorder.txt`,
`state/comments-notes.md`, and `state/project-status.md` are synchronized
snapshots of MO2 state.
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
For mod entries within a section or sub-section, mirror the MO2 left-pane order;
do not use right-pane plugin order. If `state/modlist.txt` presents a group in
bottom-to-top order before its separator, reverse that group for README output.

Do not invent test results, compatibility conclusions or configuration choices.

Do not mark something as tested unless I explicitly say that I tested it.

Metadata tags in MO2 mod names are intentional searchable metadata, not part of
the mod's actual title. Preserve them in synchronized state; do not remove or
rename them.

- `[SKSE]` means an SKSE-based or SKSE-requiring mod.
- `[FOMOD]` means the mod has a FOMOD installer with selectable options or patches.
- `[O]` means a generated-output or override-container mod. Treat these as
  implementation/maintenance containers, not normal user-facing mods.
- `[SkyPatcher]` Skypatcher mod
- `[DEV]` mod being developed
- `[H]` mod has files that has been set to hidden
- `[LODS]` DynDoLod meshes

Near the top of `README.md`, maintain a concise generated summary block:

- `## Being Developed` lists enabled non-`[O]` mods tagged `[DEV]`.
- `## Patches Created` lists enabled non-`[O]` mods whose MO2 Comments field
  contains `[PATCH]` (case-insensitive).

If a listed mod has an MO2 comment, include it after the mod name as inline
code. Treat `[PATCH]` as hidden metadata: remove the marker from all README
output. If nothing remains after removing it, show only the mod name. Preserve
visible metadata tags such as `[SkyPatcher]` and `[DEV]` in this summary.

For `[O]` mods:

- do not list them in the main README mod list unless explicitly asked;
- do not infer gameplay functionality from them;
- they may still be mentioned in the diary when created, rebuilt, or relevant to troubleshooting.

As an explicit exception, list enabled `[O]` mods under the `970 LODs`
`Pre-LOD Generated Patches` subsection. Continue to omit disabled entries.

When referring to the actual mod name in prose, metadata tags may be omitted
unless they are relevant.

During sync, export only non-empty MO2 `comments` and `notes` fields from
installed mod `meta.ini` files into `state/comments-notes.md`. Do not export
Nexus descriptions or unrelated metadata. README entries may include these when
present: treat comments as concise mod context and notes as
installation/technical reminders. Preserve uncertainty and intent from the
original notes; do not embellish or invent details. Blank fields should produce
no README output. Format README comment/note values as inline code.
If MO2 rich-text notes contain links, render those links as normal Markdown
links in `README.md` while preserving the note's intent.

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

Overwrite routing must use explicit approved mappings only. Unknown or ambiguous
MO2 overwrite contents must never be moved automatically.

Use `tools/copy-xlodgen-terrain-output.ps1` for xLODGen terrain output copying.
It copies `F:\Modding\Tools\xLODGen\OUTPUT` into the existing
`xLODGen Terrain Output - Baseline v1` MO2 mod. The destination must be emptied
before copying so old and new generated files are not mixed. After a successful
copy, the xLODGen source output folder is emptied so it is clean for the next
run.

Use `tools/copy-grass-cache-output.ps1` for grass cache output copying. It
copies `F:\Modding\Skyrim\Ancestries\overwrite\grass` into the existing
`Grass Cache Output` MO2 mod, replacing that mod's existing `grass` folder
first. Remove the source overwrite `grass` folder only after the copy succeeds.

Use `tools/copy-dyndolod-output.ps1` for DynDOLOD and TexGen output copying.
It copies the generated output into the existing baseline output MO2 mods:
`F:\Modding\Tools\DynDOLOD\DynDOLOD\DynDOLOD_Output` to
`DynDOLOD Output - Baseline v1`, and
`F:\Modding\Tools\DynDOLOD\TexGen_Output` to `TexGen Output - Baseline v1`.
The destination output mod must be emptied before copying so old and new
generated files are not mixed. The DynDOLOD and TexGen clean tasks empty the
generated output source folders so they are clean for the next run, not the MO2
output mods.

Use `tools/toggle-dyndolod-patches.ps1` to toggle `Synthesis.esp` and
`Bashed Patch, 0.esp` together between their normal names and MO2's
`.mohidden` names before and after DynDOLOD generation. Mixed or missing states
must block the toggle without changing either plugin.

## Testing and issue tracking

`Skyrim Ancestries - Testing & Issues` is a special MO2 placeholder mod used
for project status tracking. It is not a gameplay mod.
Do not list it as a normal README mod or include it in the listed mod count.

Its MO2 Notes field may contain these headings:

- `[CRITICAL]`
- `[TEST]`
- `[BROKEN]`
- `[TODO]`
- `[NOTE]`

During sync, preserve these notes in `state/comments-notes.md`.
During sync, also decode this exact mod's MO2 Qt rich-text HTML Notes field into
plain paragraph lines, parse the headings above, and write the structured result
to `state/project-status.md`.

Empty status categories are omitted from `state/project-status.md`. If all five
categories are empty, write `No active project status entries.` The sync process
also regenerates a managed project-status block near the top of `README.md` with
readable headings for populated categories, so removed MO2 status entries do not
remain stale.

Do not invent, reclassify, resolve or remove entries unless explicitly asked.
