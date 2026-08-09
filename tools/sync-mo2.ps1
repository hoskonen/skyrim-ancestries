$mo2Profile = "F:\Modding\Skyrim\Ancestries\profiles\Default"
$repo = "F:\Modding\Skyrim\ancestries-codex"

Copy-Item `
    "$mo2Profile\modlist.txt" `
    "$repo\state\modlist.txt" `
    -Force

Write-Host "MO2 state synchronized."