param(
    [switch]$Apply,
    [switch]$Yes,
    [switch]$CleanOnly,
    [string]$SourceGrassPath = "F:\Modding\Skyrim\Ancestries\overwrite\grass",
    [string]$DestinationModPath = "F:\Modding\Skyrim\Ancestries\mods\Grass Cache Output"
)

function Get-EntryCount {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return 0
    }

    return @(Get-ChildItem -LiteralPath $Path -Force).Count
}

function Assert-SafeDirectory {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw "directory does not exist: $Path"
    }

    $resolved = (Resolve-Path -LiteralPath $Path).Path
    $root = [System.IO.Path]::GetPathRoot($resolved)

    if ($resolved.TrimEnd("\") -eq $root.TrimEnd("\")) {
        throw "refusing to operate on filesystem root: $resolved"
    }

    return $resolved
}

function Remove-DirectoryIfPresent {
    param(
        [string]$Path,
        [string]$ExpectedParent
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    $resolved = Assert-SafeDirectory $Path
    $parentResolved = Assert-SafeDirectory $ExpectedParent
    $parentPrefix = $parentResolved.TrimEnd("\") + "\"

    if (-not $resolved.StartsWith($parentPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "refusing to remove path outside expected parent: $resolved"
    }

    Remove-Item -LiteralPath $resolved -Recurse -Force
}

function Copy-GrassFolder {
    param(
        [string]$Source,
        [string]$Destination
    )

    $sourceResolved = Assert-SafeDirectory $Source
    $destinationParent = Split-Path -Path $Destination -Parent
    $destinationParentResolved = Assert-SafeDirectory $destinationParent
    $destinationResolved = Join-Path $destinationParentResolved (Split-Path -Path $Destination -Leaf)

    Copy-Item -LiteralPath $sourceResolved -Destination $destinationResolved -Recurse -Force
}

if ($Yes -and -not $Apply) {
    Write-Host "-Yes is only valid with -Apply."
    Write-Host "No files changed."
    exit 1
}

$destinationGrassPath = Join-Path $DestinationModPath "grass"

if ($Apply) {
    Write-Host "Grass Cache Output Copy"
} else {
    Write-Host "Grass Cache Output Copy Preview"
}
Write-Host ""

$blocked = @()

if (-not (Test-Path -LiteralPath $SourceGrassPath -PathType Container)) {
    $blocked += "source grass directory does not exist"
}

if (-not (Test-Path -LiteralPath $DestinationModPath -PathType Container)) {
    $blocked += "destination mod directory does not exist"
}

$sourceEntries = Get-EntryCount $SourceGrassPath
$destinationEntries = Get-EntryCount $destinationGrassPath

Write-Host "SOURCE"
Write-Host "  $SourceGrassPath"
Write-Host "  Entries: $sourceEntries"
Write-Host ""

Write-Host "DESTINATION"
Write-Host "  $destinationGrassPath"
Write-Host "  Entries before action: $destinationEntries"
Write-Host ""

Write-Host "ACTION"
Write-Host "  Remove destination grass folder"
if (-not $CleanOnly) {
    Write-Host "  Copy source grass folder to destination mod"
    Write-Host "  Remove source grass folder after successful copy"
}
Write-Host ""

if (-not $CleanOnly -and (Test-Path -LiteralPath $SourceGrassPath -PathType Container) -and $sourceEntries -eq 0) {
    $blocked += "source grass directory is empty"
}

if ($blocked.Count -gt 0) {
    Write-Host "BLOCKED"
    foreach ($reason in $blocked) {
        Write-Host "  Reason: $reason"
    }
    Write-Host ""
    Write-Host "No files changed."
    exit 1
}

if (-not $Apply) {
    Write-Host "No files changed."
    exit 0
}

if (-not $Yes) {
    Write-Host -NoNewline "Apply these changes? [y/N]: "
    $answer = [Console]::In.ReadLine()

    if ($answer -notmatch '^(?i:y|yes)$') {
        Write-Host ""
        Write-Host "Cancelled. No files changed."
        exit 0
    }
    Write-Host ""
}

try {
    Remove-DirectoryIfPresent -Path $destinationGrassPath -ExpectedParent $DestinationModPath

    if (-not $CleanOnly) {
        Copy-GrassFolder -Source $SourceGrassPath -Destination $destinationGrassPath
        Remove-DirectoryIfPresent -Path $SourceGrassPath -ExpectedParent (Split-Path -Path $SourceGrassPath -Parent)
    }

    $finalEntries = Get-EntryCount $destinationGrassPath

    Write-Host "DONE"
    if ($CleanOnly) {
        Write-Host "  Destination grass folder removed."
    } else {
        Write-Host "  Destination grass folder refreshed."
        Write-Host "  Source grass folder removed."
    }
    Write-Host "  Entries after action: $finalEntries"
} catch {
    Write-Host "FAILED"
    Write-Host "  Reason: $($_.Exception.Message)"
    exit 1
}
