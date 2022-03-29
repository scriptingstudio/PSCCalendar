# Controller v1.4

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
        [string]$end, # if not specified $end = $start + 1 month

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

        [switch]$monthOnly, # month title style; if specified will cut the year off

        [ValidateSet('h','v')]
        [alias('type','mode','transpose')][string]$orientation = 'h',

        [ValidateSet('u','l','t')]
        [string]$titleCase, # day name case option

        [alias('long')][switch]$wide, # uses AbbreviatedDayNames instead ShortestDayNames
        
        [alias('language')][System.Globalization.CultureInfo]$culture,

        #[ValidateCount(2,2)]
        [array]$weekend, # weekend day names
        
        [switch]$latin, # experimental; english titles instead of national; workaround for problem cultures

        [Parameter(ParameterSetName = "span")]
        [switch]$grid, # experimental; [int]
        [switch]$dayOff # experimental; duplicate $highlightDate?
    )

    Begin {
        # Initialize culture settings
        $curCulture = [System.Globalization.CultureInfo]::CurrentCulture
        if ($culture) {
            $OldCulture   = $PSCulture
            $OldUICulture = $PSUICulture
            [System.Threading.Thread]::CurrentThread.CurrentCulture   = $culture
            [System.Threading.Thread]::CurrentThread.CurrentUICulture = $culture
            if (-not $PSBoundParameters.ContainsKey('firstDay')) {
                [System.DayOfWeek]$firstDay = [System.Threading.Thread]::CurrentThread.CurrentCulture.DateTimeFormat.FirstDayOfWeek
            }
            if (-not $PSBoundParameters.ContainsKey('year')) {
                [int]$year = [datetime]::today.tostring('yyyy')
            }
            $curCulture = [System.Threading.Thread]::CurrentThread.CurrentCulture
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

        # Enforce NoStyle if running in the PowerShell ISE; just in case
        if ($host.name -match "ISE Host") {$nostyle = $true}
        if ($nostyle) {$trim = $true}

        $internationalDayOff = '' # TODO

        # Validate weekend day names and convert em to indices
        if ($weekend) {
            if ($weekend -match 'ww|%|default|^d(ef(ault)?)?$') {$weekend = 'sa','su'}
            [string[]]$weekend = switch -regex ($weekend) {
                'm|1'   {'Monday'}
                '^tu|2' {'Tuesday'}
                'w|3'   {'Wednesday'}
                'th|4'  {'Thursday'}
                'f|5'   {'Friday'}
                'sa|6'  {'Saturday'}
                'su|7'  {'Sunday'}
            }
            if ($weekend.count -lt 2) {
                Write-Warning "Possible errors: 1 - Invalid day name specified. Valid values are of English day names. Specify 2 days. 2 - The number of provided arguments is fewer than the minimum number of allowed arguments (2)."
                $weekend = $null
            } else {
                $dn = [cultureinfo]::new('en-us').DateTimeFormat.DayNames
                $weekend = $weekend[0,1] | ForEach-Object {[array]::IndexOf($dn,$_)}
            }
        }
    } # begin
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
        $equalwidth = $startd.Month -ne $endd.Month # experimental
        while ($startd -le $endd) {
            $params = @{ # formatter controls
                highlightDate  = $highlightDate        
                nostyle        = $nostyle
                trim           = $trim
                monthOnly      = $monthOnly
                wide           = $wide
                equalwidth     = $equalwidth # experimental
                latin          = $latin # experimental
                weekend        = $weekend
            }
            if ($titleCase)   {$params['titleCase'] = $titleCase}
            if ($orientation) {$params['orientation'] = $orientation}

            # Get data (Collector), format output (Formatter)
            get-calendarMonth -start $startd -firstday $firstDay | format-calendar @params

            try {$startd = $startd.AddMonths(1)} catch {break} # select next month
        }
    } # process
    End {
        if ($culture -and $OldCulture) {
            [System.Threading.Thread]::CurrentThread.CurrentCulture   = $OldCulture
            [System.Threading.Thread]::CurrentThread.CurrentUICulture = $OldUICulture
        }
    }
} # END Show-Calendar
    
# Controller Auxiliary Tools

function Find-Culture ([string]$culture, [alias('dtf')][switch]$DateTimeFormat) {
# Simple culture explorer
    if (-not $culture) {$culture = '.*'}
    [cultureinfo]::GetCultures('allCultures').where{$_.Name,$_.DisplayName -match $culture} | . { process {
        $cultureinfo = [cultureinfo]::new($_)
        if ($DateTimeFormat) {return $cultureinfo.DateTimeFormat}
        $dtf = $cultureinfo.DateTimeFormat
        [pscustomobject]@{
            Culture      = $_.DisplayName
            Id           = $_.Name
            FDW          = $dtf.FirstDayOfWeek
            Calendar     = $dtf.Calendar.tostring().split('.')[2].replace('Calendar','')
            DateFormat   = $dtf
            NumberFormat = $cultureinfo.NumberFormat
        }
    }}
} # END Find-Culture

