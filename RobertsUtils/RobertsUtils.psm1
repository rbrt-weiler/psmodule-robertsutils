class GitPathStatus {
    [String]$Path
    [Bool]$PathExists
    [Bool]$IsRepository
    [Bool]$ContainsSubmodules
    GitPathStatus() {
        $this.Path = ""
        $this.PathExists = $false
        $this.IsRepository = $false
        $this.ContainsSubmodules = $false
    }
    GitPathStatus([String]$Path) {
        $this.Path = $Path
        $this.PathExists = $false
        $this.IsRepository = $false
        $this.ContainsSubmodules = $false
    }
}

<#
    .SYNOPSIS
    Tests is a given path is a Git repository and if it contains submodules.

    .DESCRIPTION
    For a given path, this function will check if it is a Git repository. If it is, it will also check if the Git repository contains submodules.

    .PARAMETER Name
    The path that shall be tested.

    .PARAMETER FullName
    The path that shall be tested in absolute form; provided to work with Get-ChildItem.

    .INPUTS
    System.String[]

    .OUTPUTS
    GitPathStatus[]

    .NOTES
    The check performed by this function is solely based on the fact if a subdirectory ".git" (or ".gitmodules" for the submodule check) exists in the path provided by either Name or FullName.
#>
function Test-GitPath {
    Param (
        [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [String]$Name,
        [Parameter(Position = 1, ValueFromPipelineByPropertyName = $true)]
        [String]$FullName
    )
    begin {
        $StatusCollection = @()
    }
    process {
        $TestPath = ""
        if ($FullName) {
            $TestPath = $FullName
        } else {
            $TestPath = $Name
        }
        $Status = [GitPathStatus]::new("$TestPath")
        if (Test-Path -Path "$TestPath") {
            $Status.PathExists = $true
            if (Test-Path -Path (Join-Path -Path "$TestPath" -ChildPath ".git")) {
                $Status.IsRepository = $true
                if (Test-Path -Path (Join-Path -Path "$TestPath" -ChildPath ".gitmodules")) {
                    $Status.ContainsSubmodules = $true
                }
            }
        }
        $StatusCollection += $Status
    }
    end {
        return $StatusCollection
    }
}

<#
    .SYNOPSIS
    Updates a Git repository.

    .DESCRIPTION
    Updates a Git repository by entering the given directory and performing the necessary Git commands. The function will also update remotes, if any other than "origin" are configured.

    .PARAMETER Directory
    The directory that shall be treated as a Git repository.

    .INPUTS
    None.

    .OUTPUTS
    Logging to CLI.

    .EXAMPLE
    Update-GitRepository ../../Git/my-repo
#>
function Update-GitRepository {
    Param(
        [Parameter(Mandatory = $true, Position = 0)]
        [String]$Directory
    )

    $StartDirectory = $(Get-Location)
    $GitCommand = $((Get-Command git).Source)

    Write-Output "Info: Entering <$Directory>:"
    Set-Location -Path "$Directory"
    if (Test-Path -Path ".git") {
        & "$GitCommand" "pull" "origin"
        if (Test-Path -Path ".gitmodules") {
            & "$GitCommand" "submodule" "update" "--remote" "--merge"
        }
        $Remotes = & "$GitCommand" "remote" "-v" | Select-String -Pattern '(fetch)' | Select-String -NotMatch -Pattern '^origin'
        if ($Remotes) {
            $Remotes.ToString() | ForEach-Object {
                $RemoteName = ($_ | Select-String -Pattern '^(?<name>\w+)\s+').Matches[0].Groups['name'].Value
                Write-Output "Info: Updating remote <$RemoteName>..."
                & "$GitCommand" "fetch" "$RemoteName"
            }
        }
    } else {
        Write-Output "Info: No <.git> found, skipping."
    }
    Write-Output ""

    Set-Location -Path "$StartDirectory"
}

<#
    .SYNOPSIS
    Updates multiple Git repositories.

    .DESCRIPTION
    Updates multiple Git repositories by accepting multiple directories. Each given directory can also be treated as containing multiple Git repositories, enabling updating a set of sub-directories at once.

    .PARAMETER BaseDirectories
    A set of directories that shall be used as Git repositories or base directories containing multiple Git repositories.

    .PARAMETER Recursive
    If set, the given BaseDirectories will be treated as containing multiple Git repositories in sub-directories.

    .INPUTS
    None.

    .OUTPUTS
    Logging to CLI.

    .EXAMPLE
    Update-GitRepositories ../../Git/my-repo,../../Git/my-other-repo

    .EXAMPLE
    Update-GitRepositories -BaseDirectories ../../Git -Recursive
#>
function Update-GitRepositories {
    Param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string[]]$BaseDirectories,
        [Parameter(Position = 1)]
        [switch]$Recursive
    )

    $StartDirectory = $(Get-Location)

    foreach ($Directory in $BaseDirectories) {
        if (Test-Path -Path "$Directory") {
            Set-Location -Path "$Directory"
            if ($Recursive) {
                Get-ChildItem -Directory | ForEach-Object { Update-GitRepository -Directory "$($_.FullName)" }
            } else {
                & Update-GitRepository -Directory "$Directory"
            }
        } else {
            Write-Output "Warn: <$Directory> does not exist, skipping."
            Write-Output ""
            continue
        }
        Set-Location -Path "$StartDirectory"
    }
}

Export-ModuleMember -Function Test-GitPath
Export-ModuleMember -Function Update-GitRepository
Export-ModuleMember -Function Update-GitRepositories
