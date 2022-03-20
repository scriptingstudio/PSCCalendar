# This is a customized edition of Get-Calendar function by Jeff Hicks (https://github.com/jdhitsolutions/PSCalendar)

function Show-Calendar {
# Status: in dev
# begin,process,end blocks are useless if pileline-awareness is not configured
    [cmdletbinding(DefaultParameterSetName = "month")]
    [alias('cal','pscal')]
    param (
        [Parameter(Position = 1, ParameterSetName = "month")]
        [string]$month = [datetime]::today.tostring('MMMM'),
        [Parameter(Position = 2, ParameterSetName = "month")]
        [ValidatePattern('^\d{4}$')]
        [int]$year = [datetime]::today.year,

        [Parameter(Mandatory, HelpMessage = "Enter the start of a month like 1/1/2020 that is correct for your culture.", ParameterSetName = "span")]
        [ValidateNotNullOrEmpty()]
        [string]$start,
        [Parameter(HelpMessage = "Enter an ending date for the month like 3/1/2020 that is correct for your culture.", ParameterSetName = "span")]
        [string]$end, # if not specified ($start + 1 month)

        [Parameter(HelpMessage = "Specify a collection of dates to highlight in the calendar display.")]
        [ValidateNotNullorEmpty()]
        [alias('highlightDay','hd')][string[]]$highlightDate,

        [Parameter(HelpMessage = "Specify the first day of the week.")]
        [ValidateNotNullOrEmpty()]
        [alias('fd')][System.DayOfWeek]$firstDay = ([System.Globalization.CultureInfo]::CurrentCulture).DateTimeFormat.FirstDayOfWeek,

        [Parameter(HelpMessage = "Do not use any ANSI formatting.")]
        [alias('plain','noansi')][switch]$noStyle,
        [Parameter(HelpMessage = "Do not show leading/trailing days of non-current month.")]
        [switch]$trim, # cuts trailing days
        [switch]$monthOnly, # month title style; displays no year

        [ValidateSet('h','v')]
        [alias('type')][string]$orientation = 'h',
        [ValidateSet('u','l','t')]
        [string]$titleCase, # day name case option
        [switch]$wide, # uses AbbreviatedDayNames instead ShortestDayNames
        [alias('language')][string]$culture, # [cultureinfo]
        
        [Parameter(ParameterSetName = "span")]
        [switch]$grid, # experimental; [int]
        [switch]$dayOff # experimental; duplicate $highlightDate?
    )

    Begin {
        $curCulture = [system.globalization.cultureinfo]::CurrentCulture
        if ($culture) { # not finished
            $c = try {[cultureinfo]::GetCultureInfo($culture)} catch {}
            if (-not $c) { # or display calendar in current culture? - autocorrection
                ##$culture = $null
                Throw "Invalid culture ID specified. Find desired culture ID with command [cultureinfo]::GetCultures('allCultures')"
            } # else { 
            $OldCulture   = $PSCulture
            $OldUICulture = $PSUICulture
            [System.Threading.Thread]::CurrentThread.CurrentCulture   = $culture
            [System.Threading.Thread]::CurrentThread.CurrentUICulture = $culture # ???
            if (-not $PSBoundParameters.ContainsKey('firstDay')) {
                [System.DayOfWeek]$firstDay = [System.Threading.Thread]::CurrentThread.CurrentCulture.DateTimeFormat.FirstDayOfWeek
            }
            if (-not $PSBoundParameters.ContainsKey('month')) {$month = [datetime]::today.tostring('MMMM')}
            $curCulture = [System.Threading.Thread]::CurrentThread.CurrentCulture
        }
        if ($month) {
            $c = [system.threading.thread]::currentThread.CurrentCulture
            $names = [cultureinfo]::GetCultureInfo($c).DateTimeFormat.Monthnames
            if ($names -notcontains $month) {
                if ($month -as [int]) {
                    if (12 -lt $month) {$month = [datetime]::today.month}
                    $month = $curCulture.DateTimeFormat.MonthNames[[int]$month - 1]
                }
                else {
                    $n = $curCulture.TextInfo.ToTitleCase($month.ToLower())
                    $i = [array]::IndexOf($curCulture.DateTimeFormat.MonthNames,$n)
                    if ($i -eq -1) {
                        $i = [array]::IndexOf([cultureinfo]::new('en-us').DateTimeFormat.MonthNames,$n)
                    }
                    $month = $curCulture.DateTimeFormat.MonthNames[$i]
                    if (-not $month -or $names -notcontains $month) {
                        $month = $curCulture.DateTimeFormat.MonthNames[([datetime]::today.month - 1)] # autocorrection
                        #Throw "Invalid month specified. Valid choices are $($names -join ',')"
                    }
                }
            }
        } #else {$month = [datetime]::today.tostring('MMMM')}

        # Enforce NoStyle if running in the PowerShell ISE; Is it still used?
        if ($host.name -Match "ISE Host") {$nostyle = $true}
        if ($nostyle) {$trim = $true}

        $internationalDayOff = ''
    }
    Process {
        # Validate $start and $end
        if ($PSCmdlet.ParameterSetName -eq 'span') {
            if ($start -as [int]) {$start = "1/$start/$([datetime]::now.Year)"}
            if ($end -and $end -as [int]) {$end = "1/$end/$([datetime]::now.Year)"}
            if (-not $end) {$end = [datetime]::parse($start).AddMonths(1).tostring('dd/MM/yyyy')}
            if ([datetime]::parse($end) -lt [datetime]::parse($start)) {
                $start, $end = $end, $start # autocorrection
            }
        }

        # Figure out the first day of the start and end months
        if ($pscmdlet.ParameterSetName -eq "month") {
            <## !!! not all cultures tested; japan was a problem !!!DELETE!!!
            # adjust date format to specified/default culture
            $ldp = [string[]][char[]]($curCulture.DateTimeFormat.LongDatePattern.toupper())
            $y,$m,$d = foreach ($item in 'Y','M','D') {[array]::indexof($ldp,$item)}
            $s = $y,$m,$d | measure-object -Minimum -Maximum
            $p1 = if ($s.Maximum -eq $d) {2} elseif ($s.Minimum -eq $d) {0} else {1}
            $p2 = if ($s.Maximum -eq $m) {2} elseif ($s.Minimum -eq $m) {0} else {1}
            $p3 = if ($s.Maximum -eq $y) {2} elseif ($s.Minimum -eq $y) {0} else {1}
            $dateformat = "{$p3} {$p2} {$p1}" -f $year, $month, 1
            $monthid = try {[datetime]::parse($dateformat).month} catch {}
            if (-not $monthid) {Throw "Incorrect date format for '$($curCulture.name)' culture."}
            #if (-not $monthid) {$monthid = [datetime]::today.month}
            $startd  = [datetime]::new($year, $monthid, 1)
            $endd    = $startd.date#>
            $monthid = [array]::IndexOf($curCulture.DateTimeFormat.MonthNames,$month)
            $startd  = [datetime]::new($year, $mmonthid + 1, 1)
            $endd    = $startd
        } else {
            $startd = $start -as [datetime]
            $endd   = $end -as [datetime]
        }

        if ($startd.Year -ne $endd.Year) {$monthOnly = $false}
        while ($startd -le $endd) {
            $params = @{ # format controls
                highlightDate  = $highlightDate        
                nostyle        = $nostyle
                trim           = $trim
                monthOnly      = $monthOnly
                wide           = $wide
            }
            if ($titleCase)   {$params['titleCase'] = $titleCase}
            if ($orientation) {$params['orientation'] = $orientation}

            # Get data and format output
            get-calendarMonth -start $startd -firstday $firstDay | format-calendar @params

            try {$startd = $startd.AddMonths(1)} catch {break} # next month
        }
    } # process
    End {
        if ($culture -and $OldCulture) {
            [System.Threading.Thread]::CurrentThread.CurrentCulture   = $OldCulture
            [System.Threading.Thread]::CurrentThread.CurrentUICulture = $OldUICulture
        }
    }
} # END Show-Calendar
