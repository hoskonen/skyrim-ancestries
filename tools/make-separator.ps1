$number = Read-Host "Separator number"
$name = Read-Host "Separator name"

$number = "{0:D3}" -f [int]$number
$name = $name.ToUpper()

$result = "$number ____________________ $name ______________________"

Write-Host $result
Set-Clipboard $result