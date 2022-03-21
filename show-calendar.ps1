# This is a customized edition of Get-Calendar function by Jeff Hicks (https://github.com/jdhitsolutions/PSCalendar)

function Show-Calendar {
# Status: in dev
# begin,process,end blocks are useless if pileline-awareness is not configured; just for visual structure?
    [cmdletbinding(DefaultParameterSetName = "month")]
    [alias('cal','pscal')]
    param (
        [Parameter(Position = 1, ParameterSetName = "month")]
        [string]$month,
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
        [alias('highlightDay','hd')][string[]]$highlightDate, # alias "weekend"

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
        ##[switch]$noWeekend # experimental;
    )

    Begin {
        # Initialize culture settings
        $curCulture = [system.globalization.cultureinfo]::CurrentCulture
        if ($culture) { # not finished?
            $c = try {[cultureinfo]::GetCultureInfo($culture)} catch {}
            if (-not $c) { # or display calendar in current culture? - autodefault
                ##$culture = $null
                Throw "Invalid culture ID specified. Find desired culture ID by command [cultureinfo]::GetCultures('allCultures')"
            } # else { 
            $OldCulture   = $PSCulture
            $OldUICulture = $PSUICulture
            [System.Threading.Thread]::CurrentThread.CurrentCulture   = $culture
            [System.Threading.Thread]::CurrentThread.CurrentUICulture = $culture # ???
            if (-not $PSBoundParameters.ContainsKey('firstDay')) {
                [System.DayOfWeek]$firstDay = [System.Threading.Thread]::CurrentThread.CurrentCulture.DateTimeFormat.FirstDayOfWeek
            }
            if (-not $PSBoundParameters.ContainsKey('year')) {
                [int]$year = [datetime]::today.tostring('yyyy')
            }
            $curCulture = [System.Threading.Thread]::CurrentThread.CurrentCulture
            #}
        }

        # Validate $month
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
                        $month = $curCulture.DateTimeFormat.MonthNames[([datetime]::today.month - 1)] # autodefault
                        #Throw "Invalid month specified. Valid choices are $($names -join ',')"
                    }
                }
            }
        } else {$month = [datetime]::today.tostring('MMMM')}

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

        # Figure out the first day of the start and the end months
        if ($pscmdlet.ParameterSetName -eq 'month') {
            $monthid = [array]::IndexOf($curCulture.DateTimeFormat.MonthNames,$month)
            $startd  = [datetime]::new($year, 1+$monthid, 1)
            $endd    = $startd
        } else {
            $startd = $start -as [datetime]
            $endd   = $end -as [datetime]
        }

        if ($startd.Year -ne $endd.Year) {$monthOnly = $false}
        $equalwidth = $startd.Month -ne $endd.Month
        while ($startd -le $endd) {
            $params = @{ # format controls
                highlightDate  = $highlightDate        
                nostyle        = $nostyle
                trim           = $trim
                monthOnly      = $monthOnly
                wide           = $wide
                equalwidth     = $equalwidth # experimental
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
