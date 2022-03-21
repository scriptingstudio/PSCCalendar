# Culture test #1 to see how each culture looks
[cultureinfo]::GetCultures('allCultures') | 
Where-Object {$_.name -and $_.name -notmatch '^en-'} | 
ForEach-Object {
    write-host "`nCulture : $($_.name) | $($_.displayname)" -f green
    Show-Calendar -culture $_.name 

    write-host "`nPress any key to continue..."
    $null = [Console]::ReadKey()
}
