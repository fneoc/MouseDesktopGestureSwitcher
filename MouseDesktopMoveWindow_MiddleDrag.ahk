#Requires AutoHotkey v2.0
#SingleInstance Force

; Tunables
targetWindowMode := "foreground" ; "foreground" or "mouse"
dragThresholdPx := 220
horizontalDominance := 1.35
pollIntervalMs := 10
feedbackMs := 620
feedbackWidth := 216
feedbackHeight := 40
feedbackTopOffsetPx := 32
feedbackOpacity := 235
feedbackRadius := 19
feedbackShadowOffsetY := 5
feedbackShadowOpacity := 42
feedbackFontName := "Microsoft YaHei UI"
feedbackFontSize := 10.2
feedbackFontWeight := 600
desktopSwitchCooldownMs := 500
followMovedWindow := true
focusMovedWindowAfterFollow := true
wrapDesktopSwitching := true
wrapWindowMoving := false
leftDragMovesToNext := true ; Desktop switching gesture mapping.
leftDragMovesWindowToPrevious := true ; Window moving gesture mapping.

; Load the VDA DLL.
vdaPath := A_ScriptDir "\VirtualDesktopAccessor.dll"
if !FileExist(vdaPath) {
    MsgBox("VirtualDesktopAccessor.dll was not found:`n" vdaPath, "Mouse Desktop Window Mover", "Iconx")
    ExitApp()
}

hVDA := DllCall("LoadLibrary", "Str", vdaPath, "Ptr")
if !hVDA {
    MsgBox("Failed to load VirtualDesktopAccessor.dll:`n" vdaPath, "Mouse Desktop Window Mover", "Iconx")
    ExitApp()
}
OnExit(ReleaseVdaDll)

; Resolve function pointers.
GetCountPtr := GetVdaProc("GetDesktopCount")
GetCurrentPtr := GetVdaProc("GetCurrentDesktopNumber")
GoToPtr := GetVdaProc("GoToDesktopNumber")
MoveWindowPtr := GetVdaProc("MoveWindowToDesktopNumber")
IsPinnedWindowPtr := GetVdaProc("IsPinnedWindow")
IsPinnedAppPtr := GetVdaProc("IsPinnedApp")

gestureActive := false
gestureMode := ""
gestureTargetHwnd := 0
gestureOriginX := 0
gestureOriginY := 0
lastDesktopSwitch := 0
feedbackGui := ""
feedbackShadowGui := ""

GetVdaProc(name)
{
    global hVDA
    ptr := DllCall("GetProcAddress", "Ptr", hVDA, "AStr", name, "Ptr")
    if !ptr {
        MsgBox("VirtualDesktopAccessor.dll is missing export:`n" name, "Mouse Desktop Window Mover", "Iconx")
        ExitApp()
    }
    return ptr
}

ReleaseVdaDll(*)
{
    global hVDA
    if hVDA {
        DllCall("FreeLibrary", "Ptr", hVDA)
        hVDA := 0
    }
}

GetDesktopCount()
{
    global GetCountPtr
    return DllCall(GetCountPtr, "Int")
}

GetCurrentDesktop()
{
    global GetCurrentPtr
    return DllCall(GetCurrentPtr, "Int")
}

GoToDesktopNumber(n)
{
    global GoToPtr
    count := GetDesktopCount()
    if (count <= 1 || n < 0 || n >= count)
        return false

    return DllCall(GoToPtr, "Int", n, "Int") != -1
}

MoveWindowToDesktop(hwnd, n)
{
    global MoveWindowPtr
    count := GetDesktopCount()
    if (hwnd = 0 || count <= 1 || n < 0 || n >= count)
        return false

    return DllCall(MoveWindowPtr, "Ptr", hwnd, "Int", n, "Int") != -1
}

IsPinnedWindow(hwnd)
{
    global IsPinnedWindowPtr
    if !hwnd
        return false

    return DllCall(IsPinnedWindowPtr, "Ptr", hwnd, "Int") = 1
}

IsPinnedApp(hwnd)
{
    global IsPinnedAppPtr
    if !hwnd
        return false

    return DllCall(IsPinnedAppPtr, "Ptr", hwnd, "Int") = 1
}

GetTargetDesktop(current, direction, count, shouldWrap)
{
    target := current + direction

    if shouldWrap
        return Mod(target + count, count)

    if (target < 0 || target >= count)
        return -1

    return target
}

