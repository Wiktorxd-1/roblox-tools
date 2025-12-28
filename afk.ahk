#Persistent
SetTitleMatchMode, 3

isRunning := false
totalWindows := 0
interval1 := 420000
interval2 := 840000
activeInterval := 1
clickInterval := (activeInterval = 1) ? interval1 : interval2
previousActiveWindow := 0
previousActiveWindowTitle := ""
manualRun := false
timerCountdown := clickInterval // 1000 
notifFile := A_ScriptDir . "\notif.mp3"
notifPlayed := false
abortNow := false
settingsOpen := false


FormatSeconds(s) {
    hh := s // 3600
    mm := mod(s // 60, 60)
    ss := mod(s, 60)
    
    if (hh > 0)
        return hh ":" (mm < 10 ? "0" mm : mm) ":" (ss < 10 ? "0" ss : ss)
    else if (mm > 0)
        return mm ":" (ss < 10 ? "0" ss : ss)
    else
        return ss
}

UpdateWindowCount() {
    global totalWindows
    WinGet, id, List, Roblox
    totalWindows := id
    if (!totalWindows || totalWindows = "") {
        GuiControl, , WindowCount, No windows found.
        return
    }
    GuiControl, , WindowCount, %totalWindows%
}

Gui, 1: +AlwaysOnTop
Gui, 1: Add, Text, , Amount of roblox windows found: 
Gui, 1: Add, Edit, vWindowCount r1 w200 ReadOnly
Gui, 1: Add, Button, gOpenSettings, Settings 

Gui, 1: Show, x50 y50 w320, Roblox AFK 
settingsOpen := false
IfWinExist, Settings
    WinClose, Settings
Gui, 3: Destroy

GuiControl, 1:, WindowCount, 0
GuiControl, 2:, TimerDisplay, % FormatSeconds(timerCountdown)

SetTimer, UpdateWindowCount, -50
SetTimer, UpdateWindowCount, -300

SetTimer, CloseSettingsOnce, -150
CloseSettingsOnce:
    settingsOpen := false
    IfWinExist, Settings
        WinClose, Settings
    Gui, 3: Destroy
Return


HumanizeHotkey(ahk) {
    if (!ahk) return ""
    mods := []
    if InStr(ahk, "^")
        mods.Push("Ctrl")
    if InStr(ahk, "!")
        mods.Push("Alt")
    if InStr(ahk, "+")
        mods.Push("Shift")
    if InStr(ahk, "#")
        mods.Push("Win")
    displayKey := ahk
    displayKey := StrReplace(displayKey, "^", "")
    displayKey := StrReplace(displayKey, "!", "")
    displayKey := StrReplace(displayKey, "+", "")
    displayKey := StrReplace(displayKey, "#", "")
    if (mods.MaxIndex()) {
        joined := ""
        for idx, v in mods {
            if (idx = 1)
                joined := v
            else
                joined := joined . "+" . v
        }
        return joined . "+" . displayKey
    }
    return displayKey
}

OpenSettings:
    settingsOpen := true
    if (isRunning)
        StopScript()
    FileRead, s, %A_ScriptFullPath%

    HKStart := "F2"
    HKClose := "F3"
    HKManual := "F4"
    HKAbort := "F5"
    HKTog := "F7"
    RegExMatch(s, "(?m)^\s*(\S+)::\s*\r?\n\s*if\s*\(\!isRunning\)", m)
    if (m1)
        HKStart := m1
    RegExMatch(s, "(?m)^\s*(\S+)::\s*\r?\n\s*StopScript\(\)\r?\n\s*CloseGui\(\)", m)
    if (m1)
        HKClose := m1
    RegExMatch(s, "(?m)^\s*(\S+)::\s*\r?\n\s*if\s*\(isRunning\)", m)
    if (m1)
        HKManual := m1
    RegExMatch(s, "(?m)^\s*(\S+)::\s*\r?\n\s*abortNow\s*:=\s*true", m)
    if (m1)
        HKAbort := m1
    RegExMatch(s, "(?m)^\s*(\S+)::\s*\r?\n\s*oldInterval\s*:=\s*clickInterval", m)
    if (m1)
        HKTog := m1


    FormatInterval(interval1, i1num, i1unit)
    FormatInterval(interval2, i2num, i2unit)
    if (!i1unit) {
        i1unit := "min"
        i1num := interval1 // 60000
    }
    if (!i2unit) {
        i2unit := "min"
        i2num := interval2 // 60000
    }

    HKStartAhk := "F2"
    HKCloseAhk := "F3"
    HKManualAhk := "F4"
    HKAbortAhk := "F5"
    HKTogAhk := "F7"
    RegExMatch(s, "(?m)^\s*(\S+)::\s*\r?\n\s*if\s*\(\!isRunning\)", m)
    if (m1) {
        HKStartAhk := m1
        HKStart := HumanizeHotkey(m1)
    }
    RegExMatch(s, "(?m)^\s*(\S+)::\s*\r?\n\s*StopScript\(\)\r?\n\s*CloseGui\(\)", m)
    if (m1) {
        HKCloseAhk := m1
        HKClose := HumanizeHotkey(m1)
    }
    RegExMatch(s, "(?m)^\s*(\S+)::\s*\r?\n\s*if\s*\(isRunning\)", m)
    if (m1) {
        HKManualAhk := m1
        HKManual := HumanizeHotkey(m1)
    }
    RegExMatch(s, "(?m)^\s*(\S+)::\s*\r?\n\s*abortNow\s*:=\s*true", m)
    if (m1) {
        HKAbortAhk := m1
        HKAbort := HumanizeHotkey(m1)
    }
    RegExMatch(s, "(?m)^\s*(\S+)::\s*\r?\n\s*oldInterval\s*:=\s*clickInterval", m)
    if (m1) {
        HKTogAhk := m1
        HKTog := HumanizeHotkey(m1)
    }

    Gui, 3: New, +AlwaysOnTop +Resize
    Gui, 3: Font, s10
    Gui, 3: Add, Text, x150 y8 w120 Center, Hotkeys
    Gui, 3: Add, Text, x10 y36, Start/Pause
    Gui, 3: Add, Edit, vHKStart Center x110 y34 w130, %HKStart%
    Gui, 3: Add, Button, x250 y34 w90 gRecordHKStart, Record

    Gui, 3: Add, Text, x10 y66, Exit
    Gui, 3: Add, Edit, vHKClose Center x110 y64 w130, %HKClose%
    Gui, 3: Add, Button, x250 y64 w90 gRecordHKClose, Record

    Gui, 3: Add, Text, x10 y96, Run Instantly
    Gui, 3: Add, Edit, vHKManual Center x110 y94 w130, %HKManual%
    Gui, 3: Add, Button, x250 y94 w90 gRecordHKManual, Record

    Gui, 3: Add, Text, x10 y126, Return to window
    Gui, 3: Add, Edit, vHKAbort Center x110 y124 w130, %HKAbort%
    Gui, 3: Add, Button, x250 y124 w90 gRecordHKAbort, Record

    Gui, 3: Add, Text, x10 y156, Switch Interval
    Gui, 3: Add, Edit, vHKTog Center x110 y154 w130, %HKTog%
    Gui, 3: Add, Button, x250 y154 w90 gRecordHKTog, Record


    Gui, 3: Add, Text, x10 y190, Interval 1
    Gui, 3: Add, Edit, vI1Num x110 y188 w80, %i1num%
    Gui, 3: Add, DropDownList, vI1Unit x200 y188 w70, ms|s|min|h
    Gui, 3: Add, Text, x10 y220, Interval 2
    Gui, 3: Add, Edit, vI2Num x110 y218 w80, %i2num%
    Gui, 3: Add, DropDownList, vI2Unit x200 y218 w70, ms|s|min|h

    Gui, 3: Add, Text, x10 y258, Interval
    Gui, 3: Add, DropDownList, vActiveInterval x110 y256 w60, 1|2
    Gui, 3: Add, Button, x90 y298 w80 gSaveSettings, Save
    Gui, 3: Add, Button, x190 y298 w80 gCancelSettings, Cancel

    StringReplace, i1unit, i1unit, %A_Space%, , All
    StringReplace, i2unit, i2unit, %A_Space%, , All
    GuiControl, 3: , I1Unit, ms|s|min|h
    if (i1unit = "ms")
        GuiControl, 3: Choose, I1Unit, 1
    else if (i1unit = "s")
        GuiControl, 3: Choose, I1Unit, 2
    else if (i1unit = "min")
        GuiControl, 3: Choose, I1Unit, 3
    else if (i1unit = "h")
        GuiControl, 3: Choose, I1Unit, 4

    GuiControl, 3: , I2Unit, ms|s|min|h
    if (i2unit = "ms")
        GuiControl, 3: Choose, I2Unit, 1
    else if (i2unit = "s")
        GuiControl, 3: Choose, I2Unit, 2
    else if (i2unit = "min")
        GuiControl, 3: Choose, I2Unit, 3
    else if (i2unit = "h")
        GuiControl, 3: Choose, I2Unit, 4

    GuiControl, 3:, I1Num, %i1num%
    GuiControl, 3:, I2Num, %i2num%
    GuiControl, 3: , ActiveInterval, 1|2
    sel := (activeInterval = 1) ? 1 : 2
    GuiControl, 3: Choose, ActiveInterval, %sel%

    Gui, 3: Show, w360 h360, Settings
Return

CancelSettings:
    settingsOpen := false
    Gui, 3: Destroy
Return

SaveSettings:
    settingsOpen := false
    Gui, 3: Submit, NoHide
    global HKStartAhk, HKCloseAhk, HKManualAhk, HKAbortAhk, HKTogAhk, ActiveInterval
    if (HKStart == "" || HKAbort == "") {
        MsgBox, 48, Error, Hotkeys cannot be empty (at least Start and Abort).
        return
    }

    i1 := ConvertToMs(I1Num, I1Unit)
    i2 := ConvertToMs(I2Num, I2Unit)
    if (!i1)
        i1 := interval1
    if (!i2)
        i2 := interval2
    ActiveInterval := ActiveInterval + 0
    if (ActiveInterval != 1 && ActiveInterval != 2)
        ActiveInterval := 1
    if (!i1 || !i2) {
        MsgBox, 48, Error, Invalid interval values. Make sure intervals are set.
        return
    }

    FileRead, s, %A_ScriptFullPath%


    s := RegExReplace(s, "(?m)^\s*interval1\s*:=\s*\d+", "interval1 := " i1)
    s := RegExReplace(s, "(?m)^\s*interval2\s*:=\s*\d+", "interval2 := " i2)


    startAhk := (HKStartAhk ? HKStartAhk : DehumanizeHotkey(HKStart))
    closeAhk := (HKCloseAhk ? HKCloseAhk : DehumanizeHotkey(HKClose))
    manualAhk := (HKManualAhk ? HKManualAhk : DehumanizeHotkey(HKManual))
    abortAhk := (HKAbortAhk ? HKAbortAhk : DehumanizeHotkey(HKAbort))
    togAhk := (HKTogAhk ? HKTogAhk : DehumanizeHotkey(HKTog))
    startLabel := startAhk . "::"
    closeLabel := closeAhk . "::"
    manualLabel := manualAhk . "::"
    abortLabel := abortAhk . "::"
    togLabel := togAhk . "::"

    s := RegExReplace(s, "(?m)^[ \t]*\S+::(?=\r?\n\s*if\s*\(\!isRunning\))", startLabel)
    s := RegExReplace(s, "(?m)^[ \t]*\S+::(?=\r?\n\s*StopScript\(\)\r?\n\s*CloseGui\(\))", closeLabel)
    s := RegExReplace(s, "(?m)^[ \t]*\S+::(?=\r?\n\s*if\s*\(isRunning\))", manualLabel)
    s := RegExReplace(s, "(?m)^[ \t]*\S+::(?=\r?\n\s*abortNow\s*:=\s*true)", abortLabel)
    s := RegExReplace(s, "(?m)^[ \t]*\S+::(?=\r?\n\s*oldInterval\s*:=\s*clickInterval)", togLabel)

    s := RegExReplace(s, "(?m)^\s*activeInterval\s*:=\s*\d+", "activeInterval := " . ActiveInterval)

    activeInterval := ActiveInterval + 0
    clickInterval := (activeInterval = 1) ? interval1 : interval2

    FileDelete, %A_ScriptFullPath%
    FileAppend, %s%, %A_ScriptFullPath%

    MsgBox, 64, Saved, Settings saved. Reloading script...
    Sleep, 300
    Reload
Return

ConvertToMs(num, unit) {
    if (!num) return 0

    if (num is not number) {

        if RegExMatch(num, "^\s*(\d+(?:\.\d+)?)\s*([a-zA-Z]+)\s*$", m) {
            number := m1 + 0
            unitStr := m2
            unit := SubStr(unitStr, 1, 2)
            unit := Lower(unit)

            if (unit = "ms")
                return number
            else if (unit = "s" || unit = "se")
                return number * 1000
            else if (unit = "mi")
                return number * 60000
            else if (unit = "h")
                return number * 3600000

            unit := Lower(unitStr)
            if (unit ~= "ms|msec|millisecond|milliseconds")
                return number
            if (unit ~= "s|sec|secs|second|seconds")
                return number * 1000
            if (unit ~= "m|min|mins|minute|minutes")
                return number * 60000
            if (unit ~= "h|hr|hrs|hour|hours")
                return number * 3600000
            return 0
        }
        return 0
    }

    num := num + 0
    if (unit = "ms")
        return num
    else if (unit = "s")
        return num * 1000
    else if (unit = "min")
        return num * 60000
    else if (unit = "h")
        return num * 3600000
    return 0
}

FormatInterval(ms, ByRef outNum, ByRef outUnit) {
    outUnit := "ms"
    outNum := ms
    if ((ms // 3600000) * 3600000 == ms) {
        outNum := ms // 3600000
        outUnit := "h"
    } else if ((ms // 60000) * 60000 == ms) {
        outNum := ms // 60000
        outUnit := "min"
    } else if ((ms // 1000) * 1000 == ms) {
        outNum := ms // 1000
        outUnit := "s"
    }
}




Gui, 2: +AlwaysOnTop -Caption +LastFound +ToolWindow
Gui, 2: Color, 010101
WinSet, TransColor, 010101
Gui, 2: Font, s22 w900 cFF0000, Arial Black
Gui, 2: Add, Text, vTimerDisplay Center w250, % FormatSeconds(timerCountdown)
Gui, 2: Show, % "x" . (A_ScreenWidth - 260) . " y10 NoActivate", TimerOverlay
WinSet, AlwaysOnTop, On, TimerOverlay
WinShow, TimerOverlay
GuiControl, 2:, TimerDisplay, % FormatSeconds(timerCountdown)
SetTimer, EnsureTimerVisible, 1000
EnsureTimerVisible:
    if !WinExist("TimerOverlay") {
        Gui, 2: Show, % "x" . (A_ScreenWidth - 260) . " y10 NoActivate", TimerOverlay
        WinSet, TransColor, 010101
        WinSet, AlwaysOnTop, On, TimerOverlay
        WinShow, TimerOverlay
        GuiControl, 2:, TimerDisplay, % FormatSeconds(timerCountdown)
    } else {
        WinSet, AlwaysOnTop, On, TimerOverlay
    }
Return

SetTimer, UpdateWindowCount, 5000
UpdateWindowCount()
SetTimer, UpdateWindowCount, -200
UpdateWindowCountDelayed:
    UpdateWindowCount()
Return

F2::
    if (settingsOpen) {
        MsgBox, 48, Settings open, Close the Settings window before running the macro.
        return
    }
    if (!isRunning) {
        isRunning := true
        previousActiveWindow := WinActive("A")
        WinGetTitle, previousActiveWindowTitle, ahk_id %previousActiveWindow%
        timerCountdown := clickInterval // 1000
        notifPlayed := false
        GuiControl, 2:, TimerDisplay, % FormatSeconds(timerCountdown)
        SetTimer, ClickRobloxWindows, %clickInterval%
        SetTimer, UpdateCountdown, 1000 
    } else {
        StopScript()
    }
Return


F4::
    if (settingsOpen) {
        MsgBox, 48, Settings open, Close the Settings window before running the macro.
        return
    }
    if (isRunning) {
        SetTimer, ClickRobloxWindows, Off
        manualRun := true
        ClickRobloxWindows()
        manualRun := false
        SetTimer, ClickRobloxWindows, %clickInterval%
        timerCountdown := clickInterval // 1000
        notifPlayed := false
        GuiControl, 2:, TimerDisplay, % FormatSeconds(timerCountdown)
    } else {
        manualRun := true
        ClickRobloxWindows()
        manualRun := false
    }
Return

F5::
    abortNow := true
    StopScript()
    RestorePreviousWindow()
Return

F7::
    oldInterval := clickInterval
    oldSec := oldInterval // 1000
    elapsed := oldSec - timerCountdown
    if (elapsed < 0)
        elapsed := 0

    if (clickInterval = interval1)
        clickInterval := interval2
    else
        clickInterval := interval1

    newSec := clickInterval // 1000
    if (isRunning) {
        newTimer := newSec - elapsed
        if (newTimer < 0)
            newTimer := 0
        timerCountdown := newTimer
        SetTimer, ClickRobloxWindows, Off
        SetTimer, ClickRobloxWindows, %clickInterval%
    } else {
        timerCountdown := newSec
    }

    notifPlayed := false
    GuiControl, 2:, TimerDisplay, % FormatSeconds(timerCountdown)
Return

UpdateCountdown:
    if (isRunning) {
        timerCountdown--
        if (timerCountdown < 0)
            timerCountdown := (clickInterval // 1000) - 1

        if (timerCountdown == 30 && !notifPlayed) {
            if FileExist(notifFile)
                PlayNotification(notifFile)
            notifPlayed := true
        }
        
        GuiControl, 2:, TimerDisplay, % FormatSeconds(timerCountdown)
    }
Return

StopScript() {
    global isRunning, clickInterval, timerCountdown, notifPlayed
    SetTimer, ClickRobloxWindows, Off
    SetTimer, UpdateCountdown, Off
    isRunning := false
    timerCountdown := clickInterval // 1000
    notifPlayed := false
    GuiControl, 2:, TimerDisplay, % FormatSeconds(timerCountdown)
} 

ClickRobloxWindows() {
    global isRunning, totalWindows, clickInterval, timerCountdown, notifPlayed, abortNow, previousActiveWindow, previousActiveWindowTitle, manualRun
    
    if (manualRun || !isRunning || !previousActiveWindow) {
        previousActiveWindow := WinActive("A")
        WinGetTitle, previousActiveWindowTitle, ahk_id %previousActiveWindow%
    }

    if (abortNow) {
        abortNow := false
        return
    }

    timerCountdown := clickInterval // 1000
    notifPlayed := false
    GuiControl, 2:, TimerDisplay, % FormatSeconds(timerCountdown)
    
    WinGet, id, List, Roblox
    totalWindows := id
    GuiControl, , WindowCount, %totalWindows%

    originalWindowID := WinActive("A")
    
    if (totalWindows > 0) {
        Loop, % totalWindows {
            this_id := id%A_Index%
            if (abortNow) {
                break
            }
            WinActivate, ahk_id %this_id%
            Sleep, 100
            if (abortNow) {
                break
            }

            WinGetPos, X, Y, Width, Height, ahk_id %this_id%
            centerX := Width // 2
            centerY := Height // 2

            Click, %centerX%, %centerY%
            Sleep, 100
        }
    } else {
        GuiControl, , WindowCount, No windows found.
    }

    if (abortNow) {
        abortNow := false
        RestorePreviousWindow()
        return
    }

    if (originalWindowID) {
        WinActivate, ahk_id %originalWindowID%
    }
}

RestorePreviousWindow() {
    global previousActiveWindow, previousActiveWindowTitle
    if (previousActiveWindow && WinExist("ahk_id " previousActiveWindow)) {
        attempts := 0
        while (attempts < 5) {
            WinActivate, ahk_id %previousActiveWindow%
            Sleep, 100
            if (WinActive("A") == previousActiveWindow)
                return
            attempts++
        }
    }

    if (previousActiveWindowTitle) {
        attempts := 0
        while (attempts < 3) {
            WinActivate, %previousActiveWindowTitle%
            Sleep, 150
            WinGetTitle, curTitle, A
            if (InStr(curTitle, previousActiveWindowTitle))
                return
            attempts++
        }
    }
}





Lower(s) {
    StringLower, s, s
    return s
}

DehumanizeHotkey(text) {
    if (!text) return ""
    StringTrimLeft, t, text, 0
    StringReplace, t, t, %A_Space%, , All
    if InStr(t, "^") || InStr(t, "!") || InStr(t, "+") || InStr(t, "#")
        return t

    parts := StrSplit(t, "+")
    prefix := ""
    key := ""
    for idx, p in parts {
        up := p
        StringUpper, up, up
        if (up = "CTRL" || up = "CONTROL")
            prefix .= "^"
        else if (up = "ALT" || up = "MENU")
            prefix .= "!"
        else if (up = "SHIFT")
            prefix .= "+"
        else if (up = "WIN" || up = "WINDOW" || up = "LWIN" || up = "RWIN")
            prefix .= "#"
        else
            key := p
    }
    if (key = "")
        key := parts[parts.MaxIndex()]
    StringUpper, kup, key
    if (kup = "SPACE")
        key := "Space"
    return prefix . key
}




RecordHKStart:
    keyAhk := CaptureKey()
    if (keyAhk != "") {
        GuiControl, 3:, HKStart, % HumanizeHotkey(keyAhk)
        HKStartAhk := keyAhk
        HKStart := HumanizeHotkey(keyAhk)
        Gosub, SaveSettings
    }
Return

RecordHKClose:
    keyAhk := CaptureKey()
    if (keyAhk != "") {
        GuiControl, 3:, HKClose, % HumanizeHotkey(keyAhk)
        HKCloseAhk := keyAhk
        HKClose := HumanizeHotkey(keyAhk)
        Gosub, SaveSettings
    }
Return

RecordHKManual:
    keyAhk := CaptureKey()
    if (keyAhk != "") {
        GuiControl, 3:, HKManual, % HumanizeHotkey(keyAhk)
        HKManualAhk := keyAhk
        HKManual := HumanizeHotkey(keyAhk)
        Gosub, SaveSettings
    }
Return

RecordHKAbort:
    keyAhk := CaptureKey()
    if (keyAhk != "") {
        GuiControl, 3:, HKAbort, % HumanizeHotkey(keyAhk)
        HKAbortAhk := keyAhk
        HKAbort := HumanizeHotkey(keyAhk)
        Gosub, SaveSettings
    }
Return

RecordHKTog:
    keyAhk := CaptureKey()
    if (keyAhk != "") {
        GuiControl, 3:, HKTog, % HumanizeHotkey(keyAhk)
        HKTogAhk := keyAhk
        HKTog := HumanizeHotkey(keyAhk)
        Gosub, SaveSettings
    }
Return

PlayNotification(filePath) {
    if (!FileExist(filePath))
        return
    alias := "notif"
    DllCall("winmm.dll\mciSendString", "Str", "close " alias, "Str", 0, "UInt", 0, "UInt", 0)
    cmd := "open """ filePath """ alias " alias
    DllCall("winmm.dll\mciSendString", "Str", cmd, "Str", 0, "UInt", 0, "UInt", 0)
    DllCall("winmm.dll\mciSendString", "Str", "play " alias " from 0", "Str", 0, "UInt", 0, "UInt", 0)
}

CaptureKey() {
    ToolTip, Press the desired hotkey (Esc to cancel)...
    Sleep, 150

    Loop, 50 {
        Sleep, 10
        if (!AnyKeyDown())
            break
    }

    Loop {
        Sleep, 10
        if GetKeyState("Esc", "P") {
            ToolTip
            return ""
        }

        ctrl := GetKeyState("Ctrl", "P")
        alt := GetKeyState("Alt", "P")
        shift := GetKeyState("Shift", "P")
        win := GetKeyState("LWin", "P") || GetKeyState("RWin", "P")
        prefix := ""
        if (ctrl) prefix .= "^"
        if (alt) prefix .= "!"
        if (shift) prefix .= "+"
        if (win) prefix .= "#"


        Loop, 26 {
            key := Chr(64 + A_Index)
            if GetKeyState(key, "P") {
                ToolTip
                return prefix . key
            }
        }

        Loop, 10 {
            key := A_Index - 1
            if GetKeyState(key, "P") {
                ToolTip
                return prefix . key
            }
        }

        Loop, 24 {
            key := "F" . A_Index
            if GetKeyState(key, "P") {
                ToolTip
                return prefix . key
            }
        }

        keys := ["Space","Tab","Enter","Esc","Backspace","Delete","Insert","Home","End","PgUp","PgDn","Up","Down","Left","Right","LButton","RButton","MButton"]
        for k, name in keys {
            if GetKeyState(name, "P") {
                ToolTip
                return prefix . name
            }
        }
    }
}

AnyKeyDown() {

    Loop, 26 {
        if GetKeyState(Chr(64 + A_Index), "P")
            return true
    }
    Loop, 10 {
        if GetKeyState(A_Index - 1, "P")
            return true
    }
    Loop, 24 {
        if GetKeyState("F" . A_Index, "P")
            return true
    }
    keys := ["Space","Tab","Enter","Esc","Backspace","Delete","Insert","Home","End","PgUp","PgDn","Up","Down","Left","Right","LButton","RButton","MButton"]
    for k, name in keys
        if GetKeyState(name, "P")
            return true
    return false
}

CloseGui() {
    Gui, 1: Destroy
    Gui, 2: Destroy
    ExitApp
}