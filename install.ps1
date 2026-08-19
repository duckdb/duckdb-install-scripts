<#
DuckDB Windows installer script, revision $Id$
Issues/PRs for this script: https://github.com/duckdb/duckdb-install-scripts
#>

$duckdb_staged = $env:DUCKDB_STAGED
$requested_version = $env:DUCKDB_VERSION

if (-not $duckdb_staged -and $requested_version -eq "alpha") {
    $duckdb_staged = (iwr "https://duckdb-staging.duckdb.org/latest_alpha_version.txt").Content.Trim()
}

if ($duckdb_staged) {
    $staged_parts = $duckdb_staged.Split('/')
    $staged_commit = $staged_parts[0]
    if ($staged_commit.Length -gt 10) {
        $staged_commit = $staged_commit.Substring(0, 10)
    }
    $duckdb_version = $staged_parts[1]
    $duckdb_staged = "${staged_commit}/${duckdb_version}"
} elseif ($requested_version) {
    $duckdb_version = $requested_version
} else {
    $duckdb_version = (iwr "https://duckdb.org/data/latest_stable_version.txt").Content.Trim()
}

$expected_duckdb_version = $duckdb_version
if (-not $expected_duckdb_version.StartsWith("v")) {
    $expected_duckdb_version = "v${expected_duckdb_version}"
}


Write-Host
Write-Host "*** DuckDB Windows installation script, version ${duckdb_version} ***"
Write-Host
Write-Host
Write-Host "         .;odxdl,            "
Write-Host "       .xXXXXXXXXKc          "
Write-Host "       0XXXXXXXXXXXd  cooo:  "
Write-Host "      ,XXXXXXXXXXXXK  OXXXXd "
Write-Host "       0XXXXXXXXXXXo  cooo:  "
Write-Host "       .xXXXXXXXXKc          "
Write-Host "         .;odxdl,  "
Write-Host 
Write-Host 


function TestDuckDB {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Path
    )

    $duckdb_output = & $Path -noheader -init NUL -csv -batch -s "SELECT version()"
    if ($duckdb_output -ne $expected_duckdb_version) {
        throw ("Version mismatch, ${duckdb_version} vs. ${duckdb_output}")
    }
}


# really powershell?!

$cli_path = Join-Path (Join-Path $env:LOCALAPPDATA -ChildPath "duckdb") -ChildPath "cli"
$local_install_dir = Join-Path $cli_path -ChildPath $duckdb_version

if (-not (Test-Path $local_install_dir -PathType Container)) {
    $null = New-Item -Path $local_install_dir -ItemType Directory
}
$duckdb_exec = Join-Path $local_install_dir -ChildPath "duckdb.exe"

if (Test-Path -Path ${duckdb_exec}) {
    TestDuckDB(${duckdb_exec})

    Write-Host "Destination binary ${duckdb_exec} already exists and seems to work."
    Write-Host
    Write-Host "To launch DuckDB now, type"
    Write-Host "${duckdb_exec}"
    return
}

$duckdb_arch = ''
$arch = (Get-CimInstance Win32_operatingsystem).OSArchitecture
if ($arch -eq '64-bit') {
    $duckdb_arch = 'windows-amd64'
}
if ($arch -eq 'ARM 64-bit Processor') {
    $duckdb_arch = 'windows-arm64'
}
# TODO is this enough?
if ($duckdb_arch -eq '') {
    throw "Architecture ${arch} is not supported. Sorry."
}


function ExtractV1 {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $DestinationPath
    )

    $download_url = "https://install.duckdb.org/v${duckdb_version}/duckdb_cli-${duckdb_arch}.zip"
    $archive_file = Join-Path $DestinationPath "duckdb.zip"
    Invoke-WebRequest $download_url -OutFile $archive_file
    if (-not (Test-Path $archive_file -PathType Leaf)) {
        throw ("Failed to download DuckDB")
    }
    Microsoft.PowerShell.Archive\Expand-Archive -Path $archive_file -DestinationPath $DestinationPath -Force
}

function ExtractV2 {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $DestinationPath
    )

    if ($duckdb_staged) {
        $download_url = "https://duckdb-staging.duckdb.org/${duckdb_staged}/duckdb/duckdb/github_release/duckdb-cli-${duckdb_arch}.tar.gz"
    } else {
        $download_url = "https://install.duckdb.org/v${duckdb_version}/duckdb-cli-${duckdb_arch}.tar.gz"
    }
    $archive_file = Join-Path $DestinationPath "duckdb.tar.gz"
    Invoke-WebRequest $download_url -OutFile $archive_file
    if (-not (Test-Path $archive_file -PathType Leaf)) {
        throw ("Failed to download DuckDB")
    }
    tar.exe -xzf $archive_file -C $DestinationPath
    if ($LASTEXITCODE -ne 0) {
        throw ("Failed to unpack DuckDB")
    }
}

# if we don't have a temp dir, create one using system drive ('C:\') and 'temp' folder.
if (-not $env:TEMP) {
    $env:TEMP = Join-Path $env:SystemDrive -ChildPath 'temp'
}

# generate some randomness for the name of the temp download folder
$random_path_ele = (-join ((65..90) + (97..122) | Get-Random -Count 10 | % {[char]$_}))


$temp_dir = Join-Path $env:TEMP -ChildPath "duckdb_install_${random_path_ele}"

# create target dir if not present
if (-not (Test-Path $temp_dir -PathType Container)) {
    $null = New-Item -Path $temp_dir -ItemType Directory
}

if (-not $duckdb_staged -and "${duckdb_version}" -like "1*") {
    ExtractV1 $temp_dir
} else {
    ExtractV2 $temp_dir
}


$duckdb_exec_candidate = Join-Path $temp_dir "duckdb.exe"
if (-not (Test-Path $duckdb_exec_candidate -PathType Leaf)) {
    throw ("Failed to download and/or unpack DuckDB")
}

TestDuckDB(${duckdb_exec_candidate})


Write-Host "Installing to ${local_install_dir}"
Copy-Item -Path $duckdb_exec_candidate -Destination $duckdb_exec -Force -ErrorAction SilentlyContinue

if (-not $duckdb_exec) {
    throw ("Failed to download and/or unpack DuckDB")
}
TestDuckDB(${duckdb_exec})

Write-Host "Successfully installed DuckDB binary to ${duckdb_exec}"
Write-Host
Write-Host "To launch DuckDB now, type"
Write-Host "${duckdb_exec}"

try {
    $WshShell = New-Object -COMObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$Home\Desktop\DuckDB.lnk")
    $Shortcut.TargetPath = ${duckdb_exec}
    $Shortcut.Save()
    Write-Host "There should also be a shortcut on your Desktop now."

} catch {
}

