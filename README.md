<!--
README.md
- https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax#referencing-external-resources
- https://daringfireball.net/projects/markdown/syntax#backslash
-->
# PSCCalendar

***PSCCalendar*** is a culture-aware PowerShell console calendar engine inspired by (and based on) [@jdhitsolutions](https://github.com/jdhitsolutions/PSCalendar) PSCalendar module but significantly/totally rewritten/refactored. It is not technically a PowerShell module, just snippets/sketches as a sandbox to play with calendar ideas.

`C` is for Console and Culture.

## Tier Architecture
1. Input Controller
2. Data Collector
3. Output Formatter

![pscal](https://user-images.githubusercontent.com/17237559/158593488-c95aa3bd-badd-4fc2-a549-21f790f7a537.png)

`Controller` is a high-lever (wrapper), end-user function. `Collector`, `Formatter` are internal helpers but can be used all alone.

**MVC model mapping**
- `Model` - collector
- `View` - formatter
- `Controller` - controller

## Notes on Culture (dependencies)
- Short day names can be different length
- `ShortestDayNames` property values can be not unique
- Visual and calculated length of short names can vary (seems to be a font rendering issue: [Example 7](https://github.com/scriptingstudio/PSCCalendar/blob/main/show-calendar.md#example-7-culture-font-rendering-anomalies)). The formatter tries to adjust day name titles by the max width
- The beginning of the week is not only Mon/Sun
- If Mon/Sun is not the beginning of the week, what are weekends?
- No certainty whether Sat/Sun are world-wide weekend/dayoff days
- There are 3 categories of culture issues
    - **Critical** (non Gregorian Calendar): ar, ar-SA, yav\* 
    - **Warning** (font rendering): as-\*, az, az-Latn, az-Latn-AZ, bn, bn-\*, bo, bo-\*, br, br-\*, brx\*, ccp, ccp-\*, cu, cu-\*, doi, doi-\*, dua, dua-\*, dv, dv-\*, dz, dz-\*, ewo, ewo-\*, ff, ff-\*, gu, gu-\*, hi, hi-\*, ii, ii-\*, jgo, jgo-\*, kok, kok-\*, ks, ks-arab\*, mai\*, mr\*, my\*, ne\*, nmg\*, nnh\*, or\*, pcm*, sa, sa-\*, sd-deva\*, si\*, te, te-\*, uz-arab\*, yi\*, yo\*, zh-Hans\*
    - **Information** (small visual shift): km, km-\*, kn, kn-\*, pa-guru, pa-in, ksf\*, ml\*, mni\*

## Notes on PowerShell (dependencies)
- Month names can be in lower case
- PS7: short day names can be in lower case
- PS7: short day names can be single-char
- The culture sets in PS7 and PS5 differ (.NET versions differ)
```powershell
[cultureinfo]::GetCultures('allCultures') | . { process {
    [pscustomobject]@{
        Culture = $_.DisplayName
        Id      = $_.name
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

## How to use
- Copy PSCCalendar sources to your script or dotsource it to PowerShell console/terminal
- See examples [here](https://github.com/scriptingstudio/PSCCalendar/blob/main/show-calendar.md)

## Known Issues
- Some cultures display day names incorrectly ([Example 7](https://github.com/scriptingstudio/PSCCalendar/blob/main/show-calendar.md#example-7-culture-font-rendering-anomalies))

## ToDo
- Fix or work around culture issues
- Multicolumn (grid) by month output
- International holiday highlighting
- Adaptive coloring
- General styling improvements
- Controller parameters optimization
