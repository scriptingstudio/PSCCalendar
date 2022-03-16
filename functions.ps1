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
            foreach ($value in $table.$p) {
                if ($i -ge $objwidth) {break}
                $row.($newheader[$i++]) = $value
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

function get-dayoff {
# Russian dayoff json database
# по этим базам странные данные: выходные и праздники - одно и то же; поэтому нужно фильтровать выходные (сб и вс)
# https://github.com/d10xa/holidays-calendar/blob/master/json/consultant2022.json
# https://raw.githubusercontent.com/d10xa/holidays-calendar/master/json/consultant2022.json
# https://raw.githubusercontent.com/d10xa/holidays-calendar/master/json/calendar.json
    ###[CmdletBinding()]
    param (
        [ValidateRange(1,12)]$MonthNumber = ([datetime]::now).Month,
        [ValidateRange(2011,2030)]$YearNumber = ([datetime]::now).Year
    )

    if (-not $script:ParsedAllDayoff.count) {$script:ParsedAllDayoff = @{}}
    if (-not $script:ParsedAllDayoff[$YearNumber].count) {
        $progressPreference = 'silentlyContinue' # hide progress bar
        $WebRequest = Invoke-WebRequest -Uri "https://raw.githubusercontent.com/d10xa/holidays-calendar/master/json/calendar.json" -ErrorAction SilentlyContinue -UseBasicParsing
        $progressPreference = 'Continue'
        if (-not $WebRequest.Content) {return @{}}
        $WebRequest.Content | ConvertFrom-Json | . { process {
            ###if (-not $_) {return}
            ###if (-not $AllDayoff.ContainsKey($y)) {$AllDayoff[$y] = @{}}
            $_.holidays.foreach{
                if (-not $_) {return}
                $y,$m,$d = [int[]]$_.split('-')
                if (-not $AllDayoff.ContainsKey($y)) {$AllDayoff[$y] = @{}}
                if (-not $AllDayoff[$y].ContainsKey($m)) {$AllDayoff[$y][$m] = @{}}
                $AllDayoff[$y][$m][$d] = '1'
            }
            @($_.preholidays).foreach{
                if (-not $_) {return}
                $y,$m,$d = [int[]]$_.split('-')
                if (-not $AllDayoff.ContainsKey($y)) {$AllDayoff[$y] = @{}}
                if (-not $AllDayoff[$y].ContainsKey($m)) {$AllDayoff[$y][$m] = @{}}
                $AllDayoff[$y][$m][$d] = '2'
            }
            @($_.nowork).foreach{
                if (-not $_) {return}
                $y,$m,$d = [int[]]$_.split('-')
                if (-not $AllDayoff.ContainsKey($y)) {$AllDayoff[$y] = @{}}
                if (-not $AllDayoff[$y].ContainsKey($m)) {$AllDayoff[$y][$m] = @{}}
                $AllDayoff[$y][$m][$d] = '3'
            }
        }}
        if (-not $AllDayoff.$YearNumber) {return @{}}
        $script:ParsedAllDayoff[$YearNumber] = $AllDayoff[$YearNumber]
    } else {$AllDayoff = $ParsedAllDayoff}

    $AllDayoffOfMonth = $AllDayoff[$YearNumber][$MonthNumber]
    $DaysFoundHash = @{}
    (1..$([DateTime]::DaysInMonth($YearNumber,$MonthNumber))).foreach{
        if ($AllDayoffOfMonth.$_) {
            $DaysFoundHash[$_] = $AllDayoff[$YearNumber][$MonthNumber][$_]
        }    
    }
    $DaysFoundHash            
} # END get-dayoff
