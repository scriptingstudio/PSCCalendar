# This is a customized edition of Get-Calendar function by Jeff Hicks (https://github.com/jdhitsolutions/PSCalendar)
<#
.SYNOPSIS
.DESCRIPTION
.PARAMETER
.EXAMPLE
.INPUTS
    None
.OUTPUTS
    String
#>

function Show-Calendar {
# Status: in dev
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
        [string]$end, # if not set ($start + 1 day); or 1 month?

        [Parameter(HelpMessage = "Specify a collection of dates to highlight in the calendar display.")]
        [ValidateNotNullorEmpty()]
        [string[]]$highlightDate,

        [Parameter(HelpMessage = "Specify the first day of the week.")]
        [ValidateNotNullOrEmpty()]
        [System.DayOfWeek]$firstDay = ([System.Globalization.CultureInfo]::CurrentCulture).DateTimeFormat.FirstDayOfWeek,

        [Parameter(HelpMessage = "Do not use any ANSI formatting.")]
        [alias('plain','noansi')][switch]$nostyle,
        [Parameter(HelpMessage = "Do not show any leading or trailing days.")]
        [alias('trim')][switch]$monthOnly,

        [ValidateSet('h','v')]
        [alias('type')][string]$orientation = 'h',
        [ValidateSet('u','l','t')]
        [string]$titleCase, # day name case option
        [switch]$wide, # uses AbbreviatedDayNames for ShortestDayNames
        #[switch]$grid, # experimental
        [string]$culture, # experimental; [CultureInfo]

        [switch]$dayOff # experimental; duplicate $highlightDate?
    )

    Begin {
        if ($culture -and $culture -match '\w-') {
            $OldCulture   = $PSCulture
            $OldUICulture = $PSUICulture
            [System.Threading.Thread]::CurrentThread.CurrentCulture   = $culture
            [System.Threading.Thread]::CurrentThread.CurrentUICulture = $culture
            if (-not $PSBoundParameters.ContainsKey('firstDay')) {
                $firstDay = [System.Threading.Thread]::CurrentThread.CurrentCulture.DateTimeFormat.FirstDayOfWeek
            }
        } else {$culture = $null}
        $curCulture = [system.globalization.cultureinfo]::CurrentCulture
        if ($month) {
            $c = [system.threading.thread]::currentThread.CurrentCulture
            $names = [cultureinfo]::GetCultureInfo($c).DateTimeFormat.Monthnames
            if ($names -notcontains $_) {
                if ($month -as [int]) {
                    $month = $curCulture.DateTimeFormat.MonthNames[[int]$month - 1]
                }
                else {
                    $n = $curCulture.TextInfo.ToTitleCase($month.ToLower())
                    $i = [array]::IndexOf([system.globalization.cultureinfo]::new('en-us').DateTimeFormat.MonthNames,$n)
                    $month = $curCulture.DateTimeFormat.MonthNames[$i]
                    if (-not $month -or $names -notcontains $month) {
                        Throw "You entered an invalid month. Valid choices are $($names -join ',')"
                    }
                }
            }
        } else {$month = ([datetime]::today).tostring('MMMM')}

        # Enforce NoAnsi if running in the PowerShell ISE; Is it still used?
        if ($host.name -Match "ISE Host") {$nostyle = $true}
        if ($nostyle) {$monthOnly = $true}

        $internationalDayOff = ''
    }
    Process {
        # Validate $start and $end
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

        while ($startd -le $endd) {
            $params = @{ # format controls
                highlightDate  = $highlightDate        
                noAnsi         = $nostyle
                monthOnly      = $monthOnly
                wide           = $wide
            }
            if ($titleCase)   {$params['titleCase'] = $titleCase}
            if ($orientation) {$params['orientation'] = $orientation}
            # Get data and format output
            get-calendarMonth -start $startd -firstday $firstDay | format-calendar @params

            $startd = $startd.AddMonths(1) # next month
        }
    } # process
    End {
        if ($culture -and $OldCulture) {
            [System.Threading.Thread]::CurrentThread.CurrentCulture   = $OldCulture
            [System.Threading.Thread]::CurrentThread.CurrentUICulture = $OldUICulture
        }
    }
} # END Show-Calendar
