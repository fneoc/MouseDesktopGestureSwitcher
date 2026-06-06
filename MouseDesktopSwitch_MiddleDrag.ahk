#Requires AutoHotkey v2.0
#SingleInstance Force

; Tunables
dragThresholdPx := 260
dragCooldownMs := 500
pollIntervalMs := 10
horizontalDominance := 1.45
middleDragPassthroughPx := 80
middleClickTolerancePx := 35
showSwitchTip := true
switchTipMs := 650

; Load the VDA DLL.
vdaPath := A_ScriptDir "\VirtualDesktopAccessor.dll"
if !FileExist(vdaPath) {
    MsgBox("VirtualDesktopAccessor.dll was not found:`n" vdaPath, "Mouse Desktop Switcher", "Iconx")
    ExitApp()
}

hVDA := DllCall("LoadLibrary", "Str", vdaPath, "Ptr")
if !hVDA {
    MsgBox("Failed to load VirtualDesktopAccessor.dll:`n" vdaPath, "Mouse Desktop Switcher", "Iconx")
    ExitApp()
}
OnExit(ReleaseVdaDll)

; Resolve function pointers.
GetCountPtr := GetVdaProc("GetDesktopCount")
GetCurrentPtr := GetVdaProc("GetCurrentDesktopNumber")
GoToPtr := GetVdaProc("GoToDesktopNumber")

middleDragActive := false
lastDragSwitch := 0

GetVdaProc(name)
{
    global hVDA
    ptr := DllCall("GetProcAddress", "Ptr", hVDA, "AStr", name, "Ptr")
    if !ptr {
        MsgBox("VirtualDesktopAccessor.dll is missing export:`n" name, "Mouse Desktop Switcher", "Iconx")
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

    DllCall(GoToPtr, "Int", n)
    return true
}

GoToAdjacentDesktop(direction)
{
    count := GetDesktopCount()
    if (count <= 1)
        return false

    current := GetCurrentDesktop()
    if (current < 0 || current >= count)
        return false

    target := Mod(current + direction + count, count)
    if !GoToDesktopNumber(target)
        return false

    ShowSwitchFeedback(target + 1, count)
    return true
}

CanSwitch(&lastSwitch, cooldownMs)
{
    now := A_TickCount
    if (now - lastSwitch < cooldownMs)
        return false

    lastSwitch := now
    return true
}

IsHorizontalSwitchGesture(deltaX, deltaY)
{
    global dragThresholdPx, horizontalDominance
    absX := Abs(deltaX)
    absY := Abs(deltaY)
    return (absX >= dragThresholdPx && absX >= absY * horizontalDominance)
}

ShouldPassMiddleDragThrough(deltaX, deltaY)
{
    global middleDragPassthroughPx, horizontalDominance
    absX := Abs(deltaX)
    absY := Abs(deltaY)
    return (absY >= middleDragPassthroughPx && absY >= absX * horizontalDominance)
}

ShowSwitchFeedback(desktopNumber, count)
{
    global showSwitchTip, switchTipMs
    if !showSwitchTip
        return

    ToolTip(Format("Desktop {} / {}", desktopNumber, count))
    SetTimer(HideSwitchFeedback, -switchTipMs)
}

HideSwitchFeedback()
{
    ToolTip()
}

; Hold middle mouse button and drag left/right to switch desktops.
; If no switch happened and the pointer barely moved, release sends a normal middle-click.
; Vertical middle-button drags are passed through for apps that use panning/autoscroll.
$MButton:: {
    global middleDragActive, lastDragSwitch, dragCooldownMs, pollIntervalMs
    global middleClickTolerancePx

    if middleDragActive
        return

    MouseGetPos(&startX, &startY)
    middleDragActive := true
    gestureOriginX := startX
    gestureOriginY := startY
    maxAbsX := 0
    maxAbsY := 0
    passthrough := false
    switched := false

    try {
        while GetKeyState("MButton", "P") {
            MouseGetPos(&currentX, &currentY)
            deltaX := currentX - gestureOriginX
            deltaY := currentY - gestureOriginY

            maxAbsX := Max(maxAbsX, Abs(currentX - startX))
            maxAbsY := Max(maxAbsY, Abs(currentY - startY))

            if passthrough {
                Sleep(pollIntervalMs)
                continue
            }

            if ShouldPassMiddleDragThrough(deltaX, deltaY) {
                Send "{MButton down}"
                passthrough := true
                Sleep(pollIntervalMs)
                continue
            }

            if (IsHorizontalSwitchGesture(deltaX, deltaY) && CanSwitch(&lastDragSwitch, dragCooldownMs)) {
                GoToAdjacentDesktop(deltaX > 0 ? -1 : 1)
                gestureOriginX := currentX
                gestureOriginY := currentY
                switched := true
            }

            Sleep(pollIntervalMs)
        }
    } finally {
        if passthrough
            Send "{MButton up}"

        middleDragActive := false
    }

    maxMove := Max(maxAbsX, maxAbsY)
    if (!switched && !passthrough && maxMove <= middleClickTolerancePx)
        Send "{MButton}"
}
