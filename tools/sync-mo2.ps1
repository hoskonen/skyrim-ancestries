$mo2Profile = "F:\Modding\Skyrim\Ancestries\profiles\Default"
$mo2Mods = "F:\Modding\Skyrim\Ancestries\mods"
$repo = "F:\Modding\Skyrim\ancestries-codex"

Copy-Item `
    "$mo2Profile\modlist.txt" `
    "$repo\state\modlist.txt" `
    -Force

Copy-Item `
    "$mo2Profile\plugins.txt" `
    "$repo\state\plugins.txt" `
    -Force

Copy-Item `
    "$mo2Profile\loadorder.txt" `
    "$repo\state\loadorder.txt" `
    -Force

$metadata = @("# MO2 Comments and Notes", "")
$commentsByMod = @{}

Get-Content "$repo\state\modlist.txt" | ForEach-Object {
    if (-not $_.StartsWith("+")) {
        return
    }

    $modName = $_.Substring(1)
    $metaPath = Join-Path (Join-Path $mo2Mods $modName) "meta.ini"

    if (-not (Test-Path -LiteralPath $metaPath)) {
        return
    }

    $comments = ""
    $notes = ""

    Get-Content -LiteralPath $metaPath | ForEach-Object {
        if ($_ -match "^comments=(.*)$") {
            $comments = $Matches[1].Trim()
        } elseif ($_ -match "^notes=(.*)$") {
            $notes = $Matches[1].Trim()
        }
    }

    if ($comments -or $notes) {
        $metadata += "## $modName"

        if ($comments) {
            $commentsByMod[$modName] = $comments

            $metadata += ""
            $metadata += "- Comments: $comments"
        }

        if ($notes) {
            $metadata += ""
            $metadata += "- Notes: $notes"
        }

        $metadata += ""
    }
}

$metadata | Set-Content "$repo\state\comments-notes.md" -Encoding UTF8

function Get-ReadmeModName {
    param([string]$ModName)

    return ($ModName -replace '\s+\[(?:SKSE|FOMOD|O)\]', '').Trim()
}

function Get-InlineCode {
    param([string]$Value)

    $text = $Value.Trim()

    if ($text.StartsWith('"') -and $text.EndsWith('"')) {
        $text = $text.Substring(1, $text.Length - 2)
    }

    $text = $text -replace '\\n', ' '
    $text = $text -replace '\\"', '"'
    $text = $text -replace '`', '``'

    return "``$text``"
}

function Get-TopListItem {
    param([string]$ModName)

    $displayName = Get-ReadmeModName $ModName

    if ($commentsByMod.ContainsKey($ModName)) {
        return "- $displayName`: $(Get-InlineCode $commentsByMod[$ModName])"
    }

    return "- $displayName"
}

$enabledMods = @()

Get-Content "$repo\state\modlist.txt" | ForEach-Object {
    if ($_.StartsWith("+")) {
        $enabledMods += $_.Substring(1)
    }
}

$developingMods = @($enabledMods | Where-Object {
    $_ -match '\[DEV\]' -and $_ -notmatch '\[O\]'
})
$patchMods = @($enabledMods | Where-Object {
    $_ -match '\[C\]' -and $_ -notmatch '\[O\]'
})

$statusModName = "Skyrim Ancestries - Testing & Issues"
$statusMetaPath = Join-Path (Join-Path $mo2Mods $statusModName) "meta.ini"
$statusCategories = @("[CRITICAL]", "[TEST]", "[BROKEN]", "[TODO]", "[NOTE]")
$status = [ordered]@{}

$statusCategories | ForEach-Object {
    $status[$_] = @()
}

if (Test-Path -LiteralPath $statusMetaPath) {
    $rawNotes = ""

    Get-Content -LiteralPath $statusMetaPath | ForEach-Object {
        if ($_ -match "^notes=(.*)$") {
            $rawNotes = $Matches[1].Trim()
        }
    }

    if ($rawNotes.StartsWith('"') -and $rawNotes.EndsWith('"')) {
        $rawNotes = $rawNotes.Substring(1, $rawNotes.Length - 2)
    }

    $html = $rawNotes `
        -replace '\\n', "`n" `
        -replace '\\"', '"'

    $paragraphs = @()
    $matches = [regex]::Matches(
        $html,
        '<p\b[^>]*>(.*?)</p>',
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
            [System.Text.RegularExpressions.RegexOptions]::Singleline
    )

    foreach ($match in $matches) {
        $text = $match.Groups[1].Value -replace '<[^>]+>', ''
        $text = [System.Net.WebUtility]::HtmlDecode($text).Trim()

        if ($text) {
            $paragraphs += $text
        }
    }

    $currentCategory = $null

    foreach ($paragraph in $paragraphs) {
        if ($statusCategories -contains $paragraph) {
            $currentCategory = $paragraph
            continue
        }

        if ($paragraph -match '^(\[(?:CRITICAL|TEST|BROKEN|TODO|NOTE)\])\s*(.*)$') {
            $currentCategory = $Matches[1]
            $item = $Matches[2].Trim() -replace '^-+\s*', ''

            if ($item) {
                $status[$currentCategory] += $item
            }

            continue
        }

        if ($currentCategory) {
            $status[$currentCategory] += ($paragraph -replace '^-+\s*', '')
        }
    }
}