function Set-PsCss {
    param (
        [string]$Title,
        [string]$DayOfWeek,
        [string]$Today,
        [string]$Highlight,
        [string]$Weekend,
        [string]$Holiday,
        [string]$PreHoliday,
        [string]$Trails,

        [ValidateSet('h','v')]
        [string]$orientation,
        [ValidateSet('u','l','t')]
        [string]$titleCase,
        [switch]$trim,
        [switch]$latin, # experimental
        [ValidateCount(2,2)]
        [string[]]$weekendlist,
        #[switch]$noStyle,

        [alias('rm','del')][string[]]$remove,
        [alias('default','reset')][switch]$clear,

        [alias('apply')][switch]$run # safe execution technique
    )

    $ansi = '<ANSI_color>'
    $bl   = '$true|$false'
    Write-Host "USAGE: set-pscss [-title $ansi] [-dayofweek $ansi] [-today $ansi] [-highlight $ansi] [-weekend $ansi] [-holiday $ansi] [-preHoliday $ansi] [-trails $ansi] [-orientation h|v] [-titleCase u|l|t] [-trim:$bl] [-latin:$bl] [-weekendlist <string[]>] [-remove <string[]>] [-clear] [-run]`n"

    $css = Get-Variable -name PSCalendarConfig -scope Script -ErrorAction 0
    $css = if (-not $css) {
        $css = Get-Variable -name PSCalendarConfig -scope Global -ErrorAction 0
        if (-not $css) {
            if ($run) {
                ($script:PSCalendarConfig = @{})
            } else {@{}}
        }
        else {if ($run) {$global:PSCalendarConfig} else {@{}+$global:PSCalendarConfig}}
    } else {if ($run) {$script:PSCalendarConfig} else {@{}+$script:PSCalendarConfig}}

    # Precleaning CSS
    if ($run) {
        if ($remove) {$remove.foreach{$css.remove($_)}}
        elseif ($clear) {$css.clear()}
    }

    $ansi = Write-Output Title DayOfWeek Today Highlight Weekend Holiday PreHoliday Trails
    $opt  = $ansi + (Write-Output titleCase trim orientation latin weekendlist) # noStyle
    $opt.foreach{
        if ($PSBoundParameters.ContainsKey($_)) {
            # filter empty values
            if ($PSBoundParameters[$_]) {$css[$_] = $PSBoundParameters[$_]}
        }
    }
    if (-not $css.count) {
        if ($PSBoundParameters.count) {
            Write-Warning 'New CSS is empty' # write mode
        } else {Write-Host 'CSS is empty' -ForegroundColor Yellow} # read mode
        return
    }

    if (-not $run -and -not $clear) {
        if ($PSBoundParameters.count) {Write-Host "CSS after new settings applied:"}
        else {Write-Host "User-defined CSS:"}
    }
    if (-not $clear) {
        $cfg  = [ordered]@{}
        $e    = if ($IsCoreCLR) {'`e'} else {'$([char]27)'}
        $esc  = [char]27
        $css.keys.foreach{
            $cfg[$_] = if ($_ -in $ansi) {
                "$($css[$_]){0}{1}$esc[0m" -f $e, $(-join ($css[$_].ToCharArray() | Select-Object -Skip 1))
            }
            else {$css[$_]}
        }
        [pscustomobject]$cfg | Format-List
    }
} # END Set-PsCss

function Get-PsCss ([switch]$default) {
    Write-Host "USAGE: get-pscss [-default]"
    if ($default) { # show up default Formatter settings
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
            Write-Host 'CSS is empty' -ForegroundColor Yellow
            return
        }
    }

    $e    = if ($IsCoreCLR) {'`e'} else {'$([char]27)'}
    $esc  = [char]27
    $ansi = Write-Output Title DayOfWeek Today Highlight Weekend Holiday PreHoliday Trails
    $cfg  = [ordered]@{}

    $css.keys.foreach{
        $cfg[$_] = if ($_ -in $ansi) {
            "$($css[$_]){0}{1}$esc[0m" -f $e, $(-join ($css[$_].ToCharArray() | Select-Object -Skip 1 ))
        }
        else {$css[$_]}
    }
    [pscustomobject]$cfg | Format-List
} # END Get-PsCss
