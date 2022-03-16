# A set of miscellaneous functions

function transpose-object ([string[]]$header, [switch]$include, [string]$prefix='col') {
# $include - includes original header in the output object as the first column
    begin {
        $table = [System.Collections.Generic.List[object]]::new()
        if (-not $prefix) {$prefix = 'col'}
    }
    process {
        $table.add($_)
    }
    end {
        if ($table.count -eq 1) { # singleton detected
            $newheader = if ($header -and $header.count -gt 1) {$header} else {'property','value'}
            $_.psobject.properties.foreach{
                [pscustomobject]@{
                    $newheader[0] = $_.name
                    $newheader[1] = $_.value
                }
            }
            return
        }
        $rows = $table[0].psobject.properties.name # row identities
        $colcount = $table.count
        if ($include) {$colcount++}
        $newheader = if ($header) {$header} 
        else {for ($i=0; $i -lt $colcount; $i++) {"$prefix$i"}}
        $start = if ($include) {1} else {0}
        # Build new object
        $objwidth = $newheader.count
        foreach ($p in $rows) {
            $row = '' | Select-Object $newheader
            if ($include) {$row.($newheader[0]) = $p}
            $i = $start
            # Import data
            foreach ($v in $table.$p) {
                if ($i -ge $objwidth) {break}
                $row.($newheader[$i++]) = $v
            }
            $row
        }
    }
} # END transpose-object

function transpose ([string[]]$header) {
# for singletons only
    process {
        $newheader = if ($header -and $header.count -gt 1) {$header} else {'property','value'}
        $_.psobject.properties.foreach{
            [pscustomobject]@{
                $newheader[0] = $_.name
                $newheader[1] = $_.value
            }
        }
    }
} # END transpose