$hasStatus = $false

foreach ($category in $statusCategories) {
    if ($status[$category].Count -gt 0) {
        $hasStatus = $true
        break
    }
}

$statusOutput = @("# Skyrim Ancestries - Testing & Issues", "")

if ($hasStatus) {
    foreach ($category in $statusCategories) {
        if ($status[$category].Count -eq 0) {
            continue
        }

        $statusOutput += "## $category"
        $statusOutput += ""

        foreach ($item in $status[$category]) {
            $statusOutput += "- $item"
        }

        $statusOutput += ""
    }
} else {
    $statusOutput += "No active project status entries."
    $statusOutput += ""
}

$statusOutput | Set-Content "$repo\state\project-status.md" -Encoding UTF8

$readmePath = "$repo\README.md"
$readme = Get-Content $readmePath

$overviewReadme = @(
    "<!-- mod-development:start -->",
    "## Being Developed",
    ""
)

if ($developingMods.Count -gt 0) {
    foreach ($modName in $developingMods) {
        $overviewReadme += Get-TopListItem $modName
    }
} else {
    $overviewReadme += "- None"
}

$overviewReadme += ""
$overviewReadme += "## Patches Created"
$overviewReadme += ""

if ($patchMods.Count -gt 0) {
    foreach ($modName in $patchMods) {
        $overviewReadme += Get-TopListItem $modName
    }
} else {
    $overviewReadme += "- None"
}

$overviewReadme += ""
$overviewReadme += "<!-- mod-development:end -->"

$overviewStart = [Array]::IndexOf($readme, "<!-- mod-development:start -->")
$overviewEnd = [Array]::IndexOf($readme, "<!-- mod-development:end -->")

if ($overviewStart -ge 0 -and $overviewEnd -ge $overviewStart) {
    $before = @()
    $after = @()

    if ($overviewStart -gt 0) {
        $before = @($readme[0..($overviewStart - 1)])
    }

    if ($overviewEnd -lt ($readme.Count - 1)) {
        $after = @($readme[($overviewEnd + 1)..($readme.Count - 1)])
    }

    $readme = $before + $overviewReadme + $after
} else {
    $metricStart = [Array]::IndexOf($readme, "| Metric | Value |")
    $metricEnd = $metricStart

    if ($metricStart -ge 0) {
        while ($metricEnd -lt $readme.Count -and $readme[$metricEnd].Trim()) {
            $metricEnd++
        }

        $before = @()
        $after = @()

        if ($metricStart -gt 0) {
            $before = @($readme[0..($metricStart - 1)])
        }

        if ($metricEnd -lt ($readme.Count - 1)) {
            $after = @($readme[($metricEnd + 1)..($readme.Count - 1)])
        }

        $readme = $before + $overviewReadme + "" + $after
    }
}

$statusReadme = @(
    "<!-- project-status:start -->",
    "## Project Status",
    ""
)
$statusNames = @{
    "[CRITICAL]" = "Critical"
    "[TEST]" = "Testing"
    "[BROKEN]" = "Broken"
    "[TODO]" = "Todo"
    "[NOTE]" = "Notes"
}

if ($hasStatus) {
    foreach ($category in $statusCategories) {
        if ($status[$category].Count -eq 0) {
            continue
        }

        $statusReadme += "### $($statusNames[$category])"
        $statusReadme += ""

        foreach ($item in $status[$category]) {
            $statusReadme += "- $item"
        }

        $statusReadme += ""
    }
} else {
    $statusReadme += "No active project status entries."
    $statusReadme += ""
}

$statusReadme += "<!-- project-status:end -->"

$start = [Array]::IndexOf($readme, "<!-- project-status:start -->")
$end = [Array]::IndexOf($readme, "<!-- project-status:end -->")

if ($start -ge 0 -and $end -ge $start) {
    $before = @()
    $after = @()

    if ($start -gt 0) {
        $before = @($readme[0..($start - 1)])
    }

    if ($end -lt ($readme.Count - 1)) {
        $after = @($readme[($end + 1)..($readme.Count - 1)])
    }

    $readme = $before + $statusReadme + $after
} else {
    $insertAt = [Array]::IndexOf($readme, "| Metric | Value |")

    if ($insertAt -lt 0) {
        $insertAt = 4
    }

    $before = @()
    $after = @()

    if ($insertAt -gt 0) {
        $before = @($readme[0..($insertAt - 1)])
    }

    if ($insertAt -le ($readme.Count - 1)) {
        $after = @($readme[$insertAt..($readme.Count - 1)])
    }

    $readme = $before + $statusReadme + "" + $after
}

$readme | Set-Content $readmePath -Encoding UTF8

Write-Host "MO2 state synchronized."
