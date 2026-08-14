$type = Read-Host "Separator type (M = Main, S = Sub)"
$number = Read-Host "Separator number"
$name = Read-Host "Separator name"

if ($type -match '^[Mm]$') {
    if ($number -match '^\d+$') {
        $number = "{0:D3}" -f [int]$number
    }

    $name = $name.ToUpper()
}
elseif ($type -match '^[Ss]$') {
    # Preserve number and name exactly for sub separators.
}
else {
    Write-Error "Separator type must be M or S."
    exit 1
}

$separatorWidth = 60
$title = " $name "

# Account for "<number> " before the separator body.
$underscoreCount = $separatorWidth - $title.Length

if ($underscoreCount -lt 2) {
    Write-Error "Separator name is too long."
    exit 1
}

$leftCount = [math]::Floor($underscoreCount / 2)
$rightCount = $underscoreCount - $leftCount

$result =
    "$number " +
    ("_" * $leftCount) +
    $title +
    ("_" * $rightCount)

Write-Host ""
Write-Host $result
Write-Host "Length: $($result.Length) characters"

Set-Clipboard $result

Write-Host ""
Write-Host "Copied to clipboard."
