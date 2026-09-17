$repo = "F:\Modding\Skyrim\ancestries-codex"

Set-Location $repo

$changes = git status --porcelain

if (-not $changes) {
    Write-Host "Nothing to snapshot."
    exit 0
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"

$modlist = Get-Content "$repo\state\modlist.txt"
$activeModCount = @($modlist | Where-Object { $_ -match '^\+' }).Count

$profilePluginCount = @(
    Get-Content "$repo\state\plugins.txt" |
    Where-Object { $_ -match '^\*' }
).Count

# plugins.txt omits Skyrim.esm, Update.esm, DLC, and Creation Club plugins.
$builtInPluginCount = 2 + @(
    $modlist |
    Where-Object { $_ -match '^\*(?:DLC|Creation Club):' }
).Count
$pluginCount = $profilePluginCount + $builtInPluginCount

$commitMessage = "snapshot: M$activeModCount P$pluginCount - $timestamp"

git add -A

git commit -m $commitMessage

if ($LASTEXITCODE -ne 0) {
    Write-Error "Git commit failed."
    exit 1
}

git push

if ($LASTEXITCODE -ne 0) {
    Write-Warning "Snapshot committed locally, but push failed."
    exit 1
}

Write-Host ""
Write-Host "Snapshot saved:"
Write-Host $commitMessage
