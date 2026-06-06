#Requires AutoHotkey v2.0
#SingleInstance Force

; Tunables
scrollCooldownMs := 800
dragCooldownMs := 500
dragThresholdPx := 350
pollIntervalMs := 10

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

lastScrollSwitch := 0
lastDragSwitch := 0
dragActive := false
dragStartX := 0

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
    return GoToDesktopNumber(target)
}

CanSwitch(&lastSwitch, cooldownMs)
{
    now := A_TickCount
    if (now - lastSwitch < cooldownMs)
        return false

    lastSwitch := now
    return true
}

; ============================================================
; Mode 1: Hold middle button + scroll wheel
; ============================================================

MButton:: {
    Click "Middle"
}

MButton & WheelUp::
{
    global lastScrollSwitch, scrollCooldownMs
    if CanSwitch(&lastScrollSwitch, scrollCooldownMs)
        GoToAdjacentDesktop(-1)
}

MButton & WheelDown::
{
    global lastScrollSwitch, scrollCooldownMs
    if CanSwitch(&lastScrollSwitch, scrollCooldownMs)
        GoToAdjacentDesktop(1)
}

; ============================================================
; Mode 2: Hold side button + drag left/right
; ============================================================

XButton2:: {
    global dragActive, dragStartX, dragThresholdPx, pollIntervalMs
    global lastDragSwitch, dragCooldownMs

    if dragActive
        return

    MouseGetPos(&dragStartX)
    dragActive := true

    try {
        while GetKeyState("XButton2", "P") {
            MouseGetPos(&currentX)
            delta := currentX - dragStartX

            if (Abs(delta) >= dragThresholdPx && CanSwitch(&lastDragSwitch, dragCooldownMs)) {
                GoToAdjacentDesktop(delta > 0 ? -1 : 1)
                dragStartX := currentX
            }

            Sleep(pollIntervalMs)
        }
    } finally {
        dragActive := false
    }
}
