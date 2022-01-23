# PowerShell Module: Roberts Utils

A [PowerShell](https://github.com/PowerShell/PowerShell) module that contains various functions that [I, Robert](https://robert.weiler.one/), created for my personal use. Currently **in development** and not yet stable.

## Installation

An installer is contained in this repository. Run `./install.ps1 -Replace` to install the module to your module path. `Get-Help ./install.ps1 -Full` will provide a full help.

You can also import the modules manually with `Import-Module <./FileName.psm1>` (and remove them with `Remove-Module <ModuleName>`).

## Functions

The module exports the following functions:

- `Test-GitPath`
- `Update-GitRepository`

All exported functions come with an associated help; `Get-Help <FunctionName>` is your friend for now.
