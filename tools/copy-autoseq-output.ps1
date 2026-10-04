param(
    [switch]$Apply,
    [switch]$Yes,
    [string]$SourceModPath = "F:\Modding\Skyrim\Ancestries\mods\AutoSEQ",
    [string]$DestinationModPath = "F:\Modding\Skyrim\Ancestries\mods\AutoSeq [O]"
)

$archiveName = "AutoSEQ Output.zip"
$sourceArchive = Join-Path $SourceModPath $archiveName
$destinationArchive = Join-Path $DestinationModPath $archiveName
$destinationSeq = Join-Path $DestinationModPath "Seq"

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

function Test-AutoSeqArchive {
    param([string]$Path)

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($Path)

    try {
        $fileCount = 0

        foreach ($entry in $archive.Entries) {
            $relativePath = $entry.FullName.Replace("/", "\")
            $segments = @($relativePath.Split(@("\"), [System.StringSplitOptions]::RemoveEmptyEntries))

            if ($segments.Count -eq 0) {
                continue
            }

            if ([System.IO.Path]::IsPathRooted($relativePath) -or
                $relativePath.StartsWith("\") -or
                $segments -contains "..") {
                throw "archive contains an unsafe path: $($entry.FullName)"
            }

            if ($segments[0] -cne "Seq") {
                throw "archive entry is outside the Seq folder: $($entry.FullName)"
            }

            if (-not $entry.FullName.EndsWith("/")) {
                $fileCount++
            }
        }

        if ($fileCount -eq 0) {
            throw "archive contains no files under Seq"
        }

        return $fileCount
    } finally {
        $archive.Dispose()
    }
}

if ($Yes -and -not $Apply) {
    Write-Host "-Yes is only valid with -Apply."
    Write-Host "No files changed."
    exit 1
}

if ($Apply) {
    Write-Host "AutoSEQ Output"
} else {
    Write-Host "AutoSEQ Output Preview"
}
Write-Host ""

$blocked = @()
$archiveFileCount = 0

try {
    $sourceResolved = Assert-SafeDirectory $SourceModPath
} catch {
    $blocked += $_.Exception.Message
}

try {
    $destinationResolved = Assert-SafeDirectory $DestinationModPath
} catch {
    $blocked += $_.Exception.Message
}

$archiveExists = Test-Path -LiteralPath $sourceArchive -PathType Leaf

if ($archiveExists) {
    try {
        $archiveFileCount = Test-AutoSeqArchive $sourceArchive
    } catch {
        $blocked += $_.Exception.Message
    }
}

Write-Host "SOURCE"
Write-Host "  $sourceArchive"
if ($archiveExists) {
    $archiveInfo = Get-Item -LiteralPath $sourceArchive
    Write-Host "  Found: $($archiveInfo.Length) bytes, $archiveFileCount files"
    Write-Host "  Modified: $($archiveInfo.LastWriteTime)"
} else {
    Write-Host "  No new archive found."
}
Write-Host ""

Write-Host "DESTINATION"
Write-Host "  $DestinationModPath"
if (Test-Path -LiteralPath $destinationSeq -PathType Container) {
    $existingFiles = @(Get-ChildItem -LiteralPath $destinationSeq -File -Recurse -Force).Count
    Write-Host "  Existing Seq: $existingFiles files (will be replaced)"
} else {
    Write-Host "  Existing Seq: (none)"
}
Write-Host ""

Write-Host "ACTION"
Write-Host "  Copy $archiveName to the destination mod"
Write-Host "  Extract and validate Seq"
Write-Host "  Replace the destination Seq folder"
Write-Host "  Delete both ZIP copies after success"
Write-Host ""

if ($blocked.Count -gt 0) {
    Write-Host "BLOCKED"
    foreach ($reason in $blocked) {
        Write-Host "  Reason: $reason"
    }
    Write-Host ""
    Write-Host "No files changed."
    exit 1
}

if (-not $archiveExists) {
    if ($Apply) {
        Write-Host "BLOCKED"
        Write-Host "  Reason: no new $archiveName was found"
        Write-Host ""
    } else {
        Write-Host "NO NEW OUTPUT"
    }
    Write-Host "No files changed."
    if ($Apply) { exit 1 } else { exit 0 }
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

$operationId = [Guid]::NewGuid().ToString("N")
$stagingRoot = Join-Path $destinationResolved ".autoseq-staging-$operationId"
$stagedSeq = Join-Path $stagingRoot "Seq"
$backupSeq = Join-Path $destinationResolved ".autoseq-backup-$operationId"
$oldSeqMoved = $false
$newSeqInstalled = $false

try {
    Copy-Item -LiteralPath $sourceArchive -Destination $destinationArchive -Force

    $sourceHash = (Get-FileHash -LiteralPath $sourceArchive -Algorithm SHA256).Hash
    $destinationHash = (Get-FileHash -LiteralPath $destinationArchive -Algorithm SHA256).Hash
    if ($sourceHash -ne $destinationHash) {
        throw "copied ZIP failed SHA-256 verification"
    }

    Expand-Archive -LiteralPath $destinationArchive -DestinationPath $stagingRoot

    if (-not (Test-Path -LiteralPath $stagedSeq -PathType Container)) {
        throw "extracted archive did not contain the Seq folder"
    }

    $stagedFileCount = @(Get-ChildItem -LiteralPath $stagedSeq -File -Recurse -Force).Count
    if ($stagedFileCount -ne $archiveFileCount) {
        throw "extracted file count did not match the archive"
    }

    if (Test-Path -LiteralPath $destinationSeq -PathType Container) {
        Move-Item -LiteralPath $destinationSeq -Destination $backupSeq
        $oldSeqMoved = $true
    }

    Move-Item -LiteralPath $stagedSeq -Destination $destinationSeq
    $newSeqInstalled = $true

    if (Test-Path -LiteralPath $stagingRoot) {
        Remove-Item -LiteralPath $stagingRoot -Recurse -Force
    }

    if ($oldSeqMoved -and (Test-Path -LiteralPath $backupSeq)) {
        Remove-Item -LiteralPath $backupSeq -Recurse -Force
    }

    Remove-Item -LiteralPath $destinationArchive -Force
    Remove-Item -LiteralPath $sourceArchive -Force

    Write-Host "DONE"
    Write-Host "  Installed Seq with $stagedFileCount files."
    Write-Host "  Deleted both ZIP copies."
} catch {
    if (-not $newSeqInstalled -and $oldSeqMoved -and
        -not (Test-Path -LiteralPath $destinationSeq) -and
        (Test-Path -LiteralPath $backupSeq)) {
        Move-Item -LiteralPath $backupSeq -Destination $destinationSeq
    }

    if (Test-Path -LiteralPath $stagingRoot) {
        Remove-Item -LiteralPath $stagingRoot -Recurse -Force
    }

    Write-Host "FAILED"
    Write-Host "  Reason: $($_.Exception.Message)"
    Write-Host "  The source ZIP was left in place unless installation had already completed."
    exit 1
}
