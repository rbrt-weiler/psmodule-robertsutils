<#
    .SYNOPSIS
    Installs the modules contained in this repository.

    .PARAMETER Replace
    If set, existing versions of the modules in $env:PSModulePath[0] will be replaced.

    .PARAMETER Uninstall
    If set, existing versions of the modules in $env:PSModulePath[0] will be removed only.

    .EXAMPLE
    ./install.ps1

    .EXAMPLE
    ./install.ps1 -Replace

    .EXAMPLE
    ./install.ps1 -Uninstall
#>
Param (
    [Parameter()]
    [switch]$Replace,
    [Parameter()]
    [switch]$Uninstall
)

<#
    .SYNOPSIS
    Returns $env:PSModulePath[0] on all supported platforms.
#>
function Get-BaseInstallPath {
    if ($IsWindows) {
        $ModulePaths = $env:PSModulePath -split ';'
    } else {
        $ModulePaths = $env:PSModulePath -split ':'
    }
    $InstallPath = $ModulePaths[0]
    return $InstallPath
}

<#
    .SYNOPSIS
    Copies a module to a specified location.

    .PARAMETER InstallPath
    The base path where the module should be installed.

    .PARAMETER ModuleName
    The short name of the module to be installed.

    .PARAMETER ModulePath
    The full path of the module to be installed.
#>
function Publish-Module {
    Param (
        [Parameter(Mandatory = $true)]
        [string]$InstallPath,
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,
        [Parameter(Mandatory = $true)]
        [string]$ModulePath
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

<#
    .SYNOPSIS
    Removes a module from a specified location.

    .PARAMETER InstallPath
    The base path from which the module should be removed.

    .PARAMETER ModuleName
    The short name of the module to be removed.
#>
function Unpublish-Module {
    Param (
        [Parameter(Mandatory = $true)]
        [string]$InstallPath,
        [Parameter(Mandatory = $true)]
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
