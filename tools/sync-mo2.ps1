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

Write-Host "MO2 state synchronized."
