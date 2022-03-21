<!-- show-calendar.md -->
# Show-Calendar

## SYNOPSIS
Displays a calendar. <!-- A calendar generator -->

## DESCRIPTION
This command displays a month calendar. It supports multiple months, representation type, basic styling, setting culture as well as the ability to highlight a specific dates, and more. The default display uses ANSI escape sequences for styling.

When you enter `HighlightDate`, `Start`, or `End` dates, be sure to use the format that is culturally appropriate. It should match the pattern you get by command `(Get-Culture).datetimeformat.ShortDatePattern` or part of the pattern.

## SYNTAX
There are two types of calendar range setting. <!-- [<CommonParameters>] -->

### month (default)
```powershell
Show-Calendar [[-Month] <String>] [[-Year] <Int32>] [-HighlightDate <String[]>] [-FirstDay <DayOfWeek>] [-Culture <String>] [-NoStyle] [-MonthOnly] [-Trim] [-Orientation <String>] [-TitleCase <String>] [-Wide]
```
### span <!-- [-Grid <Int32>] -->
```powershell
Show-Calendar -Start <String> [-End <String>] [-HighlightDate <String[]>] [-FirstDay <DayOfWeek>] [-Culture <String>] [-NoStyle] [-MonthOnly] [-Trim] [-Orientation <String>] [-TitleCase <String>] [-Wide]
```

## EXAMPLES
**Note:** Examples can not reproduce full command output coloring due to Markdown limitations. <!-- imperfection -->
### Example 1: Default view
```powershell
Show-Calendar

       March 2022

Su  Mo  Tu  We  Th  Fr  Sa
27  28   1   2   3   4   5
 6   7   8   9  10  11  12
13  14  15  16  17  18  19
20  21  22  23  24  25  26
27  28  29  30  31   1   2
```
### Example 2: Cut (trim) trailing months
```powershell
Show-Calendar -trim

       March 2022

Su  Mo  Tu  We  Th  Fr  Sa
         1   2   3   4   5
 6   7   8   9  10  11  12
13  14  15  16  17  18  19
20  21  22  23  24  25  26
27  28  29  30  31
```
### Example 3: Display vertical representation of a calendar (default is horisontal)
```powershell
Show-Calendar -trim -orientation v

      March 2022

Su      6  13  20  27
Mo      7  14  21  28
Tu  1   8  15  22  29
We  2   9  16  23  30
Th  3  10  17  24  31
Fr  4  11  18  25
Sa  5  12  19  26
```
### Example 4: Display `monthonly` title
```powershell
Show-Calendar -trim -orientation v -monthOnly

        March

Su      6  13  20  27
Mo      7  14  21  28
Tu  1   8  15  22  29
We  2   9  16  23  30
Th  3  10  17  24  31
Fr  4  11  18  25
Sa  5  12  19  26
```
### Example 5: Override the default first day of the week 
```powershell
Show-Calendar -firstday Monday

        March 2022

Mo  Tu  We  Th  Fr  Sa  Su
28   1   2   3   4   5   6
 7   8   9  10  11  12  13
14  15  16  17  18  19  20
21  22  23  24  25  26  27
28  29  30  31   1   2   3
```
### Example 6: Select another culture 
```powershell
Show-Calendar -culture fr-fr -trim

        mars 2022

lu  ma  me  je  ve  sa  di
     1   2   3   4   5   6
 7   8   9  10  11  12  13
14  15  16  17  18  19  20
21  22  23  24  25  26  27
28  29  30  31
```

### Example 7: Culture font rendering anomalies 
```powershell
Show-Calendar -culture zh-CN -trim

        三月 2022

一  二  三  四  五  六  日
     1   2   3   4   5   6
 7   8   9  10  11  12  13
14  15  16  17  18  19  20
21  22  23  24  25  26  27
28  29  30  31

Show-Calendar -culture ja-JP -trim

        3月 2022

日  月  火  水  木  金  土
         1   2   3   4   5
 6   7   8   9  10  11  12
13  14  15  16  17  18  19
20  21  22  23  24  25  26
27  28  29  30  31

Show-Calendar -culture ar-QA -trim

        مارس 2022

س  ح  ن  ث  ر  خ  ج
             1   2   3   4
 5   6   7   8   9  10  11
12  13  14  15  16  17  18
19  20  21  22  23  24  25
26  27  28  29  30  31
```
Cases 1 and 2 are actually correct. Visual shift is due to Markdown oddities.

## PARAMETERS
### -Month
Selects a month to display. The command will default to the current year unless otherwise specified. Month numbers are accepted.

### -Year
Selects a year for the specified month.

### -Start
The first month to display. You must format the dates to match your culture. It should match the pattern you get by command `(Get-Culture).datetimeformat.ShortDatePattern`. The parameter can also accept the parts of the pattern like `8 mar`,`8.3`,`3`. The parameter parser will try to complete the input value.

### -End
The last month to display. You must format the dates to match your culture. It should match the pattern you get by command `(Get-Culture).datetimeformat.ShortDatePattern`. The parameter can also accept the parts of the pattern like `8 mar`,`8.3`,`3`. The parameter parser will try to complete input value. If not specified the next month will be used.

### -HighlightDate
Specific days (named) to highlight. These dates are color formatted using ANSI escape sequences. You must format the dates to match your culture. It should match the pattern you get by command `(Get-Culture).datetimeformat.ShortDatePattern`. The parameter can also accept the parts of the pattern like `8 mar`,`8.3`,`3`. The parameter parser will try to complete the input value.

### -FirstDay
Specifies the first day of the week that should be displayed first. 

### -Culture
Calendar culture. Specify the culture name in the format of command `(Get-Culture).Name` output.
The full list of culture names you can get by running command `[cultureinfo]::GetCultures('allCultures')`.

### -Trim
This switch cuts any leading or trailing days from other months for the current month.

### -NoStyle
This switch turns off any ANSI formatting. The output will be plain-text. This also means that the current day and highlight dates will not be reflected in the output. This parameter has no affect when running the command in the PowerShell ISE. There is no color formatting when using this host.

### -MonthOnly
This switch alters the month title style to "without year". The default style is with year.

### -Orientation
This parameter selects representation type of the calendar to display. There are 2 types: horisontal (default) and vertical. Valid type values are `v` and `h` for vertical and horisontal type respectively. The default orientation is horisontal.

### -TitleCase
By this parameter you can select a case of the day names and month title. Valid values are `u`, `l`, `t` for uppercase, lowercase, and titlecase respectively.

### -Wide
This switch selects display type of the calendar day names. By default `ShortestDayNames` property is used to display day names. The name width is 1 to 5 chars depending on the selected culture. Alternatively the width by `AbbreviatedDayNames` property is 2 to 5 chars depending on the selected culture. In PowerShell 7 the default display type is wide because one-char names can be not unique.

## INPUTS
### Defined by the command parameters

## OUTPUTS
### System.String[]

## NOTES
- Weekend days are highlighted by default if the first day of the week is Monday or Sunday 

## CREDITS
- The PSCCalendar idea was originally inspired from and based on the [PSCalendar module](https://github.com/jdhitsolutions/PSCalendar) by Jeff Hicks. <!-- This manual is a kind of extended edition of the origin. -->
