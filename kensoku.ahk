#InstallKeybdHook
#SingleInstance Force
#NoEnv
SetWorkingDir %A_ScriptDir%
SetMouseDelay, -1
SetKeyDelay, -1

; Configuration
global MOUSE_MODE := "NORMAL"       ; "NORMAL", "INSERT", or "OFF"
global FAST_MODE := False
global ACCELERATION := 3.275        ; Base acceleration force
global FRICTION := 0.8              ; Velocity decay per tick
global MAX_VELOCITY := 50           ; Cap on velocity to prevent overshooting
global SENSITIVITY := 0.8           ; Mouse movement sensitivity
global TICK_RATE := 10              ; Timer interval in ms (125 Hz)

global VELOCITY_X := 0
global VELOCITY_Y := 0

; Initialize
DllCall("SetThreadDpiAwarenessContext", "ptr", -3)
SwitchMode(True)

Accelerate(velocity, pos, neg) {
    input := pos + neg
    if (input == 0) {
        return velocity * FRICTION  ; Apply consistent friction
    }
    new_velocity := velocity * FRICTION + ACCELERATION * input * SENSITIVITY
    return Clamp(new_velocity, -MAX_VELOCITY, MAX_VELOCITY)
}

Clamp(value, min_val, max_val) {
    return Min(Max(value, min_val), max_val)
}

SnapToZero(value, threshold := 0.5) {
    return (Abs(value) < threshold) ? 0 : value
}

MoveCursor() {
    if (MOUSE_MODE != "NORMAL") {
        VELOCITY_X := 0
        VELOCITY_Y := 0
        SetTimer,, Off
        return
    }

    left := GetKeyState("a", "P") ? -1 : 0
    right := GetKeyState("d", "P") ? 1 : 0
    up := GetKeyState("w", "P") ? -1 : 0
    down := GetKeyState("s", "P") ? 1 : 0

    VELOCITY_X := SnapToZero(Accelerate(VELOCITY_X, left, right))
    VELOCITY_Y := SnapToZero(Accelerate(VELOCITY_Y, up, down))

    if (VELOCITY_X != 0 || VELOCITY_Y != 0)
        MouseMove, % Round(VELOCITY_X), % Round(VELOCITY_Y), 0, R
}

SwitchMode(init:=False, normal:=False) {
    if (init || normal) {
        MOUSE_MODE := "NORMAL"
        SetTimer, MoveCursor, %TICK_RATE%
    } else {
        MOUSE_MODE := "INSERT"
        SetTimer, MoveCursor, Off
    }
}

EnableFast(fast:=False) {
    FAST_MODE := fast
    ACCELERATION := fast ? 3.275 : 3.0
    FRICTION := fast ? 0.8 : 0.4
    SENSITIVITY := fast ? 0.8 : 0.4
}

Drag() {
    Click, Down
}

Yank() {
    WinGetPos, wx, wy, width,, A
    center := wx + width - 180
    y := wy + 12
    MouseMove, %center%, %y%, 0
    Drag()
}

RightDrag() {
    Click, Right, Down
}

MouseLeft() {
    Click
}

MouseRight() {
    Click, Right
}

MouseMiddle() {
    Click, Middle
}

MouseCtrlClick() {
    Send {Ctrl Down}
    Click
    Send {Ctrl Up}
}

MonitorLeftEdge() {
    CoordMode, Mouse, Screen
    MouseGetPos, mx
    return (mx // A_ScreenWidth) * A_ScreenWidth
}

JumpLeftEdge() {
    CoordMode, Mouse, Screen
    MouseGetPos,, y
    x := MonitorLeftEdge() + 2
    MouseMove, %x%, %y%, 0
}

JumpBottomEdge() {
    CoordMode, Mouse, Screen
    MouseGetPos, x
    MouseMove, %x%, % A_ScreenHeight - 2, 0
}

JumpTopEdge() {
    CoordMode, Mouse, Screen
    MouseGetPos, x
    MouseMove, %x%, 0, 0
}

JumpRightEdge() {
    CoordMode, Mouse, Screen
    MouseGetPos,, y
    x := MonitorLeftEdge() + A_ScreenWidth - 2
    MouseMove, %x%, %y%, 0
}

ScrollUp() {
    Click, WheelUp
}

ScrollDown() {
    Click, WheelDown
}

ScrollRight() {
    Click, WheelRight
}

ScrollLeft() {
    Click, WheelLeft
}

; Hotkeys
+!k:: SwitchMode(False, True)   ; Normal mode
+!l:: SwitchMode(False, False)  ; Insert mode
+!o:: EnableFast(True)          ; Fast mode on
+!p:: EnableFast(False)         ; Fast mode off

#If (MOUSE_MODE == "NORMAL")
w:: Return
a:: Return
s:: Return
d:: Return
+E:: MouseCtrlClick()
+W:: JumpTopEdge()
+A:: JumpLeftEdge()
+S:: JumpBottomEdge()
+D:: JumpRightEdge()
e:: MouseLeft()
q:: MouseRight()
r:: MouseMiddle()
+Y:: Yank()
n:: Drag()
m:: RightDrag()
i:: ScrollUp()
j:: ScrollLeft()
k:: ScrollDown()
l:: ScrollRight()
b:: Click, Up
#If
