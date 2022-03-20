function format-calendar {
# Calendar formatter; receives data from the collector tier
# Input: hashtable
    [cmdletbinding()]
    param (
        [Parameter(Position=0, Mandatory, ValueFromPipeline)]
        $inputObject,

        [string[]]$highlightDate, # accepts full and short date strings,
        [alias('plain','noansi')][switch]$noStyle,
        [ValidateSet('h','v')][alias('type')]
        [string]$orientation = 'h',
        [switch]$monthOnly, # month title style; displays no year
        [switch]$trim, # cuts trailing days
        [ValidateSet('u','l','t')]
        [string]$titleCase, # day name case option
        [switch]$wide, # uses AbbreviatedDayNames for ShortestDayNames

        #[switch]$noWeekend, # do not highlight weekends
        [switch]$dayOff # experimental; holiday list; duplicate $highlightDate?
    )

    $calendar  = $inputObject.calendar
    if ($calendar.count -eq 0) {return}
    $separator = '  '
    $esc       = if ($IsCoreCLR) {"`e"} else {[Char]27}
    $calendarStyle = @{
        Title      = "$esc[33m" #38;5;3
        DayOfWeek  = "$esc[1;1;36m" # 1;4;36
        Today      = "$esc[30;47m" #;3 7   93;7 [30;107m  [93;3
        Highlight  = "$esc[91m"
        Weekend    = "$esc[31;1m" # 38;5;1
        Holiday    = "$esc[38;5;1m"
        PreHoliday = "$esc[38;5;13m" # is it needed/important?
        Trails     = "$esc[90;1m"
    }

    # Initialize reference points
    $curMonth  = [datetime]::new($inputObject.year,$inputObject.month,1)
    $fd        = $inputObject.firstday
    $i1        = 6 - $fd
    $i2        = if ($fd -eq 0) {0} else {$i1 + 1}
    $weekend   = $i1,$i2 # weekend indices
    $weekindex = (0..6+0..6)[$fd..($fd + 6)] # day sequence FDW-aware index
    $culture   = [system.globalization.cultureinfo]::CurrentCulture

    if (-not $noStyle -and $highlightDate) { # not finished
        $md = $culture.DateTimeFormat.MonthDayPattern.split(' -./')
        $ym = $culture.DateTimeFormat.YearMonthPattern.split(' -./')
        $p2 = if ($ym[0] -match 'y') {'{1}/{0}'} else {'{0}/{1}'}
        $p1 = if ($md[0] -match 'd') {'{0}/{1}/{2}'} elseif ($ym[0] -match 'y') {'{2}/{0}/{1}'} else {'{1}/{0}/{2}'} # test!!!!!
        $highlightDate = foreach ($item in $highlightDate) {
            if ($item -as [int]) {$item = $p1 -f [int]$item,$curMonth.month,$curMonth.year}
            elseif ($item -notmatch "$($curMonth.year.substring(2,2))|$($curMonth.year)") {$item = $p2 -f $item,$curMonth.year}
            $item -as [datetime]
        }
    } # end highlightDate

    # Build an array of short day names
    # NOTE on PS7: abbreviate day names can be in lower case; short day names can be of 1 char
    # PS7: in some cultures short day names are in lower case
    if ($psversiontable.PSVersion.Major -gt 5) {$wide = $true} # just in case
    $headstyle = if ($wide) {'AbbreviatedDayNames'} else {'ShortestDayNames'}
    $abbreviated = $culture.DateTimeFormat.$headstyle
    if ($headstyle -eq 'ShortestDayNames') { # validate name series
        # NOTE: ShortestDayNames can be not unique
        $sdn = $abbreviated | Sort-Object -Unique
        if ($sdn.count -ne $abbreviated.count) {
            $abbreviated = $culture.DateTimeFormat.AbbreviatedDayNames
        }
    }

    # Align week day names
    # in some cultures short day names can vary in length, calculate the maximum width
    # in some cultures visual and calculated length can vary - font rendering issue
    $max = ($abbreviated.foreach{$_.length} | Measure-Object -Maximum).Maximum
    # PROBLEM: in some cultures 1 char takes 2 positions on screen
    #if ($max -lt 2) {$max = 2}
    $abbreviated = $abbreviated.foreach{$_.padleft($max,' ')}
    
    $days      = $abbreviated[$weekindex].foreach{$_.replace('.','')}
    $weekdays  = $days
    $weekend   = $weekdays[$weekend]
    $headWidth = $weekdays[0].length
    if ($headWidth -lt 2) {$headWidth = 2}
    if ($titleCase) {
        $weekdays = switch ($titleCase) {
            'u' {$weekdays.foreach{$_.toupper()}}
            'l' {$weekdays.foreach{$_.tolower()}}
            't' {$weekdays.foreach{$culture.TextInfo.ToTitleCase($_.ToLower())}}
        }
    }

    # Generic to actual day name converter
    $oldname = $calendar[0].psobject.Properties.name.foreach{"`$_.$_"}
    $calHeader = for ($i=0; $i -lt 7; $i++) {
        @{n = "$($days[$i])"; e = [scriptblock]::create($oldname[$i])}    
    }

    # Convert from binary to text
    if ($orientation -eq 'h') {
        $month = foreach ($week in ($calendar | Select-Object $calHeader)) {
            $wk = foreach ($day in $weekdays) {
                $trails = $false
                $cm = $curMonth.month -ne $week.$day.month
                if ($cm) {
                    if ($trim) {
                        $day = $null
                        $d = ' '
                    } else {
                        $trails = $true
                        $d = $week.$day.day
                    }
                } else {
                    $d = $week.$day.day
                }
                $value = "$d".padleft($headWidth, ' ')
                if (($week.$day.date -eq $curMonth) -AND -Not $noStyle -and $cm) {
                    "{0}{1}{2}" -f $calendarStyle.Today, $value, "$esc[0m"
    
                }
                elseif (($highlightDate -contains $week.$day.date) -AND -Not $noStyle) {
                    "{0}{1}{2}" -f $calendarStyle.Highlight, $value, "$esc[0m"
                }
                else {
                    if ($noStyle) {$value}
                    elseif ($day -in $weekend -and $fd -in 0,1) {
                        $style = if ($trails) {'Trails'} else {'Weekend'}
                        "{0}{1}{2}" -f $calendarStyle.$style, $value, "$esc[0m"
                    } elseif ($trails) {
                        "{0}{1}{2}" -f $calendarStyle.Trails, $value, "$esc[0m"
                    }
                    else {$value}
                }
            }    
            $wk -join $separator
        }
    
        $days = if ($noStyle) {$weekdays} else {
            foreach ($d in $weekdays) {
                "{0}{1}{2}" -f $calendarStyle.DayofWeek, $d, "$esc[0m"
            }
        }    
    } 
    else { # vertical calendar; not finished
        $calendar = ($calendar | Select-Object $calHeader)
        # style issue (doubtful): gaps between columns are not equal if all values less 10
        $maxw = ($weekdays.foreach{$calendar[1].$_.day.tostring().length} | Measure-Object -Maximum).Maximum
        $month = foreach ($name in $weekdays) {
            $i = 0 # column counter; used to resolve style issue
            $row = foreach ($day in $calendar.$name) {
                $trails = $false
                $cm = $curMonth.month -ne $day.month
                if ($cm) {
                    if ($trim) {
                        $day = $null
                        $d = ' '
                    } else {
                        $trails = $true
                        $d = $day.day
                    }
                } else {
                    $d = $day.day
                }
                # adjust the gap before column 2 if all values less 10; but this breaks visual regular structure
                if ($i -eq 1 -and $maxw -eq 1) {"$d"}
                else {"$d".padleft($headWidth, ' ')}
                $i++
                # styling comes here; in dev
            }
            if (-not $noStyle) {
                $name = "{0}{1}{2}" -f $calendarStyle.DayofWeek, $name, "$esc[0m"
            }
            '{0} {1}' -f $name, ($row -join $separator)
        }
    } # end orientation formatter

    # Finalize format
    $plainHead = if ($monthOnly) {$curMonth.tostring('MMMM')} 
    else {'{0} {1}' -f $curMonth.tostring('MMMM'), $curMonth.year}
    if ($psversiontable.PSVersion.Major -gt 5 -or $titleCase -eq 't') {
        $plainHead = $culture.TextInfo.ToTitleCase($plainHead.ToLower())
    }
    $head = if ($noStyle) {$plainHead} else {
        "{0}{1}{2}" -f $calendarStyle.title, $plainhead, "$esc[0m"
    }
    [int]$pad = if ($orientation -eq 'v') {
        (($calendar.count+1)*($headWidth+1) - $plainhead.Length) / 2 + 2
    } else {
        (10*$headWidth - $plainhead.Length) / 2 + 2
    }
    $p = " " * $pad
    $titleMargin = if ($noStyle) {''} else {"`n"}
    # Output
    "`n$p$head`n" # newline (btm margin) after the month title or only in plain mode?
    if ($orientation -eq 'h') {
        $days -join $separator
        if ($noStyle) {($days -join $separator) -replace '\w','-'}
    }
    $month
} # END format-calendar
