function transpose-object {
    begin {
        $column = [ordered]@{}
        $i = 1
    }
    process {
        if (@($_).count -eq 1) {
            $_.psobject.properties.foreach{
                [pscustomobject]@{property = $_.name; value = $_.value}
            }
        } else {
            foreach ($obj in $_) {
                $column["col$i"] = $obj.psobject.properties.value
                $i++
            }
        }
    }
    end {
        if ($i -eq 1) {return}
        $header = [string[]]$column.keys
        $i = 0
        $header | . { process { # walk through columns
            $row = '' | Select-Object $header
            foreach ($p in $header) {
                #if ($col[$p].count -lt $i) {
                $row.$p = $column[$p][$i]
                #}
            }
            $i++
            $row
        }}
    }
} # END transpose-object
