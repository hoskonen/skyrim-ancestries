$ErrorActionPreference = "Stop"

$plugins = @(
    [pscustomobject]@{
        Name = "Synthesis.esp"
        VisiblePath = "F:\Modding\Skyrim\Ancestries\mods\Synthesis Builds [O]\Synthesis.esp"
    },
    [pscustomobject]@{
        Name = "Bashed Patch, 0.esp"
        VisiblePath = "F:\Modding\Skyrim\Ancestries\overwrite\Bashed Patch, 0.esp"
    }
)

Write-Host "DynDOLOD Patch Plugin Toggle"
Write-Host ""

$states = foreach ($plugin in $plugins) {
    $hiddenPath = "$($plugin.VisiblePath).mohidden"
    $visibleExists = Test-Path -LiteralPath $plugin.VisiblePath -PathType Leaf
    $hiddenExists = Test-Path -LiteralPath $hiddenPath -PathType Leaf

    if ($visibleExists -and $hiddenExists) {
        Write-Host "BLOCKED"
        Write-Host "  $($plugin.Name)"
        Write-Host "  Reason: both visible and hidden files exist"
        exit 1
    }

    if (-not $visibleExists -and -not $hiddenExists) {
        Write-Host "BLOCKED"
        Write-Host "  $($plugin.Name)"
        Write-Host "  Reason: neither visible nor hidden file exists"
        exit 1
    }

    [pscustomobject]@{
        Name = $plugin.Name
        VisiblePath = $plugin.VisiblePath
        HiddenPath = $hiddenPath
        State = if ($visibleExists) { "Visible" } else { "Hidden" }
    }
}

$currentStates = @($states | Select-Object -ExpandProperty State -Unique)
if ($currentStates.Count -ne 1) {
    Write-Host "BLOCKED"
    Write-Host "  Plugin states are mixed. No files changed."
    foreach ($state in $states) {
        Write-Host "  $($state.Name): $($state.State)"
    }
    exit 1
}

$hide = $currentStates[0] -eq "Visible"
$action = if ($hide) { "HIDE" } else { "RESTORE" }
$completed = @()

Write-Host $action
foreach ($state in $states) {
    $source = if ($hide) { $state.VisiblePath } else { $state.HiddenPath }
    $destination = if ($hide) { $state.HiddenPath } else { $state.VisiblePath }
    Write-Host "  $([System.IO.Path]::GetFileName($source)) -> $([System.IO.Path]::GetFileName($destination))"
}
Write-Host ""

try {
    foreach ($state in $states) {
        $source = if ($hide) { $state.VisiblePath } else { $state.HiddenPath }
        $destination = if ($hide) { $state.HiddenPath } else { $state.VisiblePath }
        Move-Item -LiteralPath $source -Destination $destination
        $completed += [pscustomobject]@{
            Source = $source
            Destination = $destination
        }
    }
} catch {
    Write-Host "FAILED"
    Write-Host "  $($_.Exception.Message)"
    Write-Host "  Rolling back completed changes."

    for ($index = $completed.Count - 1; $index -ge 0; $index--) {
        $change = $completed[$index]
        if (Test-Path -LiteralPath $change.Destination -PathType Leaf) {
            try {
                Move-Item -LiteralPath $change.Destination -Destination $change.Source
            } catch {
                Write-Host "  Rollback failed: $($_.Exception.Message)"
            }
        }
    }
    exit 1
}

$finalState = if ($hide) { "hidden" } else { "visible" }
Write-Host "Completed. Both plugins are now $finalState."
