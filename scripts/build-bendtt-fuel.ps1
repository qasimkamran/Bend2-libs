param(
    [Parameter(Mandatory = $true)]
    [string]$Bend2Source,
    [long]$Fuel = 20000000000,
    [Parameter(Mandatory = $true)]
    [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'
if ($Fuel -lt 400000000) {
    throw 'Fuel must be at least the official BendTT default (400000000).'
}

$sourcePath = Join-Path (Resolve-Path -LiteralPath $Bend2Source).Path 'bendtt.lean'
$sourceText = [System.IO.File]::ReadAllText($sourcePath)
$officialFuel = 'def FUEL : Nat := 400000000'
if (-not $sourceText.Contains($officialFuel)) {
    throw "Expected the official BendTT fuel declaration in $sourcePath."
}

$outputPath = [System.IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
$kernelSource = $sourceText.Replace($officialFuel, "def FUEL : Nat := $Fuel")
[System.IO.File]::WriteAllText(
    (Join-Path $outputPath 'bendtt.lean'),
    $kernelSource,
    [System.Text.UTF8Encoding]::new($false)
)

$lean = Get-Command lean -ErrorAction Stop
$leanc = Get-Command leanc -ErrorAction Stop
Push-Location $outputPath
try {
    & $lean.Source -c bendtt.c bendtt.lean
    if ($LASTEXITCODE -ne 0) { throw 'Lean compilation failed.' }
    & $leanc.Source -O3 -DNDEBUG bendtt.c -o bendtt.exe
    if ($LASTEXITCODE -ne 0) { throw 'BendTT kernel linking failed.' }
}
finally {
    Pop-Location
}

$sourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $outputPath 'bendtt.lean')).Hash.ToLowerInvariant()
$binaryHash = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $outputPath 'bendtt.exe')).Hash.ToLowerInvariant()
Write-Output "Built BendTT with unchanged proof rules and FUEL=$Fuel."
Write-Output "Kernel source SHA256: $sourceHash"
Write-Output "Kernel executable SHA256: $binaryHash"
