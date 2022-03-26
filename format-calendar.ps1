function format-calendar {
# Calendar formatter; receives data from the collector tier
# Input: hashtable
# Status: in dev
    [cmdletbinding()]
    param (
        [Parameter(Position=0, Mandatory, ValueFromPipeline)]
        $inputObject,

        [string[]]$highlightDate, # accepts full and short date strings,
        [alias('plain','noansi')][switch]$noStyle,

        [ValidateSet('h','v')][alias('type','mode','transpose')]
        [string]$orientation = 'h',

        [switch]$monthOnly, # month title style; displays no year

        [switch]$trim, # cuts trailing days

        [ValidateSet('u','l','t')]
        [string]$titleCase, # day name case option

        [alias('long')][switch]$wide, # uses AbbreviatedDayNames for ShortestDayNames

        [switch]$latin, # experimental; use english instead of national names
        [switch]$equalwidth, # experimental; for vertical calendars; equal width columns
        #[switch]$noWeekend, # experimental; do not highlight weekends
        [switch]$dayOff # holiday list; duplicate $highlightDate?
    )

    $calendar  = $inputObject.calendar
    if ($calendar.count -eq 0) {return}
    $separator = '  '
    $esc       = if ($IsCoreCLR) {"`e"} else {[char]27}
    $closeAnsi = "$esc[0m"
    $calendarStyle = @{ # default CSS
        Title      = "$esc[33m"
        DayOfWeek  = "$esc[1;1;36m"
        Today      = "$esc[30;47m"
        Highlight  = "$esc[91m"
        Weekend    = "$esc[31;1m"
        Holiday    = "$esc[38;5;1m"
        PreHoliday = "$esc[38;5;13m"
        Trails     = "$esc[90;1m"
        # runtime options
        titleCase   = $titleCase
        orientation = $orientation
        wide        = $wide
        noStyle     = $noStyle
        monthOnly   = $monthOnly
        trim        = $trim
        latin       = $latin # experimental
    }
    # Update CSS from user-defined table
    if ($PSCalendarConfig -and $PSCalendarConfig.count) {
        #$opt = Write-Output titleCase orientation wide noStyle monthOnly trim latin
        $PSCalendarConfig.Keys.foreach{
            $calendarStyle[$_] = $PSCalendarConfig[$_]
        }
    }

    # Initialize reference points
    $curMonth  = [datetime]::new($inputObject.year,$inputObject.month,1) # get-date -year $inputObject.year -month $inputObject.month -day 1 -hour 0 -minute 0 -second 0
    $fd        = $inputObject.firstday
    $i1        = 6 - $fd
    $i2        = if ($fd -eq 0) {0} else {$i1 + 1}
    $weekend   = $i1,$i2 # weekend indices
    $weekindex = (0..6+0..6)[$fd..($fd + 6)] # day sequence FDW-aware index
    $culture   = [system.globalization.cultureinfo]::CurrentCulture
    #if ($latin) {$culture = [system.globalization.cultureinfo]::new('en-us')}

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
    ##if ($psversiontable.PSVersion.Major -gt 5) {$wide = $true} # just in case
    $headstyle = if ($wide) {'AbbreviatedDayNames'} else {'ShortestDayNames'}
    $abbreviated = if ($latin) {
        [cultureinfo]::new('en-us').DateTimeFormat.$headstyle
    } else {$culture.DateTimeFormat.$headstyle}
    #if ($abbreviated.foreach('length') -eq 1) {
    #    $abbreviated = $culture.DateTimeFormat.AbbreviatedDayNames
    #} else
    if ($headstyle -eq 'ShortestDayNames') { # validate name series
        # NOTE: ShortestDayNames can be not unique
        $sdn = $abbreviated | Sort-Object -Unique
        if ($sdn.count -ne $abbreviated.count) {
            $abbreviated = if ($latin) {[cultureinfo]::new('en-us').DateTimeFormat.AbbreviatedDayNames} else {$culture.DateTimeFormat.AbbreviatedDayNames}
        }
    }

    # Align week day names
    # in some cultures short day names can vary in length, calculate the maximum width
    # in some cultures visual and calculated length can vary - font rendering issue
    $max = ($abbreviated.foreach{$_.length} | Measure-Object -Maximum).Maximum
    # PROBLEM: in some cultures 1 char takes 2 positions on screen
    # it is impossible here to exactly figure out the font subset to adjust day name title width
    $exclude = $culture.name -match '^(ja-?|zh-?|sa-|hi-?|ko-?)'
    # title width should be at least 2
    if ($max -lt 2 -and -not $exclude) {$max = 2}
    ##if ($orientation -eq 'v') {$max = -$max}
    ##$abbreviated = $abbreviated.foreach{"{0,$max}" -f $_}
    $abbreviated = if ($orientation -eq 'h') {
        $abbreviated.foreach{$_.padleft($max,' ')}
    } else {
        $abbreviated.foreach{$_.padright($max,' ')}
    }
    
    $wi        = $weekend
    $days      = $abbreviated[$weekindex].foreach{$_.replace('.','')}
    $weekdays  = $days
    $weekend   = $weekdays[$weekend] # not nice to redefined a variable
    if ($orientation -eq 'v') {
        # because a day object from The Collector exposes day name in English
        # $weekend should contain full day names in English as well
        #$weekend = [cultureinfo]::CurrentCulture.DateTimeFormat.DayNames[$weekindex][$wi] + 
        #[cultureinfo]::CurrentUICulture.DateTimeFormat.DayNames[$weekindex][$wi] +
        $weekend = [cultureinfo]::new('en-us').DateTimeFormat.DayNames[$weekindex][$wi]
    }
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
    #$hlday = {param ($day, $wkday)} experimental parameterization
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
                #. $hlday $week.$day $day
                if (($week.$day.date -eq [datetime]::today) -AND -Not $noStyle -and -not $cm) {
                    "{0}{1}{2}" -f $calendarStyle.Today, $value, $closeAnsi
    
                }
                elseif (($highlightDate -contains $week.$day.date) -AND -Not $noStyle) {
                    "{0}{1}{2}" -f $calendarStyle.Highlight, $value, $closeAnsi
                }
                else {
                    if ($noStyle) {$value}
                    elseif ($day -in $weekend -and $fd -in 0,1) {
                        $style = if ($trails) {'Trails'} else {'Weekend'}
                        "{0}{1}{2}" -f $calendarStyle.$style, $value, $closeAnsi
                    } elseif ($trails) {
                        "{0}{1}{2}" -f $calendarStyle.Trails, $value, $closeAnsi
                    }
                    else {$value}
                }
            }    
            $wk -join $separator
        }
    
        $days = if ($noStyle) {$weekdays} else {
            foreach ($d in $weekdays) {
                "{0}{1}{2}" -f $calendarStyle.DayofWeek, $d, $closeAnsi
            }
        }    
    } 
    else { # vertical calendar
        $dnpad = if ($monthOnly) {' '} else {'  '}
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
                $value = if (-not $equalwidth -and $i -eq 1 -and $maxw -eq 1) {"$d"}
                #else {"$d".padleft($headWidth, ' ')}
                else {"$d".padleft(2, ' ')}
                $i++
                #. $hlday $day $day.DayOfWeek
                if (($day.date -eq [datetime]::today) -AND -Not $noStyle -and -not $cm) {
                    "{0}{1}{2}" -f $calendarStyle.Today, $value, $closeAnsi
                }
                elseif (($highlightDate -contains $day.date) -AND -Not $noStyle) {
                    "{0}{1}{2}" -f $calendarStyle.Highlight, $value, $closeAnsi
                }
                else {
                    # NOTE: $day.DayOfWeek is always English so $weekend should contain English names
                    if ($noStyle) {$value}
                    elseif ($day.DayOfWeek -in $weekend -and $fd -in 0,1) {
                        $style = if ($trails) {'Trails'} else {'Weekend'}
                        "{0}{1}{2}" -f $calendarStyle.$style, $value, $closeAnsi
                    } elseif ($trails) {
                        "{0}{1}{2}" -f $calendarStyle.Trails, $value, $closeAnsi
                    }
                    else {$value}
                }
            }
            if (-not $noStyle) {
                $name = "{0}{1}{2}" -f $calendarStyle.DayofWeek, $name, $closeAnsi
            }
            "{0}${dnpad}{1}" -f $name, ($row -join $separator) # $dnpad working weird
        }
    } # end orientation formatter

    # Finalize format
    if ($latin) { # experimental
        $cm = [cultureinfo]::new('en-us').DateTimeFormat.MonthNames[$curMonth.month - 1]
        $plainHead = if ($monthOnly) {$cm} else {'{0} {1}' -f $cm, $curMonth.year}
    } else {
        $cm = $culture.DateTimeFormat.MonthNames[$curMonth.month - 1]
        $plainHead = if ($monthOnly) {$curMonth.tostring('MMMM')} 
        #else {'{0} {1}' -f $curMonth.tostring('MMMM'), $curMonth.tostring('yyyy')}
        else {'{0} {1}' -f $cm, $curMonth.year}
    }
    if ($psversiontable.PSVersion.Major -gt 5 -or $titleCase -eq 't') { # force T
        $plainHead = $culture.TextInfo.ToTitleCase($plainHead.ToLower())
    }
    $head = if ($noStyle) {$plainHead} else {
        "{0}{1}{2}" -f $calendarStyle.title, $plainhead, $closeAnsi
    }

    # centering calendar title; too complicated?
    $padhead = $separator.Length - 1
    [int]$pad = if ($orientation -eq 'v') {
        (($calendar.count+1)*(2 + $padhead) + $headWidth + 1 - $plainhead.Length) / 2
    } else {
        (7*($headWidth + $padhead) - $plainhead.Length) / 2 + 2
    }
    $p = if ($pad -gt 0) {' ' * $pad} else {''}
    $titleMargin = if ($noStyle) {''} else {"`n"}

    # Output
    "`n$p$head`n" # newline (btm margin) after the month title or only in plain mode?
    if ($orientation -eq 'h') {
        $days -join $separator
        if ($noStyle) {($days -join $separator) -replace '\w','-'}
    }
    $month
} # END format-calendar
