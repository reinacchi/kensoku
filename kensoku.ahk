#InstallKeybdHook
#SingleInstance Force
#NoEnv
SetWorkingDir %A_ScriptDir%
SetMouseDelay, -1
SetKeyDelay, -1

; =========================
; Configuration
; =========================
global MOUSE_MODE := "CURSOR"   ; "CURSOR" or "TYPING"
global PACING_MODE := "NORMAL"  ; "NORMAL" or "PRECISE"

; Active movement values
global ACCELERATION := 2.0
global FRICTION := 0.78
global STOP_FRICTION := 0.52
global REVERSE_BRAKE := 0.45
global MAX_VELOCITY := 20.0
global SNAP_THRESHOLD := 0.12
global TICK_RATE := 10

global VELOCITY_X := 0.0
global VELOCITY_Y := 0.0
global REMAINDER_X := 0.0
global REMAINDER_Y := 0.0

; Initialize
DllCall("SetThreadDpiAwarenessContext", "ptr", -3)
SetPacingMode(False)  ; start in normal mode
SwitchMode(True)

; =========================
; Movement helpers
; =========================
Clamp(value, min_val, max_val) {
    return Min(Max(value, min_val), max_val)
}

SnapToZero(value, threshold) {
    return (Abs(value) < threshold) ? 0.0 : value
}

UpdateAxis(velocity, input) {
    global ACCELERATION, FRICTION, STOP_FRICTION, REVERSE_BRAKE, MAX_VELOCITY, SNAP_THRESHOLD

    ; No input: brake harder so cursor stops sooner for precision
    if (input = 0) {
        velocity *= STOP_FRICTION
        return SnapToZero(velocity, SNAP_THRESHOLD)
    }

    ; If reversing direction, kill momentum first to avoid overshoot
    if ((velocity > 0 && input < 0) || (velocity < 0 && input > 0))
        velocity *= REVERSE_BRAKE
    else
        velocity *= FRICTION

    ; Apply input acceleration
    velocity += input * ACCELERATION

    ; Clamp top speed
    velocity := Clamp(velocity, -MAX_VELOCITY, MAX_VELOCITY)

    return SnapToZero(velocity, SNAP_THRESHOLD)
}

MoveCursor() {
    global MOUSE_MODE, VELOCITY_X, VELOCITY_Y, REMAINDER_X, REMAINDER_Y

    if (MOUSE_MODE != "CURSOR") {
        VELOCITY_X := 0.0
        VELOCITY_Y := 0.0
        REMAINDER_X := 0.0
        REMAINDER_Y := 0.0
        SetTimer, MoveCursor, Off
        return
    }

    left  := GetKeyState("a", "P") ? -1 : 0
    right := GetKeyState("d", "P") ?  1 : 0
    up    := GetKeyState("w", "P") ? -1 : 0
    down  := GetKeyState("s", "P") ?  1 : 0

    inputX := left + right
    inputY := up + down

    VELOCITY_X := UpdateAxis(VELOCITY_X, inputX)
    VELOCITY_Y := UpdateAxis(VELOCITY_Y, inputY)

    ; Keep fractional movement so low-speed movement still feels smooth
    moveX := VELOCITY_X + REMAINDER_X
    moveY := VELOCITY_Y + REMAINDER_Y

    stepX := (moveX >= 0) ? Floor(moveX) : Ceil(moveX)
    stepY := (moveY >= 0) ? Floor(moveY) : Ceil(moveY)

    REMAINDER_X := moveX - stepX
    REMAINDER_Y := moveY - stepY

    if (stepX != 0 || stepY != 0)
        MouseMove, %stepX%, %stepY%, 0, R
}

; =========================
; Modes
; =========================
SwitchMode(init:=False, normal:=False) {
    global MOUSE_MODE, TICK_RATE

    if (init || normal) {
        MOUSE_MODE := "CURSOR"
        SetTimer, MoveCursor, %TICK_RATE%
    } else {
        MOUSE_MODE := "TYPING"
        SetTimer, MoveCursor, Off
    }
}

SetPacingMode(precise:=False) {
    global PACING_MODE
    global ACCELERATION, FRICTION, STOP_FRICTION, REVERSE_BRAKE, MAX_VELOCITY, SNAP_THRESHOLD
    global VELOCITY_X, VELOCITY_Y, REMAINDER_X, REMAINDER_Y

    if (precise) {
        PACING_MODE := "PRECISE"

        ; Slower, tighter control for precision work
        ACCELERATION := 0.9
        FRICTION := 0.72
        STOP_FRICTION := 0.38
        REVERSE_BRAKE := 0.27
        MAX_VELOCITY := 6.0
        SNAP_THRESHOLD := 0.10
    } else {
        PACING_MODE := "NORMAL"

        ; Your current/default configuration
        ACCELERATION := 2.0
        FRICTION := 0.78
        STOP_FRICTION := 0.52
        REVERSE_BRAKE := 0.45
        MAX_VELOCITY := 20.0
        SNAP_THRESHOLD := 0.12
    }

    ; Reset momentum when switching pacing modes
    VELOCITY_X := 0.0
    VELOCITY_Y := 0.0
    REMAINDER_X := 0.0
    REMAINDER_Y := 0.0
}

; =========================
; Mouse actions
; =========================
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

; =========================
; Hotkeys
; =========================
+!k::SwitchMode(False, True)    ; Cursor mode
+!l::SwitchMode(False, False)   ; Typing mode
+!o::SetPacingMode(False)       ; Normal pace
+!p::SetPacingMode(True)        ; Precise pace

#If (MOUSE_MODE == "CURSOR")
w::Return
a::Return
s::Return
d::Return
+E::MouseCtrlClick()
+W::JumpTopEdge()
+A::JumpLeftEdge()
+S::JumpBottomEdge()
+D::JumpRightEdge()
e::MouseLeft()
q::MouseRight()
r::MouseMiddle()
+Y::Yank()
n::Drag()
m::RightDrag()
i::ScrollUp()
j::ScrollLeft()
k::ScrollDown()
l::ScrollRight()
b::Click, Up
#If