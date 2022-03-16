function transpose-object ([string[]]$header, [switch]$include) {
# $include - includes original header in the output object as the first column
    begin {
        $table = [System.Collections.Generic.List[object]]::new()
    }
    process {
        $table.add($_)
    }
    end {
        if ($table.count -eq 1) {
            $newheader = if ($header -and $header.count -gt 1) {$header} else {'property','value'}
            $_.psobject.properties.foreach{
                [pscustomobject]@{
                    $newheader[0] = $_.name
                    $newheader[1] = $_.value
                }
            }
            return
        }
        $rows = $table[0].psobject.properties.name
        $colcount = $table.count
        if ($include) {$colcount++}
        $newheader = if ($header) {$header} 
        else {for ($i=0; $i -lt $colcount; $i++) {"col$i"}}
        $start = if ($include) {1} else {0}
        foreach ($p in $rows) {
            $row = '' | Select-Object $newheader
            if ($include) {
                $row.($newheader[0]) = $p
            }
            $i = $start
            foreach ($v in $table.$p) {
                if ($i -ge $newheader.count) {break}
                $row.($newheader[$i]) = $v
                $i++
            }
            $row
        }
    }
} # END transpose-object
