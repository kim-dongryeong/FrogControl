#Requires AutoHotkey v1.1 	; v1 syntax - does NOT run on AutoHotkey v2
; ---------------------------------------------------------------
; FrogControl - keyboard & mouse window-management shortcuts for Windows.
; Copyright (C) 2015-2026 Kim Dongryeong <kdr@namouli.com>
;
; This program is free software: you can redistribute it and/or modify it under
; the terms of the GNU General Public License as published by the Free Software
; Foundation, either version 3 of the License, or (at your option) any later
; version. It is distributed WITHOUT ANY WARRANTY; see the GNU GPL for details.
; You should have received a copy of the GNU General Public License along with
; this program (see the LICENSE file). If not, see <https://www.gnu.org/licenses/>.
; ---------------------------------------------------------------
AppName 		:= "FrogControl"
AppAuthor 		:= "Kim Dongryeong"
AppAuthorEmail	:= "kdr@namouli.com"
AppUpdateDate 	:= "2026-07-06"
AppVersion 		:= "2.1.2"
AppSite			:= "https://github.com/kim-dongryeong/FrogControl"

; ---------------------------------------------------------------


;; Not assigned
; !^1::
; !^2::
; !^3::
; !^4::
; !^5::
; !^6::
; !^7::
; !^8::
; !^9::
 
;
; Assigned as Window Bookmark. But !1~!0 are also Window Bookmark. So we can remove them.
;CapsLock & F1::
;CapsLock & F2::
;CapsLock & F3::
;CapsLock & F4::
;CapsLock & F5::
;CapsLock & F6::
;CapsLock & F7::
;CapsLock & F8::
;CapsLock & F9::


;;; tray menu
;==================================
#NoEnv  ; Prevent empty variables from falling back to environment variables (also faster variable lookup).
#SingleInstance Force  ; Replace the old instance silently instead of showing a prompt when launched twice.
#Persistent  ; Keep the script running until the user exits it.
#MaxHotkeysPerInterval 2000
; #include Acc.ahk ; 2023-01-14 이거 없애보기
ListLines, Off  ; Don't log executed lines; big speedup for the polling loops below.
SetWinDelay, -1

;============ Settings ============
SETTING_CONSTANT_HALFTRANS := 100
SETTING_CONSTANT_FOCUSTRANS := 250
SETTING_CONSTANT_TOOLTIPDUR_S := 1000
SETTING_CONSTANT_TOOLTIPDUR_L := 10000
SETTING_CONSTANT_WINMOV_STEP_REP := 0.2 	; second. windowMove. Grid 2x2, 3x3, screen edge
SETTING_CONSTANT_WINMOV_PX_L_RepSec := 0.05 		; second. windowMove. Moving by 200 px or the like.
SETTING_CONSTANT_WINMOV_PX_S_RepSec := 0.006 		; second. windowMove. Moving by 200 px or the like.
SETTING_CONSTANT_WINMOV_PX_L := 200 		; pixel
SETTING_CONSTANT_WINMOV_PX_S := 20 			; pixel
SETTING_CONSTANT_CAPSMOVE_CORNER := 180 			; pixel
SETTING_CONSTANT_CAPSMOVE_LRB := 150 			; pixel
SETTING_CONSTANT_CAPSMOVE_HALFTOP := 150 			; pixel
SETTING_CONSTANT_CAPSMOVE_TOP := 60 			; pixel
;==================================
;============ Flag variables ======
FLAG_HALFTRANS := ""
FLAG_CONSTRAINEDMOUSE := ""
FLAG_MOUSECONTROL := ""
FLAG_COOR_CONSTRAINED_MOUSE := 0
FLAG_HELP_LANG := 1
;==================================
global_wheel_count := 0
global_wheel_count_check := 0
timeStamp_CapsLock_index := 0
timeStamp_Alt_index := 0
timeStamp_Control_index := 0
timeStamp_Shift_index := 0
timeStamp_Win_index := 0
timeStamp_modfr_max := 20
Gosub, ResetTimeStampModifiers 	; if they are not set to 0, wheel scroll level up doesn't work properly.
wheelScroll_speedUp_default := 4
mousePosBookmark_0 := 0
mbIndex := 0
windowBookmark := {}
mousePosBookmark := {}


;==================================

If( !A_IsCompiled && FileExist(A_ScriptDir . "\frog face icon 3.ico")) {
	Menu, Tray, Icon, %A_ScriptDir%\frog face icon 3.ico
}

