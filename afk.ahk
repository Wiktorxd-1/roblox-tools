#Persistent
SetTitleMatchMode, 3

isRunning := false
totalWindows := 0
clickInterval := 420000
timerCountdown := clickInterval // 1000 
notifFile := "C:\Users\Gebruiker\Downloads\notif.mp3"
notifPlayed := false


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
    GuiControl, 1:, WindowCount, %totalWindows%
}

Gui, 1: +AlwaysOnTop
Gui, 1: Add, Text, , Amount of roblox windows found: 
Gui, 1: Add, Edit, vWindowCount r1 w300 ReadOnly
Gui, 1: Add, Button, gCloseGui, Shutdown 
Gui, 1: Show, x50 y50, Roblox AFK 

Gui, 2: +AlwaysOnTop -Caption +LastFound +ToolWindow
Gui, 2: Color, 010101
WinSet, TransColor, 010101
Gui, 2: Font, s22 w900 cFF0000, Arial Black
Gui, 2: Add, Text, vTimerDisplay Center w250, % FormatSeconds(timerCountdown)
Gui, 2: Show, % "x" . (A_ScreenWidth - 260) . " y10 NoActivate", TimerOverlay

SetTimer, UpdateWindowCount, 5000
UpdateWindowCount()

SetTimer, CheckIntervalFile, 1000

envFile := A_ScriptDir "\.env"
if FileExist(envFile) {
    if (!ValidateEnv(envFile)) {
        MsgBox, 16, .env Error, The .env file exists but is invalid. Fix it and restart this script.
    } else {
        EnsureDependencies()
        StartBot()
    }
} 

EnsureDependencies() {
    depsDir := A_UserProfile "\Dependencies"
    ffExe := depsDir "\ffmpeg\bin\ffmpeg.exe"

    RunWait, %ComSpec% /C where ffmpeg >nul 2>&1, , Hide
    if (ErrorLevel != 0 && !FileExist(ffExe)) {
        ps := A_ScriptDir "\install_deps.ps1"
        if FileExist(ps) {
            TrayTip, Installing dependencies, Installing ffmpeg and npm packages..., 5
            RunWait, % "powershell -ExecutionPolicy Bypass -File """ ps """", , Hide
            TrayTip, Installing dependencies, Done, 3
        } else {
            MsgBox, 48, Dependencies missing, install_deps.ps1 not found. Please run install_deps.ps1 manually.
        }
    }

    RunWait, %ComSpec% /C node -v >nul 2>&1, , Hide
    if (ErrorLevel != 0) {
        MsgBox, 48, Node.js missing, Node.js not found in PATH. Please install Node.js or run install_deps.ps1 to attempt install.
    } else {
        RunWait, % "npm install", %A_ScriptDir%, Hide
    }
} 

F2::
    if (!isRunning) {
        isRunning := true
        timerCountdown := clickInterval // 1000
        notifPlayed := false
        GuiControl, 2:, TimerDisplay, % FormatSeconds(timerCountdown)
        SetTimer, ClickRobloxWindows, %clickInterval%
        SetTimer, UpdateCountdown, 1000 
    } else {
        StopScript()
    }
Return

F3::
    StopScript()
    CloseGui()
Return

F4::
    if (isRunning) {
        SetTimer, ClickRobloxWindows, Off
        ClickRobloxWindows()
        SetTimer, ClickRobloxWindows, %clickInterval%
        timerCountdown := clickInterval // 1000
        notifPlayed := false
        GuiControl, 2:, TimerDisplay, % FormatSeconds(timerCountdown)
    } else {
        ClickRobloxWindows()
    }
Return





ValidateEnv(filePath) {
    FileRead, content, %filePath%
    if (!InStr(content, "token"))
        return false
    if (!InStr(content, "prefix"))
        return false
    if (!InStr(content, "commandAliases"))
        return false
    RegExMatch(content, "i)token\s*=\s*['""]?([^'""]+)['""]?", token)
    if (!token1)
        return false
    return true
}

CheckIntervalFile() {
    file := A_ScriptDir "\afk_interval.txt"
    if !FileExist(file)
        return
    FileRead, s, %file%
    FileDelete, %file%
    s := Trim(s)
    RegExMatch(s, "i)^\s*(\d+)\s*(ms|s|sec|secs|m|min|mins|h|hour|hours)?\s*$", m)
    if (m1) {
        val := m1
        unit := m2
        if (unit = "" || unit = "ms") {
            ms := val
        } else if InStr(unit, "h") {
            ms := val * 3600000
        } else if InStr(unit, "m") {
            ms := val * 60000
        } else {
            ms := val * 1000
        }
        clickInterval := ms
        timerCountdown := clickInterval // 1000
        GuiControl, 2:, TimerDisplay, % FormatSeconds(timerCountdown)
        if (isRunning) {
            SetTimer, ClickRobloxWindows, Off
            SetTimer, ClickRobloxWindows, %clickInterval%
            SetTimer, UpdateCountdown, 1000
        }
    }
}

StartBot() {
    global botPID, botStarted
    if (botStarted)
        return
    Run, % "node """ . A_ScriptDir . "\bot.js""", , Hide, botPID
    botStarted := true
}

CloseGui() {
    Gui, 1: Destroy
    Gui, 2: Destroy
    if (botStarted && botPID) {
        Process, Close, %botPID%
    }
    ExitApp
}




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
    global isRunning, totalWindows, clickInterval, timerCountdown, notifPlayed

    timerCountdown := clickInterval // 1000
    notifPlayed := false
    GuiControl, 2:, TimerDisplay, % FormatSeconds(timerCountdown)

    WinGet, id, List, Roblox
    totalWindows := id
    GuiControl, 1:, WindowCount, %totalWindows%

    WinGet, originalWindowID, ID, A

    if (totalWindows > 0) {
        Loop, % totalWindows {
            this_id := id%A_Index%
            WinActivate, ahk_id %this_id%
            Sleep, 100

            WinGetPos, X, Y, Width, Height, ahk_id %this_id%
            centerX := Width // 2
            centerY := Height // 2

            Click, %centerX%, %centerY%
            Sleep, 100
        }
    } else {
        GuiControl, 1:, WindowCount, No windows found.
    }

    if (originalWindowID && WinExist("ahk_id " originalWindowID)) {
        WinActivate, ahk_id %originalWindowID%
    }
}

PlayNotification(filePath) {
    if (!FileExist(filePath))
        return
    DllCall("winmm.dll\PlaySound", "Str", filePath, "Ptr", 0, "UInt", 0x00020001)
}

