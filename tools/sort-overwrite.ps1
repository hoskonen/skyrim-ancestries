param(
    [switch]$Apply,
    [switch]$Yes,
    [string]$OverwritePath = "F:\Modding\Skyrim\Ancestries\overwrite",
    [string]$ModsPath = "F:\Modding\Skyrim\Ancestries\mods"
)

$mappings = @(
    @{
        Source = "SKSE\Plugins\IED"
        TargetMod = "IED [O]"
        TargetPath = "SKSE\Plugins\IED"
    },
    @{
        Source = "SKSE"
        TargetMod = "SKSE [O]"
        TargetPath = "SKSE"
    },
    @{
        Source = "ShaderCache"
        TargetMod = "Shader Cache [O]"
        TargetPath = "Shader Cache"
    },
    @{
        Source = "MCM"
        TargetMod = "MCM [O]"
        TargetPath = "MCM"
    },
    @{
        Source = "KiLoader"
        TargetMod = "KiLoader [O]"
        TargetPath = "KiLoader"
    },
    @{
        Source = "NL_MCM"
        TargetMod = "NL_MCM [O]"
        TargetPath = "NL_MCM"
    },
    @{
        Source = "SSEEdit Backups"
        TargetMod = "SSEEdit Backups [O]"
        TargetPath = "SSEEdit Backups"
    },
    @{
        Source = "SSEEdit Cache"
        TargetMod = "SSEEdit Backups [O]"
        TargetPath = "SSEEdit Cache"
    },
    @{
        Source = "DIP"
        TargetMod = "DIP [O]"
        TargetPath = "DIP"
    },
    @{
        Source = "interface"
        TargetMod = "DIP [O]"
        TargetPath = "DIP"
    },
    @{
        Source = "CalienteTools"
        TargetMod = "CalienteTools [O]"
        TargetPath = "CalienteTools"
    },
    @{
        Source = "Viny Mods"
        TargetMod = "Viny Mods [O]"
        TargetPath = "Viny Mods"
    }
)

$emptyDirectoryCleanupNames = @(
    "INI Tweaks",
    "ShaderCache"
)

$alwaysRemoveDirectoryNames = @(
    "Docs"
)

