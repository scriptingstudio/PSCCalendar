'controller.ps1', 'collector.ps1', 'formatter.ps1' | ForEach-Object {
    . $PSScriptRoot\$_
}
