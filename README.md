<!--
README.md
- https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax#referencing-external-resources
- https://daringfireball.net/projects/markdown/syntax#backslash
-->

# PSCCalendar

***PSCCalendar*** is a simple culture-aware PowerShell console calendar engine/framework inspired by [@jdhitsolutions](https://github.com/jdhitsolutions/PSCalendar) PSCalendar module but significantly/totally rewritten/refactored. It is not technically a PowerShell module, just snippets/sketches as a sandbox to play with calendar ideas.

`C` is for Console and Culture.

## Tier Architecture

1. Input Controller
2. Data Collector
3. Output Formatter

![pscal](https://user-images.githubusercontent.com/17237559/158593488-c95aa3bd-badd-4fc2-a549-21f790f7a537.png)

`Controller` is a high-level end-user commands. `Collector`, `Formatter` are internal helpers but can be used all alone.

### MVC model mapping

- `Model` - collector
- `View` - formatter
- `Controller` - controller

### Infrastructure

| Tier       | Commands | Files | Help |
|------------|----------|-------|------|
| Controller | Show-Calendar<br/>Find-Culture<br/>Set-PsCss<br/>Get-PsCss | show-calendar.ps1 | show-calendar.md<br/>README.md |
| Collector  | Get-CalendarMonth | get-calendarmonth.ps1 | |
| Formatter  | Format-Calendar | format-calendar.ps1 | |

## Notes on Culture

- Short day names can be different length
- `ShortestDayNames` property values can be not unique
- Visual and calculated length of short names can vary (It seems to be a font rendering issue: [Example 7](https://github.com/scriptingstudio/PSCCalendar/blob/main/show-calendar.md#example-7-culture-font-rendering-anomalies)). The formatter tries to adjust day name titles by max width 
- The beginning of the week is not only Mon/Sun
- If Mon/Sun is not the beginning of the week, what are weekends?
- No certainty whether Sat/Sun are world-wide weekend/dayoff days
- In some cultures 1 char takes 2 positions on screen
- There are 3 categories of culture issues
    - **Critical** (specific non Gregorian Calendar): ar, ar-SA, yav\* - **FIXED**
    - **Warning** (font rendering): as-\*, az, az-Latn, az-Latn-AZ, bn, bn-\*, bo, bo-\*, br, br-\*, brx\*, ccp, ccp-\*, cu, cu-\*, doi, doi-\*, dua, dua-\*, dv, dv-\*, dz, dz-\*, ewo, ewo-\*, ff, ff-\*, gu, gu-\*, hi, hi-\*, ii, ii-\*, jgo, jgo-\*, kok, kok-\*, ks, ks-arab\*, mai\*, mr\*, my\*, ne\*, nmg\*, nnh\*, or\*, pcm\*, sa, sa-\*, sd-deva\*, si\*, te, te-\*, uz-arab\*, yi\*, yo\*, zh-Hans\*
    - **Information** (small visual shift): km, km-\*, kn, kn-\*, pa-guru, pa-in, nus\*, ksf\*, ml\*, mni\*
- Font rendering issue
    - There are cultures where some characters become conditionally invisible (merging with neighboring ones), and this does not depend on font
    - A character width in monospace fonts is not constant
    - Workaround: use of english names instead of national ones
<!-- - A calendar with **critical** issue will not show -->

## Notes on PowerShell

- Month names can be in lower case
- PS7: short day names can be in lower case
- PS7: short day names can be single-char
- The culture sets in PS7 and PS5 differ (.NET versions differ)

```powershell
[cultureinfo]::GetCultures('allCultures') | . { process {
    [pscustomobject]@{
        Culture = $_.DisplayName
        Id      = $_.Name
        FDW     = [cultureinfo]::new($_).DateTimeFormat.FirstDayOfWeek
    }
}} | Group-Object fdw -NoElement

# PS5
Count Name
----- ----
  250 Sunday
   41 Saturday
  598 Monday

# PS7
Count Name
----- ----
  256 Sunday
  570 Monday
    2 Friday
   41 Saturday
```

## How to Use

- Copy content of `get-calendarmonth.ps1`, `format-calendar.ps1`, and `show-calendar.ps1` files to your script or dotsource it to PowerShell console/terminal
- See examples [here](https://github.com/scriptingstudio/PSCCalendar/blob/main/show-calendar.md)

## CSS – Calendar Style Sheet

The `Formatter`, like any web-browser, has its own built-in style sheet but it can be partially or completely redefined manually with `hashtable` global/script scope variable `$PSCalendarConfig`. Styling is based on using of ANSI escape sequences. Default settings are:

```powershell
$PSCalendarConfig = @{
    Title      = "$([char]27)[33m"
    DayOfWeek  = "$([char]27)[1;1;36m"
    Today      = "$([char]27)[30;47m"
    Highlight  = "$([char]27)[91m"
    Weekend    = "$([char]27)[31;1m"
    Holiday    = "$([char]27)[38;5;1m"
    PreHoliday = "$([char]27)[38;5;13m" # in some cultures, business hours of the day before the holiday are shorter
    Trails     = "$([char]27)[90;1m" # non current month days
}
```

### Formatter Configuration Automation

`$PSCalendarConfig` is a user-defined `Formatter` configuration and can be managed by two commands: `Set-PsCss` and `Get-PsCss` which are the part of `Controller`.

**Set-PsCss**

```powershell
Set-PsCss [-title <ANSI_color>] [-dayofweek <ANSI_color>] 
[-today <ANSI_color>] [-highlight <ANSI_color>] 
[-weekend <ANSI_color>] [-holiday <ANSI_color>] 
[-preHoliday <ANSI_color>] [-trails <ANSI_color>] 
[-orientation h|v] [-titleCase u|l|t] [-trim:$true|$false] 
[-latin:$true|$false]
[-remove <style_name[]>] [-clear] [-run]
```

<table><tbody>
<tr><td valign="top"><code>-title</code>, <code>&#8209;dayofweek</code>, <br/><code>&#8209;today</code>, <code>&#8209;highlight</code>, <br/><code>&#8209;weekend</code>, <code>&#8209;holiday</code>,  <br/><code>&#8209;preHoliday</code>, <code>&#8209;trails</code></td><td valign="top">These parameters set new calendar colors/styles.</td></tr>

<tr><td valign="top"><code>&#8209;orientation</code></td><td>Sets default calendar type.</td></tr>

<tr><td valign="top"><code>&#8209;titleCase</code></td><td>Sets default calendar titles case.</td></tr>

<tr><td valign="top"><code>&#8209;trim</code></td><td>Sets default display mode for the non-current month days.</td></tr>

<tr><td valign="top"><code>&#8209;latin</code></td><td>[experimental] Sets English titles as default that prevents incorrect screen text alignment for problem cultures.</td></tr>

<tr><td valign="top"><code>&#8209;remove</code></td><td>Removes one or more parameters from user CSS.</td></tr>

<tr><td valign="top"><code>&#8209;clear</code></td><td>Clears user CSS.</td></tr>

<tr><td valign="top"><code>-run</code></td><td><i>The technique of safe execution.</i><br/>Allows to apply changes. If this parameter is not specified the command will show how new CSS would look.<br/>This parameter prevents accidental change so it makes the command safe by default. It is not so important for this project but that is a principle of safe execution used far before PowerShell.</td></tr>
</tbody></table>

**Get-PsCss**

```powershell
Get-PsCss [-default]
```

<table><tbody>
<tr><td><code>&#8209;default</code></td><td>Shows up built-in CSS of <code>Formatter</code>.</td></tr>
</tbody></table>

## Culture Explorer

**PSCCalendar** has a set of commands to work with calendar/culture. One of them is **CSS Configurator** which has been introduced above. The other tool is **Culture Explorer** implemented by command `Find-Culture`. **Culture Explorer** is the part of `Controller`.

### Syntax

```powershell
Find-Culture [[-culture] <string>]
```

<table><tbody>
<tr><td><code>&#8209;culture</code></td><td>Search mask.<br/>The finder uses regular expressions to filter cultures by short and long culture names.</td></tr>
</tbody></table>

### Examples

```powershell
# find culture by short name
Find-Culture fr-fr

Culture      : French (France)
Id           : fr-FR
FDW          : Monday
Calendar     : Gregorian
OtherFormats : System.Globalization.DateTimeFormatInfo

# find culture by long name
Find-Culture French | ft

Culture                            Id          FDW Calendar  OtherFormats
-------                            --          --- --------  ------------
French                             fr       Monday Gregorian System.Globalization.DateTimeFormatInfo
French (Caribbean)                 fr-029   Monday Gregorian System.Globalization.DateTimeFormatInfo
French (Belgium)                   fr-BE    Monday Gregorian System.Globalization.DateTimeFormatInfo
French (Burkina Faso)              fr-BF    Monday Gregorian System.Globalization.DateTimeFormatInfo
French (Burundi)                   fr-BI    Monday Gregorian System.Globalization.DateTimeFormatInfo
French (Benin)                     fr-BJ    Monday Gregorian System.Globalization.DateTimeFormatInfo
French (Saint Barthélemy)          fr-BL    Monday Gregorian System.Globalization.DateTimeFormatInfo
French (Canada)                    fr-CA    Sunday Gregorian System.Globalization.DateTimeFormatInfo
French (Congo DRC)                 fr-CD    Monday Gregorian System.Globalization.DateTimeFormatInfo
French (Central African Republic)  fr-CF    Monday Gregorian System.Globalization.DateTimeFormatInfo
...

# exploring all formats
(Find-Culture fr-fr).OtherFormats

AMDesignator                     :
Calendar                         : System.Globalization.GregorianCalendar
DateSeparator                    : /
FirstDayOfWeek                   : Monday
CalendarWeekRule                 : FirstFourDayWeek
FullDateTimePattern              : dddd d MMMM yyyy HH:mm:ss
LongDatePattern                  : dddd d MMMM yyyy
LongTimePattern                  : HH:mm:ss
MonthDayPattern                  : d MMMM
PMDesignator                     :
RFC1123Pattern                   : ddd, dd MMM yyyy HH':'mm':'ss 'GMT'
ShortDatePattern                 : dd/MM/yyyy
ShortTimePattern                 : HH:mm
SortableDateTimePattern          : yyyy'-'MM'-'dd'T'HH':'mm':'ss
TimeSeparator                    : :
UniversalSortableDateTimePattern : yyyy'-'MM'-'dd HH':'mm':'ss'Z'
YearMonthPattern                 : MMMM yyyy
AbbreviatedDayNames              : {dim., lun., mar., mer....}
ShortestDayNames                 : {di, lu, ma, me...}
DayNames                         : {dimanche, lundi, mardi, mercredi...}
AbbreviatedMonthNames            : {janv., févr., mars, avr....}
MonthNames                       : {janvier, février, mars, avril...}
IsReadOnly                       : False
NativeCalendarName               : calendrier grégorien
AbbreviatedMonthGenitiveNames    : {janv., févr., mars, avr....}
MonthGenitiveNames               : {janvier, février, mars, avril...}
```

## Known Issues

- Some cultures display day names incorrectly ([Example 7](https://github.com/scriptingstudio/PSCCalendar/blob/main/show-calendar.md#example-7-culture-font-rendering-anomalies))

## ToDo and Experimental

- Fix or work around culture issues
- Multicolumn (grid) by month output
- International holiday highlighting
- Adaptive coloring
- CSS enhancements
- Controller parameters optimization

## Credits

- The **PSCCalendar** idea was originally inspired from and based on the [PSCalendar module](https://github.com/jdhitsolutions/PSCalendar) by Jeff Hicks.
