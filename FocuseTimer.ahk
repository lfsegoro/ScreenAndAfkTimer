#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

global elapsedSeconds := 0
global sessionSeconds := 0
global noAfkSeconds := 0
global pauseCount := 0
global afkCount := 0
global totalElapsed := 0
global totalNoAfk := 0
global totalPause := 0
global totalAfk := 0
global today := A_YYYY A_MM A_DD ; Track today's date

Gui, +Resize +MinSize230x100 ; Enables resizing and sets a minimum window size
Gui, +AlwaysOnTop             ; Makes the window stay on top
Gui, Add, Text, w150 h25 cBlue vDateTimeText, Date/Time: %A_Now% ; Blue color for Date/Time
Gui, Add, Text, w150 h13 cGreen vTotalTimerText, Total Time Elapsed: 00:00:00 ; Green color for Total Time Elapsed
Gui, Add, Text, w150 h13 cOrange vNoAfkTimerText, Total Time noAFK: 00:00:00 ; Orange color for Total Time noAFK
Gui, Add, Text, w150 h13 cPurple vSessionTimerText, Current Session Time: 00:00:00 ; Purple color for Current Session Time
Gui, Add, Text, w150 h13 cRed vPauseCountText, Pause Count: 0 ; Red color for Pause Count
Gui, Add, Text, w150 h13 cCyan vAfkCountText, 5 mins AFK Count: 0 ; Cyan color for 5 mins AFK Count
Gui, Add, Button, w100 h30 gLogResults, Save
Gui, Show, , Stopwatch for "New World"

SetTimer, CheckWindowFocus, 100
SetTimer, UpdateDateTime, 1000
SetTimer, MonitorActivity, 1000
SetTimer, HourlyLogCheck, 60000 ; Check for hourly logging every minute
;LogResults("Start") ; Log results on app start
LoadPreviousValues() ; Load previous values on app start
Return

LoadPreviousValues() {
    ; Attempt to read the last line from the log file
    if (FileExist("stopwatch_log.csv")) {
        FileRead, logContents, stopwatch_log.csv
        lines := StrSplit(logContents, "`n")
        lastLine := lines[lines.Length()] ; Get the last line (ensure it’s not empty)

        ; If the last line is empty (e.g., newline at the end of the file), use the second last line
        if (lastLine = "")
            lastLine := lines[lines.Length() - 1]

        ; Extract values from the last line
        columns := StrSplit(lastLine, ",")
        if (columns.Length() >= 6) {
            logDateTime := columns[1] ; Column 1: Date/Time
            logTotalElapsed := columns[2] ; Column 2: Total Timer
            logNoAfk := columns[3] ; Column 3: NoAFK Timer

            ; Compare the log's date (extract from logDateTime) with today's date
            FormatTime, currentDate,, yyyy-MM-dd
            logDate := SubStr(logDateTime, 1, 10) ; Extract yyyy-MM-dd from logDateTime
            if (logDate = currentDate) {
                ; Parse previous values (convert HH:MM:SS to seconds)
                elapsedSeconds := ParseTimeToSeconds(logTotalElapsed)
                noAfkSeconds := ParseTimeToSeconds(logNoAfk)
            }
        }
    }
}

ParseTimeToSeconds(formattedTime) {
    parts := StrSplit(formattedTime, ":")
    if (parts.Length() = 3) {
        return (parts[1] * 3600) + (parts[2] * 60) + parts[3] ; Convert HH:MM:SS to total seconds
    }
    return 0
}


CheckWindowFocus:
    WinGetActiveTitle, activeTitle
    if (activeTitle = "New World") {
        if (!timerActive) {
            timerActive := true
            SetTimer, UpdateTotalTimer, 1000
        }
        if (!sessionActive) {
            sessionActive := true
            sessionSeconds := 0
            SetTimer, UpdateSessionTimer, 1000
        }
        if (!noAfkActive) {
            noAfkActive := true
            SetTimer, UpdateNoAfkTimer, 1000
        }
    } else {
        if (timerActive || sessionActive || noAfkActive) {
            pauseCount++
            totalPause := pauseCount
            GuiControl,, PauseCountText, Pause Count: %pauseCount%
        }
        timerActive := false
        sessionActive := false
        noAfkActive := false
        SetTimer, UpdateTotalTimer, Off
        SetTimer, UpdateSessionTimer, Off
        SetTimer, UpdateNoAfkTimer, Off
    }
