# This is a customized edition of Get-Calendar function by [@jdhitsolutions](https://github.com/jdhitsolutions/PSCalendar)
<#
.SYNOPSIS
.DESCRIPTION
.PARAMETERS
.EXAMPLES
.INPUTS
.OUTPUTS
#>

function Show-Calendar {
    [cmdletbinding(DefaultParameterSetName = "month")]
    [alias('cal','pscal')]
    param (
        [Parameter(Position = 1, ParameterSetName = "month")]
        [string]$month,
        [Parameter(Position = 2, ParameterSetName = "month")]
        [ValidatePattern('^\d{4}$')]
        [int]$year = ([datetime]::today).year,

        [Parameter(Mandatory, HelpMessage = "Enter the start of a month like 1/1/2020 that is correct for your culture.", ParameterSetName = "span")]
        [ValidateNotNullOrEmpty()]
        [string]$start,
        [Parameter(HelpMessage = "Enter an ending date for the month like 3/1/2020 that is correct for your culture.", ParameterSetName = "span")]
        [string]$end, # if not set ($start + 1 day)

        [Parameter(HelpMessage = "Specify a collection of dates to highlight in the calendar display.")]
        [ValidateNotNullorEmpty()]
        [string[]]$highlightDate,

        [Parameter(HelpMessage = "Specify the first day of the week.")]
        [ValidateNotNullOrEmpty()]
        [System.DayOfWeek]$firstDay = ([System.Globalization.CultureInfo]::CurrentCulture).DateTimeFormat.FirstDayOfWeek,

        [Parameter(HelpMessage = "Do not use any ANSI formatting.")]
        [alias('plain')][switch]$noANSI,
        [Parameter(HelpMessage = "Do not show any leading or trailing days.")]
        [alias('trim')][switch]$monthOnly,

        [ValidateSet('h','v')]
        [alias('type')][string]$orientation = 'h',
        [ValidateSet('u','l','t')]
        [string]$titleCase, # day name case option
        [switch]$wide, # AbbreviatedDayNames for ShortestDayNames
        #[switch]$grid, # experimental
        #[string]$culture, # experimental
        [switch]$dayOff # experimental
    )

    Begin {
        $currCulture = [system.globalization.cultureinfo]::CurrentCulture
        if ($month) {
            $c = [system.threading.thread]::currentThread.CurrentCulture
            $names = [cultureinfo]::GetCultureInfo($c).DateTimeFormat.Monthnames
            if ($names -notcontains $_) {
                if ($month -as [int]) {
                    $month = $currCulture.DateTimeFormat.MonthNames[[int]$month - 1]
                }
                else {
                    $n = $currCulture.TextInfo.ToTitleCase($month.ToLower())
                    $i = [array]::IndexOf([system.globalization.cultureinfo]::new('en-us').DateTimeFormat.MonthNames,$n)
                    $month = $currCulture.DateTimeFormat.MonthNames[$i]
                    if (-not $month -or $names -notcontains $month) {
                        Throw "You entered an invalid month. Valid choices are $($names -join ',')"
                    }
                }
            }
        } else {$month = ([datetime]::today).tostring('MMMM')}

        # enforce NoAnsi if running in the PowerShell ISE; who uses it?
        if ($host.name -Match "ISE Host") {$noAnsi = $true}
        if ($noAnsi) {$monthOnly = $true}

        $internationalDayOff = ''
    }
    Process {
        # validate $start and $end
        if ($PSCmdlet.ParameterSetName -eq 'span') {
            if ($start -and $start -as [int]) {$start = "1/$start/$([datetime]::now.Year)"}
            if ($end -and $end -as [int]) {$end = "1/$end/$([datetime]::now.Year)"}
            if (-not $end) {$end = [datetime]::parse($start).AddDays(1).tostring('dd/MM/yyyy')}
            if ([datetime]::parse($end) -lt [datetime]::parse($start)) {
                $start, $end = $end, $start
                ##Throw "[Validation Error] The end date ($end) must be later than the start date ($start)"
            }
        }

        # Figure out the first day of the start and end months
        if ($pscmdlet.ParameterSetName -eq "month") {
            $monthid = [datetime]::parse("1 $month $year").month
            $startd  = [datetime]::new($year, $monthid, 1)
            $endd    = $startd.date
        } else {
            $startd = $start -as [datetime]
            $endd   = $end -as [datetime]
        }

        if ($culture) {
            #$OldCulture = $PSCulture
            #$OldUICulture = $PSUICulture
            #[System.Threading.Thread]::CurrentThread.CurrentCulture = $culture
            #[System.Threading.Thread]::CurrentThread.CurrentUICulture = $culture
        }
        while ($startd -le $endd) {
            $params = @{
                highlightDate  = $highlightDate        
                noAnsi         = $noAnsi
                monthOnly      = $monthOnly
                wide           = $wide
            }
            if ($titleCase)   {$params['titleCase'] = $titleCase}
            if ($orientation) {$params['orientation'] = $orientation}
            get-calendarMonth -start $startd -firstday $firstDay | format-calendar @params

            # And now move onto the next month
            $startd = $startd.AddMonths(1)
        }
        if ($culture) {
            #[System.Threading.Thread]::CurrentThread.CurrentCulture = $OldCulture
            #[System.Threading.Thread]::CurrentThread.CurrentUICulture = $OldUICulture
        }
    } # process
} # END Show-Calendar
