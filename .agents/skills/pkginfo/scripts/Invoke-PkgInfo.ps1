<#
.SYNOPSIS
    Dumps Unreal package info (PkgInfo commandlet) for each given asset into
    "<AssetName>.pkginfo.txt" next to the asset.

.PARAMETER Assets
    Paths to .uasset / .umap files (absolute or relative to the current directory).

.PARAMETER Project
    Path to the .uproject. Default: the first .uproject found walking up from the first asset.

.PARAMETER EngineDir
    Engine root (folder containing "Engine"). Default: resolved from the project's EngineAssociation.

.PARAMETER ExtraArgs
    PkgInfo switches. Default: -all (full dump: summary, names, imports, exports, ...).

.EXAMPLE
    .\Invoke-PkgInfo.ps1 Content\Summary\M_Summary.uasset Content\Summary\L_SummaryLevel.umap
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$Assets,
    [string]$Project,
    [string]$EngineDir,
    [string[]]$ExtraArgs = @('-all')
)

$ErrorActionPreference = 'Stop'

function Find-UProject([string]$StartDir) {
    $dir = Get-Item -LiteralPath $StartDir
    while ($dir) {
        $found = Get-ChildItem -LiteralPath $dir.FullName -Filter *.uproject -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) { return $found.FullName }
        $dir = $dir.Parent
    }
    return $null
}

function Resolve-EngineDir([string]$UProject) {
    $assoc = (Get-Content -LiteralPath $UProject -Raw | ConvertFrom-Json).EngineAssociation
    if (-not $assoc) { throw "No EngineAssociation in $UProject; pass -EngineDir." }

    # Source / custom builds and launcher installs registered by UnrealVersionSelector.
    $builds = Get-ItemProperty 'HKCU:\Software\Epic Games\Unreal Engine\Builds' -ErrorAction SilentlyContinue
    if ($builds -and $builds.PSObject.Properties[$assoc]) { return $builds.$assoc }

    # Launcher installs ("5.8" style association).
    $key = "HKLM:\SOFTWARE\EpicGames\Unreal Engine\$assoc"
    $installed = (Get-ItemProperty $key -ErrorAction SilentlyContinue).InstalledDirectory
    if ($installed) { return $installed }

    $default = "C:\Program Files\Epic Games\UE_$assoc"
    if (Test-Path -LiteralPath $default) { return $default }

    throw "Cannot resolve engine for EngineAssociation '$assoc'; pass -EngineDir."
}

$assetFiles = foreach ($a in $Assets) {
    $item = Get-Item -LiteralPath $a -ErrorAction SilentlyContinue
    if (-not $item) { throw "Asset not found: $a" }
    if ($item.Extension -notin '.uasset', '.umap') { throw "Not a .uasset/.umap: $a" }
    $item
}

if (-not $Project) { $Project = Find-UProject $assetFiles[0].DirectoryName }
if (-not $Project) { throw 'No .uproject found above the assets; pass -Project.' }
$Project = (Resolve-Path -LiteralPath $Project).Path

if (-not $EngineDir) { $EngineDir = Resolve-EngineDir $Project }
$exe = Join-Path $EngineDir 'Engine\Binaries\Win64\UnrealEditor-Cmd.exe'
if (-not (Test-Path -LiteralPath $exe)) { throw "UnrealEditor-Cmd.exe not found: $exe" }

Write-Host "Project: $Project"
Write-Host "Engine:  $EngineDir"

$logDir = Join-Path ([IO.Path]::GetTempPath()) 'pkginfo-logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$failed = 0
foreach ($asset in $assetFiles) {
    $name = [IO.Path]::GetFileNameWithoutExtension($asset.Name)
    $out  = Join-Path $asset.DirectoryName "$name.pkginfo.txt"
    $log  = Join-Path $logDir "$name.log"

    # One commandlet run per asset: -dumptofile would otherwise merge all packages into one file.
    if (Test-Path -LiteralPath $out) { Remove-Item -LiteralPath $out -Force }
    $cmdArgs = @($Project, '-run=PkgInfo', $asset.FullName) + $ExtraArgs +
               @("-dumptofile=$out", '-unattended', '-nop4', '-nosplash', '-nullrhi', "-abslog=$log")
    & $exe @cmdArgs | Out-Null
    $code = $LASTEXITCODE

    if ($code -eq 0 -and (Test-Path -LiteralPath $out) -and (Get-Item -LiteralPath $out).Length -gt 0) {
        Write-Host ("OK    {0} -> {1} ({2} B)" -f $asset.Name, $out, (Get-Item -LiteralPath $out).Length)
    } else {
        $failed++
        Write-Host ("FAIL  {0} (exit {1}, log: {2})" -f $asset.Name, $code, $log)
    }
}

if ($failed) { exit 1 }