GetGestureDirection(deltaX, deltaY, mode := "switch")
{
    global dragThresholdPx, horizontalDominance
    global leftDragMovesToNext, leftDragMovesWindowToPrevious
    absX := Abs(deltaX)
    absY := Abs(deltaY)

    if (absX < dragThresholdPx || absX < absY * horizontalDominance)
        return 0

    leftDragMeansNext := leftDragMovesToNext
    if (mode = "move")
        leftDragMeansNext := !leftDragMovesWindowToPrevious

    if leftDragMeansNext
        return deltaX < 0 ? 1 : -1

    return deltaX > 0 ? 1 : -1
}

CanSwitchDesktop()
{
    global lastDesktopSwitch, desktopSwitchCooldownMs
    now := A_TickCount
    if (now - lastDesktopSwitch < desktopSwitchCooldownMs)
        return false

    lastDesktopSwitch := now
    return true
}

PickTargetWindow()
{
    global targetWindowMode

    if (StrLower(targetWindowMode) = "mouse")
        return GetWindowUnderMouse()

    return GetForegroundWindow()
}

GetForegroundWindow()
{
    try hwnd := WinGetID("A")
    catch
        return 0

    return NormalizeWindow(hwnd)
}

GetWindowUnderMouse()
{
    MouseGetPos(&x, &y, &hwnd)
    return NormalizeWindow(hwnd)
}

NormalizeWindow(hwnd)
{
    if !hwnd
        return 0

    root := DllCall("GetAncestor", "Ptr", hwnd, "UInt", 2, "Ptr")
    return root ? root : hwnd
}

GetWindowClass(hwnd)
{
    try return WinGetClass("ahk_id " hwnd)
    catch
        return ""
}

IsSystemWindowClass(className)
{
    return (className = "Progman"
        || className = "WorkerW"
        || className = "Shell_TrayWnd"
        || className = "Shell_SecondaryTrayWnd"
        || className = "MultitaskingViewFrame")
}

GetMoveBlockReason(hwnd)
{
    if !hwnd
        return "没有目标窗口"

    if (hwnd = A_ScriptHwnd)
        return "脚本窗口不能移动"

    if !DllCall("IsWindow", "Ptr", hwnd, "Int")
        return "目标窗口已不存在"

    className := GetWindowClass(hwnd)
    if IsSystemWindowClass(className)
        return "系统窗口不能移动"

    if !DllCall("IsWindowVisible", "Ptr", hwnd, "Int")
        return "隐藏窗口不能移动"

    if DllCall("IsIconic", "Ptr", hwnd, "Int")
        return "最小化窗口不能移动"

    if IsPinnedWindow(hwnd) || IsPinnedApp(hwnd)
        return "固定窗口会停留在所有桌面"

    return ""
}

MoveWindowBy(hwnd, direction)
{
    global followMovedWindow, focusMovedWindowAfterFollow
    global wrapWindowMoving

    count := GetDesktopCount()
    current := GetCurrentDesktop()
    if (count <= 1 || current < 0 || current >= count) {
        ShowFeedback("没有目标桌面")
        return false
    }

    blockReason := GetMoveBlockReason(hwnd)
    if blockReason {
        ShowFeedback(blockReason)
        return false
    }

    target := GetTargetDesktop(current, direction, count, wrapWindowMoving)
    if (target = -1) {
        ShowFeedback("已到桌面边界")
        return false
    }

    if !MoveWindowToDesktop(hwnd, target) {
        ShowFeedback("移动失败")
        return false
    }

    followed := false
    if followMovedWindow {
        followed := GoToDesktopNumber(target)
        if followed && focusMovedWindowAfterFollow {
            Sleep(100)
            try WinActivate("ahk_id " hwnd)
        }
    }

    text := Format("已移动到桌面 {}", target + 1)
    if (followMovedWindow && !followed)
        text := Format("已移动到桌面 {}，未跟随", target + 1)

    ShowFeedback(text)
    return true
}

