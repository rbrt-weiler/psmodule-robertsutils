function Update-GitRepository {
    Param(
        [Parameter(Mandatory = $true, Position = 0)]
        [String]$Directory
    )

    $StartDirectory=$(Get-Location)
    $GitCommand=$((Get-Command git).Source)

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
                & "$GitCommand" "fetch" "$RemoteName"
            }
        }
    } else {
        Write-Output "Info: No <.git> found, skipping."
    }
    Write-Output ""

    Set-Location -Path "$StartDirectory"
}

Export-ModuleMember -Function Update-GitRepository