menu, tray, NoStandard
Menu, tray, add, Disable, SuspendKeys
Menu, tray, add  ; Creates a separator line.
Menu, tray, add, About (Korean), MenuHandlerKo  ; Creates a new menu item.
Menu, tray, add, About (English), MenuHandlerEn  ; Creates a new menu item.
Menu, tray, add
Menu, tray, add, Reload, ReloadScript 	; apply script changes without exiting (re-running FrogControl.ahk also works: #SingleInstance Force replaces the old instance)
Menu, tray, add, Exit, GoExit
return

#a::Goto, AlwaysOnTop


ReloadScript:
Reload
Return

GoExit:
ExitApp

SuspendKeys:
Menu, Tray, Icon,,, 1
Suspend
if OldName = Disable
{
    OldName = Enable
    NewName = Disable
    TrayTip
	TrayTip, % "FrogControl", % "Hi again! Now enabled", , 16
	; (removed a block here that flipped the real CapsLock toggle state on resume via CapsLock+F12;
	;  CapsLock stays a suppressed prefix during suspension, so no compensation is needed)
}
else
{
    OldName = Disable
    NewName = Enable
    TrayTip
	TrayTip, % "FrogControl", % "Bye for now! Now disabled", , 16
}
menu, tray, rename, %OldName%, %NewName%
return

MenuHandlerEn:
	ShowHelp("en")
Return

ABOUTOK:
Gui,Destroy
Return

MenuHandlerKo:
	ShowHelp("ko")
Return

RemoveToolTip:
	; usage: https://www.autohotkey.com/docs/v1/lib/ToolTip.htm
	SetTimer, RemoveToolTip, Off
	ToolTip
return

fct_RemoveToolTip_time:
	SetTimer, fct_RemoveToolTip_time, Off
	fct_RemoveToolTip_time()
return

RemoveMousePosBookmarkGui:
	SetTimer, RemoveMousePosBookmarkGui, Off
	Loop, % mousePosBookmark[mouseBookmark_no].length(){
			Gui, mousePosBookmark%A_Index%: Destroy
	}
Return

AlwaysOnTop:
	Winset, AlwaysOnTop, , A
	WinGet, vExStyle, ExStyle, A
	if (vExStyle & 0x8) {  ; 0x8 is WS_EX_TOPMOST (always on top).
		alwaysOnTopOnOff := "On"
	} else {
		alwaysOnTopOnOff := "Off"
	}
	TrayTip, % "Always On Top - "alwaysOnTopOnOff, % AltTab_window_list_findID(WinExist("A")).title, , 16
Return

#LButton::
	MouseGetPos, mousex, mousey, winUnderMouse
	WinSet, AlwaysOnTop, toggle, % "ahk_id " winUnderMouse
	WinGet, vExStyle, ExStyle, % "ahk_id " winUnderMouse
	if (vExStyle & 0x8) {  ; 0x8 is WS_EX_TOPMOST (always on top).
		alwaysOnTopOnOff := "On"
	} else {
		alwaysOnTopOnOff := "Off"
	}
	TrayTip, % "Always On Top - "alwaysOnTopOnOff, % AltTab_window_list_findID(winUnderMouse).title, , 16
Return

;; changing window transparencies
#!WheelUp::  ; Decrease window transparency
#!]::
;    DetectHiddenWindows, on
    WinGet, curtrans, Transparent, A
    if ! curtrans {         ; curtrans is 0 or not assigned
        if curtrans != 0    ; curtrans is not 0 (so not assigned)
            curtrans := 255
    }
    curtrans := curtrans + 20 > 255 ? 255 : curtrans + 20 	; clamp to the valid 0-255 range
	WinSet, Transparent, %curtrans%, A
return


#!WheelDown::  ; Increments transparency down by ??% (with wrap-around)
#![::
;    DetectHiddenWindows, on
    WinGet, curtrans, Transparent, A
    if ! curtrans {     ; curtrans is 0 or not assigned
        if curtrans != 0 ; curtrans is not 0. (so not assigned)
            curtrans := 255
    }
    curtrans := curtrans - 20 < 0 ? 0 : curtrans - 20 	; clamp to the valid 0-255 range (prevents out-of-range values)
    WinSet, Transparent, %curtrans%, A

return

#+F1::
	MouseGetPos, mousex, mousey, winUnderMouse
	PixelGetColor, colorUnderMouse, %MouseX%, %MouseY%
	WinSet, TransColor, %colorUnderMouse%, % "ahk_id " winUnderMouse
Return

#+F2::
	WinSet, Style, ^0xC00000, A ; remove the titlebar and border(s) 
return

#+F3::
	WinSet, Style, ^0x800000, A ; remove the titlebar and border(s) 
return


;; sound control with mouse and Control + Shift
#WheelUp::
#]::
	Volume_Adjust("+10")
return

#WheelDown::
#[::
	Volume_Adjust("-10")
return

;; sound micro control with mouse and Control + Shift + Alt
#^WheelUp:: 	;  Alt-Win + Wheel + Alt-Whin will trigger this hotkey but also will open Window Start!
#^]::
	Volume_Adjust("+1")
Return

#^WheelDown::
#^[::
	Volume_Adjust("-1")
Return

;; to close a tab (like Ctrl + W) by Control + Shift + Right Click
;; while the original active window will be still active
^+RButton::
	DllCall("SystemParametersInfo", UInt, 0x0001, UInt, 0, UIntP, beep_rbtn, UInt,0)
	DllCall("SystemParametersInfo", UInt, 0x0002, UInt, 0, UInt,0, UInt,0) 	; SPI_SETBEEP : 0x0002
	MouseGetPos, , , mousewin
	WinGet, var_id, ID, A
	WinActivate, ahk_id %mousewin%
	WinWaitActive, ahk_id %mousewin%, , 0.5 	; timeout: without it this thread could hang forever with the beep left disabled
	if (!ErrorLevel)
		SendInput, {Blind}{Shift Up}w 	; {Blind}: keep the physically-held Ctrl, drop only the held
						; Shift, and send w with the current modifiers = a CLEAN Ctrl+W. Ending the
						; batch with Shift UP (no in-batch restore) is the key: Chrome drains the
						; message queue before handling, reading GetKeyState as of the last RETRIEVED
						; message, so a restored {Shift down} in the same batch would still make it
						; see Ctrl+Shift+W (= close the WHOLE window). The physical Shift the user is
						; still holding re-asserts itself via typematic repeat right after, so it's
						; not left stuck. Plain SendEvent/`^w` had both the queue-drain leak and the
						; typematic race - this closes both, even on fast repeated clicks.
	;WinActivate, ahk_id %var_id%  	; if it's presented, minor error: no tab closed.  -> What I meant before?
	DllCall("SystemParametersInfo", UInt, 0x0002, UInt, beep_rbtn, UInt,0, UInt,0) 	; SPI_SETBEEP : 0x0002
return


;; to close a window (like Alt + F4) by Control + Shift + Alt + Right Click
;; while the original active window will be still active
^+!RButton::
	MouseGetPos, , , mousewin
	if (!mousewin)
		Return
	WinActivate, ahk_id %mousewin%
	WinWaitActive, ahk_id %mousewin%, , 0.5 	; timeout: without it this thread could wait forever
	if (!ErrorLevel)
		SendInput, {Blind}{Ctrl Up}{Shift Up}{F4} 	; keep the physically-held Alt, drop Ctrl+Shift,
						; and no in-batch restore -> a clean Alt+F4 that fast clicks can't corrupt (see ^w above)
Return

#^+!RButton::
	MouseGetPos, , , mousewin
	WinClose, ahk_id %mousewin%
Return

;; To send a window to be clicked to the bottom of stack 
;; The same as Alt + Esc
;; Alt + Shift + Right Click
!+RButton::
	MouseGetPos, , , mousewin
	; Basically WinSet, Bottom revokes the WS_EX_TOPMOST (always on top) state.
	WinGet, var_ExStyle, ExStyle, ahk_id %mousewin%
	if (var_ExStyle & 0x8) {  ; 0x8 is WS_EX_TOPMOST (always on top).
		Return
	} else {
		WinSet, Bottom, , ahk_id %mousewin%
		; If it was an active window, it will be still active. In this case, if a user clicks the same window from the taskbar immediately, 
		; it will not appear, but rather will be minimized because it was still active! So activating something will solve this problem.
		; Because AltTab_window_list() is not perfect to filter out all, we rather activate the taskbar.
		WinActivate, ahk_class Shell_TrayWnd 	
	}
Return

;; To minimize a LWinDown
;; Alt + Right Click
!RButton::
	MouseGetPos,,, mousewin
	WinMinimize, ahk_id %mousewin%
Return


; ================= ================ ================== ; ================= ================ ==================

											;; WINDOW ROTATION ;; 

;											- Simple Staking
;											- Temporary showing around
; 											-  

; ================= ================ ================== ; ================= ================ ==================

; ================= Simple Staking ==================== starts ============================

;; To send an active window to the bottom of stack
;; Alt + Shift + Scroll down
;;; to improve: 1. always on top, 2. task manager

!^WheelDown::
!^[::
	WindowRotate_OnWheel(false, true)
return

!^WheelUp::
!^]::
	WindowRotate_OnWheel(false, false)
return

window_rotate_stacking:
	SetTimer, window_rotate_stacking, off
	WinActivate, ahk_class Shell_TrayWnd 	; The original active window will be still active even if it goes the bottom or something comes on it, which causes that even if you click the original window, it won't come to the topmost. Therefore, instead deactivate it.
	; The main loop
	Loop {
		Sleep, 10 	; poll ~100x/s instead of busy-waiting (CPU)
		;Tooltip looping window_rotate_stacking FLAG_HALFTRANS IS %FLAG_HALFTRANS%
		if (!(GetKeyState("Alt", "P")) or !(GetKeyState("control", "P"))) {
			WinActivate, % "ahk_id " AltTab_ID_List_%window_rotate_current% 	; AltTab_window_list() is not perfect so it may activate unwanted window or it may fail to activate the visually topmost window
			; To make topmost again
			Loop, %AltTab_ID_List_0% {
				if (A_Index < AltTab_ID_List_topOfNontopmost) {
					temp := AltTab_ID_List_topOfNontopmost - A_Index
					WinSet, AlwaysOnTop, On, % "ahk_id " AltTab_ID_List_%temp%	; For the order of topmost's
					;MsgBox, % "AltTab_ID_List_topOfNontopmost  " AltTab_ID_List_topOfNontopmost " temp " temp " AltTab_ID_List_%temp% " AltTab_ID_List_%temp%
				} else {
					break
				}
			}
			wheel_count_down := 0
			wheel_count_check := 0
			window_rotate_firstcheck := 0

			break
		}
		if (wheel_count_down > wheel_count_check) {

			; If we only use wheel_count_down instead of window_rotate_current, then it can be a problem
			; when !^WheelDown:: is triggered again continuously before giving window_rotate_stacking: a chance to proceed its loop which was looping before 
			; As a result, it may skip a window to send back.
			; Therefore, we use window_rotate_current
			; It means generally abs(wheel_count_down - wheel_count_check) = 1. But when it happens, i.e., wheel_count_down ++ is called twice, abs(wheel_count_down - wheel_count_check) = 2 or more.
			
			WinSet, Bottom, , % "ahk_id " AltTab_ID_List_%window_rotate_current%
			window_rotate_current ++
			if (window_rotate_current > AltTab_ID_List_0) {
				window_rotate_current := 1
			}

			; ToolTip to check the current focused window
			WinGetTitle, wintitle, % "ahk_id " AltTab_ID_List_%window_rotate_current%
			tooltip % wintitle
			SetTimer, RemoveToolTip, % SETTING_CONSTANT_TOOLTIPDUR_S 

			wheel_count_check ++ 	; advance one step per processed window instead of snapping (which dropped queued scroll clicks)
		}
		if (wheel_count_down < wheel_count_check) {

			window_rotate_current --
			if (window_rotate_current < 1) {
				window_rotate_current := AltTab_ID_List_0
			}
			PulseTop(AltTab_ID_List_%window_rotate_current%)

			; ToolTip to check the current focused window
			WinGetTitle, wintitle, % "ahk_id " AltTab_ID_List_%window_rotate_current%
			tooltip % wintitle
			SetTimer, RemoveToolTip, % SETTING_CONSTANT_TOOLTIPDUR_S 

			wheel_count_check -- 	; advance one step per processed window instead of snapping (which dropped queued scroll clicks)
		}
	}
return

; ================= Simple Staking ======================== ends ==============================


; ================= Temporary showing around ==================== starts ============================
#!^WheelDown::
#!^[::
	WindowRotate_OnWheel(true, true)
return

#!^WheelUp::
#!^]::
	WindowRotate_OnWheel(true, false)
return

window_rotate_popup:
	SetTimer, window_rotate_popup, off
	WinActivate, ahk_class Shell_TrayWnd 	; The original active window will be still active even if it goes the bottom or something comes on it, which causes that even if you click the original window, it won't come to the topmost. Therefore, instead deactivate it.

	Loop {
		Sleep, 10 	; poll ~100x/s instead of busy-waiting (CPU)
		if (!FLAG_HALFTRANS) {
			Loop, %AltTab_ID_List_0% {
			    WinGet, original_trans%A_Index%, Transparent, % "ahk_id " AltTab_ID_List_%A_index%
			    if ! original_trans%A_Index% {         ; original_trans is 0 or not assigned
			        if original_trans%A_Index% != 0    ; original_trans is not 0 (so not assigned)
			            original_trans%A_Index% := 255
			    }
				WinSet, Transparent, % SETTING_CONSTANT_HALFTRANS, % "ahk_id " AltTab_ID_List_%A_index% 	; % original_trans%A_Index%/2
			}
			FLAG_HALFTRANS := 1
		}
		;Tooltip looping window_rotate_popup FLAG_HALFTRANS IS %FLAG_HALFTRANS%;
		if ((!(GetKeyState("LWin", "P")) and !(GetKeyState("Rwin", "P"))) or !(GetKeyState("control", "P")) or !(GetKeyState("Alt", "P"))) {
			WinActivate, % "ahk_id " AltTab_ID_List_%window_rotate_current% 	; AltTab_window_list() is not perfect so it may activate unwanted window or it may fail to activate the visually topmost window

			; To make topmost again
			Loop, %AltTab_ID_List_0% {
				if (A_Index < AltTab_ID_List_topOfNontopmost) {
					temp := AltTab_ID_List_topOfNontopmost - A_Index
					WinSet, AlwaysOnTop, On, % "ahk_id " AltTab_ID_List_%temp%	; For the order of topmost's
				} else if (A_Index != window_rotate_current) {
					WinSet, Bottom, , % "ahk_id " AltTab_ID_List_%A_Index%
				}
				
			}
			if (window_rotate_current < AltTab_ID_List_topOfNontopmost) {
				WinSet, AlwaysOnTop, On, % "ahk_id " AltTab_ID_List_%window_rotate_current%
			}

			if (FLAG_HALFTRANS) {
				Loop, %AltTab_ID_List_0% {
					;WinSet, Transparent, % original_trans%A_Index%, % "ahk_id " AltTab_ID_List_%A_index%
					WinSet, Transparent, 255, % "ahk_id " AltTab_ID_List_%A_index%
				}
				;tooltip transparent reset all !!popup
			}
			FLAG_HALFTRANS := 0

			wheel_count_down := 0
			wheel_count_check := 0 	; Before ending window_rotate_popup, when window_rotate_stacking is triggered, it's needed. Or somehow. 
			window_rotate_firstcheck_popup := 0
			break
		}
		if (wheel_count_down > wheel_count_check) {

			; If we only use wheel_count_down instead of window_rotate_current, then it can be a problem
			; when !^WheelDown:: is triggered again continuously before giving window_rotate_popup: a chance to proceed its loop which was looping before 
			; As a result, it may skip a window to send back.
			; Therefore, we use window_rotate_current
			WinSet, Transparent, % SETTING_CONSTANT_HALFTRANS, % "ahk_id " AltTab_ID_List_%window_rotate_current%
			window_rotate_current ++
			if (window_rotate_current > AltTab_ID_List_0) {
				window_rotate_current := 1
			}

			PulseTop(AltTab_ID_List_%window_rotate_current%)
			WinSet, Transparent, % SETTING_CONSTANT_FOCUSTRANS, % "ahk_id " AltTab_ID_List_%window_rotate_current%
			; ToolTip to check the current focused window
			WinGetTitle, wintitle, % "ahk_id " AltTab_ID_List_%window_rotate_current%
			tooltip % wintitle
			SetTimer, RemoveToolTip, % SETTING_CONSTANT_TOOLTIPDUR_S 

			wheel_count_check ++ 	; advance one step per processed window instead of snapping (which dropped queued scroll clicks)
		}

		if (wheel_count_down < wheel_count_check) {
			WinSet, Transparent, % SETTING_CONSTANT_HALFTRANS, % "ahk_id " AltTab_ID_List_%window_rotate_current%
			window_rotate_current --
			if (window_rotate_current < 1) {
				window_rotate_current := AltTab_ID_List_0
			}
			PulseTop(AltTab_ID_List_%window_rotate_current%)
			WinSet, Transparent, % SETTING_CONSTANT_FOCUSTRANS, % "ahk_id " AltTab_ID_List_%window_rotate_current%
			; ToolTip to check the current focused window
			WinGetTitle, wintitle, % "ahk_id " AltTab_ID_List_%window_rotate_current%
			tooltip % wintitle
			SetTimer, RemoveToolTip, % SETTING_CONSTANT_TOOLTIPDUR_S 

			wheel_count_check -- 	; advance one step per processed window instead of snapping (which dropped queued scroll clicks)
		}
	}
return
; ================= Temporary showing around ==================== ends ==============================

; ================= Rotating the same type (class) windows ==================== starts ==============================
;; Rotating the same type (class) windows

#!+WheelDown::	; Next Window. While sending the current window most bottom,
#!+[::
!`::
;!~::
WinGetClass, CurrentActive, A
WinGet, Instances, Count, ahk_class %CurrentActive%
If Instances > 1
	WinSet, Bottom,, A
WinActivate, ahk_class %CurrentActive%
return

#!+WheelUp::	; Previous Window. Without sending the current window most bottom
#!+]::
!+`::
;!+~::
WinGetClass, CurrentActive, A
WinGet, Instances, Count, ahk_class %CurrentActive%
If Instances > 1
	WinActivateBottom, ahk_class %CurrentActive%
return

; ================= Rotating the same type (class) windows ==================== ends ==============================

; ================= Navigating windows by arrow keys ==================== starts ==============================
;;windowSeekArrow
; Ctrl+Alt + Arrows are used in Sublime!

#!^Right::
#!^Left::
#!^Down::
#!^Up::
GetKeyState, is_right, Right, P
GetKeyState, is_left, Left, P
GetKeyState, is_down, Down, P
GetKeyState, is_up, Up, P

	if (started_windowSeekArrow = 1) {
		return
	}
	started_windowSeekArrow := 1
	AltTab_window_list()

	;=== To exclude minimized windows ===
	AltTab_ID_List_woMinWin_0 := 0
	Loop, %AltTab_ID_List_0% {
		WinGet, is_max, MinMax, % "ahk_id " AltTab_ID_List_%A_index% ; To skip minimized windows
		if (is_max = -1)
			Continue
		AltTab_ID_List_woMinWin_0 ++
		AltTab_ID_List_woMinWin_%AltTab_ID_List_woMinWin_0% := AltTab_ID_List_%A_index%
	}
	;=== AltTab_ID_List_woMinWin_0 = the number of windows which are not minimized. 
	;=== AltTab_ID_List_woMinWin_%A_Index% is each ID value.
	;=== FINISED: To exclude minimized windows ===

	; Checking WS_EX_TOPMOST windows
	Loop, %AltTab_ID_List_woMinWin_0% {
		; Basically WinSet, Bottom revokes the WS_EX_TOPMOST (always on top) state.
		WinGet, var_ExStyle, ExStyle, % "ahk_id " AltTab_ID_List_woMinWin_%A_index%
		if !(var_ExStyle & 0x8) {  ; 0x8 is WS_EX_TOPMOST (always on top).
			AltTab_ID_List_topOfNontopmost := A_Index
			break
		}
	}
;	window_rotate_current := AltTab_ID_List_topOfNontopmost

	; To make all half transparent
	if (!FLAG_HALFTRANS) {
		Loop, %AltTab_ID_List_woMinWin_0% {
		    WinGet, original_trans%A_Index%, Transparent, % "ahk_id " AltTab_ID_List_woMinWin_%A_index%
		    if ! original_trans%A_Index% {         ; original_trans is 0 or not assigned
		        if original_trans%A_Index% != 0    ; original_trans is not 0 (so not assigned)
		            original_trans%A_Index% := 255
		    }
		    WinSet, Transparent, % SETTING_CONSTANT_HALFTRANS, % "ahk_id " AltTab_ID_List_woMinWin_%A_index% 	; % original_trans%A_Index%/2
		}
		FLAG_HALFTRANS := 1
	}

	; To find the current active window 
	WinGet, window_current_id, ID, A
	Loop, %AltTab_ID_List_woMinWin_0% {
		if (window_current_id = AltTab_ID_List_woMinWin_%A_Index%) {
			window_current := A_Index
		}
	}
	window_original := window_current 	; window_original is the starting point of this hotkey. (Even if many arrow keys are inputted, window_original doesn't change.)
										; window_current is a current window at each stage while pressing arrow keys
										; window_original may not be used!

	; The main loop to receive arrow key inputs
	Loop, {
		Sleep, 10 	; poll ~100x/s instead of busy-waiting (CPU)
		; One shared step per direction (the four ~46-line copy-pasted blocks were unified 2026-07-05;
		; direction selection now uses dot/cross scoring, see SeekArrow_FindNext)
		if (is_right = "D")
			SeekArrow_Step(1, 0, "Right")
		if (is_left = "D")
			SeekArrow_Step(-1, 0, "Left")
		if (is_down = "D")
			SeekArrow_Step(0, 1, "Down")
		if (is_up = "D")
			SeekArrow_Step(0, -1, "Up")

		if (!((GetKeyState("LWin", "P") or GetKeyState("RWin", "P")) and GetKeyState("control", "P") and GetKeyState("Alt", "P"))) {
			WinActivate, % "ahk_id " AltTab_ID_List_woMinWin_%window_current%
			; To make topmost again
			Loop, %AltTab_ID_List_woMinWin_0% {
				if (A_Index < AltTab_ID_List_topOfNontopmost) {
					temp := AltTab_ID_List_topOfNontopmost - A_Index
					WinSet, AlwaysOnTop, On, % "ahk_id " AltTab_ID_List_woMinWin_%temp%	; For the order of topmost's
				} else if (A_Index != window_current) {
					WinSet, Bottom, , % "ahk_id " AltTab_ID_List_woMinWin_%A_Index%
				}
			}
			if (window_current < AltTab_ID_List_topOfNontopmost) {
				WinSet, AlwaysOnTop, On, % "ahk_id " AltTab_ID_List_woMinWin_%window_current%
			}
			if (FLAG_HALFTRANS) {
				Loop, %AltTab_ID_List_woMinWin_0% {
					WinSet, Transparent, % original_trans%A_Index%, % "ahk_id " AltTab_ID_List_woMinWin_%A_index%
				}
			}
			FLAG_HALFTRANS := 0
			started_windowSeekArrow := 0
			break
		}
		GetKeyState, is_right, Right, P
		GetKeyState, is_left, Left, P
		GetKeyState, is_down, Down, P
		GetKeyState, is_up, Up, P
	}
return
; ================= Navigating windows by arrow keys ==================== ends ==============================


; ===========================================================================================================
 											;; WINDOW ROTATION ;;     ends
; ===========================================================================================================


; ================= Ctrl + Page up/down effect ==================== starts ==============================
;^+]:: 	; not good becuase of Photoshop
^+WheelDown::
	SendInput, {Blind}{Shift Up}{PgDn} 	; {Blind}: keep the physically-held Ctrl, drop only the
						; held Shift, no in-batch restore -> a clean Ctrl+PgDn (Ctrl+Shift+PgDn would
						; MOVE the tab in Chrome instead of switching). Same fix pattern as ^w above.
Return

;^+[:: 	; not good becuase of Photoshop
^+WheelUp::
	SendInput, {Blind}{Shift Up}{PgUp} 	; clean Ctrl+PgUp (see ^+WheelDown)
Return
; ================= Ctrl + Page up/down effect ==================== ends ==============================


; ================= Showing only File Explorer - into grid, changing size ======= starts ==================
; Currently only on the primary Screen
; to add with a modifier: put windows on their Screens
; to add with a modifier: put windows only on the screen where mouse cursor is.
;F4:: 
+F2::
;CapsLock & 2::
; When it's only F4, it's a problem on Excel.
	Show_Windows("Explorer.exe", "", 1) 	; grid mode - the old ~145-line Explorer-only implementation was superseded by Show_Windows()
Return



; ================= Showing only File Explorer - without changing size ======= starts ==================
; Currently only on the primary Screen
; to add with a modifier: put windows on their Screens
; to add with a modifier: put windows only on the screen where mouse cursor is.
;F3::
+F1::
;CapsLock & F3::
	Show_Windows("Explorer.exe", "", 0) 	; spread mode - the old ~690-line Explorer-only implementation was superseded by Show_Windows()
Return
; ================= Showing only File Explorer - without changing size ======= ends ==================



;; MOVING WINDOW
;; Perhaps using Loop and 

;;windowMove
; CaspLock + Arrow key
; CapsLock + Win + Arrow key: move a window with the arrow keys
; CapsLock + Win + Arrow key: move a window with the arrow keys faster
; CapsLock + Shift + Arrow key: move a window to the edges
; ...
CapsLock & Up::
CapsLock & Down::
CapsLock & Left::
CapsLock & Right::
; X & Y::  => X must be pressed before Y. So CapsLock & Alt isn't a good idea.
; Shift & CapsLock & Right, + & CapsLock & Right, +CapsLock & Right, + CapsLock & Right all don't work.
	
	IF (FLAG_MOUSECONTROL = 1) {
		return
	}

	if (started_windowMove = 1) { 	; We can do it wihtout if(started_windowMove) and the loop statement below. However, without them, 
		return 						; if a user strokes the right key and left key very fast, 
	} 								; the right key state will be still down even at the left key's cycle. It will cause two right keys instead of right - left.
	started_windowMove := 1

	control_repushCheck := 0
	control_triggered := 0
	capSpeedUpArrowKey := 0

	CollectMonitorInfo() 	; (hoisted out of the loop below; it used to be re-queried every iteration)

	loop {
		WinGet, wm_target_id, ID, A 	; snapshot the active window once per iteration, so a focus change between the position read and the move cannot hand this window's coordinates to a different window
		if (wm_target_id = "")
			wm_target_id := 0 	; no active window: "ahk_id 0" matches nothing, so the moves below silently do nothing
		WinGetPos, X,Y,W,H, ahk_id %wm_target_id%

		GetKeyState, is_ctrl, Ctrl, P
		GetKeyState, is_up, Up, P
		GetKeyState, is_down, Down, P
		GetKeyState, is_left, Left, P
		GetKeyState, is_right, Right, P
		GetKeystate, is_lstart, LWin, P
		GetKeystate, is_rstart, RWin, P
		GetKeyState, is_shift, Shift, P
		if (is_lstart = "D") or (is_rstart = "D") {
			if (is_shift = "D") {
				
				;; move by 200 px
				;; CapsLock + Win + Shift + Arrow Key (처음엔 이걸로 했었던 듯 Win+Ctrl+Shift+Arrow Key)
/*
				if (is_right = "D") {
					WinMove,A,, X + SETTING_CONSTANT_WINMOV_PX_L,
					KeyWait, Right, % "T" SETTING_CONSTANT_WINMOV_PX_L_RepSec
				}
				if (is_left = "D") { 		; If else if is used, it won't go diagonally when two buttons pressed together. 
					WinMove,A,, X - SETTING_CONSTANT_WINMOV_PX_L,
					KeyWait, Left, % "T" SETTING_CONSTANT_WINMOV_PX_L_RepSec
				}
				if (is_up = "D") {
					WinMove,A,,, Y - SETTING_CONSTANT_WINMOV_PX_L
					KeyWait, Up, % "T" SETTING_CONSTANT_WINMOV_PX_L_RepSec
				}
				if (is_down = "D") {
					WinMove,A,,, Y + SETTING_CONSTANT_WINMOV_PX_L
					KeyWait, Down, % "T" SETTING_CONSTANT_WINMOV_PX_L_RepSec
				}
*/
				if (is_right = "D") {
					WinMove, ahk_id %wm_target_id%,, X + SETTING_CONSTANT_WINMOV_PX_S,
					KeyWait, Right, % "T" "0.005"
				} 
				if (is_left = "D") {
					WinMove, ahk_id %wm_target_id%,, X - SETTING_CONSTANT_WINMOV_PX_S,
					KeyWait, Left, % "T" "0.005"
				} 
				if (is_up = "D") {
					WinMove, ahk_id %wm_target_id%,,, Y - SETTING_CONSTANT_WINMOV_PX_S
					KeyWait, Up, % "T" "0.005"
				} 
				if (is_down = "D") {
					WinMove, ahk_id %wm_target_id%,,, Y + SETTING_CONSTANT_WINMOV_PX_S
					KeyWait, Down, % "T" "0.005"
				}



			} else {

				;; move by 20 px
				;; CapsLock + Win + Arrow Key

				if (is_right = "D") {
					WinMove, ahk_id %wm_target_id%,, X + SETTING_CONSTANT_WINMOV_PX_S,
					KeyWait, Right, % "T" SETTING_CONSTANT_WINMOV_PX_S_RepSec
				} 
				if (is_left = "D") {
					WinMove, ahk_id %wm_target_id%,, X - SETTING_CONSTANT_WINMOV_PX_S,
					KeyWait, Left, % "T" SETTING_CONSTANT_WINMOV_PX_S_RepSec
				} 
				if (is_up = "D") {
					WinMove, ahk_id %wm_target_id%,,, Y - SETTING_CONSTANT_WINMOV_PX_S
					KeyWait, Up, % "T" SETTING_CONSTANT_WINMOV_PX_S_RepSec
				} 
				if (is_down = "D") {
					WinMove, ahk_id %wm_target_id%,,, Y + SETTING_CONSTANT_WINMOV_PX_S
					KeyWait, Down, % "T" SETTING_CONSTANT_WINMOV_PX_S_RepSec
				}
			}
		} else { 	; Without Win key.  (monitor info is collected once, before this loop)
			if (is_shift = "D") {

				;; move to an edge
				;; Win+Ctrl+Alt+Arrow Key (이거 아닌데)
				;; ~((screen_top > window_botom) v (screen_bottom < window_top)) => the window overlaps the screen

				if (is_right = "D") {
					edge_i := Monitor_EdgeScan("right_edge", X, Y, W, H) 	; nearest work-area right edge beyond the window's right side
					edge_j := Monitor_EdgeScan("right_gap", X, Y, W, H) 	; nearest work-area left edge beyond the window's left side (next monitor)
					DWM_GetBorders(wm_target_id, bL, bT, bR, bB)
					if (edge_i != "" and edge_j != "") {
						if (edge_i - X - W < edge_j - X)
							WinMove, ahk_id %wm_target_id%, , % edge_i - W + bR
						else
							WinMove, ahk_id %wm_target_id%, , % edge_j - bL
					} else if (edge_i != "") {
						WinMove, ahk_id %wm_target_id%, , % edge_i - W + bR
					} else if (edge_j != "") {
						WinMove, ahk_id %wm_target_id%, , % edge_j - bL
					}
					KeyWait, Right, % "T" SETTING_CONSTANT_WINMOV_STEP_REP
				}
				if (is_left = "D") {
					edge_i := Monitor_EdgeScan("left_edge", X, Y, W, H)
					edge_j := Monitor_EdgeScan("left_gap", X, Y, W, H)
					DWM_GetBorders(wm_target_id, bL, bT, bR, bB)
					if (edge_i != "" and edge_j != "") {
						if (X - edge_i < X + W - edge_j)
							WinMove, ahk_id %wm_target_id%, , % edge_i - bL
						else
							WinMove, ahk_id %wm_target_id%, , % edge_j - W + bR
					} else if (edge_i != "") {
						WinMove, ahk_id %wm_target_id%, , % edge_i - bL
					} else if (edge_j != "") {
						WinMove, ahk_id %wm_target_id%, , % edge_j - W + bR
					}
					KeyWait, Left, % "T" SETTING_CONSTANT_WINMOV_STEP_REP
				}
				if (is_up = "D") {
					edge_i := Monitor_EdgeScan("up_edge", X, Y, W, H)
					edge_j := Monitor_EdgeScan("up_gap", X, Y, W, H)
					DWM_GetBorders(wm_target_id, bL, bT, bR, bB)
					if (edge_i != "" and edge_j != "") {
						if (Y - edge_i < Y + H - edge_j)
							WinMove, ahk_id %wm_target_id%, , , % edge_i - bT
						else
							WinMove, ahk_id %wm_target_id%, , , % edge_j - H + bB
					} else if (edge_i != "") {
						WinMove, ahk_id %wm_target_id%, , , % edge_i - bT
					} else if (edge_j != "") {
						WinMove, ahk_id %wm_target_id%, , , % edge_j - H + bB
					}
					KeyWait, Up, % "T" SETTING_CONSTANT_WINMOV_STEP_REP
				}
				if (is_down = "D") {
					edge_i := Monitor_EdgeScan("down_edge", X, Y, W, H)
					edge_j := Monitor_EdgeScan("down_gap", X, Y, W, H)
					DWM_GetBorders(wm_target_id, bL, bT, bR, bB)
					if (edge_i != "" and edge_j != "") {
						if (edge_i - Y - H < edge_j - Y)
							WinMove, ahk_id %wm_target_id%, , , % edge_i - H + bB
						else
							WinMove, ahk_id %wm_target_id%, , , % edge_j - bT
					} else if (edge_i != "") {
						WinMove, ahk_id %wm_target_id%, , , % edge_i - H + bB
					} else if (edge_j != "") {
						WinMove, ahk_id %wm_target_id%, , , % edge_j - bT
					}
					KeyWait, Down, % "T" SETTING_CONSTANT_WINMOV_STEP_REP
				}
				;Continue		
			} else {

				;; moving in grid with Arrow Key

				; (the monitor-detection loop moved into the is_ctrl branch below: it must run AFTER WinRestore,
				;  because a maximized window's raw rect lies outside every monitor's full bounds)

				; General idea is to use ceil() function. 

				; If the screen width is 11, and we use the grid of 3 * 3, the grid points will be 0, 3.666, 7.333, 11.
				; In this case, if the original position is at the point 5, and if we move to decrease (up or left), it will go to the point 3.66, but since there is no pixel,
				; it will go to the point 4 (roundupped). Then even if we try to move to decrease (up or left), it will be stuck at the point 4 without adjusting.
				; Hence, we need to modify the functions: f(x) (= ceil(x+ε)), g(x-ε) will work well.

				; - to the direction of increasing (the down arrow, the right arrow)
				;	f(x) := ceil(x+ε)	= 0, -1 <= x < 0
				;						  1,  0 <= x < 1
				;						  2,  1 <= x < 2
				;						  3,  2 <= x < 3
				;						  4,  3 <= x < 4
				; - to the direction of decreasing (the up arrow, the left arrow)
				;	g(x) := ceil(x) - 1 = ceil(x-1)	= 0,  0 < x <= 1
				;									  1,  1 < x <= 2
				;									  2,  2 < x <= 3
				;									  3,  3 < x <= 4
				
				if (is_ctrl = "D") {
					WinRestore, ahk_id %wm_target_id%
					WinGetPos, X,Y,W,H, ahk_id %wm_target_id% 	; re-read after restoring: a maximized window's raw rect (e.g. -8,-8) lies outside every monitor's full bounds
					cenX := X + W/2
					cenY := Y + H/2
					foundMon := 0
					loop, %monitor_no% {
						if (monitor_%A_Index%_left <= cenX) and (cenX < monitor_%A_Index%_right) and (monitor_%A_Index%_top <= cenY) and (cenY < monitor_%A_Index%_bottom) {		; half-open ranges partition the desktop exactly even for fractional centers
							ScreenWoTaskbar_X := monitor_%A_Index%_workarea_left
							ScreenWoTaskbar_Y := monitor_%A_Index%_workarea_top
							ScreenWoTaskbar_W := monitor_%A_Index%_workarea_width
							ScreenWoTaskbar_H := monitor_%A_Index%_workarea_height
							foundMon := 1
						}
					}
					if (foundMon = 0) {		; window center is on no monitor: fall back to the primary so the WinMove below never gets blank/stale parameters
						SysGet, monPrm, MonitorPrimary
						ScreenWoTaskbar_X := monitor_%monPrm%_workarea_left
						ScreenWoTaskbar_Y := monitor_%monPrm%_workarea_top
						ScreenWoTaskbar_W := monitor_%monPrm%_workarea_width
						ScreenWoTaskbar_H := monitor_%monPrm%_workarea_height
					}

					; to check how many controls were pushed and so as to set girdNo.
					if (control_triggered = 0) {
						control_triggered := 1
						control_repushCheck := 0
						gridNo := 1 + CountRecentTaps("Control")
					}

					if (is_up = "D") {
						DWM_WinMove("ahk_id " wm_target_id, "", ScreenWoTaskbar_Y + Ceil((Y - ScreenWoTaskbar_Y - 1)/ScreenWoTaskbar_H * gridNo - 1)*ScreenWoTaskbar_H / gridNo, ScreenWoTaskbar_W / gridNo, ScreenWoTaskbar_H / gridNo) 
						KeyWait, Up, % "T" SETTING_CONSTANT_WINMOV_STEP_REP
					}
					if (is_down = "D") {
						DWM_WinMove("ahk_id " wm_target_id, "", ScreenWoTaskbar_Y + Ceil((Y - ScreenWoTaskbar_Y + 1)/ScreenWoTaskbar_H * gridNo)*ScreenWoTaskbar_H / gridNo, ScreenWoTaskbar_W / gridNo, ScreenWoTaskbar_H / gridNo) 
						KeyWait, Down, % "T" SETTING_CONSTANT_WINMOV_STEP_REP
					}
					if (is_left = "D") {
						DWM_WinMove("ahk_id " wm_target_id, ScreenWoTaskbar_X + Ceil((X - ScreenWoTaskbar_X - 1)/ScreenWoTaskbar_W * gridNo - 1)*ScreenWoTaskbar_W / gridNo, "", ScreenWoTaskbar_W / gridNo, ScreenWoTaskbar_H / gridNo)
						KeyWait, Left, % "T" SETTING_CONSTANT_WINMOV_STEP_REP
					}
					if (is_right = "D") {
						DWM_WinMove("ahk_id " wm_target_id, ScreenWoTaskbar_X + Ceil((X - ScreenWoTaskbar_X + 1)/ScreenWoTaskbar_W * gridNo)*ScreenWoTaskbar_W / gridNo, "", ScreenWoTaskbar_W / gridNo, ScreenWoTaskbar_H / gridNo)
						KeyWait, Right, % "T" SETTING_CONSTANT_WINMOV_STEP_REP
					}
				} else {
					; to check how many Shifts were pushed and so as to set speedup.
					if (!capSpeedUpArrowKey) {
						capSpeedUpArrowKey := 1 + CountRecentTaps("CapsLock") 	; The last CapsLock stroke is not stamped. So we start at 1.
						;Tooltip, % "Speed level up - lev. " capSpeedUpArrowKey " " is_down " " is_up " " is_right " " is_left " " GetKeyState("CapsLock", "P")	
						;SetTimer, RemoveToolTip, % SETTING_CONSTANT_TOOLTIPDUR_S
					}
					;speed := 3 * capSpeedUpArrowKey
					Loop, % capSpeedUpArrowKey {
						if (is_up = "D") {
							;Send, {Up 2}
							SendInput {Up}
						}
						if (is_down = "D") {
							;Send, {Down 2} 
							SendInput, {Down}
						}
						if (is_left = "D") {
							;Send, {Left 2} 
							SendInput, {Left}
						}
						if (is_right = "D") {
							;Send, {Right 2} 
							SendInput, {Right}
						}
					}
					;KeyWait, Up, T0.1
					;KeyWait, Down, T0.1
					;KeyWait, Left, T0.1
					;KeyWait, Right, T0.1
					Sleep, 10
				}
			}
		}
		if (!GetKeyState("Control", "P") and (control_triggered = 1) and (control_repushCheck = 0)) {
			control_repushCheck := 1
		}
		if (!GetKeyState("CapsLock", "P")) {
			started_windowMove := 0
			Break
		}
		if (is_up != "D" and is_down != "D" and is_left != "D" and is_right != "D") {
			Sleep, 10 	; idle poll; the arrow-held paths pace themselves via KeyWait
		}
	}
return

; (removed a debug-only hotkey #^!+K that showed a key-state tooltip)

; (removed leftover debug combo `~Right & CapsLock::` — while the Right arrow was held it outranked
;  the plain CapsLock:: hotkey, making CapsLock completely dead: no toggle, no timestamp)

;; RESIZING WINDOW

;; resize by 20 px
;; Win+Alt+Arrow Key
#!Right::
#!Left::
#!Down::
#!Up::
	beep_resize_depth += 1 	; the four arrow hotkeys share this body; only the outermost thread saves/restores the beep setting
	if (beep_resize_depth = 1) {
		DllCall("SystemParametersInfo", UInt, 0x0001, UInt, 0, UIntP, beep_resize, UInt,0)
		DllCall("SystemParametersInfo", UInt, 0x0002, UInt, 0, UInt,0, UInt,0) 	; SPI_SETBEEP : 0x0002
	}
	loop {
		WinGet, wr_target_id, ID, A 	; snapshot the active window once per iteration (same reason as the CapsLock+Arrow loop)
		if (wr_target_id = "")
			wr_target_id := 0 	; "ahk_id 0" matches nothing -> the resizes below silently do nothing
		GetKeyState, is_up, Up, P
		GetKeyState, is_down, Down, P
		GetKeyState, is_left, Left, P
		GetKeyState, is_right, Right, P

		GetKeyState, is_x, x, P

		if (is_right = "D") {
			WinGetPos, X,Y,W,H, ahk_id %wr_target_id%
			if (is_x = "D") {
				WinMove, ahk_id %wr_target_id%,,X+20,,W-20,
				KeyWait, Right, % "T" SETTING_CONSTANT_WINMOV_PX_S_RepSec
			} else {
				WinMove, ahk_id %wr_target_id%,,,,W+20,
				WinGetPos, X,,W2,, ahk_id %wr_target_id%
				if (W = W2) {
					WinMove, ahk_id %wr_target_id%,, X+20,,,
				}
				KeyWait, Right, % "T" SETTING_CONSTANT_WINMOV_PX_S_RepSec
			}
		}
		if (is_left = "D") {
			WinGetPos, X,Y,W,H, ahk_id %wr_target_id%
			if (is_x = "D") {
				WinMove, ahk_id %wr_target_id%,,,,W-20,
				WinGetPos, X,,W2,, ahk_id %wr_target_id%
				if (W = W2) {
					WinMove, ahk_id %wr_target_id%,, X-20,,,
				}
				KeyWait, Left, % "T" SETTING_CONSTANT_WINMOV_PX_S_RepSec
			} else {

				WinMove, ahk_id %wr_target_id%,,X-20,,W+20,
				KeyWait, Left, % "T" SETTING_CONSTANT_WINMOV_PX_S_RepSec
			}
		}
		if (is_down = "D") {
			WinGetPos, X,Y,W,H, ahk_id %wr_target_id%
			if (is_x = "D") {
				WinMove, ahk_id %wr_target_id%,,,Y+20,,H-20
				KeyWait, Down, % "T" SETTING_CONSTANT_WINMOV_PX_S_RepSec
			} else {
				WinMove, ahk_id %wr_target_id%,,,,,H+20
				WinGetPos, ,Y,,H2, ahk_id %wr_target_id%
				if (H = H2) {
					WinMove, ahk_id %wr_target_id%,,,Y+20,,
				}
				KeyWait, Down, % "T" SETTING_CONSTANT_WINMOV_PX_S_RepSec
			}
		}
		if (is_up = "D") {
			WinGetPos, X,Y,W,H, ahk_id %wr_target_id%
			if (is_x = "D") {
				WinMove, ahk_id %wr_target_id%,,,,,H-20
				WinGetPos, ,Y,,H2, ahk_id %wr_target_id%
				if (H = H2) {
					WinMove, ahk_id %wr_target_id%,,,Y-20,,
				}
				KeyWait, Up, % "T" SETTING_CONSTANT_WINMOV_PX_S_RepSec
			} else {
				WinMove, ahk_id %wr_target_id%,,,Y-20,,H+20
				KeyWait, Up, % "T" SETTING_CONSTANT_WINMOV_PX_S_RepSec
			}
		}

		if (!GetKeyState("Alt", "P")) {
			Break
		}
		if (is_up != "D" and is_down != "D" and is_left != "D" and is_right != "D") {
			Sleep, 10 	; idle poll; the arrow-held paths pace themselves via KeyWait
		}
	}
	beep_resize_depth -= 1
	if (beep_resize_depth <= 0) {
		beep_resize_depth := 0
		DllCall("SystemParametersInfo", UInt, 0x0002, UInt, beep_resize, UInt,0, UInt,0) 	; SPI_SETBEEP : 0x0002
	}
return

	
;; disabled as useless
;;
;;;; resize by 200 px
;;;; Win+Alt+Shift+Arrow Key
;;#!+Right::
;;	WinGetPos, X,Y,W,H,A  ; "A" to get the active window's pos.
;;	GetKeyState, is_x, x, P
;;	if (is_x = "D") {
;;		WinMove,A,,X+200,,W-200,
;;		} else {
;;			WinMove,A,,,,W+200,
;;		}
;;return
;;#!+Left::
;;	WinGetPos, X,Y,W,H,A  ; "A" to get the active window's pos.
;;	GetKeyState, is_x, x, P
;;	if (is_x = "D") {
;;		WinMove,A,,,,W-200,
;;		} else {
;;			WinMove,A,,X-200,,W+200,
;;		}
;;return
;;#!+Up::
;;	WinGetPos, X,Y,W,H,A  ; "A" to get the active window's pos.
;;	GetKeyState, is_x, x, P
;;	if (is_x = "D") {
;;		WinMove,A,,,,,H-200
;;		} else {
;;			WinMove,A,,,Y-200,,H+200
;;		}
;;return
;;#!+Down::
;;	WinGetPos, X,Y,W,H,A  ; "A" to get the active window's pos.
;;	GetKeyState, is_x, x, P
;;	if (is_x = "D") {
;;		WinMove,A,,,Y+200,,H-200
;;		} else {
;;			WinMove,A,,,,,H+200
;;		}
;;return


;; resize to the edge
;; Win+Alt+Shift+Arrow Key
#!+Right::
	WinGet, wr_id, ID, A
	if (!wr_id)
		Return
	WinGetPos, X,Y,W,H, ahk_id %wr_id%
	CollectMonitorInfo()
	edge := Monitor_EdgeScan("right_edge", X, Y, W, H)
	if (edge != "") {
		DWM_GetBorders(wr_id, bL, bT, bR, bB)
		WinMove, ahk_id %wr_id%, , , , % edge - X + bR 	; grow so the VISIBLE right edge lands on the screen edge
	}
return

#!+Left::
	WinGet, wr_id, ID, A
	if (!wr_id)
		Return
	WinGetPos, X,Y,W,H, ahk_id %wr_id%
	CollectMonitorInfo()
	edge := Monitor_EdgeScan("left_edge", X, Y, W, H)
	if (edge != "") {
		DWM_GetBorders(wr_id, bL, bT, bR, bB)
		WinMove, ahk_id %wr_id%, , % edge - bL, , % X + W - edge + bL 	; grow left so the VISIBLE left edge lands on the screen edge
	}
return

#!+Up::
	WinGet, wr_id, ID, A
	if (!wr_id)
		Return
	WinGetPos, X,Y,W,H, ahk_id %wr_id%
	CollectMonitorInfo()
	edge := Monitor_EdgeScan("up_edge", X, Y, W, H)
	if (edge != "") {
		DWM_GetBorders(wr_id, bL, bT, bR, bB)
		WinMove, ahk_id %wr_id%, , , % edge - bT, , % Y + H - edge + bT 	; grow up so the VISIBLE top edge lands on the screen edge
	}
return

#!+Down::
	WinGet, wr_id, ID, A
	if (!wr_id)
		Return
	WinGetPos, X,Y,W,H, ahk_id %wr_id%
	CollectMonitorInfo()
	edge := Monitor_EdgeScan("down_edge", X, Y, W, H)
	if (edge != "") {
		DWM_GetBorders(wr_id, bL, bT, bR, bB)
		WinMove, ahk_id %wr_id%, , , , , % edge - Y + bB 	; grow so the VISIBLE bottom edge lands on the screen edge
	}
return


;; CapsLock + Left mouse click-drag
;;;RButton::Send {RButton}
;;;RButton & LButton:: 	; It will disable usability of right-click drag like in Google Earth or some CAD programs
CapsLock & LButton::
	if (FLAG_CONSTRAINEDMOUSE = 1) 	; If perpendicular mouse movement hotkey is working, this hotkey shouldn't be triggered.
		Return 						;
	CoordMode, Mouse  ; Switch to screen/absolute coordinates.
	MouseGetPos, MouseStartX, MouseStartY, MouseWin
	
	; CapsLock + Control + Left click = activating the window under the mouse pointer
	; It would be useful when you want to activate an window/application but without changing the location of the cursor (ex. File Explorer, Sublime Text, Foobar)
	GetKeyState, CtrlState, Control, P  ;If Ctrl is pressed, the window being moved get activated.
	if CtrlState = D  ; Escape has been pressed, so drag is cancelled.
	{
		WinActivate, ahk_id %MouseWin%
	}	
	
	CollectMonitorInfo()
	
	; 마우스 클릭을 할 당시 윈도우가 max였는지 아닌지 확인. max였다면 그걸 끌어당겨 내려왔을 때 창의 크기에 대한 준비
	WinGet, is_max, MinMax, ahk_id %MouseWin% 
	if (is_max = 0) {		; if the window is not maximized 
		WinGetPos, OriginalPosX, OriginalPosY, W, H, ahk_id %MouseWin%
		original_max := 0
	} else if (is_max = 1) {
		original_max := 1 ;
		WinGetPos, maxWin_X, maxWin_Y, maxWin_W, maxWin_H, ahk_id %MouseWin%
		; in case moving a maxmized window
		max_quadrant := -1 	; mathematical quadrants: 1st=1, 2nd=2, 3rd=-2, 4th=-1
		short_x := maxWin_X + maxWin_W - MouseStartX
		short_y := maxWin_Y + maxWin_H - MouseStartY
		if ((MouseStartX - maxWin_X) < maxWin_W/2) {
			short_x := MouseStartX - maxWin_X
			max_quadrant := max_quadrant*2
		}
		if ((MouseStartY - maxWin_Y) < maxWin_H/2) {
			short_y := MouseStartY - maxWin_Y
			max_quadrant := max_quadrant * (-1)
		}
	}
	
	;SetTimer, WatchMouse, 1 ; Track the mouse as the user drags it.
	;WatchMouse:
	; When SetTimer and WatchMouse are used instead of Loop, a problem is created that is if you CapsLock-left-click in those zones 
	; which provoke "half top" or "half bottom" or a quater and drag it to the center, it doesn't form the restored form, but "half top", "half bottom" or a quater.
	; But "half left/right" are fine. 
	Loop {
		Sleep, 10 	; ~100 updates/s is plenty for a drag; stops busy-waiting (CPU)
		GetKeyState, LButtonState, LButton, P
		if LButtonState = U  ; Button has been released, so drag is complete.
		{
		    return
		}
		GetKeyState, EscapeState, Escape, P
		if EscapeState = D  ; Escape has been pressed, so drag is cancelled.
		{
		    if (original_max = 1) or (original_max = 2) {		; if originally max
				WinMaximize, ahk_id %MouseWin%	
			} else {	
			    WinMove, ahk_id %MouseWin%,, %OriginalPosX%, %OriginalPosY%, W, H
			}
		    return
		}
		
		GetKeyState, CtrlState, Control, P  ;If Ctrl is pressed, the window being moved get activated.
		if CtrlState = D  ; Escape has been pressed, so drag is cancelled.
		{
			WinActivate, ahk_id %MouseWin%
		}
		
		; Otherwise, reposition the window to match the change in mouse coordinates
		; caused by the user having dragged the mouse:
		CoordMode, Mouse
		MouseGetPos, MouseX, MouseY
		WinGetPos, WinX, WinY,,, ahk_id %MouseWin%
		WinGet, is_max, MinMax, ahk_id %MouseWin% 
		SetWinDelay, -1   ; Makes the below move faster/smoother.
		
		loop, %monitor_no% {
			if (monitor_%A_Index%_left <= MouseX + 0.5) and (MouseX + 0.5 <= monitor_%A_Index%_right) and (monitor_%A_Index%_top <= MouseY + 0.5) and (MouseY + 0.5 <= monitor_%A_Index%_bottom) {			; monitors' lefts and rights are like 0 ~ 2560, -1920 ~ 0. And mouse point is like (0, 0) ~ (2559, 1439). So adding + 0.5 will make the cases finally exclusive.
				

				GetKeyState, is_shift, Shift, P 	; Moving a window straight
				if (is_shift = "D") {
					; This is a nerdy part.
					; floor(exp(x - abs(x))) = 1 if x >= 0
					;                          0 if x <  0
					; det = ..., -2, -1, 0, 1,  2, ...
					; floor(exp(det - abs(det))) = ..., 0, 0, 1, 1, 1, ...
					det := abs(MouseX - MouseStartX) - abs(MouseY - MouseStartY)
					step := floor(exp(det - abs(det)))	; step is either 1 (if the mouse moved in the X direction more) or 0 (if the mouse moved in the Y direction more)
					WinMove, ahk_id %MouseWin%,, OriginalPosX + (MouseX - MouseStartX)*step, OriginalPosY + (MouseY - MouseStartY)*(1-step), W, H
				} else {
					
				



					GetKeyState, is_alt, Alt, P
					if (is_alt = "U") {	; Alt is up. Aero Snap feature. If the Shift key is held, then no Aero Snap feature
						if (MouseX < monitor_%A_Index%_workarea_left + SETTING_CONSTANT_CAPSMOVE_CORNER) and (MouseY < monitor_%A_Index%_workarea_top + SETTING_CONSTANT_CAPSMOVE_CORNER) {		; left up
							if (is_max = 1) {		; if the window is maximized 
								WinRestore, ahk_id %MouseWin% 	; In case it has touched the top	
								WinGetPos, , , W, H, ahk_id %MouseWin%
							}			
							DWM_WinMove("ahk_id " MouseWin, monitor_%A_Index%_workarea_left, monitor_%A_Index%_workarea_top, monitor_%A_Index%_workarea_width/2, monitor_%A_Index%_workarea_height/2)
						} else if (MouseX > monitor_%A_Index%_workarea_right - SETTING_CONSTANT_CAPSMOVE_CORNER) and (MouseY < monitor_%A_Index%_workarea_top + SETTING_CONSTANT_CAPSMOVE_CORNER) {	; right up
							if (is_max = 1) {		; if the window is maximized 
								WinRestore, ahk_id %MouseWin% 	; In case it has touched the top	
								WinGetPos, , , W, H, ahk_id %MouseWin%
							}			
							DWM_WinMove("ahk_id " MouseWin, monitor_%A_Index%_workarea_left + monitor_%A_Index%_workarea_width/2, monitor_%A_Index%_workarea_top, monitor_%A_Index%_workarea_width/2, monitor_%A_Index%_workarea_height/2)
						} else if (MouseX > monitor_%A_Index%_workarea_right - SETTING_CONSTANT_CAPSMOVE_CORNER) and (MouseY > monitor_%A_Index%_workarea_bottom - SETTING_CONSTANT_CAPSMOVE_CORNER) {	; right bottom
							if (is_max = 1) {		; if the window is maximized 
								WinRestore, ahk_id %MouseWin% 	; In case it has touched the top	
								WinGetPos, , , W, H, ahk_id %MouseWin%
							} 
							DWM_WinMove("ahk_id " MouseWin, monitor_%A_Index%_workarea_left + monitor_%A_Index%_workarea_width/2, monitor_%A_Index%_workarea_top + monitor_%A_Index%_workarea_height/2, monitor_%A_Index%_workarea_width/2, monitor_%A_Index%_workarea_height/2)
						} else if (MouseX < monitor_%A_Index%_workarea_left + SETTING_CONSTANT_CAPSMOVE_CORNER) and (MouseY > monitor_%A_Index%_workarea_bottom - SETTING_CONSTANT_CAPSMOVE_CORNER) {	; left bottom
							if (is_max = 1) {		; if the window is maximized 
								WinRestore, ahk_id %MouseWin% 	; In case it has touched the top	
								WinGetPos, , , W, H, ahk_id %MouseWin%
							} 
							DWM_WinMove("ahk_id " MouseWin, monitor_%A_Index%_workarea_left, monitor_%A_Index%_workarea_top + monitor_%A_Index%_workarea_height/2, monitor_%A_Index%_workarea_width/2, monitor_%A_Index%_workarea_height/2)
						} else if (MouseX < monitor_%A_Index%_workarea_left + SETTING_CONSTANT_CAPSMOVE_LRB){	; left
							if (is_max = 1) {		; if the window is maximized 
								WinRestore, ahk_id %MouseWin% 	; In case it has touched the top	
								WinGetPos, , , W, H, ahk_id %MouseWin%
							} 
							DWM_WinMove("ahk_id " MouseWin, monitor_%A_Index%_workarea_left, monitor_%A_Index%_workarea_top, monitor_%A_Index%_workarea_width/2, monitor_%A_Index%_workarea_height)
						} else if (MouseY < monitor_%A_Index%_workarea_top + SETTING_CONSTANT_CAPSMOVE_TOP){	; top
							if (is_max = 0) {		; if the window is not maximized 
								; To make it remember its original position and size before being maximized
								; WinMove, ahk_id %MouseWin%,, OriginalPosX, OriginalPosY, W, H 	; When there are multiple screens, it may make the window maximized in an unwanted screen.
								WinMove, ahk_id %MouseWin%,, (monitor_%A_Index%_workarea_left + monitor_%A_Index%_workarea_right)/2 - W/2, (monitor_%A_Index%_workarea_top + monitor_%A_Index%_workarea_bottom)/2 - H/2, W, H 
							}
							WinMaximize, ahk_id %MouseWin%
						} else if (MouseY < monitor_%A_Index%_workarea_top + SETTING_CONSTANT_CAPSMOVE_HALFTOP){	; quasi top
							if (is_max = 1) {		; if the window is maximized 
								WinRestore, ahk_id %MouseWin% 	; In case it has touched the top	
								WinGetPos, , , W, H, ahk_id %MouseWin%
							}
							DWM_WinMove("ahk_id " MouseWin, monitor_%A_Index%_workarea_left, monitor_%A_Index%_workarea_top, monitor_%A_Index%_workarea_width, monitor_%A_Index%_workarea_height/2)
						} else if (MouseX > monitor_%A_Index%_workarea_right - SETTING_CONSTANT_CAPSMOVE_LRB){	; right
							if (is_max = 1) {		; if the window is maximized 
								WinRestore, ahk_id %MouseWin% 	; In case it has touched the top	
								WinGetPos, , , W, H, ahk_id %MouseWin%
							} 
							DWM_WinMove("ahk_id " MouseWin, monitor_%A_Index%_workarea_left + monitor_%A_Index%_workarea_width/2, monitor_%A_Index%_workarea_top, monitor_%A_Index%_workarea_width/2, monitor_%A_Index%_workarea_height)
						} else if (MouseY > monitor_%A_Index%_workarea_bottom - SETTING_CONSTANT_CAPSMOVE_LRB){	; bottom
							if (is_max = 1) {		; if the window is maximized 
								WinRestore, ahk_id %MouseWin% 	; In case it has touched the top	
								WinGetPos, , , W, H, ahk_id %MouseWin%
							} 
							DWM_WinMove("ahk_id " MouseWin, monitor_%A_Index%_workarea_left, monitor_%A_Index%_workarea_top + monitor_%A_Index%_workarea_height/2, monitor_%A_Index%_workarea_width, monitor_%A_Index%_workarea_height/2)
						} else {	; Aero Snap 영역 외에 있을 때
							if (is_max = 1) {		; if the window is maximized 
								WinRestore, ahk_id %MouseWin% 	; In case it has touched the top	
								WinGetPos, , , W, H, ahk_id %MouseWin%
							}
							if (original_max = 1) {	; 원래 시작 전부터 max로 되어 있는 상태면 안최대화 됐을 때 안최대화에서의 창의 기준 위치인가?!
								
								OriginalPosX := MouseStartX - (W - short_x) 
								OriginalPosY := MouseStartY - (H - short_y)
								if (max_quadrant > 0) {
									OriginalPosY := MouseStartY - short_y
								}
								if (abs(max_quadrant) = 2) {
									OriginalPosX := MouseStartX - short_x
								}
			
								if (W < short_x) {
									OriginalPosX := MouseStartX - W/2
								}
								if (H < short_y) {
									OriginalPosY := MouseStartY - H/2
								}
								original_max := 2
							}
							WinMove, ahk_id %MouseWin%,, OriginalPosX + MouseX - MouseStartX, OriginalPosY + MouseY - MouseStartY, W, H  ; 이게 핵심 코드
							; if it's outside the loop statement, when the mouse point is in the special zones like a corner, the window will alternate between a prefixed size and an original size
							; If W, H are omitted, once acting like Windows' Aero Snap, the window's size doesn't come back to the original size
						}
					} else { 	; When the Alt key is pressed
						if (is_max = 1) {		; if the window is maximized 
							WinRestore, ahk_id %MouseWin% 	; In case it has touched the top	
							WinGetPos, , , W, H, ahk_id %MouseWin%
						}
						if (original_max = 1) {
							
							OriginalPosX := MouseStartX - (W - short_x) 
							OriginalPosY := MouseStartY - (H - short_y)
							if (max_quadrant > 0) {
								OriginalPosY := MouseStartY - short_y
							}
							if (abs(max_quadrant) = 2) {
								OriginalPosX := MouseStartX - short_x
							}
		
							if (W < short_x) {
								OriginalPosX := MouseStartX - W/2
							}
							if (H < short_y) {
								OriginalPosY := MouseStartY - H/2
							}
							original_max := 2
						}
						WinMove, ahk_id %MouseWin%,, OriginalPosX + MouseX - MouseStartX, OriginalPosY + MouseY - MouseStartY, W, H  ; 이게 핵심 코드
						; if it's outside the loop statement, when the mouse point is in the special zones like a corner, the window will alternate between a prefixed size and an original size
						; If W, H are omitted, once acting like Windows' Aero Snap, the window's size doesn't come back to the original size
					}
				}
			}
		}
	}
return


;; CapsLock + Right click-drag

CapsLock & RButton::
	CoordMode, Mouse  ; Switch to screen/absolute coordinates.
	MouseGetPos, MouseStartX, MouseStartY, MouseWin
	WinGetPos, OriginalPosX, OriginalPosY, Original_W, Original_H, ahk_id %MouseWin%

	WinGet, is_max, MinMax, ahk_id %MouseWin% 
	if (is_max = 1) {		; if the window is maximized 
		WinRestore, ahk_id %MouseWin% 	; In case it has touched the top	
		WinMove, ahk_id %MouseWin%, , OriginalPosX, OriginalPosY, Original_W, Original_H
	}

	; We divide the window into 9 pieces: 3 rows and 3 columns. 
	if (MouseStartX < OriginalPosX + Original_W/3) {
		MousePosIndicator_X := -1
	} else if (MouseStartX > OriginalPosX + Original_W*2/3) {
		MousePosIndicator_X := 1
	} else {
		MousePosIndicator_X := 0
	}
	if (MouseStartY < OriginalPosY + Original_H/3) {
		MousePosIndicator_Y := -1
	} else if (MouseStartY > OriginalPosY + Original_H*2/3) {
		MousePosIndicator_Y := 1
	} else {
		MousePosIndicator_Y := 0
	}

	CursorIndicator := Abs(3*MousePosIndicator_X + MousePosIndicator_Y) + 1 

	; 3*MousePosIndicator_X + MousePosIndicator_Y: 
	; ----------------
	; | -4 | -1 |  2 |
	; |--------------|
	; | -3 |  0 |  3 |
	; |--------------|22
	; | -2 |  1 |  4 |
	; ----------------
	SystemCursor(CursorIndicator, "Toggle")


	Loop {
		Sleep, 10 	; ~100 updates/s is plenty for a resize drag; stops busy-waiting (CPU)
		GetKeyState, RButtonState, RButton, P
		if RButtonState = U  ; Button has been released, so drag is complete.
			break
		GetKeyState, EscapeState, Escape, P
		if EscapeState = D  ; Escape has been pressed, so drag is cancelled.
		{
			WinMove, ahk_id %MouseWin%,, %OriginalPosX%, %OriginalPosY%, Original_W, Original_H
			break
		}
		GetKeyState, CtrlState, Control, P  ;If Ctrl is pressed, the window being moved get activated.
		if CtrlState = D  ; Escape has been pressed, so drag is cancelled.
		{
			WinActivate, ahk_id %MouseWin%
		}

		; Otherwise, reposition the window to match the change in mouse coordinates
		; caused by the user having dragged the mouse:
		CoordMode, Mouse
		MouseGetPos, MouseX, MouseY
		WinGetPos, WinX, WinY, Current_W, Current_H, ahk_id %MouseWin%
		SetWinDelay, -1   ; Makes the below move faster/smoother.
		;; This is a neardy part. The 9 cases are done in one line thanks to math
		WinMove, ahk_id %MouseWin%,	, WinX + Floor((1 - MousePosIndicator_X)/2)*(MouseX - MouseStartX)*(1-Floor(Abs(Cos(2*MousePosIndicator_X + MousePosIndicator_Y)))) - (MouseX - MouseStartX)*Floor(Abs(Cos(2*MousePosIndicator_X + MousePosIndicator_Y)))
									, WinY + Floor((1 - MousePosIndicator_Y)/2)*(MouseY - MouseStartY)*(1-Floor(Abs(Cos(2*MousePosIndicator_X + MousePosIndicator_Y)))) - (MouseY - MouseStartY)*Floor(Abs(Cos(2*MousePosIndicator_X + MousePosIndicator_Y)))
									, Current_W + MousePosIndicator_X*(MouseX - MouseStartX)*(1-Floor(Abs(Cos(2*MousePosIndicator_X + MousePosIndicator_Y)))) + 2*(MouseX - MouseStartX)*Floor(Abs(Cos(2*MousePosIndicator_X + MousePosIndicator_Y)))
									, Current_H + MousePosIndicator_Y*(MouseY - MouseStartY)*(1-Floor(Abs(Cos(2*MousePosIndicator_X + MousePosIndicator_Y)))) + 2*(MouseY - MouseStartY)*Floor(Abs(Cos(2*MousePosIndicator_X + MousePosIndicator_Y)))  
	; Floor(Abs(Cos(2*MousePosIndicator_X + MousePosIndicator_Y))) = 1 if the mouse position is at (0,0), 0 otherwise
		MouseStartX := MouseX  ; Update for the next timer-call to this subroutine.
		MouseStartY := MouseY
	}
	SystemCursor(CursorIndicator, "Toggle")
return

; (SystemCursor moved to libFC_Helpers.ahk)



; op-./;:
CapsLock & o::
	DllCall("SystemParametersInfo", UInt, 0x0001, UInt, 0, UIntP, beep_dateinput, UInt,0)
	is_capslock_initial := getkeystate("capslock", "T") 	; (the old "1 -" inverted the state, so every use flipped CapsLock)
	Hotkey, % A_ThisHotkey, , Off 	; Disable the hotkey in order to recive the keystroke of "O" or the trigger key letter.
	thisHotkey_timeInputMode := A_ThisHotkey
	DllCall("SystemParametersInfo", UInt, 0x0002, UInt, 0, UInt,0, UInt,0) 	; SPI_SETBEEP : 0x0002
	date_short := 1
	date_time_short := 0 		
	date_separator := ""
	StringRight, date_year_2, A_YYYY, 2
	date_1 := date_year_2
	date_2 := A_MM
	date_3 := A_DD
	;date_help := "(Press enter to enter. Backspace to remove separator)"
	date_help := "Date and Time Input Help`n`nPress a keyboard as bellow to change`n`nO: YY ↔ YYYY`n0: YY/MM/DD → DD/MM/YY → MM/DD/YY`nP: HH:mm ↔ HH:mm:ss`nAny symbol for separator(/.-: etc. ex) 12/04/26, 12-04-26)`nEnter: enter the date or time`nEsc: cancel`n`nFrogControl"
	CoordMode, ToolTip
	CoordMode, Caret
	CollectMonitorInfo()
	caret_x := A_CaretX
	caret_y := A_CaretY
	if (caret_x = "" or caret_y = "") { 	; some apps (Electron, elevated windows, terminals) expose no caret: fall back to the mouse position
		CoordMode, Mouse
		MouseGetPos, caret_x, caret_y
	}
	monitor_current := monitor_no_prm 	; fallback: primary monitor, in case the caret is on no monitor
	loop, %monitor_no% {
		if (monitor_%A_Index%_left <= caret_x) and (caret_x <= monitor_%A_Index%_right - 1) and (monitor_%A_Index%_top <= caret_y) and (caret_y <= monitor_%A_Index%_bottom - 1) {		; monitors' lefts and rights are like 0 ~ 2560, -1920 ~ 0.
			monitor_current := A_Index
		}
	}
	
	Loop {
		date_output := date_1 date_separator date_2
		if (date_3 != "") {
			date_output .= date_separator date_3
		}

		if (A_CaretY < 30) {
			date_ttip_Yadjust := 40
		} else {
			date_ttip_Yadjust := -30
		}
		ToolTip, % date_output "     (Press ? for help)", A_CaretX, A_CaretY + date_ttip_Yadjust, 1

		Input, date_input, L1 E, {Enter}{BackSpace}{Escape}
		if (date_input = "o") {
			date_short := 1 - date_short
			if (date_short) {
				date_1 := date_year_2
				date_2 := A_MM
				date_3 := A_DD
				
			} if(!date_short) {
				date_1 := A_YYYY
				date_2 := A_MM
				date_3 := A_DD
			}
		} else if (date_input = "p") {
			date_time_short := 1 - date_time_short
			if (date_time_short) {
				date_1 := A_Hour
				date_2 := A_Min
				date_3 := ""
			} if(!date_time_short) {
				date_1 := A_Hour
				date_2 := A_Min
				date_3 := A_Sec
			}
		} else if (InStr(".,<>/:'``~[]{}\|=+-_!@#$%^&*()""", date_input)) { ; When + is applied, a strange result comes up like 15!2@8 
			date_separator := date_input
		} else if (date_input = ";") {
			date_separator := ":"
		} else if (date_input = "0") {
			if (date_3 = A_DD) {
				date_3 := date_1
				date_1 := A_DD
			} else if (date_1 = A_DD) {
				date_1 := date_2
				date_2 := A_DD
			} else if (date_2 = A_DD) {
				date_1 := date_3
				date_2 := A_MM
				date_3 := A_DD
			}
		} else if (date_input = "?") {
			ToolTip, % date_help, (monitor_%monitor_current%_workarea_right - monitor_%monitor_current%_workarea_left)/2, monitor_%monitor_current%_workarea_bottom - 300, 2
			fct_RemoveToolTip_time(2, true)
			SetTimer, fct_RemoveToolTip_time, % SETTING_CONSTANT_TOOLTIPDUR_L
			
		}

		if (ErrorLevel = "EndKey:BackSpace") {
			date_separator := ""
		} else if ((ErrorLevel = "EndKey:Enter") or (ErrorLevel = "EndKey:Escape")) {
			Break
		}
	}
	ToolTip, , , , 1
	ToolTip, , , , 2
	if (ErrorLevel != "EndKey:Escape") {
		;Send, % date_output 	; When it's 2016#07#16, it works as if an user really pressed Windows key + 0, Windows + 1
		SendRaw, % date_output 	; When it's 2016#07#16, it interpret literally so that it doesn't translate # to Windows key.
	}
	DllCall("SystemParametersInfo", UInt, 0x0002, UInt, beep_dateinput, UInt,0, UInt,0) 	; SPI_SETBEEP : 0x0002
	if (is_capslock_initial) {
		SetCapsLockState, on
	} else {
		SetCapsLockState, off
	}
	Hotkey, % thisHotkey_timeInputMode, , On 	; We a user did input a shift key during the time input mode like to put :, then A_ThisHotkey changed to "~shift". So it won't be re-enabled.
Return


; Click by keyboard
CapsLock & Z::
	Click Down
	KeyWait, Z
	Click Up
	WinGet, mouseControl_activeWin, ID, A 	; In case it's triggered during a thread of the mouse move by keybard mode.
Return

CapsLock & C::
	Click Down Right
	KeyWait, C
	Click Up Right
Return

CapsLock & X::
	Click Down Middle
	KeyWait, X
	Click Up Middle
Return

CapsLock & W::
	Click WheelUp
Return

CapsLock & S::
	Click WheelDown
Return

CapsLock & A::
	Click WheelLeft
Return

CapsLock & D::
	; 아래 내가 뭘 하려고 했던 거지? 2016-06-25
	;Click WheelRight
	MouseClick, WheelRight
	;send, {WheelRight}
	;SendEvent, {WheelRight}
	;SendInput {wheelRight}
	;SendInput {Right}
Return


;CapsLock & 1::
CapsLock & Tab::
	Send, {Enter}
Return



; Move the active window to the mouse cursor
; CapsLock + Win + w
CapsLock & E::
	;GetKeyState, islwin, LWin, P
	;GetKeyState, isrwin, RWin, P
	;if (islwin = "D") or (isrwin = "D") {
		CoordMode, Mouse  ; Switch to screen/absolute coordinates.
		MouseGetPos, x, y
		WinGetPos, , , W, H, A
		WinMove, A,, x - W/2, y - H/2
	;}
return

; Move the mouse cursor to the center of the active window
; CapsLock + Win + x
CapsLock & R::
	;GetKeyState, islwin, LWin, P
	;GetKeyState, isrwin, RWin, P
	;if (islwin = "D") or (isrwin = "D") {
		WinGetPos, , , W, H, A
		MouseMove, W/2, H/2, 3
	;}
Return

; Mouse coordinates and Constrain mouse movement
; If + is pressed twice quickly, Constrain Mouse mode is evoked.
CapsLock & +::
	if (!FLAG_COOR_CONSTRAINED_MOUSE) {
		is_capslock_initial_mouseCoor := getkeystate("capslock", "T") 	; To store the initial toggle state of CapsLock (the old "1 -" inverted it)
		FLAG_COOR_CONSTRAINED_MOUSE := 1
		WinGet, activeWin_ID, ID, A
		WinActivate, ahk_class Shell_TrayWnd 	; By activating the taskbar, it can prevent any keystrokes from pass to Windows.
	}
	CoordMode, Mouse  ; Although it's omitted, it's generally OK. But if somehow the active window moved, then it can be a problem.		
	CoordMode, ToolTip
	if (mouseCoor_process > 0) {
		mouseCoor_process++
		return
	} else {
		mouseCoor_process := 1
		MouseGetPos, mouseCurrent_x, mouseCurrent_y
		ToolTip % "mouse coordinates: (" mouseCurrent_x ", " mouseCurrent_y ")", , , 1
		SetTimer, RemoveToolTip, % SETTING_CONSTANT_TOOLTIPDUR_S
		SetTimer, MouseConstraintMode, -300
		SetTimer, IsCapsLockReleased, 50 	; Although CapsLock & C and MouseConstraintMode's threads finished, a user may still hold CapsLock key. So we check if it's released.
	}
Return

MouseConstraintMode:
	if (mouseCoor_process > 1) {
		Hotkey, CapsLock & LButton, , Off
		;FLAG_CONSTRAINEDMOUSE := 1
		CoordMode, Mouse  ; Although it's omitted, it's generally OK. But if somehow the active window moved, then it can be a problem.		
		CoordMode, ToolTip
		ToolTip, % "Constrained mouse mode`n- Spacebar: moves to the initial position", , mouseCurrent_y - 50, 2
		fct_RemoveToolTip_time(2, true)
		SetTimer, fct_RemoveToolTip_time, % 3000
		
		MouseGetPos, mouseOriginal_x, mouseOriginal_y
		loop {
			mouseCoor_process := 0
			; This is a nerdy part.
			; floor(exp(x - abs(x))) = 1 if x >= 0
			;                          0 if x <  0
			; det = ..., -2, -1, 0, 1,  2, ...
			; floor(exp(det - abs(det))) = ... , 0, 0, 1, 1, 1, ...
			MouseGetPos, mouseCurrent_x, mouseCurrent_y
			det := abs(mouseCurrent_x - mouseOriginal_x) - abs(mouseCurrent_y - mouseOriginal_y)
			step := floor(exp(det - abs(det)))
			MouseMove, mouseOriginal_x + (mouseCurrent_x - mouseOriginal_x)*step, mouseOriginal_y + (mouseCurrent_y - mouseOriginal_y)*(1-step), 0
			if (GetKeyState("Space", "P")) {
				MouseMove, mouseOriginal_x, mouseOriginal_y, 3
				ToolTip % "initial coordinates: (" mouseOriginal_x ", " mouseOriginal_y ")"
				SetTimer, RemoveToolTip, % SETTING_CONSTANT_TOOLTIPDUR_S
			}
			if (!GetKeyState("CapsLock", "P")) {
				Hotkey, CapsLock & LButton, , On
				;FLAG_CONSTRAINEDMOUSE := 0
				BREAK
			}
		}
	}
	mouseCoor_process := 0
Return

IsCapsLockReleased:
	if (!GetKeyState("CapsLock", "P")) {
		SetTimer, IsCapsLockReleased, off
		WinActivate, ahk_id %activeWin_ID% 
		if (FLAG_COOR_CONSTRAINED_MOUSE = 1) {
			if (is_capslock_initial_mouseCoor) {
				SetCapsLockState, on
			} else {
				SetCapsLockState, off
			}
			FLAG_COOR_CONSTRAINED_MOUSE := 0
		}
	}
Return



;; MOUSE MODE
CapsLock & M::
	FLAG_MOUSECONTROL := 1 	; Critical, on  or  thread, priority, 10000 can be used intead. But SetTimer doesn't work in this thread too.
	is_capslock_initial := getkeystate("capslock", "T") 	; (the old "1 -" inverted the state, so every use flipped CapsLock)

	; block some other hotkeys
	; to prevent the 2nd keys of this Mouse Mode from causing problems with other hotkeys
	Hotkey, CapsLock & W, , Off ; Because of if (GetKeyState("W", "P")) statement.
	;Hotkey, CapsLock & C, , Off
	Hotkey, CapsLock & Up, , Off
	Hotkey, CapsLock & Down, , Off
	Hotkey, CapsLock & Left, , Off
	Hotkey, CapsLock & Right, , Off

	CoordMode, Mouse  ; Switch to screen/absolute coordinates.
	CoordMode, ToolTip
	MouseGetPos, mousex, mousey
	;ToolTip, % "Mouse control mode", , mousey - 30, 2
	;fct_RemoveToolTip_time(2, true)
	;SetTimer, fct_RemoveToolTip_time, % 2000

	mouseControl_input := ""
	mouseControl_helpOn := 0
	;mouseControl_terminate := 0
	WinGet, mouseControl_activeWin, ID, A
	WinActivate, ahk_class Shell_TrayWnd
	TrayTip, % "Mouse control mode", % "Press ? for help", , 16
	ToolTip, % "Input any number to move mouse or press arrow keys to move it.`nEsc to quit the mouse control mode.`nPress ? for help."
	loop {
		;if (mouseControl_terminate = 1) {
		;	Break
		;}
		Input, mouseControl_input_L1, L1 E, {Left}{Right}{Down}{Up}{Enter}{BackSpace}{Escape}W?C+=R ; L1 옵션은 키 하나씩 받는 듯. 그래서 숫자 123를 받더라도 1개 받을 때 마다 tooltip을 업데이트해줌
		mouseControl_input .= mouseControl_input_L1
		if (ErrorLevel = "EndKey:Escape") {
			if (mouseControl_helpOn = 1) {
				ToolTip, , , , 3
				mouseControl_helpOn := 0
			} else {
				Break
			}
		}
		; Move the mouse cursor to the center of the active window
		else if (ErrorLevel = "EndKey:W") { ; GetKeyState("W", "P")
			WinGetPos, activeWin_X, activeWin_Y, activeWin_W, activeWin_H, ahk_id %mouseControl_activeWin%
			MouseMove, activeWin_X + activeWin_W/2, activeWin_Y + activeWin_H/2, 3
			ToolTip, % "Input any number to move mouse or press arrow keys to move it.`nEsc to quit the mouse control mode.`nPress ? for help."
		}

		else if (ErrorLevel = "EndKey:?") {
			CoordMode, Mouse  ; Switch to screen/absolute coordinates.
			MouseGetPos, mousex, mousey
			ToolTip, % "Mouse control mode help`n`n- Type any number in pixel followed by an arrow key : Move the mouse to the direction`n- While holding CapsLock, hold any Arrow key : Move the mouse pointer by the keyboard (holding with Alt, Shift or Ctrl will change the speed)`n- + (or =) : Enter the mouse constrained mode. (Press SpaceBar to move the mouse pointer back to the original position.)`n- R : Enter the mouse ruler mode. (Then press SpaceBar to set the reference point.)`n- W : move the mouse pointer to the center of a current window`n- C : Show the current coordinates`n- ? : Open the help`n- Esc : close the help and finish the Mouse control mode", , mousey + 60, 3
			mouseControl_helpOn := 1
			;ToolTip, % "Input any number to move mouse or press arrow keys to move it.`nEsc to quit the mouse control mode."
		} 
		else if (ErrorLevel = "EndKey:C") {
			MouseGetPos, mousex, mousey
			ToolTip % "mouse coordinates: (" mousex ", " mousey ")", , mousey - 30, 2
			fct_RemoveToolTip_time(2, true)
			SetTimer, fct_RemoveToolTip_time, % SETTING_CONSTANT_TOOLTIPDUR_S
		}
		else if ((ErrorLevel = "EndKey:=") or (ErrorLevel = "EndKey:+")) {
			ToolTip, % "Constrained mouse mode`n- Space bar: moves to the initial position`n- Esc: finishes the constrained mouse mode"
			fct_RemoveToolTip_time(1, true)
			SetTimer, fct_RemoveToolTip_time, % SETTING_CONSTANT_TOOLTIPDUR_S
			MouseGetPos, mouseOriginal_x, mouseOriginal_y
			loop {
				MouseGetPos, mouseCurrent_x, mouseCurrent_y
				; This is a nerdy part.
				; floor(exp(x - abs(x))) = 1 if x >= 0
				;                          0 if x <  0
				; det = ..., -2, -1, 0, 1,  2, ...
				; floor(exp(det - abs(det))) = ... , 0, 0, 1, 1, 1, ...
				det := abs(mouseCurrent_x - mouseOriginal_x) - abs(mouseCurrent_y - mouseOriginal_y)
				step := floor(exp(det - abs(det)))
				MouseMove, mouseOriginal_x + (mouseCurrent_x - mouseOriginal_x)*step, mouseOriginal_y + (mouseCurrent_y - mouseOriginal_y)*(1-step), 0
				if (GetKeyState("Space", "P")) {
					MouseMove, mouseOriginal_x, mouseOriginal_y, 3
					ToolTip % "initial coordinates: (" mouseOriginal_x ", " mouseOriginal_y ")"
					SetTimer, RemoveToolTip, % SETTING_CONSTANT_TOOLTIPDUR_S
				}
				if (GetKeyState("Esc", "P")) {
					; ToolTip, % "Input any number to move mouse or press arrow keys to move it.`nEsc to quit the mouse control mode."
					Break
				}
			}
			break
		}
		else if (ErrorLevel = "EndKey:R") {  ; ruler mode
			ToolTip, % "Press SpaceBar to set the first point"
			BlockInput, on
			;KeyWait, LButton, D 	; if it's possible to block a click to pass, this is better than SpaceBar.
			KeyWait, Space, D T10 	; timeout so a missed keypress can't leave input blocked forever
			BlockInput, Off 	; always release input FIRST - a stuck BlockInput locks the whole session
			MouseGetPos, mouseInit_x, mouseInit_y
			if (!ErrorLevel) 	; Space actually pressed -> enter ruler mode (ErrorLevel is from KeyWait)
			{
	
			; To show t he reference point
			Gui, mouseRulerRefPoint: New
			Gui, mouseRulerRefPoint: +Owner +Disabled -SysMenu -Caption +AlwaysOnTop
			Gui, mouseRulerRefPoint: Color, EEAA99
			Gui, mouseRulerRefPoint: Show, % "x" mouseInit_x - 5 " y" mouseInit_y - 5 " h11 w11 NoActivate"
	
			vtext := {}
			Loop, {
				Sleep, 10 	; poll ~100x/s instead of busy-waiting (CPU)
				index := Mod(A_Index, 2)
				vtext[index] := ""
				MouseGetPos, mousex, mousey
				vtext[index] .= "Initial mouse coordinates: (" mouseInit_x ", " mouseInit_y ")`n"
				vtext[index] .= "Current mouse coordinates: (" mousex ", " mousey ")`n"
				vtext[index] .= "horizontal distance (x): " mousex - mouseInit_x "`n"
				vtext[index] .= "veritical distance (y): " - (mousey - mouseInit_y) "`n"
				vdistance := sqrt( (mousex - mouseInit_x) ** 2 + (mousey - mouseInit_y) ** 2 )
				vtext[index] .= "distance : " vdistance "`n"
				vangle := ASin( - (mousey - mouseInit_y) / vdistance)
				if (MouseX - mouseInit_x < 0) 
					vangle := 3.141592653589793 - vangle
				vtext[index] .= "angle : " vangle * 57.29578 "`n"
				vtext[index] .= "Esc to quit the ruler mode."

				if (vtext[index] != vtext[1 - index]) 
					ToolTip, % vtext[index]
				if (GetKeyState("Esc", "P")) {
					Gui, mouseRulerRefPoint: Destroy
					Break
				}
			}
			} 	; end if (!ErrorLevel) - ruler mode ran only if Space was pressed
			SetTimer, RemoveToolTip, % 1000
			ToolTip, % "Input any number to move mouse or press arrow keys to move it.`nEsc to quit the mouse control mode.`nPress ? for help."
		}

		else if (mouseControl_input_L1 = "") {
			if (mouseControl_input = "") {
				tooltip, % "Mouse move by keyboard mode. Hold Ctrl or Alt to change speed."
				SetTimer, RemoveToolTip, % 3000
				loop {
					;Tooltip % A_Index "-" mouseControl_input "-Iuppidu! " ErrorLevel
					if (GetKeyState("Control", "P")) {
						if (GetKeyState("Right", "P")) {
							MouseGetPos, mousex, mousey
							DllCall("SetCursorPos", int, mousex + 10, int, mousey) 
							KeyWait, Right, T0.006
						} 
						if (GetKeyState("Left", "P")) {
							MouseGetPos, mousex, mousey
							DllCall("SetCursorPos", int, mousex - 10, int, mousey) 
							KeyWait, Left, T0.006
						} 
						if (GetKeyState("Down", "P")) {
							MouseGetPos, mousex, mousey
							DllCall("SetCursorPos", int, mousex, int, mousey + 10) 
							KeyWait, Down, T0.006
						} 
						if (GetKeyState("Up", "P")) {
							MouseGetPos, mousex, mousey
							DllCall("SetCursorPos", int, mousex, int, mousey - 10) 
							KeyWait, Up, T0.006
						}
					} else if (GetKeyState("Alt", "P")) {
						if (GetKeyState("Right", "P")) {
							MouseGetPos, mousex, mousey
							DllCall("SetCursorPos", int, mousex + 1, int, mousey)
							KeyWait, Right, T0.01 		; The speed of MouseMove, mousex + 1, mousey,  0 is similar to that of DllCall"SetCursorPos" with KeyWait T0.005
						} 
						if (GetKeyState("Left", "P")) {
							MouseGetPos, mousex, mousey
							DllCall("SetCursorPos", int, mousex - 1, int, mousey)
							KeyWait, Left, T0.01
						} 
						if (GetKeyState("Down", "P")) {
							MouseGetPos, mousex, mousey
							DllCall("SetCursorPos", int, mousex, int, mousey+ 1)
							KeyWait, Down, T0.01
						} 
						if (GetKeyState("Up", "P")) {
							MouseGetPos, mousex, mousey
							DllCall("SetCursorPos", int, mousex, int, mousey- 1)
							KeyWait, Up, T0.01
						}
					} else if (GetKeyState("Shift", "P")) {
						if (GetKeyState("Right", "P")) {
							MouseGetPos, mousex, mousey
							DllCall("SetCursorPos", int, mousex + 1, int, mousey) 	; most fast
							KeyWait, Right, T0.005
						} 
						if (GetKeyState("Left", "P")) {
							MouseGetPos, mousex, mousey
							DllCall("SetCursorPos", int, mousex - 1, int, mousey) 	; most fast
							KeyWait, Left, T0.005
						} 
						if (GetKeyState("Down", "P")) {
							MouseGetPos, mousex, mousey
							DllCall("SetCursorPos", int, mousex, int, mousey+ 1) 	; most fast
							KeyWait, Down, T0.005
						} 
						if (GetKeyState("Up", "P")) {
							MouseGetPos, mousex, mousey
							DllCall("SetCursorPos", int, mousex, int, mousey- 1) 	; most fast
							KeyWait, Up, T0.005
						}
					} else {
						if (GetKeyState("Right", "P")) {
							MouseGetPos, mousex, mousey
							;DllCall("SetCursorPos", int, mousex + 1, int, mousey) 	; most fast
							;KeyWait, Right, T0.001
							MouseMove, mousex + 20, mousey,  0 					; middle speed (0 means fastest speed of MouseMove)
							;mousex := mousex + 1
							;Click %mousex%, %mousey% , 0 							; most slow (0 means 0 click)
						} 
						if (GetKeyState("Left", "P")) {
							MouseGetPos, mousex, mousey
							;DllCall("SetCursorPos", int, mousex - 1, int, mousey) 	; most fast
							;KeyWait, Left, T0.001
							MouseMove, mousex - 20, mousey,  0 					; middle speed (0 means fastest speed of MouseMove)
							;mousex := mousex - 1
							;Click %mousex%, %mousey% , 0 							; most slow (0 means 0 click)
						} 
						if (GetKeyState("Down", "P")) {
							MouseGetPos, mousex, mousey
							;DllCall("SetCursorPos", int, mousex, int, mousey+ 1) 	; most fast
							;KeyWait, Down, T0.001
							MouseMove, mousex, mousey + 20,  0 					; middle speed (0 means fastest speed of MouseMove)
							;mousey := mousey + 1
							;Click %mousex%, %mousey% , 0 							; most slow (0 means 0 click)
						} 
						if (GetKeyState("Up", "P")) {
							MouseGetPos, mousex, mousey
							;DllCall("SetCursorPos", int, mousex, int, mousey- 1) 	; most fast
							;KeyWait, Up, T0.001
							MouseMove, mousex, mousey - 20,  0 					; middle speed (0 means fastest speed of MouseMove)
							;mousey := mousey - 1
							;Click %mousex%, %mousey% , 0 							; most slow (0 means 0 click)
						}
						; Move the mouse cursor to the center of the active window
						if (GetKeyState("W", "P")) {
							WinGetPos, activeWin_X, activeWin_Y, activeWin_W, activeWin_H, ahk_id %mouseControl_activeWin%
							MouseMove, activeWin_X + activeWin_W/2, activeWin_Y + activeWin_H/2, 3
						} 
						; Constrain mouse movement
						;if (GetKeyState("=", "P") or GetKeyState("+", "P")) {
						;	KeyWait, =
						;	KeyWait, +
						;	ToolTip, % "Constrained mouse mode`n- Esc: moves to the initial position", , mouseCurrent_y - 50, 2
						;	fct_RemoveToolTip_time(2, true)
						;	SetTimer, fct_RemoveToolTip_time, % SETTING_CONSTANT_TOOLTIPDUR_S
						;	MouseGetPos, mouseOriginal_x, mouseOriginal_y
						;	loop {
						;		MouseGetPos, mouseCurrent_x, mouseCurrent_y
						;		; This is a nerdy part.
						;		; floor(exp(x - abs(x))) = 1 if x >= 0
						;		;                          0 if x <  0
						;		; det = ..., -2, -1, 0, 1,  2, ...
						;		; floor(exp(det - abs(det))) = ... , 0, 0, 1, 1, 1, ...
						;		det := abs(mouseCurrent_x - mouseOriginal_x) - abs(mouseCurrent_y - mouseOriginal_y)
						;		step := floor(exp(det - abs(det)))
						;		MouseMove, mouseOriginal_x + (mouseCurrent_x - mouseOriginal_x)*step, mouseOriginal_y + (mouseCurrent_y - mouseOriginal_y)*(1-step), 0
						;		if (GetKeyState("Esc", "P")) {
						;			MouseMove, mouseOriginal_x, mouseOriginal_y, 3
						;			ToolTip % "initial coordinates: (" mouseOriginal_x ", " mouseOriginal_y ")"
						;			SetTimer, RemoveToolTip, % SETTING_CONSTANT_TOOLTIPDUR_S
						;		}
						;		if (GetKeyState("=", "P") or GetKeyState("+", "P")) {
						;			KeyWait, =
						;			KeyWait, +
						;			;FLAG_CONSTRAINEDMOUSE := 0
						;			Break
						;		}
						;	}
						;}
					}

					if (!GetKeyState("CapsLock", "P")) {
						;mouseControl_terminate := 1
						Break
					}
				}
				break	
							
			} else { 	; Endkey was input after something had been input.
				if (ErrorLevel = "EndKey:Right") {
					MouseGetPos, mousex, mousey
					MouseMove, mousex + mouseControl_input, mousey, 2
					mouseControl_input := ""
					ToolTip, % "Input any number to move mouse or press arrow keys to move it.`nEsc to quit the mouse control mode.`nPress ? for help."
				} else if (ErrorLevel = "EndKey:Left") {
					MouseGetPos, mousex, mousey
					MouseMove, mousex - mouseControl_input, mousey, 2
					mouseControl_input := ""
					ToolTip, % "Input any number to move mouse or press arrow keys to move it.`nEsc to quit the mouse control mode.`nPress ? for help."
				} else if (ErrorLevel = "EndKey:Down") {
					MouseGetPos, mousex, mousey
					MouseMove, mousex, mousey + mouseControl_input, 2
					mouseControl_input := ""
					ToolTip, % "Input any number to move mouse or press arrow keys to move it.`nEsc to quit the mouse control mode.`nPress ? for help."
				} else if (ErrorLevel = "EndKey:Up") {
					MouseGetPos, mousex, mousey
					MouseMove, mousex, mousey - mouseControl_input, 2
					mouseControl_input := ""
					ToolTip, % "Input any number to move mouse or press arrow keys to move it.`nEsc to quit the mouse control mode.`nPress ? for help."
				} else if (ErrorLevel = "EndKey:BackSpace") {
					mouseControl_input := SubStr(mouseControl_input, 1, StrLen(mouseControl_input) - 1)
					ToolTip, % "Move mouse " mouseControl_input " px.  Press an arrow key to move the mouse to the direction.`nEsc to quit the mouse control mode.`nPress ? for help."
				}
				else {
					mouseControl_input := ""
					ToolTip, % "Input any number to move mouse or press arrow keys to move it.`nEsc to quit the mouse control mode.`nPress ? for help."
				}
			}
		} else {
			ToolTip, % "Move mouse " mouseControl_input " px.  Press an arrow key to move the mouse to the direction.`nEsc to quit the mouse control mode.`nPress ? for help."
		} 
		
	}
	WinActivate, ahk_id %mouseControl_activeWin%
	ToolTip, , , , 2
	ToolTip, , , , 3
	MouseGetPos, mousex, mousey
	ToolTip, % "Mouse control mode finished"
	fct_RemoveToolTip_time(1, true)
	SetTimer, fct_RemoveToolTip_time, % 2000
	
	; block some other hotkeys
	Hotkey, CapsLock & W, , On
	;Hotkey, CapsLock & C, , On
	Hotkey, CapsLock & Up, , On
	Hotkey, CapsLock & Down, , On
	Hotkey, CapsLock & Left, , On
	Hotkey, CapsLock & Right, , On
	if (is_capslock_initial) {
		SetCapsLockState, on
	} else {
		SetCapsLockState, off
	}
	FLAG_MOUSECONTROL := 0
Return

;==================== Mouse Bookmark ============== starts =============================

CapsLock & 1::
CapsLock & 2::
CapsLock & 3::
CapsLock & 4::
CapsLock & 5::
CapsLock & 6::
CapsLock & 7::
CapsLock & 8::
CapsLock & 9::
CapsLock & 0::

	; This is added on 2022/10/18
	; When using a different scale other than 100% on a display, GetMousePose will handle positions as sacled. 즉 4k UHD 모니터에서 150% 스케일 설정해 놓으면 마치 QHD 모니터인것처럼 GetMousePose로 좌표를 받아온다. 즉 세로가 2160이 아니라 1440인것 마냥. 하지만 mouse move는 scale에 상관없이 실제 물리적 픽셀로 이동해서 매치가 안된다.
	; 아래가 해결책. 출처: https://www.reddit.com/r/AutoHotkey/comments/lrkjuq/mousegetpos_and_mousemove_coordinates_not/
	DllCall("SetThreadDpiAwarenessContext", "ptr", -4, "ptr")

	; variables:
	; 	mousePosBookmark_0
	; 	mbIndex
	if (A_ThisHotkey != A_PriorHotkey) {
		mbIndex := 0
	}
	hotkeypart := HotkyeAnalysis()
	modifier1 := hotkeypart[2][1]
	mouseBookmark_no := hotkeyPart[1][2]

	if (!mousePosBookmark[mouseBookmark_no]) { 	; if it hasn't created, then create it as an object.
		mousePosBookmark[mouseBookmark_no] := {}
	}

	CoordMode, Mouse  ; Switch to screen/absolute coordinates.
	CoordMode, ToolTip  
	MouseGetPos, mousex, mousey
	if (GetKeyState("Control", "P") and !GetKeyState("Shift", "P")) { 	; to save
			
		mousePosBookmark[mouseBookmark_no].Push({x: mousex, y: mousey}) 	; mousePosBookmark[mouseBookmark_no].length(), mousePosBookmark[mouseBookmark_no][2].y, ...
		ToolTip, % "Mouse bookmark at " mouseBookmark_no " (" mousePosBookmark[mouseBookmark_no].length() ") has been stored."
		
		; Showing current mouse bookmarks are lagging
		;Loop, %mousePosBookmark[mouseBookmark_no].length()% {
		;	Gui, mousePosBookmark%A_Index%: New
		;	Gui, mousePosBookmark%A_Index%: +Owner +Disabled -SysMenu -Caption +AlwaysOnTop
		;	Gui, mousePosBookmark%A_Index%: Color, EEAA99
		;	Gui, mousePosBookmark%A_Index%: Show, % "x" mousePosBookmark%A_Index%_x - 5 " y" mousePosBookmark%A_Index%_y - 5 " h11 w11 NoActivate"
		;	;Gui, mousePosBookmark%A_Index%: +LastFound
		;	;WinSet, Region,0-0 W11 H11 E
		;}
		;SetTimer, RemoveMousePosBookmarkGui, % SETTING_CONSTANT_TOOLTIPDUR_S
		;



	} else if (GetKeyState("Alt", "P")) {
		if (mousePosBookmark[mouseBookmark_no].length() >= 1) {
			;mousePosBookmark_0 := mousePosBookmark_0 > 0 ? mousePosBookmark_0 - 1 : 0
			ToolTip, % "Mouse bookmark at " mouseBookmark_no " (" mousePosBookmark[mouseBookmark_no].length() ") has been deleted."
			mousePosBookmark[mouseBookmark_no].Pop() 
		} else {
			ToolTip, % "There is no mouse bookmark to delete at " mouseBookmark_no ".`nYou can boomark mouse position by pressing CapsLock + Ctrl + " mouseBookmark_no "."
			}
		; Showing current mouse bookmarks are lagging
		;temp := mousePosBookmark[mouseBookmark_no].length() + 1
		;Gui, mousePosBookmark%temp%: Destroy
		;Loop, %mousePosBookmark[mouseBookmark_no].length()% {
		;	Gui, mousePosBookmark%A_Index%: New
		;	Gui, mousePosBookmark%A_Index%: +Owner +Disabled -SysMenu -Caption +AlwaysOnTop
		;	Gui, mousePosBookmark%A_Index%: Color, EEAA99
		;	Gui, mousePosBookmark%A_Index%: Show, % "x" mousePosBookmark%A_Index%_x - 5 " y" mousePosBookmark%A_Index%_y - 5 " h11 w11 NoActivate"
		;	;Gui, mousePosBookmark%A_Index%: +LastFound
		;	;WinSet, Region,0-0 W11 H11 E
		;}
		;SetTimer, RemoveMousePosBookmarkGui, % SETTING_CONSTANT_TOOLTIPDUR_S

	} else if (!GetKeyState("Control", "P") and GetKeyState("Shift", "P")) {
		if (mousePosBookmark[mouseBookmark_no].length() >= 1) {
			mbIndex := mbIndex <= 1 ? mousePosBookmark[mouseBookmark_no].length() : mbIndex - 1
			MouseMove, mousePosBookmark[mouseBookmark_no][mbIndex].x, mousePosBookmark[mouseBookmark_no][mbIndex].y, 2
			ToolTip, % "Mouse bookmark at " mouseBookmark_no " (" mbIndex ")", mousePosBookmark[mouseBookmark_no][mbIndex].x + 16, mousePosBookmark[mouseBookmark_no][mbIndex].y + 16
		} else {
			ToolTip, % "There is no mouse bookmark at " mouseBookmark_no ".`nYou can boomark mouse position by pressing CapsLock + Ctrl + " mouseBookmark_no "."
		}
	} else if (GetKeyState("Control", "P") and GetKeyState("Shift", "P")) { 	; To show all mouse bookmark positions
		if (mousePosBookmark[mouseBookmark_no].length() >= 1) {
			Loop, % mousePosBookmark[mouseBookmark_no].length() {
				Gui, mousePosBookmark%A_Index%: Destroy 	; a quick re-show would otherwise orphan the previous square permanently
				Gui, mousePosBookmark%A_Index%: New
				Gui, mousePosBookmark%A_Index%: +Owner +Disabled -SysMenu -Caption +AlwaysOnTop
				Gui, mousePosBookmark%A_Index%: Color, EEAA99
				Gui, mousePosBookmark%A_Index%: Show, % "x" mousePosBookmark[mouseBookmark_no][A_Index].x - 5 " y" mousePosBookmark[mouseBookmark_no][A_Index].y - 5 " h11 w11 NoActivate"
				;Gui, mousePosBookmark%A_Index%: +LastFound
				;WinSet, Region,0-0 W11 H11 E
			}
			SetTimer, RemoveMousePosBookmarkGui, % 2000
		} else {
		ToolTip, % "There is no mouse bookmark to show at " mouseBookmark_no ".`nYou can boomark mouse position by pressing CapsLock + Ctrl + " mouseBookmark_no "."
		}
	} else if (GetKeyState(mouseBookmark_no, "P")) {
		if (mousePosBookmark[mouseBookmark_no].length() >= 1) {
			
			mbIndex := mousePosBookmark[mouseBookmark_no].length()
			; if more than one mouse bookmark position are allowed.
			;mbIndex := mbIndex >= mousePosBookmark[mouseBookmark_no].length() ? 1 : mbIndex + 1
			
			MouseGetPos, mousex, mousey
			MouseMove, mousePosBookmark[mouseBookmark_no][mbIndex].x, mousePosBookmark[mouseBookmark_no][mbIndex].y, 2
			Click
			MouseMove, mousex, mousey
			ToolTip, % "Mouse bookmark at " mouseBookmark_no " (" mbIndex ")", mousePosBookmark[mouseBookmark_no][mbIndex].x + 16, mousePosBookmark[mouseBookmark_no][mbIndex].y + 16
		} else {
			ToolTip, % "There is no mouse bookmark at " mouseBookmark_no ".`nYou can boomark mouse position by pressing CapsLock + Ctrl + " mouseBookmark_no "."
		}
	}
	SetTimer, RemoveToolTip, % SETTING_CONSTANT_TOOLTIPDUR_S
Return
;==================== Mouse Bookmark ============== ends =============================


;;==================== Window Bookmark with Alt ============== starts =============================
; Decided to remove this shortcut Alt+1 and so on because Alt+1 and so on are used in other applications
; such as Android Studio (Alt+4 for the Run window, Alt+1 for the Project window).
;!1::
;!2::
;!3::
;!4::
;!5::
;!6::
;!7::
;!8::
;!9::
;	; ; SETTING
;	modifier2 := "Control"
;	; ; SETTING ENDS
;
;	hotkeypart := HotkyeAnalysis()
;	modifier1 := hotkeypart[2][1]
;	windowBookmark_no := hotkeyPart[1][2]
;	windowBookmark[windowBookmark_no] := WindowBookmark_operation(modifier1, modifier2, windowBookmark_no, windowBookmark[windowBookmark_no])
;
;Return
;
;;; To display a list of the window bookmarks
;!0::
;	; ; SETTING
;	; modifier2 := "Control"
;	; ; SETTING ENDS	
;	
;	; hotkeypart := HotkyeAnalysis()
;	; modifier1 := hotkeypart[2][1]
;	; windowBookmark_no := hotkeyPart[1][2]
;
;	windowBookmark_list := ""
;	Loop, 9 {
;		windowBookmark_list .= "Alt + " A_Index " = " windowBookmark[A_Index].ID "-" windowBookmark[A_Index].title "`n"
;	}
;	MsgBox, , % "Alt + 1 ~ 9", % windowBookmark_list
;Return
;
;;
;; To save bookmarks
;
;!+1::
;!+2::
;!+3::
;!+4::
;!+5::
;!+6::
;!+7::
;!+8::
;!+9::
;
;	;; SETTING
;	;modifier2 := "Control"
;	;; SETTING ENDS
;
;	hotkeypart := HotkyeAnalysis()
;	;modifier1 := hotkeypart[2][1] ; Alt if !+2
;	windowBookmark_no := hotkeyPart[1][2] ; 2 if !+2
;	; MsgBox, , , % "modifier1 = " modifier1	", windowBookmark_no = " windowBookmark_no
;	windowBookmark[windowBookmark_no] := WindowBookmark_setup(windowBookmark_no)
;Return

CapsLock & F1::
CapsLock & F2::
CapsLock & F3::
CapsLock & F4::
CapsLock & F5::
CapsLock & F6::
CapsLock & F7::
CapsLock & F8::
CapsLock & F9::
	; SETTING
	modifier2 := "Control"
	; SETTING ENDS

	hotkeyPart := HotkyeAnalysis()
	modifier1 := hotkeyPart[2][1] ; CapsLock if CapsLock & F2
	windowBookmark_no := hotkeyPart[1][2] ; F2 if CapsLock & F2
	; MsgBox, , , % "modifier1 = " modifier1	", windowBookmark_no = " windowBookmark_no
	if (GetKeyState(modifier2, "P")) {
		windowBookmark[windowBookmark_no] := WindowBookmark_setup(windowBookmark_no)
	} else {
		windowBookmark[windowBookmark_no] := WindowBookmark_operation(modifier1, modifier2, windowBookmark_no, windowBookmark[windowBookmark_no])
	}
Return

;; To display a list of the window bookmarks
CapsLock & F10::
	hotkeypart := HotkyeAnalysis()
	modifier1 := hotkeypart[2][1]
	windowBookmark_no := hotkeyPart[1][2]

	windowBookmark_list := ""
	Loop, 9 {
		Fnumber := "F" . A_Index
		windowBookmark_list .= "CapsLock + " Fnumber " = " windowBookmark[Fnumber].ID "-" windowBookmark[Fnumber].title "`n"
	}
	MsgBox, , % "CapsLock + F1 ~ F9", % windowBookmark_list
Return

; (HotkyeAnalysis, WindowBookmark_* and WindowInfo moved to libFC_Bookmarks.ahk)

;==================== Window Bookmark ============== ends =============================


;; WheelScroll slow mode 

;CapsLock & F1::
CapsLock & `::
;CapsLock & Tab::
;F10::
	Hotkey, % "CapsLock & WheelDown", , Off
	Hotkey, % "CapsLock & WheelUp", , Off
	TrayTip, % "Mouse curosr, wheel slow mode", % "Hold the hotkey and press for different mouse cursor speed", , 16
	DllCall("SystemParametersInfo", UInt, 0x68, UInt, 0, UIntP, initScrollLines, UInt, 0)  ; SPI_GETWHEELSCROLLLINES 0x0068
	DllCall("SystemParametersInfo", UInt, 0x69, UInt, 1, UInt, 0, UInt, 0)
	;KeyWait, F10
	KeyWait, CapsLock
	DllCall("SystemParametersInfo", UInt, 0x69, UInt, initScrollLines, UInt, 0, UInt, 0)
	Hotkey, % "CapsLock & WheelDown", , On
	Hotkey, % "CapsLock & WheelUp", , On
Return



; ====================== WheelScroll fast's 1st method for showing tooltip only once =============================
CapsLock & WheelDown::
	Thread, NoTimers 	; keep the WheelScroll_fast_first timer from interleaving with this body
	WheelScroll_CapsFast(true)
Return

CapsLock & WheelUp::
	Thread, NoTimers 	; keep the WheelScroll_fast_first timer from interleaving with this body
	WheelScroll_CapsFast(false)
Return




;SetTitleMatchMode, RegEx
;#IfWinActive ahk_class XLMAIN
;#IfWinActive ahk_class OpusApp
#if WinActive("ahk_class XLMAIN") or WinActive("ahk_class OpusApp")
	+WheelUp::
		Thread, NoTimers 	; keep the WheelScroll_fast_first timer from interleaving with this body
		WheelScroll_OfficeFast(false)
	Return

	+WheelDown::
		Thread, NoTimers 	; keep the WheelScroll_fast_first timer from interleaving with this body
		WheelScroll_OfficeFast(true)
	Return
;#IfWinActive
#if


/*
#IfWinActive, ahk_class ahk_class XLMAIN
!WheelUp::ComObjActive("Excel.Application").ActiveWindow.SmallScroll(0,0,0,4)  ; Scroll left. 
!WheelDown::ComObjActive("Excel.Application").ActiveWindow.SmallScroll(0,0,4)  ; Scroll right. 
#IfWinActive
*/

/*
#IfWinActive, ahk_class XLMAIN 
~LControl & WheelUp:: 
~LControl & WheelDown:: 
	ControlGet, hwnd, hwnd, , Excel71, ahk_class XLMAIN
	Acc_ObjectFromWindow(hwnd, -16).SmallScroll(0,0,InStr(A_ThisHotkey,"Up")? -4:4)
	return
#IfWinActive

*/


WheelScroll_fast_first:
	WheelScroll_fast_lv1_started := 2
	text_tooltip := ""
	if (wheelScroll_speedUp/wheelScroll_speedUp_default = 11) {
		text_tooltip := "       Do you really want more?"
	} else if (wheelScroll_speedUp/wheelScroll_speedUp_default = 10) {
		text_tooltip := "       Oh my gosh!"
	} else if (wheelScroll_speedUp/wheelScroll_speedUp_default = 9) {
		text_tooltip := "       Speed camera there!"
	} else if (wheelScroll_speedUp/wheelScroll_speedUp_default = 8) {
		text_tooltip := "       Yay!"
	} else if (wheelScroll_speedUp/wheelScroll_speedUp_default = 7) {
		text_tooltip := "       Daebak.."
	} else if (wheelScroll_speedUp/wheelScroll_speedUp_default = 6) {
		text_tooltip := "       So Cool!"
	} else if (wheelScroll_speedUp/wheelScroll_speedUp_default = 5) {
		text_tooltip := "       Cool!"
	} else if (wheelScroll_speedUp/wheelScroll_speedUp_default = 4) {
		text_tooltip := "       Iuppidu!"
	}
	else if (wheelScroll_speedUp/wheelScroll_speedUp_default = 12)
		text_tooltip := "       I hereby confirm you are a nerd."
	else if (wheelScroll_speedUp/wheelScroll_speedUp_default = 13) 
		text_tooltip := "       Basta!"
	else if (wheelScroll_speedUp/wheelScroll_speedUp_default = 14) 
		text_tooltip := "       E = mc^2 ..."
	else if (wheelScroll_speedUp/wheelScroll_speedUp_default = 15) 
		text_tooltip := "       Yes I know I'm a nerd"
	else if (wheelScroll_speedUp/wheelScroll_speedUp_default = 16) 
		text_tooltip := "       Che vuoi?"
	else if (wheelScroll_speedUp/wheelScroll_speedUp_default = 17) 
		text_tooltip := "       Really? Isn't it too much?"
	else if (wheelScroll_speedUp/wheelScroll_speedUp_default = 18) 
		text_tooltip := "       Your keyboard will die ..."
	else if (wheelScroll_speedUp/wheelScroll_speedUp_default = 19) 
		text_tooltip := "       It's not a game.."
	else if (wheelScroll_speedUp/wheelScroll_speedUp_default = 20) 
		text_tooltip := "       Well done!"

	ToolTip, % "Wheel speed up: level " round(wheelScroll_speedUp/wheelScroll_speedUp_default) text_tooltip
	SetTimer, RemoveToolTip, % SETTING_CONSTANT_TOOLTIPDUR_S
	if (InStr(A_ThisHotkey, "CapsLock") or GetKeyState("CapsLock", "P")) { 	; CapsLock & Wheel family
		KeyWait, CapsLock
		KeyWait, Shift
		SetCapsLockState, Off 	; This is the only way for user to anticipate the result of the value of CapsLock. Or we need to use Alt or Ctrl. Or we need to use Ctrl to speed up while holding CapsLock.
	} else { 	; Shift-only +Wheel family (Excel/Word): CapsLock was never touched, so leave its toggle state alone
		KeyWait, Shift
	}
	;Gosub, ResetTimeStampModifiers
	WheelScroll_fast_lv1_started := 0
Return
; ====================== WheelScroll fast's 1st method for showing tooltip only once =============== Ends ==============

#^!+1::
	Sendinput, {RWin down}^{RIGHT}{RWin up}
Return

^!+2::
	Sendinput, {RWin down}^{RIGHT}{RWin up}
Return

~Alt::
~Control::
~Shift:: 	; ~ added: without it the hook swallowed the physical Shift and re-sent a synthetic tap
~LWin::
~RWin::
CapsLock::
	; Ignore keyboard auto-repeat (typematic) re-fires while a key is held.
	; A hook hotkey fires again for every auto-repeated key-down (~33 ms apart), which floods the
	; timeStamp_* ring (20 slots in ~1.2 s of holding Ctrl) and inflates every
	; "press N times to speed up" feature to maximum. 80 ms rejects typematic repeats
	; but passes deliberate double-taps.
	if (A_ThisHotkey = A_PriorHotkey && A_TimeSincePriorHotkey < 80)
		Return
	hotkeyPart := HotkyeAnalysis()
	vHotkey := hotkeyPart[1][2]
	if ((hotkeyPart[1][2] = "LWin") or (hotkeyPart[1][2] = "RWin"))
		vHotkey := "Win"
	timeStamp_%vHotkey%_index++
	if (timeStamp_%vHotkey%_index > timeStamp_modfr_max) {
		timeStamp_%vHotkey%_index := 1
	}
	index := timeStamp_%vHotkey%_index
	timeStamp_%vHotkey%_%index% := A_TickCount
	;; == stamping times == 
	;;	timeStamp_CapsLock_%A_Index%
	;;	timeStamp_Control_%A_Index%
	;;	timeStamp_Alt_%A_Index%
	;;	timeStamp_Shift_%A_Index%
	;;	timeStamp_Win_%A_Index%

	if (hotkeyPart[1][2] = "CapsLock") {
		if (GetKeyState("CapsLock", "T")) {
			SetCapsLockState, off
		} else {
			SetCapsLockState, on
		}
	}
	; (the old `Send, {Shift}` compensation is gone: with ~Shift:: the physical Shift passes through natively)
return



^!+#C::
^!+#A::
^!+#L::
^!+#S::
^!+#W::
	hotkeyPart := HotkyeAnalysis()
	if (hotkeyPart[1][2] = "C")
		vHotkey := "Control"
	if (hotkeyPart[1][2] = "A")
		vHotkey := "Alt"
	if (hotkeyPart[1][2] = "L")
		vHotkey := "CapsLock"
	if (hotkeyPart[1][2] = "S")
		vHotkey := "Shift"
	if (hotkeyPart[1][2] = "W")
		vHotkey := "Win"
	timeStampList := ""
	loop, % timeStamp_modfr_max {
		timeStampList .= A_Index " " A_TickCount " - " timeStamp_%vHotkey%_%A_Index% " = " A_TickCount - timeStamp_%vHotkey%_%A_Index% "`n"
	}
	MsgBox, , % "Time Stamp of " vHotkey , % timeStampList

Return

ResetTimeStampModifiers:
	loop, % timeStamp_modfr_max {
		timeStamp_CapsLock_%A_Index% := 0
		timeStamp_Control_%A_Index% := 0
		timeStamp_Alt_%A_Index% := 0
		timeStamp_Shift_%A_Index% := 0
		timeStamp_Win_%A_Index% := 0
	}
Return


CapsLock & F12::
;CapsLock & F1::
	Suspend, Permit
	Gosub, SuspendKeys
Return


Capslock & ?:: 	; there was a problem when using ? key. But now I don't remember.
	if (FLAG_HELP_LANG = 1) {
		Gosub MenuHandlerEn
	} else if (FLAG_HELP_LANG  = 2) {
		Gosub MenuHandlerKo
	}
Return

; ===================== To show list of programs which you can see with Alt Tab =========================
#^L::
	altTab_List := AltTab_window_list()
	Print_Windows_ListView(altTab_List, , "List of programs on the Alt Tab list")
return
; ===================== To show list of programs which you can see with Alt Tab ================== ends ====





;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------

; (+F5/+F6 removed 2026-07-05: they were test aliases that became identical to +F1/+F2
;  after the layout-engine unification; the documented hotkeys are +F1..+F4)

+F3::
	Show_Windows("", WinExist("A"), 0)
Return

+F4::
	Show_Windows("", WinExist("A"), 1)
Return




; =====================================================================================
; ===== Library includes - all function definitions live in lib\ (moved 2026-07-05) ===
; =====================================================================================
#Include %A_ScriptDir%\lib\FC_Bookmarks.ahk
#Include %A_ScriptDir%\lib\FC_AltTab.ahk
#Include %A_ScriptDir%\lib\FC_Arrange.ahk
#Include %A_ScriptDir%\lib\FC_Helpers.ahk