SwitchDesktopBy(direction)
{
    global wrapDesktopSwitching

    count := GetDesktopCount()
    current := GetCurrentDesktop()
    if (count <= 1 || current < 0 || current >= count) {
        ShowFeedback("没有目标桌面")
        return false
    }

    target := GetTargetDesktop(current, direction, count, wrapDesktopSwitching)
    if (target = -1) {
        ShowFeedback("已到桌面边界")
        return false
    }

    if !GoToDesktopNumber(target) {
        ShowFeedback("切换失败")
        return false
    }

    ShowFeedback(Format("桌面 {} / {}", target + 1, count))
    return true
}

ShowFeedback(text)
{
    global feedbackMs, feedbackWidth, feedbackHeight, feedbackTopOffsetPx, feedbackOpacity, feedbackRadius
    global feedbackShadowOffsetY, feedbackShadowOpacity
    global feedbackGui, feedbackShadowGui

    Critical("On")
    try {
        if !EnsureFeedbackGuis()
            return

        GetFeedbackPosition(&x, &y)
        shadowHwnd := feedbackShadowGui.Hwnd
        feedbackHwnd := feedbackGui.Hwnd

        try feedbackShadowGui.Show(Format("NA x{} y{} w{} h{}", x, y + feedbackShadowOffsetY, feedbackWidth, feedbackHeight))
        if WinExist("ahk_id " shadowHwnd) {
            ApplyWindowOpacity(shadowHwnd, feedbackShadowOpacity)
            TrySetWindowRegion(shadowHwnd)
        }

        try feedbackGui.Show(Format("NA x{} y{} w{} h{}", x, y, feedbackWidth, feedbackHeight))
        if WinExist("ahk_id " feedbackHwnd) {
            ApplyWindowOpacity(feedbackHwnd, feedbackOpacity)
            TrySetWindowRegion(feedbackHwnd)
            DrawFeedbackText(text)
        }

        SetTimer(HideFeedback, -feedbackMs)
    } finally {
        Critical("Off")
    }
}

EnsureFeedbackGuis()
{
    global feedbackGui, feedbackShadowGui

    try {
        if (!IsObject(feedbackShadowGui) || !WinExist("ahk_id " feedbackShadowGui.Hwnd)) {
            feedbackShadowGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
            feedbackShadowGui.MarginX := 0
            feedbackShadowGui.MarginY := 0
            feedbackShadowGui.BackColor := "000000"
        }

        if (!IsObject(feedbackGui) || !WinExist("ahk_id " feedbackGui.Hwnd)) {
            feedbackGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
            feedbackGui.MarginX := 0
            feedbackGui.MarginY := 0
            feedbackGui.BackColor := "202633"
        }
    } catch {
        feedbackGui := ""
        feedbackShadowGui := ""
        return false
    }

    return true
}

TrySetWindowRegion(hwnd)
{
    global feedbackWidth, feedbackHeight, feedbackRadius
    try {
        if WinExist("ahk_id " hwnd)
            WinSetRegion(Format("0-0 W{} H{} R{}-{}", feedbackWidth, feedbackHeight, feedbackRadius, feedbackRadius), "ahk_id " hwnd)
    }
}

GetFeedbackPosition(&x, &y)
{
    global feedbackWidth, feedbackTopOffsetPx

    MouseGetPos(&mouseX, &mouseY)
    monitorIndex := 0
    monitorCount := MonitorGetCount()

    Loop monitorCount {
        MonitorGet(A_Index, &left, &top, &right, &bottom)
        if (mouseX >= left && mouseX < right && mouseY >= top && mouseY < bottom) {
            monitorIndex := A_Index
            break
        }
    }

    if !monitorIndex {
        monitorIndex := 1
        MonitorGet(monitorIndex, &left, &top, &right, &bottom)
    }

    x := left + Round((right - left - feedbackWidth) / 2)
    y := top + feedbackTopOffsetPx
}

ApplyWindowOpacity(hwnd, opacity)
{
    if !WinExist("ahk_id " hwnd)
        return

    if (opacity >= 255) {
        try WinSetTransparent("Off", "ahk_id " hwnd)
        return
    }

    try WinSetTransparent(opacity, "ahk_id " hwnd)
}

