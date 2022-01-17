Param (
    [Parameter()]
    [switch]$Replace,
    [Parameter()]
    [switch]$Uninstall
)

function Get-BaseInstallPath {
    if ($IsWindows) {
        $ModulePaths = $env:PSModulePath -split ';'
    } else {
        $ModulePaths = $env:PSModulePath -split ':'
    }
    $InstallPath = $ModulePaths[0]
    return $InstallPath
}

function Publish-Module {
    Param (
        [string]$InstallPath,
        [string]$ModulePath,
        [string]$ModuleName
    )
    $DestinationPath = Join-Path -Path "$InstallPath" -ChildPath "$ModuleName"
    if (Test-Path "$DestinationPath") {
        Write-Output "Existing version of <$ModuleName> found. Skipping."
        return
    }
    Write-Output "Installing <$ModuleName> to <$InstallPath>..."
    Copy-Item -Path "$ModulePath" -Recurse -Destination "$InstallPath"
    return
}

function Unpublish-Module {
    Param (
        [string]$InstallPath,
        [string]$ModuleName
    )
    $DestinationPath = Join-Path -Path "$InstallPath" -ChildPath "$ModuleName"
    if (Test-Path -Path "$DestinationPath") {
        Write-Output "Removing <$ModuleName> from <$InstallPath>..."
        Remove-Item -Path "$DestinationPath" -Recurse
    }
    return
}

$InstallPath = Get-BaseInstallPath
if (-Not $InstallPath) {
    Write-Output "Cannot determine module path. Exiting."
    exit 1
}

Get-ChildItem -Path "$PSScriptRoot" -Directory | ForEach-Object {
    $ModuleName = $_.Name
    $ModulePath = $_.FullName
    if ($Uninstall) {
        Unpublish-Module -InstallPath "$InstallPath" -ModuleName "$ModuleName"
    } else {
        if ($Replace) {
            Unpublish-Module -InstallPath "$InstallPath" -ModuleName "$ModuleName"
        }
        Publish-Module -InstallPath "$InstallPath" -ModuleName "$ModuleName" -ModulePath "$ModulePath"
    }
}
