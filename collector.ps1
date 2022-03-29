# Collector v2.0

function get-calendarMonth {
# Calendar data collector
# Output: binary (raw) calendar and month markers
# Output data go down the pipeline to the formatter tier
    param (
        [ValidateNotNullOrEmpty()]
        [alias('month')][datetime]$start = [datetime]::new(([datetime]::now.year),([datetime]::now.month),1,0,0,0), #(Get-Date -Day 1 -Hour 0 -Minute 0 -Second 0) - slower

        [ValidateNotNullOrEmpty()]
        [System.DayOfWeek]$firstDay = 'Monday' # Mon - most used day among cultures
    )

    $culture = [system.globalization.cultureinfo]::CurrentCulture
    $mo      = $start.month
    $yr      = $start.year
    #$mo      = [int]$start.tostring('MM')
    #$yr      = [int]$start.tostring('yyyy')
    $max     = try {$culture.DateTimeFormat.Calendar.GetDaysInMonth($yr, $mo)} 
    catch {Write-Warning "There was a problem. $($_.exception.message)"}
    if (-not $max) {return @{}} # culture date reckoning issue / non georgian calendar
    $end     = Get-Date -Year $yr -Month $mo -Day $max
    #$end     = [datetime]::new($yr, $mo, $max)
    $fd      = $firstDay.value__
    # generic/logical day names; they are replaced with actual on the formatter tier
    $days    = 'D1','D2','D3','D4','D5','D6','D7' 

    # Adjust for the beginning of the calendar and the month
    # calendar is a table of 7xN, N - number of weeks
    if ($start.day -ne 1) {$start = [datetime]::new($yr,$mo,1)} # validate $start
    $currentDay = $start # the beginning of the month
    while ($currentDay.DayOfWeek.value__ -ne $fd) {
        $currentDay = $currentDay.AddDays(-1)
    }
    # $currentDay is now the beginning of the calendar

    # Build the month calendar object
    # the calendar can contain trails from both the previous and the next months to full fill calendar rectangle
    # the trails can be trimmed up on the formatter tier
    $month = while ($currentDay.date -le $end.date) {
        $week = '' | Select-Object -property $days
        $days.foreach{
            $week.$_ = $currentDay
            $currentDay = $currentDay.AddDays(1)
        }
        $week
    }
    @{ # output protocol/interface
        Calendar = $month # binary calendar
        Month    = $mo    # month number
        Year     = $yr
        FirstDay = $fd    # index in day name series
    }
} # END get-calendarMonth
