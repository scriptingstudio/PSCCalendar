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

function Set-PsCss {
    param (
        [alias('default')][switch]$clear,
        [string]$Title,
        [string]$DayOfWeek,
        [string]$Today,
        [string]$Highlight,
        [string]$Weekend,
        [string]$Holiday,
        [string]$PreHoliday,
        [string]$Trails,

        [string]$orientation,
        [string]$titleCase,
        [switch]$trim,
        [switch]$latin, # experimental

        [switch]$run # safe execution method
    )

    $css = Get-Variable -name PSCalendarConfig -scope Script -ErrorAction 0
    $css = if (-not $css) {
        $css = Get-Variable -name PSCalendarConfig -scope Global -ErrorAction 0
        if (-not $css) {
            if ($run) {
                ($script:PSCalendarConfig = @{})
            } else {@{}}
        }
        else {$global:PSCalendarConfig}
    } else {$script:PSCalendarConfig}

    if ($clear) {$css.clear()}
    $ansi = Write-Output Title DayOfWeek Today Highlight Weekend Holiday PreHoliday Trails
    $opt  = $ansi + (Write-Output titleCase trim orientation latin)
    $opt.foreach{
        if ($PSBoundParameters.ContainsKey($_)) {
            $css[$_] = $PSBoundParameters[$_]
        }
    }
    if (-not $css.count -and -not $clear) {
        Write-Warning 'New CSS is empty'
        return
    }

    if (-not $run -and -not $clear) {Write-Host "CSS after applying new settings:"}
    if (-not $clear) {
        $cfg  = [ordered]@{}
        $e    = if ($IsCoreCLR) {'`e'} else {'$([char]27)'}
        $esc  = [char]27
        $css.keys.foreach{
            if ($_ -in $ansi) {
                $cfg[$_] = "$($css[$_]){0}{1}$esc[0m" -f $e, $(($css[$_].ToCharArray() | Select-Object -Skip 1 ) -join '')
            }
            else {$cfg[$_] = $css[$_]}
        }
        [pscustomobject]$cfg | Format-List
    }
} # END Set-PsCss

function Get-PsCss ([switch]$default) {
    if ($default) { # show default Formatter settings
        $css = [ordered]@{ # should be synchronized with format-calendar
            Title      = "$esc[33m"
            DayOfWeek  = "$esc[1;1;36m"
            Today      = "$esc[30;47m"
            Highlight  = "$esc[91m"
            Weekend    = "$esc[31;1m"
            Holiday    = "$esc[38;5;1m"
            PreHoliday = "$esc[38;5;13m"
            Trails     = "$esc[90;1m"    
        }
    } else {
        $css = Get-Variable -name PSCalendarConfig -scope Script -ErrorAction 0
        $css = if (-not $css) {
            $css = Get-Variable -name PSCalendarConfig -scope Global -ErrorAction 0
            if (-not $css) {return}
            else {$global:PSCalendarConfig}
        } else {$script:PSCalendarConfig}
        if (-not $css.count) {
            Write-Warning 'CSS is empty'
            return
        }
    }

    $e    = if ($IsCoreCLR) {'`e'} else {'$([char]27)'}
    $esc  = [char]27
    $ansi = Write-Output Title DayOfWeek Today Highlight Weekend Holiday PreHoliday Trails
    $cfg  = [ordered]@{}

    $css.keys.foreach{
        if ($_ -in $ansi) {
            $cfg[$_] = "$($css[$_]){0}{1}$esc[0m" -f $e, $(($css[$_].ToCharArray() | Select-Object -Skip 1 ) -join '')
        }
        else {$cfg[$_] = $css[$_]}
    }
    [pscustomobject]$cfg | Format-List
} # END Get-PsCss
