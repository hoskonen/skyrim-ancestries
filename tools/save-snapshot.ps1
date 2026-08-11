$repo = "F:\Modding\Skyrim\ancestries-codex"

Set-Location $repo

$changes = git status --porcelain

if (-not $changes) {
    Write-Host "Nothing to snapshot."
    exit 0
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"

$modCount = (
    Get-Content "$repo\state\modlist.txt" |
    Where-Object {
        $_ -match '^\+' -and
        $_ -notmatch '\[O\]$'
    }
).Count

$commitMessage = "snapshot: $modCount mods - $timestamp"

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