function Copy-MappedEntry {
    param(
        [System.IO.FileSystemInfo]$Entry,
        [hashtable]$Mapping,
        [string]$TargetModPath,
        [string[]]$ExcludedRelativePaths = @()
    )

    $targetRoot = Join-Path $TargetModPath $Mapping.TargetPath

    try {
        if (-not $Entry.PSIsContainer) {
            New-Item -ItemType Directory -Path $targetRoot -Force | Out-Null
            Copy-Item -LiteralPath $Entry.FullName -Destination (Join-Path $targetRoot $Entry.Name) -Force
            Remove-Item -LiteralPath $Entry.FullName -Force
            return $true
        }

        New-Item -ItemType Directory -Path $targetRoot -Force | Out-Null
        $files = @(Get-ChildItem -LiteralPath $Entry.FullName -File -Recurse -Force)

        foreach ($file in $files) {
            $relativePath = $file.FullName.Substring($Entry.FullName.Length).TrimStart("\", "/")

            $excluded = $false
            foreach ($excludedPath in $ExcludedRelativePaths) {
                if ($relativePath -eq $excludedPath -or $relativePath.StartsWith("$excludedPath\")) {
                    $excluded = $true
                    break
                }
            }

            if ($excluded) {
                continue
            }

            $destination = Join-Path $targetRoot $relativePath
            $destinationDirectory = Split-Path -Path $destination -Parent

            New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
            Copy-Item -LiteralPath $file.FullName -Destination $destination -Force
            Remove-Item -LiteralPath $file.FullName -Force
        }

        Get-ChildItem -LiteralPath $Entry.FullName -Directory -Recurse -Force |
            Sort-Object FullName -Descending |
            ForEach-Object {
                if (-not (Get-ChildItem -LiteralPath $_.FullName -Force)) {
                    Remove-Item -LiteralPath $_.FullName -Force
                }
            }

        if (-not (Get-ChildItem -LiteralPath $Entry.FullName -Force)) {
            Remove-Item -LiteralPath $Entry.FullName -Force
        }

        return $true
    } catch {
        Write-Error "Failed to route $($Entry.FullName): $($_.Exception.Message)"
        return $false
    }
}

if ($Yes -and -not $Apply) {
    Write-Host "-Yes is only valid with -Apply."
    Write-Host "No files changed."
    exit 1
}

if ($Apply) {
    Write-Host "MO2 Overwrite Sort"
} else {
    Write-Host "MO2 Overwrite Sort Preview"
}
Write-Host ""

if (-not (Test-Path -LiteralPath $OverwritePath)) {
    Write-Host "Overwrite directory not found: $OverwritePath"
    Write-Host ""
    Write-Host "No files changed."
    exit 1
}

$entries = @(Get-ChildItem -LiteralPath $OverwritePath -Force | Sort-Object Name)
$routable = @()
$moved = @()
$blocked = @()
$unmanaged = @()
$emptyDirectories = @()
$removedEmptyDirectories = @()
$removeDirectories = @()
$removedDirectories = @()
$matchedTopLevelEntries = @{}
$emptyDirectoryPaths = @{}

foreach ($name in $emptyDirectoryCleanupNames) {
    $path = Join-Path $OverwritePath $name
    if (-not (Test-Path -LiteralPath $path -PathType Container)) {
        continue
    }

    if (@(Get-ChildItem -LiteralPath $path -Force).Count -eq 0) {
        $item = @{
            Path = $path
            Source = Join-Path "Overwrite" $name
        }
        $emptyDirectories += $item
        $emptyDirectoryPaths[$path] = $true
        $matchedTopLevelEntries[$name] = $true
    }
}

foreach ($name in $alwaysRemoveDirectoryNames) {
    $path = Join-Path $OverwritePath $name
    if (-not (Test-Path -LiteralPath $path -PathType Container)) {
        continue
    }

    $removeDirectories += @{
        Path = $path
        Source = Join-Path "Overwrite" $name
    }
    $matchedTopLevelEntries[$name] = $true
}

foreach ($mapping in $mappings) {
    $sourcePath = Join-Path $OverwritePath $mapping.Source

    if (-not (Test-Path -LiteralPath $sourcePath)) {
        continue
    }

    if ($emptyDirectoryPaths.ContainsKey($sourcePath)) {
        continue
    }

    $entry = Get-Item -LiteralPath $sourcePath -Force
    $sourceDisplay = Join-Path "Overwrite" $mapping.Source
    $topLevelName = ($mapping.Source -split '[\\/]')[0]
    $matchedTopLevelEntries[$topLevelName] = $true

    if (-not $entry.PSIsContainer) {
        $blocked += @{
            Source = $sourceDisplay
            Target = Join-Path $mapping.TargetMod $mapping.TargetPath
            Reason = "source is not a directory"
        }
        continue
    }

    $targetModPath = Join-Path $ModsPath $mapping.TargetMod
    $targetDisplay = Join-Path $mapping.TargetMod $mapping.TargetPath
    $route = @{
        Entry = $entry
        Mapping = $mapping
        Source = $sourceDisplay
        Target = $targetDisplay
        TargetModPath = $targetModPath
        ExcludedRelativePaths = @()
    }

    if (-not (Test-Path -LiteralPath $targetModPath)) {
        $blocked += $route + @{ Reason = "destination mod does not exist" }
        continue
    }

    $routable += $route
}

$routable = @($routable | Sort-Object @{ Expression = { $_.Source.Length }; Descending = $true }, Source)
$blocked = @($blocked | Sort-Object Source)

foreach ($route in $routable) {
    $sourcePrefix = "$($route.Mapping.Source)\"
    $route.ExcludedRelativePaths = @(
        $mappings |
            Where-Object { $_.Source.StartsWith($sourcePrefix) } |
            ForEach-Object { $_.Source.Substring($sourcePrefix.Length) }
    )
}

foreach ($entry in $entries) {
    if (-not $matchedTopLevelEntries.ContainsKey($entry.Name)) {
        $unmanaged += (Join-Path "Overwrite" $entry.Name)
    }
}

if ($Apply) {
    Write-Host "ROUTABLE"
    if ($routable.Count -eq 0) {
        Write-Host "  (none)"
    } else {
        foreach ($item in $routable) {
            Write-Host "  $($item.Source) -> $($item.Target)"
        }
    }
    Write-Host ""

    Write-Host "EMPTY DIRECTORIES"
    if ($emptyDirectories.Count -eq 0) {
        Write-Host "  (none)"
    } else {
        foreach ($item in $emptyDirectories) {
            Write-Host "  $($item.Source)"
        }
    }
    Write-Host ""

    Write-Host "DIRECTORIES TO REMOVE"
    if ($removeDirectories.Count -eq 0) {
        Write-Host "  (none)"
    } else {
        foreach ($item in $removeDirectories) {
            Write-Host "  $($item.Source)"
        }
    }
    Write-Host ""

    if ($blocked.Count -gt 0) {
        Write-Host "BLOCKED"
        foreach ($item in $blocked) {
            Write-Host "  $($item.Source) -> $($item.Target)"
            Write-Host "  Reason: $($item.Reason)"
        }
        Write-Host ""
    }

    Write-Host "UNMANAGED"
    if ($unmanaged.Count -eq 0) {
        Write-Host "  (none)"
    } else {
        foreach ($item in $unmanaged) {
            Write-Host "  $item"
        }
    }
    Write-Host ""

    if ($routable.Count -gt 0 -or $emptyDirectories.Count -gt 0 -or $removeDirectories.Count -gt 0) {
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

        foreach ($item in $routable) {
            if (Copy-MappedEntry -Entry $item.Entry -Mapping $item.Mapping -TargetModPath $item.TargetModPath -ExcludedRelativePaths $item.ExcludedRelativePaths) {
                $moved += $item
            } else {
                $blocked += $item + @{ Reason = "copy failed; source content left in Overwrite" }
            }
        }

        foreach ($item in $emptyDirectories) {
            try {
                Remove-Item -LiteralPath $item.Path -Force
                $removedEmptyDirectories += $item
            } catch {
                $blocked += @{
                    Source = $item.Source
                    Target = "(remove empty directory)"
                    Reason = "cleanup failed: $($_.Exception.Message)"
                }
            }
        }

        foreach ($item in $removeDirectories) {
            try {
                Remove-Item -LiteralPath $item.Path -Recurse -Force
                $removedDirectories += $item
            } catch {
                $blocked += @{
                    Source = $item.Source
                    Target = "(remove directory)"
                    Reason = "cleanup failed: $($_.Exception.Message)"
                }
            }
        }
    }

    Write-Host "MOVED"
    if ($moved.Count -eq 0) {
        Write-Host "  (none)"
    } else {
        foreach ($item in $moved) {
            Write-Host "  $($item.Source) -> $($item.Target)"
        }
    }
    Write-Host ""

    Write-Host "REMOVED EMPTY DIRECTORIES"
    if ($removedEmptyDirectories.Count -eq 0) {
        Write-Host "  (none)"
    } else {
        foreach ($item in $removedEmptyDirectories) {
            Write-Host "  $($item.Source)"
        }
    }
    Write-Host ""

    Write-Host "REMOVED DIRECTORIES"
    if ($removedDirectories.Count -eq 0) {
        Write-Host "  (none)"
    } else {
        foreach ($item in $removedDirectories) {
            Write-Host "  $($item.Source)"
        }
    }
    Write-Host ""

    if ($blocked.Count -gt 0) {
        Write-Host "BLOCKED"
        foreach ($item in $blocked) {
            Write-Host "  $($item.Source) -> $($item.Target)"
            Write-Host "  Reason: $($item.Reason)"
        }
        Write-Host ""
    }

    Write-Host "UNMANAGED"
    if ($unmanaged.Count -eq 0) {
        Write-Host "  (none)"
    } else {
        foreach ($item in $unmanaged) {
            Write-Host "  $item"
        }
    }
} else {
    Write-Host "ROUTABLE"
    if ($routable.Count -eq 0) {
        Write-Host "  (none)"
    } else {
        foreach ($item in $routable) {
            Write-Host "  $($item.Source) -> $($item.Target)"
        }
    }
    Write-Host ""

    Write-Host "EMPTY DIRECTORIES"
    if ($emptyDirectories.Count -eq 0) {
        Write-Host "  (none)"
    } else {
        foreach ($item in $emptyDirectories) {
            Write-Host "  $($item.Source)"
        }
    }
    Write-Host ""

    Write-Host "DIRECTORIES TO REMOVE"
    if ($removeDirectories.Count -eq 0) {
        Write-Host "  (none)"
    } else {
        foreach ($item in $removeDirectories) {
            Write-Host "  $($item.Source)"
        }
    }
    Write-Host ""

    if ($blocked.Count -gt 0) {
        Write-Host "BLOCKED"
        foreach ($item in $blocked) {
            Write-Host "  $($item.Source) -> $($item.Target)"
            Write-Host "  Reason: $($item.Reason)"
        }
        Write-Host ""
    }

    Write-Host "UNMANAGED"
    if ($unmanaged.Count -eq 0) {
        Write-Host "  (none)"
    } else {
        foreach ($item in $unmanaged) {
            Write-Host "  $item"
        }
    }
    Write-Host ""
    Write-Host "No files changed."
}