Return

UpdateTotalTimer:
    elapsedSeconds++
    totalElapsed := elapsedSeconds

    totalHours := Floor(totalElapsed / 3600)
    totalMinutes := Floor((totalElapsed - (totalHours * 3600)) / 60)
    totalSeconds := Mod(totalElapsed, 60)
    formattedTotalTime := Format("{:02}:{:02}:{:02}", totalHours, totalMinutes, totalSeconds)
    GuiControl,, TotalTimerText, Total Time Elapsed: %formattedTotalTime%
Return

UpdateSessionTimer:
    sessionSeconds++

    sessionHours := Floor(sessionSeconds / 3600)
    sessionMinutes := Floor((sessionSeconds - (sessionHours * 3600)) / 60)
    sessionSecondsFormatted := Mod(sessionSeconds, 60)
    formattedSessionTime := Format("{:02}:{:02}:{:02}", sessionHours, sessionMinutes, sessionSecondsFormatted)
    GuiControl,, SessionTimerText, Current Session Time: %formattedSessionTime%
Return

UpdateNoAfkTimer:
    noAfkSeconds++
    totalNoAfk := noAfkSeconds

    noAfkHours := Floor(totalNoAfk / 3600)
    noAfkMinutes := Floor((totalNoAfk - (noAfkHours * 3600)) / 60)
    noAfkSecondsFormatted := Mod(totalNoAfk, 60)
    formattedNoAfkTime := Format("{:02}:{:02}:{:02}", noAfkHours, noAfkMinutes, noAfkSecondsFormatted)
    GuiControl,, NoAfkTimerText, Total Time noAFK: %formattedNoAfkTime%
Return

MonitorActivity:
    inputIdleTime := A_TimeIdlePhysical
    if (inputIdleTime > 300000) {
        if (noAfkActive) {
            SetTimer, UpdateNoAfkTimer, Off
            noAfkActive := false
            afkCount++
            totalAfk := afkCount
            GuiControl,, AfkCountText, 5 mins AFK Count: %afkCount%
        }
    } else if (timerActive && !noAfkActive) {
        noAfkActive := true
        SetTimer, UpdateNoAfkTimer, 1000
    }
Return

HourlyLogCheck:
    FormatTime, currentMinute,, mm
    if (currentMinute = "00") {
        LogResults("Hourly")
    }
Return

UpdateDateTime:
    FormatTime, currentDateTime,, yyyy-MM-dd HH:mm:ss
    GuiControl,, DateTimeText, Date/Time: %currentDateTime%
Return

LogResults(reason := "") {
    FormatTime, currentDateTime,, yyyy-MM-dd HH:mm:ss
    currentDate := A_YYYY A_MM A_DD

    ; Reset timers and counters if a new day
    if (currentDate != today) {
        today := currentDate
        elapsedSeconds := 0
        noAfkSeconds := 0
        pauseCount := 0
        afkCount := 0
    }

    ; Format values for logging
    totalElapsedHours := Floor(elapsedSeconds / 3600)
    totalElapsedMinutes := Floor((elapsedSeconds - (totalElapsedHours * 3600)) / 60)
    totalElapsedSeconds := Mod(elapsedSeconds, 60)
    formattedTotalTime := Format("{:02}:{:02}:{:02}", totalElapsedHours, totalElapsedMinutes, totalElapsedSeconds)

    totalNoAfkHours := Floor(noAfkSeconds / 3600)
    totalNoAfkMinutes := Floor((noAfkSeconds - (totalNoAfkHours * 3600)) / 60)
    totalNoAfkSeconds := Mod(noAfkSeconds, 60)
    formattedNoAfkTime := Format("{:02}:{:02}:{:02}", totalNoAfkHours, totalNoAfkMinutes, totalNoAfkSeconds)

    sessionHours := Floor(sessionSeconds / 3600)
    sessionMinutes := Floor((sessionSeconds - (sessionHours * 3600)) / 60)
    sessionSecondsFormatted := Mod(sessionSeconds, 60)
    formattedSessionTime := Format("{:02}:{:02}:{:02}", sessionHours, sessionMinutes, sessionSecondsFormatted)

    ; Prepare CSV line
    csvLine := currentDateTime "," formattedTotalTime "," formattedNoAfkTime "," formattedSessionTime "," pauseCount "," afkCount "`n"

    ; Append to CSV file
    FileAppend, %csvLine%, stopwatch_log.csv
}
