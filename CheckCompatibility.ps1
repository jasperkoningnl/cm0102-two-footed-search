param([Parameter(Mandatory=$true)][string]$ExePath)
$ErrorActionPreference = 'Stop'
try {
    $taskExe = (Resolve-Path -LiteralPath $ExePath).Path
    $taskBytes = [IO.File]::ReadAllBytes($taskExe)
    function U16([int]$p) { [BitConverter]::ToUInt16($taskBytes,$p) }
    function U32([int]$p) { [BitConverter]::ToUInt32($taskBytes,$p) }
    if ($taskBytes.Length -lt 4096 -or (U16 0) -ne 0x5A4D) { throw 'Not a Windows game executable.' }
    $taskPe = U32 0x3C
    if ((U32 $taskPe) -ne 0x4550 -or (U16 ($taskPe+4)) -ne 0x14C) { throw 'Expected a 32-bit Windows executable.' }
    $taskOpt = $taskPe+24
    if ((U16 $taskOpt) -ne 0x10B -or (U32 ($taskOpt+28)) -ne 0x400000) { throw 'Unsupported executable layout.' }
    $taskSections = U16 ($taskPe+6)
    $taskSectionTable = $taskOpt+(U16 ($taskPe+20))
    $taskMapped = $false
    for ($taskIndex=0; $taskIndex -lt $taskSections; $taskIndex++) {
        $taskSection=$taskSectionTable+40*$taskIndex
        $taskRva=U32 ($taskSection+12)
        $taskRawSize=U32 ($taskSection+16)
        $taskRaw=U32 ($taskSection+20)
        $taskFlags=U32 ($taskSection+36)
        if (0x8DB000 -ge $taskRaw -and 0x8DB000+93 -le $taskRaw+$taskRawSize) {
            $taskMapped=($taskRva+0x8DB000-$taskRaw -eq 0xBE6000) -and (($taskFlags -band 0x60000000) -eq 0x60000000)
        }
    }
    if (-not $taskMapped) { throw 'Required executable space is missing or mapped differently. This beta requires the expanded 3.9.68 layout created by Nick''s Patcher.' }
    $taskPatchFile=Join-Path $PSScriptRoot 'TwoFootedSearch.patch'
    $taskOriginal=$true; $taskInstalled=$true; $taskCount=0
    foreach ($taskLine in [IO.File]::ReadAllLines($taskPatchFile)) {
        if ($taskLine -match '^([0-9A-F]{8}): ([0-9A-F]{2}) ([0-9A-F]{2})$') {
            $taskOffset=[Convert]::ToInt32($Matches[1],16)
            if ($taskOffset -ge $taskBytes.Length) { throw 'Patch location is outside this executable.' }
            $taskOriginal=$taskOriginal -and ($taskBytes[$taskOffset] -eq [Convert]::ToByte($Matches[2],16))
            $taskInstalled=$taskInstalled -and ($taskBytes[$taskOffset] -eq [Convert]::ToByte($Matches[3],16))
            $taskCount++
        }
    }
    if ($taskCount -ne 98) { throw 'Patch file is incomplete or has been modified.' }
    if ($taskInstalled) { Write-Host 'ALREADY INSTALLED: the (+) search marker is present.'; exit 0 }
    if (-not $taskOriginal) { throw 'A patch location is already modified. Do not install this beta on this file.' }
    Write-Host 'PASS: expected layout and patch bytes match. Back up this executable, then install TwoFootedSearch.patch through Nick''s Patcher.'
    Write-Host 'This checks known compatibility points; other custom patches and actual screen layout still need testing.'
    exit 0
} catch {
    Write-Host ('NOT SUPPORTED: '+$_.Exception.Message)
    exit 1
}
