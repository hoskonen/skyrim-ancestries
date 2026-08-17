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
