param(
    [switch]$Apply,
    [switch]$Yes,
    [switch]$CleanOnly,
    [string]$SourcePath = "F:\Modding\Tools\xLODGen\OUTPUT",
    [string]$DestinationPath = "F:\Modding\Skyrim\Ancestries\mods\xLODGen Terrain Output - Baseline v1"
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

function Clear-DirectoryContents {
    param([string]$Path)

    $resolved = Assert-SafeDirectory $Path
    $children = @(Get-ChildItem -LiteralPath $resolved -Force)

    foreach ($child in $children) {
        if (-not $child.FullName.StartsWith($resolved.TrimEnd("\") + "\", [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "refusing to remove path outside destination: $($child.FullName)"
        }
    }

    foreach ($child in $children) {
        Remove-Item -LiteralPath $child.FullName -Recurse -Force
    }
}

function Copy-DirectoryContents {
    param(
        [string]$Source,
        [string]$Destination
    )

    $sourceResolved = Assert-SafeDirectory $Source
    $destinationResolved = Assert-SafeDirectory $Destination
    $files = @(Get-ChildItem -LiteralPath $sourceResolved -File -Recurse -Force)

    foreach ($file in $files) {
        $relativePath = $file.FullName.Substring($sourceResolved.Length).TrimStart("\", "/")
        $target = Join-Path $destinationResolved $relativePath
        $targetDirectory = Split-Path -Path $target -Parent

        New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null
        Copy-Item -LiteralPath $file.FullName -Destination $target -Force
    }
}

if ($Yes -and -not $Apply) {
    Write-Host "-Yes is only valid with -Apply."
    Write-Host "No files changed."
    exit 1
}

if ($Apply) {
    Write-Host "xLODGen Terrain Output Copy"
} else {
    Write-Host "xLODGen Terrain Output Copy Preview"
}
Write-Host ""

$blocked = @()

if (-not (Test-Path -LiteralPath $SourcePath -PathType Container)) {
    $blocked += "source directory does not exist"
}

if (-not (Test-Path -LiteralPath $DestinationPath -PathType Container)) {
    $blocked += "destination mod directory does not exist"
}

$sourceEntries = Get-EntryCount $SourcePath
$destinationEntries = Get-EntryCount $DestinationPath

Write-Host "SOURCE"
Write-Host "  $SourcePath"
Write-Host "  Entries: $sourceEntries"
Write-Host ""

Write-Host "DESTINATION"
Write-Host "  $DestinationPath"
Write-Host "  Entries before copy: $destinationEntries"
Write-Host ""

if ($CleanOnly) {
    Write-Host "ACTION"
    Write-Host "  Clean destination only"
} else {
    Write-Host "ACTION"
    Write-Host "  Clean destination"
    Write-Host "  Copy source contents to destination"
    Write-Host "  Clean source after successful copy"
}
Write-Host ""

if (-not $CleanOnly -and (Test-Path -LiteralPath $SourcePath -PathType Container) -and $sourceEntries -eq 0) {
    $blocked += "source directory is empty"
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
    Clear-DirectoryContents $DestinationPath

    if (-not $CleanOnly) {
        Copy-DirectoryContents -Source $SourcePath -Destination $DestinationPath
        Clear-DirectoryContents $SourcePath
    }

    $sourceEntriesAfter = Get-EntryCount $SourcePath
    $finalEntries = Get-EntryCount $DestinationPath

    Write-Host "DONE"
    if ($CleanOnly) {
        Write-Host "  Destination cleaned."
    } else {
        Write-Host "  Destination cleaned and source contents copied."
        Write-Host "  Source cleaned."
    }
    Write-Host "  Source entries after action: $sourceEntriesAfter"
    Write-Host "  Destination entries after action: $finalEntries"
} catch {
    Write-Host "FAILED"
    Write-Host "  Reason: $($_.Exception.Message)"
    exit 1
}
