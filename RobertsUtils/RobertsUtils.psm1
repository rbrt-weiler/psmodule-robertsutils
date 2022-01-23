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

enum GitUpdateStatusCode {
    Unknown = -1
    Successful = 0
    Failed = 1
    NoRepository = 2
    NonExistant = 3
}

class GitUpdateStatus {
    [String]$Path
    [GitUpdateStatusCode]$Status
    [Int32]$GitExitCode
    [String]$GitOutput
    GitUpdateStatus() {
        $this.Path = ""
        $this.Status = [GitUpdateStatusCode]::Unknown
        $this.GitExitCode = -1
        $this.GitOutput = ""
    }
    GitUpdateStatus([String]$Path) {
        $this.Path = $Path
        $this.Status = [GitUpdateStatusCode]::Unknown
        $this.GitExitCode = -1
        $this.GitOutput = ""
    }
}

<#
    .SYNOPSIS
    Tests if a given path is a Git repository and if it contains submodules.

    .DESCRIPTION
    For a given path, this function will check if it is a Git repository. If it is, it will also check if the Git repository contains submodules. The array returned by this function will contain one GitPathStatus object per tested path.

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
    Param (
        [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [String]$Name,
        [Parameter(Position = 1, ValueFromPipelineByPropertyName = $true)]
        [String]$FullName
    )
    begin {
        $GitCommand = (Get-Command "git").Source
        if (-Not $GitCommand) {
            Write-Error "Could not find Git, exiting."
            exit 1
        }
        $StartDirectory = Get-Location
        $StatusCollection = @()
    }
    process {
        $TestPath = ""
        if ($FullName) {
            $TestPath = $FullName
        } else {
            $TestPath = $Name
        }
        $Status = [GitUpdateStatus]::new("$TestPath")
        $GitTest = Test-GitPath -Name "$TestPath"
        if ($GitTest.IsRepository) {
            Set-Location "$($GitTest.Path)"
            $Status.GitOutput += Invoke-Expression -Command "$GitCommand pull *>&1"
            $Status.GitExitCode = $LASTEXITCODE
            if ($LASTEXITCODE -eq 0) {
                $Status.Status = [GitUpdateStatusCode]::Successful
                if ($GitTest.ContainsSubmodules) {
                    $Status.GitOutput += Invoke-Expression -Command "$GitCommand submodule update --remote --merge *>&1"
                    $Status.GitExitCode = $LASTEXITCODE
                    if ($LASTEXITCODE -ne 0) {
                        $Status.Status = [GitUpdateStatusCode]::Failed
                    }
                }
                $Remotes = Invoke-Expression "$GitCommand remote -v" | Select-String -Pattern '(fetch)' | Select-String -NotMatch -Pattern '^origin'
                if ($Remotes) {
                    $Remotes.ToString() | ForEach-Object {
                        $RemoteName = ($_ | Select-String -Pattern '^(?<name>\w+)\s+').Matches[0].Groups['name'].Value
                        $Status.GitOutput += Invoke-Expression -Command "$GitCommand fetch $RemoteName *>&1"
                        if ($LASTEXITCODE -ne 0) {
                            $Status.Status = [GitUpdateStatusCode]::Failed
                        }
                    }
                }
            } else {
                $Status.Status = [GitUpdateStatusCode]::Failed
            }
        } else {
            if ($GitTest.PathExists) {
                $Status.Status = [GitUpdateStatusCode]::NoRepository
            } else {
                $Status.Status = [GitUpdateStatusCode]::NonExistant
            }
        }
        $StatusCollection += $Status
        Set-Location "$StartDirectory"
    }
    end {
        return $StatusCollection
    }
}

Export-ModuleMember -Function Test-GitPath
Export-ModuleMember -Function Update-GitRepository