DrawFeedbackText(text)
{
    global feedbackGui, feedbackWidth, feedbackHeight
    global feedbackFontName, feedbackFontSize, feedbackFontWeight

    hwnd := feedbackGui.Hwnd
    if !WinExist("ahk_id " hwnd)
        return

    hdc := DllCall("user32\GetDC", "Ptr", hwnd, "Ptr")
    if !hdc
        return

    hFont := 0
    oldFont := 0
    hBrush := 0
    rect := Buffer(16, 0)
    NumPut("Int", 0, rect, 0)
    NumPut("Int", 0, rect, 4)
    NumPut("Int", feedbackWidth, rect, 8)
    NumPut("Int", feedbackHeight, rect, 12)

    try {
        hBrush := DllCall("gdi32\CreateSolidBrush", "UInt", 0x00332620, "Ptr")
        DllCall("user32\FillRect", "Ptr", hdc, "Ptr", rect, "Ptr", hBrush)

        fontHeight := -Round(feedbackFontSize * A_ScreenDPI / 72)
        hFont := DllCall("gdi32\CreateFontW"
            , "Int", fontHeight
            , "Int", 0
            , "Int", 0
            , "Int", 0
            , "Int", feedbackFontWeight
            , "UInt", 0
            , "UInt", 0
            , "UInt", 0
            , "UInt", 0
            , "UInt", 0
            , "UInt", 0
            , "UInt", 5
            , "UInt", 0
            , "Str", feedbackFontName
            , "Ptr")

        if hFont
            oldFont := DllCall("gdi32\SelectObject", "Ptr", hdc, "Ptr", hFont, "Ptr")

        DllCall("gdi32\SetBkMode", "Ptr", hdc, "Int", 1)
        DllCall("gdi32\SetTextColor", "Ptr", hdc, "UInt", 0x00FCFAF8)

        flags := 0x1 | 0x4 | 0x20 | 0x800 | 0x8000
        DllCall("user32\DrawTextW", "Ptr", hdc, "Str", text, "Int", -1, "Ptr", rect, "UInt", flags)
    } finally {
        if oldFont
            DllCall("gdi32\SelectObject", "Ptr", hdc, "Ptr", oldFont)
        if hFont
            DllCall("gdi32\DeleteObject", "Ptr", hFont)
        if hBrush
            DllCall("gdi32\DeleteObject", "Ptr", hBrush)
        DllCall("user32\ReleaseDC", "Ptr", hwnd, "Ptr", hdc)
    }
}

HideFeedback()
{
    global feedbackGui, feedbackShadowGui
    if (IsObject(feedbackGui) && WinExist("ahk_id " feedbackGui.Hwnd))
        try feedbackGui.Hide()
    if (IsObject(feedbackShadowGui) && WinExist("ahk_id " feedbackShadowGui.Hwnd))
        try feedbackShadowGui.Hide()
}

^!F12::ExitApp()

; Native middle-button input is allowed through. The script only observes the
; drag distance and calls virtual-desktop APIs when a horizontal gesture is clear.
~+MButton:: {
    StartMiddleGesture("move")
}

#HotIf !GetKeyState("Shift", "P")
~MButton:: {
    StartMiddleGesture("switch")
}
#HotIf

StartMiddleGesture(mode)
{
    global gestureActive, gestureMode, gestureTargetHwnd, gestureOriginX, gestureOriginY
    global pollIntervalMs

    if gestureActive
        return

    MouseGetPos(&gestureOriginX, &gestureOriginY)
    gestureMode := mode
    gestureTargetHwnd := (gestureMode = "move") ? PickTargetWindow() : 0
    gestureActive := true
    SetTimer(TrackMiddleGesture, pollIntervalMs)
}

TrackMiddleGesture()
{
    global gestureActive, gestureMode, gestureTargetHwnd, gestureOriginX, gestureOriginY

    if !GetKeyState("MButton", "P") {
        StopMiddleGesture()
        return
    }

    MouseGetPos(&currentX, &currentY)
    direction := GetGestureDirection(currentX - gestureOriginX, currentY - gestureOriginY, gestureMode)
    if !direction
        return

    if (gestureMode = "move") {
        MoveWindowBy(gestureTargetHwnd, direction)
        StopMiddleGesture()
        return
    }

    if (gestureMode = "switch" && CanSwitchDesktop() && SwitchDesktopBy(direction)) {
        gestureOriginX := currentX
        gestureOriginY := currentY
    }
}

StopMiddleGesture()
{
    global gestureActive, gestureMode, gestureTargetHwnd
    SetTimer(TrackMiddleGesture, 0)
    gestureActive := false
    gestureMode := ""
    gestureTargetHwnd := 0
}
