; ---------------------------------------------------------------
AppName 		:= "FrogControl"
AppAuthor 		:= "Kim Dongryeong"
AppAuthorEmail	:= "kdr@namouli.com"
AppUpdateDate 	:= "2024-04-05"
AppVersion 		:= "1.15.alpha.3"
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
#Persistent  ; Keep the script running until the user exits it.
#MaxHotkeysPerInterval 2000
; #include Acc.ahk ; 2023-01-14 이거 없애보기
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
Menu, tray, add, Exit, GoExit
return

#a::Goto, AlwaysOnTop


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
	TrayTip, % "FrogControl", % "Hi again! Now enalbed", , 16
	if (GetKeyState("CapsLock", "P")) {
		if (GetKeyState("CapsLock", "T")) {
			SetCapsLockState, off
		} else {
			SetCapsLockState, on
		}
	}
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
Gui, helpEn: New
If( !A_IsCompiled && FileExist(A_ScriptDir . "\frog face icon 3.ico")) {
	Gui, helpEn: Add , Picture, w40 h40, %A_ScriptDir%\frog face icon 3.ico
} else {
	Gui, helpEn: Add , Picture, icon1, %A_WorkingDir%\FrogControl.exe
}
Gui, helpEn:Font,s15
Gui, helpEn:Add,Text,x+10 yp+10, % AppName " Help"
Gui, helpEn:Font
Gui, helpEn:Add,Text,xm, Shortcut list
Gui, helpEn:Font, , Consolas
Gui, helpEn: Add, ListView, r25 w1111, Hotkey|Action
Loop, read, %A_ScriptDir%\shortcut list-en.txt
{
	inLine_1 := ""
	inLine_2 := ""
	Loop, parse, A_LoopReadLine, %A_Tab%
	{
		inLine_%A_Index% := A_LoopField
	}
	LV_Add("", inLine_1, inLine_2)
}
LV_ModifyCol()  ; Auto-size each column to fit its contents.

Gui, helpEn:Font
Gui, helpEn: Add, Text,,
Gui, helpEn:Add,Text,xm, % "Version " AppVersion " (" AppUpdateDate ")"
Gui, helpEn: Add, Link, y+3, % "<a href=""" AppSite """>" AppSite "</a>"
Gui, helpEn:Add,Text,x+10 yp+10,
Gui, helpEn:Font
Gui, helpEn:Add,Text,xm, % "Created by " AppAuthor
Gui, helpEn: Add, Link, y+3, % "<a href=""mailto:" AppAuthorEmail """>" AppAuthorEmail "</a>"
Gui, helpEn:Font
Gui, helpEn:Add,Text,y+0,`t
Gui, helpEn:Add,Button,GABOUTOK Default w75,&OK
GuiControl, Focus, &OK
Gui, helpEn: Show, , FrogControl Help
FLAG_HELP_LANG := 1
Return

ABOUTOK:
Gui,Destroy
Return

MenuHandlerKo:
Gui, helpKo: New
If( !A_IsCompiled && FileExist(A_ScriptDir . "\frog face icon 3.ico")) {
	Gui, helpKo: Add , Picture, w40 h40, %A_ScriptDir%\frog face icon 3.ico
} else {
	Gui, helpKo: Add , Picture, icon1, %A_WorkingDir%\FrogControl.exe
}
Gui, helpKo:Font,s15
Gui, helpKo:Add,Text,x+10 yp+10, % "프로그 컨트롤(FrogControl) 도움말"
Gui, helpKo:Font
Gui, helpKo:Add,Text,xm, % "단축키 목록"
Gui, helpKo:Font, , Consolas
Gui, helpKo: Add, ListView, r25 w1111, Hotkey|Action
Loop, read, %A_ScriptDir%\shortcut list-ko.txt
{
	inLine_1 := ""
	inLine_2 := ""
	Loop, parse, A_LoopReadLine, %A_Tab%
	{
		inLine_%A_Index% := A_LoopField
	}
	LV_Add("", inLine_1, inLine_2)
}
LV_ModifyCol()  ; Auto-size each column to fit its contents.

Gui, helpKo:Font
Gui, helpKo: Add, Text,,
Gui, helpKo:Add,Text,xm, % "Version " AppVersion " (" AppUpdateDate ")"
Gui, helpKo: Add, Link, y+3, % "<a href=""" AppSite """>" AppSite "</a>"
Gui, helpKo:Add,Text,x+10 yp+10,
Gui, helpKo:Font
Gui, helpKo:Add,Text,xm, % "제작자 : " AppAuthor
Gui, helpKo: Add, Link, y+3, % "<a href=""mailto:" AppAuthorEmail """>" AppAuthorEmail "</a>"
Gui, helpKo:Font
Gui, helpKo:Add,Text,y+0,`t
Gui, helpKo:Add,Button,GABOUTOK Default w75,&OK
GuiControl, Focus, &OK
Gui, helpKo: Show, , FrogControl Help
FLAG_HELP_LANG := 2
Return

RemoveToolTip:
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
    curtrans := curtrans + 20
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
    curtrans := curtrans - 20
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
	SoundSet +10
	SoundGet, master_volume
	master_volume := round(master_volume)
	ToolTip volume: %master_volume%
	SetTimer, RemoveToolTip, % SETTING_CONSTANT_TOOLTIPDUR_S
return

#WheelDown::
#[::
	SoundSet -10
	SoundGet, master_volume
	master_volume := round(master_volume)
	ToolTip volume: %master_volume%
	SetTimer, RemoveToolTip, % SETTING_CONSTANT_TOOLTIPDUR_S
return

;; sound micro control with mouse and Control + Shift + Alt
#^WheelUp:: 	;  Alt-Win + Wheel + Alt-Whin will trigger this hotkey but also will open Window Start!
#^]::
	SoundSet +1
	SoundGet, master_volume
	master_volume := round(master_volume)
	ToolTip volume: %master_volume%
	SetTimer, RemoveToolTip, % SETTING_CONSTANT_TOOLTIPDUR_S
Return

#^WheelDown::
#^[::
	SoundSet -1
	SoundGet, master_volume
	master_volume := round(master_volume)
	ToolTip volume: %master_volume%
	SetTimer, RemoveToolTip, % SETTING_CONSTANT_TOOLTIPDUR_S
Return

;; to close a tab (like Ctrl + W) by Control + Shift + Right Click
;; while the original active window will be still active
^+RButton::
	DllCall("SystemParametersInfo", UInt, 0x0001, UInt, 0, UIntP, initial_beep_setting, UInt,0) 
	DllCall("SystemParametersInfo", UInt, 0x0002, UInt, 0, UInt,0, UInt,0) 	; SPI_SETBEEP : 0x0002
	MouseGetPos, , , mousewin
	WinGet, var_id, ID, A
	WinActivate, ahk_id %mousewin%
	WinWaitActive, ahk_id %mousewin%
	SendEvent, ^w
	;WinActivate, ahk_id %var_id%  	; if it's presented, minor error: no tab closed.  -> What I meant before?
	DllCall("SystemParametersInfo", UInt, 0x0002, UInt, initial_beep_setting, UInt,0, UInt,0) 	; SPI_SETBEEP : 0x0002
return


;; to close a window (like Alt + F4) by Control + Shift + Alt + Right Click
;; while the original active window will be still active
^+!RButton::
	MouseGetPos, , , mousewin
	WinActivate, ahk_id %mousewin%
	WinWaitActive, ahk_id %mousewin%
	SendEvent, !{F4}
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
	if (!window_rotate_firstcheck) { ;; if it's first time or it is 0
		window_rotate_firstcheck := 1
		wheel_count_down := 1
		wheel_count_check := 0
		AltTab_window_list()
		Loop, %AltTab_ID_List_0% {
			; Basically WinSet, Bottom revokes the WS_EX_TOPMOST (always on top) state.
			WinGet, var_ExStyle, ExStyle, % "ahk_id " AltTab_ID_List_%A_index%
			Winset, AlwaysOnTop, Off, % "ahk_id " AltTab_ID_List_%A_Index% 	; When WheelUp, topmost windows should be covered
			if !(var_ExStyle & 0x8) {  ; 0x8 is WS_EX_TOPMOST (always on top).
				AltTab_ID_List_topOfNontopmost := A_Index
				break
			}
		}
		window_rotate_current := 1
		; If you want to skip topmost windows when rotating:
		;window_rotate_current := AltTab_ID_List_topOfNontopmost
		SetTimer, window_rotate_stacking, 1
		return
	}
	wheel_count_down ++
return

!^WheelUp::
!^]::
	if (!window_rotate_firstcheck) { 
		window_rotate_firstcheck := 1
		wheel_count_down := -1
		wheel_count_check := 0
		AltTab_window_list()
		Loop, %AltTab_ID_List_0% {
			; Basically WinSet, Bottom revokes the WS_EX_TOPMOST (always on top) state.
			WinGet, var_ExStyle, ExStyle, % "ahk_id " AltTab_ID_List_%A_index%
			Winset, AlwaysOnTop, Off, % "ahk_id " AltTab_ID_List_%A_Index% 	; When WheelUp, topmost windows should be covered
			if !(var_ExStyle & 0x8) {  ; 0x8 is WS_EX_TOPMOST (always on top).
				AltTab_ID_List_topOfNontopmost := A_Index
				break
			}
		}
		window_rotate_current := 1
		; If you want to skip topmost windows when rotating:
		;window_rotate_current := AltTab_ID_List_topOfNontopmost

		SetTimer, window_rotate_stacking, 1
		return
	}
	wheel_count_down --
return

window_rotate_stacking:
	SetTimer, window_rotate_stacking, off
	WinActivate, ahk_class Shell_TrayWnd 	; The original active window will be still active even if it goes the bottom or something comes on it, which causes that even if you click the original window, it won't come to the topmost. Therefore, instead deactivate it.
	; The main loop
	Loop {
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

			wheel_count_check := wheel_count_down
		}
		if (wheel_count_down < wheel_count_check) {

			window_rotate_current --
			if (window_rotate_current < 1) {
				window_rotate_current := AltTab_ID_List_0
			}
			Winset, AlwaysOnTop, On, % "ahk_id " AltTab_ID_List_%window_rotate_current%
			Winset, AlwaysOnTop, Off, % "ahk_id " AltTab_ID_List_%window_rotate_current%

			; ToolTip to check the current focused window
			WinGetTitle, wintitle, % "ahk_id " AltTab_ID_List_%window_rotate_current%
			tooltip % wintitle
			SetTimer, RemoveToolTip, % SETTING_CONSTANT_TOOLTIPDUR_S 

			wheel_count_check := wheel_count_down
		}
	}
return

; ================= Simple Staking ======================== ends ==============================


; ================= Temporary showing around ==================== starts ============================
#!^WheelDown::
#!^[::
	if (!window_rotate_firstcheck_popup) { ;; if it's first time or it is 0
		window_rotate_firstcheck_popup := 1
		wheel_count_down := 1
		wheel_count_check := 0
		AltTab_window_list()
		Loop, %AltTab_ID_List_0% {
			; Basically WinSet, Bottom revokes the WS_EX_TOPMOST (always on top) state.
			WinGet, var_ExStyle, ExStyle, % "ahk_id " AltTab_ID_List_%A_index%
			if !(var_ExStyle & 0x8) {  ; 0x8 is WS_EX_TOPMOST (always on top).
				AltTab_ID_List_topOfNontopmost := A_Index
				break
			}
		}
		window_rotate_current := AltTab_ID_List_topOfNontopmost
		SetTimer, window_rotate_popup, 1
		return
	}
	wheel_count_down ++
return

#!^WheelUp::
#!^]::
	if (!window_rotate_firstcheck_popup) { 
		window_rotate_firstcheck_popup := 1
		wheel_count_down := -1
		wheel_count_check := 0
		AltTab_window_list()
		Loop, %AltTab_ID_List_0% {
			; Basically WinSet, Bottom revokes the WS_EX_TOPMOST (always on top) state.
			WinGet, var_ExStyle, ExStyle, % "ahk_id " AltTab_ID_List_%A_index%
			if !(var_ExStyle & 0x8) {  ; 0x8 is WS_EX_TOPMOST (always on top).
				AltTab_ID_List_topOfNontopmost := A_Index
				break
			}
		}
		window_rotate_current := 1

		SetTimer, window_rotate_popup, 1
		return
	}
	wheel_count_down --
return

window_rotate_popup:
	SetTimer, window_rotate_popup, off
	WinActivate, ahk_class Shell_TrayWnd 	; The original active window will be still active even if it goes the bottom or something comes on it, which causes that even if you click the original window, it won't come to the topmost. Therefore, instead deactivate it.

	Loop {
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

			Winset, AlwaysOnTop, On, % "ahk_id " AltTab_ID_List_%window_rotate_current%
			Winset, AlwaysOnTop, Off, % "ahk_id " AltTab_ID_List_%window_rotate_current%
			WinSet, Transparent, % SETTING_CONSTANT_FOCUSTRANS, % "ahk_id " AltTab_ID_List_%window_rotate_current%
			; ToolTip to check the current focused window
			WinGetTitle, wintitle, % "ahk_id " AltTab_ID_List_%window_rotate_current%
			tooltip % wintitle
			SetTimer, RemoveToolTip, % SETTING_CONSTANT_TOOLTIPDUR_S 

			wheel_count_check := wheel_count_down
		}

		if (wheel_count_down < wheel_count_check) {
			WinSet, Transparent, % SETTING_CONSTANT_HALFTRANS, % "ahk_id " AltTab_ID_List_%window_rotate_current%
			window_rotate_current --
			if (window_rotate_current < 1) {
				window_rotate_current := AltTab_ID_List_0
			}
			Winset, AlwaysOnTop, On, % "ahk_id " AltTab_ID_List_%window_rotate_current%
			Winset, AlwaysOnTop, Off, % "ahk_id " AltTab_ID_List_%window_rotate_current%
			WinSet, Transparent, % SETTING_CONSTANT_FOCUSTRANS, % "ahk_id " AltTab_ID_List_%window_rotate_current%
			; ToolTip to check the current focused window
			WinGetTitle, wintitle, % "ahk_id " AltTab_ID_List_%window_rotate_current%
			tooltip % wintitle
			SetTimer, RemoveToolTip, % SETTING_CONSTANT_TOOLTIPDUR_S 

			wheel_count_check := wheel_count_down
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
		window_previous := window_current 	; window_previous is a previous window_current at a previous arrow key.
		WinGetPos, window_previous_x, window_previous_y, window_previous_w, window_previous_h, % "ahk_id " AltTab_ID_List_woMinWin_%window_previous%
		window_previous_cen_x := window_previous_x + window_previous_w/2
		window_previous_cen_y := window_previous_y + window_previous_h/2

		; ============================================= WORKING ON! =================
		Loop, %AltTab_ID_List_woMinWin_0% { 
			WinGetPos, temp_x, temp_y, temp_w, temp_h, % "ahk_id " AltTab_ID_List_woMinWin_%A_Index%
			temp_cen_x := temp_x + temp_w/2
			temp_cen_y := temp_y + temp_h/2

			window_rel_coor_from_cur%A_Index%_x := temp_cen_x - window_previous_cen_x
			window_rel_coor_from_cur%A_Index%_y := temp_cen_y - window_previous_cen_y
			window_rel_coor_from_cur%A_Index%_d2 := window_rel_coor_from_cur%A_Index%_x**2 + window_rel_coor_from_cur%A_Index%_y**2
		}

		if (is_right = "D") { 	; If we use GetKeyState(), then because it's distant between the start and the loop, meantime the first arrow key (which triggered the hotkey) state may be up when it arrives at the loop, which causes the first arrow stroke doesn't let it go to the next window!
			window_current_ScanningNext_d2 := 01100001011001010110100101101110
			window_current_ScanningNext_ID := ""

			WinSet, Transparent, % SETTING_CONSTANT_HALFTRANS, % "ahk_id " AltTab_ID_List_woMinWin_%window_current%
			
			Loop, %AltTab_ID_List_woMinWin_0% { 	; The main loop to find a next window
				if (A_Index = window_previous)  	; skip itself
					continue
				pos_det_x := abs(window_rel_coor_from_cur%A_Index%_y)/window_rel_coor_from_cur%A_Index%_x
				if (window_rel_coor_from_cur%A_Index%_d2 = 0) {
					if (AltTab_ID_List_woMinWin_%window_previous% < AltTab_ID_List_woMinWin_%A_Index%) {
						if ((AltTab_ID_List_woMinWin_%A_Index% < AltTab_ID_List_woMinWin_%window_current%) or (window_current_ScanningNext_ID = "")) { 	; AltTab_ID_List_woMinWin_%window_current% == window_current_ScanningNext_ID
							window_current := A_Index
							window_current_ScanningNext_d2 := window_rel_coor_from_cur%A_Index%_d2 	; so is 0.
							window_current_ScanningNext_ID := AltTab_ID_List_woMinWin_%A_Index%
						}
					}
				} else if ((0 <= pos_det_x) and (pos_det_x <= 1/2)) {
					if (window_rel_coor_from_cur%A_Index%_d2 <= window_current_ScanningNext_d2) {
						if (window_rel_coor_from_cur%A_Index%_d2 = window_current_ScanningNext_d2) { 	; at the first loop, it can't happen. So don't have to consider this: window_current_ScanningNext_ID := ""
							if (AltTab_ID_List_woMinWin_%A_Index% < window_current_ScanningNext_ID) {
								window_current := A_Index
								window_current_ScanningNext_d2 := window_rel_coor_from_cur%A_Index%_d2
								window_current_ScanningNext_ID := AltTab_ID_List_woMinWin_%A_Index%
							}
						} else {
							window_current := A_Index
							window_current_ScanningNext_d2 := window_rel_coor_from_cur%A_Index%_d2
							window_current_ScanningNext_ID := AltTab_ID_List_woMinWin_%A_Index%

						}
					}
				} 
			}
		
			WinSet, Transparent, % SETTING_CONSTANT_FOCUSTRANS, % "ahk_id " AltTab_ID_List_woMinWin_%window_current%
			Winset, AlwaysOnTop, On, % "ahk_id " AltTab_ID_List_woMinWin_%window_current%
			Winset, AlwaysOnTop, Off, % "ahk_id " AltTab_ID_List_woMinWin_%window_current%
			
			; ToolTip to check the current focused window
			WinGetTitle, wintitle, % "ahk_id " AltTab_ID_List_woMinWin_%window_current%
			tooltip % wintitle
			SetTimer, RemoveToolTip, % SETTING_CONSTANT_TOOLTIPDUR_S 
			
			KeyWait, Right, T0.2	;wait for release of cycleKey, timeout after .. seconds
		}

		if (is_left = "D") { 	; If we use GetKeyState(), then because it's distant between the start and the loop, meantime the first arrow key (which triggered the hotkey) state may be up when it arrives at the loop, which causes the first arrow stroke doesn't let it go to the next window!
			window_current_ScanningNext_d2 := 01100001011001010110100101101110
			window_current_ScanningNext_ID := ""

			WinSet, Transparent, % SETTING_CONSTANT_HALFTRANS, % "ahk_id " AltTab_ID_List_woMinWin_%window_current%
			
			Loop, %AltTab_ID_List_woMinWin_0% { 	; The main loop to find a next window
				if (A_Index = window_previous)  	; skip itself
					continue
				pos_det_x := abs(window_rel_coor_from_cur%A_Index%_y)/window_rel_coor_from_cur%A_Index%_x
				if (window_rel_coor_from_cur%A_Index%_d2 = 0) {
					if (AltTab_ID_List_woMinWin_%window_previous% < AltTab_ID_List_woMinWin_%A_Index%) {
						if ((AltTab_ID_List_woMinWin_%A_Index% < AltTab_ID_List_woMinWin_%window_current%) or (window_current_ScanningNext_ID = "")) { 	; AltTab_ID_List_woMinWin_%window_current% == window_current_ScanningNext_ID
							window_current := A_Index
							window_current_ScanningNext_d2 := window_rel_coor_from_cur%A_Index%_d2 	; so is 0.
							window_current_ScanningNext_ID := AltTab_ID_List_woMinWin_%A_Index%
						}
					}
				} else if ((0 >= pos_det_x) and (pos_det_x >= -1/2)) {
					if (window_rel_coor_from_cur%A_Index%_d2 <= window_current_ScanningNext_d2) {
						if (window_rel_coor_from_cur%A_Index%_d2 = window_current_ScanningNext_d2) { 	; at the first loop, it can't happen. So don't have to consider this: window_current_ScanningNext_ID := ""
							if (AltTab_ID_List_woMinWin_%A_Index% < window_current_ScanningNext_ID) {
								window_current := A_Index
								window_current_ScanningNext_d2 := window_rel_coor_from_cur%A_Index%_d2
								window_current_ScanningNext_ID := AltTab_ID_List_woMinWin_%A_Index%
							}
						} else {
							window_current := A_Index
							window_current_ScanningNext_d2 := window_rel_coor_from_cur%A_Index%_d2
							window_current_ScanningNext_ID := AltTab_ID_List_woMinWin_%A_Index%

						}
					}
				} 
			}

			WinSet, Transparent, % SETTING_CONSTANT_FOCUSTRANS, % "ahk_id " AltTab_ID_List_woMinWin_%window_current%
			Winset, AlwaysOnTop, On, % "ahk_id " AltTab_ID_List_woMinWin_%window_current%
			Winset, AlwaysOnTop, Off, % "ahk_id " AltTab_ID_List_woMinWin_%window_current%

			; ToolTip to check the current focused window
			WinGetTitle, wintitle, % "ahk_id " AltTab_ID_List_woMinWin_%window_current%
			tooltip % wintitle
			SetTimer, RemoveToolTip, % SETTING_CONSTANT_TOOLTIPDUR_S 

			KeyWait, Left, T0.2	;wait for release of cycleKey, timeout after 400ms
		}

		if (is_down = "D") { 	; If we use GetKeyState(), then because it's distant between the start and the loop, meantime the first arrow key (which triggered the hotkey) state may be up when it arrives at the loop, which causes the first arrow stroke doesn't let it go to the next window!
			window_current_ScanningNext_d2 := 01100001011001010110100101101110
			window_current_ScanningNext_ID := ""

			WinSet, Transparent, % SETTING_CONSTANT_HALFTRANS, % "ahk_id " AltTab_ID_List_woMinWin_%window_current%
			
			Loop, %AltTab_ID_List_woMinWin_0% { 	; The main loop to find a next window
				if (A_Index = window_previous)  	; skip itself
					continue
				pos_det_y := window_rel_coor_from_cur%A_Index%_y/abs(window_rel_coor_from_cur%A_Index%_x)
				if (window_rel_coor_from_cur%A_Index%_d2 = 0) {
					if (AltTab_ID_List_woMinWin_%window_previous% < AltTab_ID_List_woMinWin_%A_Index%) {
						if ((AltTab_ID_List_woMinWin_%A_Index% < AltTab_ID_List_woMinWin_%window_current%) or (window_current_ScanningNext_ID = "")) { 	; AltTab_ID_List_woMinWin_%window_current% == window_current_ScanningNext_ID
							window_current := A_Index
							window_current_ScanningNext_d2 := window_rel_coor_from_cur%A_Index%_d2 	; so is 0.
							window_current_ScanningNext_ID := AltTab_ID_List_woMinWin_%A_Index%
						}
					}
				} else if (pos_det_y >= 1/2) {
					if (window_rel_coor_from_cur%A_Index%_d2 <= window_current_ScanningNext_d2) {
						if (window_rel_coor_from_cur%A_Index%_d2 = window_current_ScanningNext_d2) { 	; at the first loop, it can't happen. So don't have to consider this: window_current_ScanningNext_ID := ""
							if (AltTab_ID_List_woMinWin_%A_Index% < window_current_ScanningNext_ID) {
								window_current := A_Index
								window_current_ScanningNext_d2 := window_rel_coor_from_cur%A_Index%_d2
								window_current_ScanningNext_ID := AltTab_ID_List_woMinWin_%A_Index%
							}
						} else {
							window_current := A_Index
							window_current_ScanningNext_d2 := window_rel_coor_from_cur%A_Index%_d2
							window_current_ScanningNext_ID := AltTab_ID_List_woMinWin_%A_Index%

						}
					}
				} 
			}

			WinSet, Transparent, % SETTING_CONSTANT_FOCUSTRANS, % "ahk_id " AltTab_ID_List_woMinWin_%window_current%
			Winset, AlwaysOnTop, On, % "ahk_id " AltTab_ID_List_woMinWin_%window_current%
			Winset, AlwaysOnTop, Off, % "ahk_id " AltTab_ID_List_woMinWin_%window_current%

			; ToolTip to check the current focused window
			WinGetTitle, wintitle, % "ahk_id " AltTab_ID_List_woMinWin_%window_current%
			tooltip % wintitle
			SetTimer, RemoveToolTip, % SETTING_CONSTANT_TOOLTIPDUR_S 
			
			KeyWait, Down, T0.2	;wait for release of cycleKey, timeout after 400ms
		}


		if (is_up = "D") { 	; If we use GetKeyState(), then because it's distant between the start and the loop, meantime the first arrow key (which triggered the hotkey) state may be up when it arrives at the loop, which causes the first arrow stroke doesn't let it go to the next window!
			window_current_ScanningNext_d2 := 01100001011001010110100101101110
			window_current_ScanningNext_ID := ""

			WinSet, Transparent, % SETTING_CONSTANT_HALFTRANS, % "ahk_id " AltTab_ID_List_woMinWin_%window_current%
			
			Loop, %AltTab_ID_List_woMinWin_0% { 	; The main loop to find a next window
				if (A_Index = window_previous)  	; skip itself
					continue
				pos_det_y := window_rel_coor_from_cur%A_Index%_y/abs(window_rel_coor_from_cur%A_Index%_x)
				if (window_rel_coor_from_cur%A_Index%_d2 = 0) {
					if (AltTab_ID_List_woMinWin_%window_previous% < AltTab_ID_List_woMinWin_%A_Index%) {
						if ((AltTab_ID_List_woMinWin_%A_Index% < AltTab_ID_List_woMinWin_%window_current%) or (window_current_ScanningNext_ID = "")) { 	; AltTab_ID_List_woMinWin_%window_current% == window_current_ScanningNext_ID
							window_current := A_Index
							window_current_ScanningNext_d2 := window_rel_coor_from_cur%A_Index%_d2 	; so is 0.
							window_current_ScanningNext_ID := AltTab_ID_List_woMinWin_%A_Index%
						}
					}
				} else if (pos_det_y <= -1/2) {
					if (window_rel_coor_from_cur%A_Index%_d2 <= window_current_ScanningNext_d2) {
						if (window_rel_coor_from_cur%A_Index%_d2 = window_current_ScanningNext_d2) { 	; at the first loop, it can't happen. So don't have to consider this: window_current_ScanningNext_ID := ""
							if (AltTab_ID_List_woMinWin_%A_Index% < window_current_ScanningNext_ID) {
								window_current := A_Index
								window_current_ScanningNext_d2 := window_rel_coor_from_cur%A_Index%_d2
								window_current_ScanningNext_ID := AltTab_ID_List_woMinWin_%A_Index%
							}
						} else {
							window_current := A_Index
							window_current_ScanningNext_d2 := window_rel_coor_from_cur%A_Index%_d2
							window_current_ScanningNext_ID := AltTab_ID_List_woMinWin_%A_Index%

						}
					}
				} 
			}

			WinSet, Transparent, % SETTING_CONSTANT_FOCUSTRANS, % "ahk_id " AltTab_ID_List_woMinWin_%window_current%
			Winset, AlwaysOnTop, On, % "ahk_id " AltTab_ID_List_woMinWin_%window_current%
			Winset, AlwaysOnTop, Off, % "ahk_id " AltTab_ID_List_woMinWin_%window_current%

			; ToolTip to check the current focused window
			WinGetTitle, wintitle, % "ahk_id " AltTab_ID_List_woMinWin_%window_current%
			tooltip % wintitle
			SetTimer, RemoveToolTip, % SETTING_CONSTANT_TOOLTIPDUR_S 

			KeyWait, Up, T0.2	;wait for release of cycleKey, timeout after 400ms
		}

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
	Send, ^{PgDn}
Return

;^+[:: 	; not good becuase of Photoshop
^+WheelUp::
	Send, ^{PgUp}
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
	SysGet, monitor_no, MonitorCount	
	SysGet, monitor_no_prm, MonitorPrimary
	Loop, %monitor_no% {
	    SysGet, Monitor_%A_Index%_, Monitor, %A_Index%	; monitor_%A_Index%_workarea_ 뒤에 접미사로 left, right, top, bottom이 붙어서 이미 변수 할당이 SysGet에 의해서 자동으로 되는 듯. https://www.autohotkey.com/docs/commands/SysGet.htm#MonitorCount
	    SysGet, Monitor_%A_Index%_WorkArea_, MonitorWorkArea, %A_Index%
		monitor_%A_Index%_workarea_width := monitor_%A_Index%_workarea_right - monitor_%A_Index%_workarea_left 	
		monitor_%A_Index%_workarea_height := monitor_%A_Index%_workarea_bottom - monitor_%A_Index%_workarea_top
		monitor_%A_Index%_workarea_ratio := monitor_%A_Index%_workarea_height/monitor_%A_Index%_workarea_width
		monitor_%A_Index%_workarea_center_x := (monitor_%A_Index%_workarea_right + monitor_%A_Index%_workarea_left)/2
		monitor_%A_Index%_workarea_center_y := (monitor_%A_Index%_workarea_bottom + monitor_%A_Index%_workarea_top)/2
		monitor_%A_Index%_grid_no_x := monitor_%A_Index%_workarea_width // 800 		; the numbers of grid along with x axis. 1920/2 = 960, 2560/3 = 853, 1920/800 = 2.xx, 2560/800 = 3.xx, 3840/800 = 4.8
		monitor_%A_Index%_grid_no_y := monitor_%A_Index%_workarea_height // 450 	; the numbers of grid along with y axis. 1080/2 = 540, 1440/3 = 480, 1080/450 = 2.xx, 1440/450 = 3.xx, 2160/450 = 4.8
		monitor_%A_Index%_grid_no_xy := monitor_%A_Index%_grid_no_x * monitor_%A_Index%_grid_no_y 			; the numbers of grids
		monitor_%A_Index%_grid_width := monitor_%A_Index%_workarea_width / monitor_%A_Index%_grid_no_x 		; width of a grid
		monitor_%A_Index%_grid_height := monitor_%A_Index%_workarea_height / monitor_%A_Index%_grid_no_y 	; height of a grid
	}

	AltTab_window_list()

	AltTab_ID_List_FileExplorer_0 := 0

	; Creating AltTab_ID_List_FileExplorer_%A_Index%. i.e., a ID list of File Explorers
	Loop, %AltTab_ID_List_0% {
		WinGetClass, temp_className, % "ahk_id " AltTab_ID_List_%A_index%
		if temp_className not in CabinetWClass, ExploreWClass
			Continue
		AltTab_ID_List_FileExplorer_0 ++
		AltTab_ID_List_FileExplorer_%AltTab_ID_List_FileExplorer_0% := AltTab_ID_List_%A_index%
		AltTab_ID_List_FileExplorer_%AltTab_ID_List_FileExplorer_0%_momIndex := A_Index
	}

	; To send all File Explorers to the bottom if they are on the top currently
	WinGetClass, class_currentActive, A
	if class_currentActive in CabinetWClass, ExploreWClass 	; 
	{
		WinGet, activeWin_ID, ID, A
		Loop, %AltTab_ID_List_FileExplorer_0% {
			if (AltTab_ID_List_FileExplorer_%A_Index% = activeWin_ID) { 	; If there is a File Explorer with TOPMOST, then the current window may not be AltTab_ID_List_FileExplorer_1
				activeWin_momIndex := AltTab_ID_List_FileExplorer_%A_Index%_momIndex
				activeWin_FExpIndex := A_Index
				activeWin_FExpIndex_nexts := A_Index + 1
				if (AltTab_ID_List_FileExplorer_%activeWin_FExpIndex_nexts%_momIndex = activeWin_momIndex + 1) { ; if the next window after the current active File Explorer is another File Explorer, we keep the current File Explorer and send the others back.
					Loop, %AltTab_ID_List_FileExplorer_0% {
						if (A_Index = activeWin_FExpIndex)
							Continue
						WinSet, Bottom, , % "ahk_id " AltTab_ID_List_FileExplorer_%A_Index%	

					}
				} else {
					Loop, %AltTab_ID_List_FileExplorer_0% {
						WinSet, Bottom, , % "ahk_id " AltTab_ID_List_FileExplorer_%A_Index%
						if (AltTab_ID_List_FileExplorer_%A_Index% = activeWin_ID) { 	; If there is a File Explorer with TOPMOST, then the current window may not be AltTab_ID_List_FileExplorer_1
							activeWin_FExpIndex := A_Index
							activeWin_momIndex := AltTab_ID_List_FileExplorer_%A_Index%_momIndex
							Loop, {
								activeWin_FExpIndex_nexts := activeWin_FExpIndex + A_Index
								if (AltTab_ID_List_FileExplorer_%activeWin_FExpIndex_nexts%_momIndex != activeWin_momIndex + A_Index) {
									toActivate := activeWin_momIndex + A_Index
									WinActivate, % "ahk_id " AltTab_ID_List_%toActivate%
									break
								}
							}
						}
					}
				}
				Break
			}
		}
	}



	; When there is no File Explorer.
	else if (AltTab_ID_List_FileExplorer_0 < 1) {
		Run, Explorer
	} 

	; putting windows
	else { 	; putting windows only on the primary screen
		Loop, %AltTab_ID_List_FileExplorer_0% {
			; first unminimize or unmaximize all File Explorers in order to prevent WinMove from not working, and in order to get proper width and height.
			WinRestore, % "ahk_id " AltTab_ID_List_FileExplorer_%A_Index%

			WinGetPos, temp_x, temp_y, temp_w, temp_h, % "ahk_id " AltTab_ID_List_FileExplorer_%A_Index%
			; It's needed to spread windows across all monitors 
			loop, %monitor_no% {
				if (monitor_%A_Index%_left <= temp_x + temp_w/2) and (temp_x + temp_w/2 <= monitor_%A_Index%_right - 1) and (monitor_%A_Index%_top <= temp_y + temp_h/2) and (temp_y + temp_h/2 <= monitor_%A_Index%_bottom - 1) {		; monitors' lefts and rights are like 0 ~ 2560, -1920 ~ 0.
					AltTab_ID_List_FileExplorer_%AltTab_ID_List_FileExplorer_0%_mon := A_Index
					AltTab_ID_List_FileExplorer_inMon_%A_Index%_all_w += temp_w 	; Sum of widths of all File Explorers in each monitor
					AltTab_ID_List_FileExplorer_inMon_%A_Index%_all_h += temp_h 	; Sum of heights of all File Explorers in each monitor
				}
			}
		}
		if (AltTab_ID_List_FileExplorer_0 > monitor_%monitor_no_prm%_grid_no_xy) {
			; to create more grid
			Loop, {
				Loop, {
					monitor_%monitor_no_prm%_grid_no_x ++
					monitor_%monitor_no_prm%_grid_no_xy := monitor_%monitor_no_prm%_grid_no_x * monitor_%monitor_no_prm%_grid_no_y
					monitor_%monitor_no_prm%_grid_width := monitor_%monitor_no_prm%_workarea_width / monitor_%monitor_no_prm%_grid_no_x
					break
				}
				if (AltTab_ID_List_FileExplorer_0 <= monitor_%monitor_no_prm%_grid_no_xy) {
					break
				}
				monitor_%monitor_no_prm%_grid_no_y ++
				monitor_%monitor_no_prm%_grid_no_xy := monitor_%monitor_no_prm%_grid_no_x * monitor_%monitor_no_prm%_grid_no_y
				monitor_%monitor_no_prm%_grid_height := monitor_%monitor_no_prm%_workarea_height / monitor_%monitor_no_prm%_grid_no_y
				if (AltTab_ID_List_FileExplorer_0 <= monitor_%monitor_no_prm%_grid_no_xy) {
					break
				}
			}
		}
		counter := 0
		isLoopDone := 0
		counterRvs := AltTab_ID_List_FileExplorer_0

		lastFExp_gridX := Ceil(AltTab_ID_List_FileExplorer_0 / monitor_%monitor_no_prm%_grid_no_y)
		lastFExp_gridY := Mod(AltTab_ID_List_FileExplorer_0, monitor_%monitor_no_prm%_grid_no_y) = 0 ? monitor_%monitor_no_prm%_grid_no_y : Mod(AltTab_ID_List_FileExplorer_0, monitor_%monitor_no_prm%_grid_no_y)

		stillEmptyLoop := 1
		Loop, % lastFExp_gridX {
			loop_1_indexRev := lastFExp_gridX - A_Index + 1
			
			Loop, % monitor_%monitor_no_prm%_grid_no_y {
				loop_2_indexRev := monitor_%monitor_no_prm%_grid_no_y - A_Index + 1
				if ((loop_2_indexRev > lastFExp_gridY) and (stillEmptyLoop = 1)) {
					Continue
				}
				stillEmptyLoop := 0
				WinMove, % "ahk_id " AltTab_ID_List_FileExplorer_%counterRvs%, 	, monitor_%monitor_no_prm%_workarea_left + monitor_%monitor_no_prm%_grid_width * (loop_1_indexRev - 1)
																				, monitor_%monitor_no_prm%_workarea_top + monitor_%monitor_no_prm%_grid_height * (loop_2_indexRev - 1)
																				, monitor_%monitor_no_prm%_grid_width
																				, monitor_%monitor_no_prm%_grid_height
				WinSet, AlwaysOnTop, On, % "ahk_id " AltTab_ID_List_FileExplorer_%counterRvs%
				WinSet, AlwaysOnTop, Off, % "ahk_id " AltTab_ID_List_FileExplorer_%counterRvs%
				counterRvs --
			}
		} 
		WinActivate, % "ahk_id " AltTab_ID_List_FileExplorer_1
	}
Return



; ================= Showing only File Explorer - without changing size ======= starts ==================
; Currently only on the primary Screen
; to add with a modifier: put windows on their Screens
; to add with a modifier: put windows only on the screen where mouse cursor is.
;F3::
+F1::
;CapsLock & F3::
	SysGet, monitor_no, MonitorCount	
	SysGet, monitor_no_prm, MonitorPrimary
	Loop, %monitor_no% {
	    SysGet, Monitor_%A_Index%_, Monitor, %A_Index%
	    SysGet, Monitor_%A_Index%_WorkArea_, MonitorWorkArea, %A_Index%
		monitor_%A_Index%_workarea_width := monitor_%A_Index%_workarea_right - monitor_%A_Index%_workarea_left
		monitor_%A_Index%_workarea_height := monitor_%A_Index%_workarea_bottom - monitor_%A_Index%_workarea_top
		monitor_%A_Index%_workarea_ratio := monitor_%A_Index%_workarea_height/monitor_%A_Index%_workarea_width
		monitor_%A_Index%_workarea_center_x := (monitor_%A_Index%_workarea_right + monitor_%A_Index%_workarea_left)/2
		monitor_%A_Index%_workarea_center_y := (monitor_%A_Index%_workarea_bottom + monitor_%A_Index%_workarea_top)/2
		monitor_%A_Index%_grid_no_x := monitor_%A_Index%_workarea_width // 800 		; the numbers of grid along with x axis. 1920/2 = 960, 2560/3 = 853, 1920/800 = 2.xx, 2560/800 = 3.xx, 3840/800 = 4.8
		monitor_%A_Index%_grid_no_y := monitor_%A_Index%_workarea_height // 450 	; the numbers of grid along with y axis. 1080/2 = 540, 1440/3 = 480, 1080/450 = 2.xx, 1440/450 = 3.xx, 2160/450 = 4.8
		monitor_%A_Index%_grid_no_xy := monitor_%A_Index%_grid_no_x * monitor_%A_Index%_grid_no_y 			; the numbers of grids
		monitor_%A_Index%_grid_width := monitor_%A_Index%_workarea_width / monitor_%A_Index%_grid_no_x 		; width of a grid
		monitor_%A_Index%_grid_height := monitor_%A_Index%_workarea_height / monitor_%A_Index%_grid_no_y 	; height of a grid
	}


	AltTab_window_list()

	AltTab_ID_List_FileExplorer_0 := 0
	AltTab_ID_List_FileExplorer_all_w := 0 	; Sum of widths of all File Explorers across all monitors
	AltTab_ID_List_FileExplorer_all_h := 0 	; Sum of heights of all File Explorers across all monitors
	AltTab_ID_List_FileExplorer_max_w := 0
	AltTab_ID_List_FileExplorer_max_h := 0
	Loop, %monitor_no% {
		AltTab_ID_List_FileExplorer_inMon_%A_Index%_all_w := 0 	; Sum of widths of all File Explorers in each monitor
		AltTab_ID_List_FileExplorer_inMon_%A_Index%_all_h := 0 	; Sum of heights of all File Explorers in each monitor
	}

	; Creating AltTab_ID_List_FileExplorer_%A_Index%. i.e., a ID list of File Explorers
	Loop, %AltTab_ID_List_0% {
		WinGetClass, temp_className, % "ahk_id " AltTab_ID_List_%A_index%
		if temp_className not in CabinetWClass, ExploreWClass
			Continue
		AltTab_ID_List_FileExplorer_0 ++
		AltTab_ID_List_FileExplorer_%AltTab_ID_List_FileExplorer_0% := AltTab_ID_List_%A_index%
		AltTab_ID_List_FileExplorer_%AltTab_ID_List_FileExplorer_0%_momIndex := A_Index
	}

	; To send all File Explorers to the bottom if they are on the top currently
	WinGetClass, class_currentActive, A
	if class_currentActive in CabinetWClass, ExploreWClass 	; 
	{
		WinGet, activeWin_ID, ID, A
		Loop, %AltTab_ID_List_FileExplorer_0% {
			if (AltTab_ID_List_FileExplorer_%A_Index% = activeWin_ID) { 	; If there is a File Explorer with TOPMOST, then the current window may not be AltTab_ID_List_FileExplorer_1
				activeWin_momIndex := AltTab_ID_List_FileExplorer_%A_Index%_momIndex
				activeWin_FExpIndex := A_Index
				activeWin_FExpIndex_nexts := A_Index + 1
				if (AltTab_ID_List_FileExplorer_%activeWin_FExpIndex_nexts%_momIndex = activeWin_momIndex + 1) { ; if the next window after the current active File Explorer is another File Explorer, we keep the current File Explorer and send the others back.
					Loop, %AltTab_ID_List_FileExplorer_0% {
						if (A_Index = activeWin_FExpIndex)
							Continue
						WinSet, Bottom, , % "ahk_id " AltTab_ID_List_FileExplorer_%A_Index%	

					}
				} else {
					Loop, %AltTab_ID_List_FileExplorer_0% {
						WinSet, Bottom, , % "ahk_id " AltTab_ID_List_FileExplorer_%A_Index%
						if (AltTab_ID_List_FileExplorer_%A_Index% = activeWin_ID) { 	; If there is a File Explorer with TOPMOST, then the current window may not be AltTab_ID_List_FileExplorer_1
							activeWin_FExpIndex := A_Index
							activeWin_momIndex := AltTab_ID_List_FileExplorer_%A_Index%_momIndex
							Loop, {
								activeWin_FExpIndex_nexts := activeWin_FExpIndex + A_Index
								if (AltTab_ID_List_FileExplorer_%activeWin_FExpIndex_nexts%_momIndex != activeWin_momIndex + A_Index) {
									toActivate := activeWin_momIndex + A_Index
									WinActivate, % "ahk_id " AltTab_ID_List_%toActivate%
									break
								}
							}
						}
					}
				}
				Break
			}
		}
	}

	; When there is no File Explorer.
	else if (AltTab_ID_List_FileExplorer_0 < 1) {
		Run, Explorer
	} 

	; putting windows
	else { 	; putting windows only on the primary screen

		; to get coordinates and measures of File Explorer (should be in the else statement.)
		Loop, %AltTab_ID_List_FileExplorer_0% { 
			; first unminimize or unmaximize all File Explorers in order to prevent WinMove from not working, and in order to get proper width and height.
			WinRestore, % "ahk_id " AltTab_ID_List_FileExplorer_%A_Index% 	; this is the problem.

			WinGetPos, temp_x, temp_y, temp_w, temp_h, % "ahk_id " AltTab_ID_List_FileExplorer_%A_Index%
			AltTab_ID_List_FileExplorer_%A_Index%_x := temp_x  
			AltTab_ID_List_FileExplorer_%A_Index%_y := temp_y
			AltTab_ID_List_FileExplorer_%A_Index%_w := temp_w
			AltTab_ID_List_FileExplorer_%A_Index%_h := temp_h  
			AltTab_ID_List_FileExplorer_all_w += temp_w
			AltTab_ID_List_FileExplorer_all_h += temp_h
			if (AltTab_ID_List_FileExplorer_max_w < temp_w) {
				AltTab_ID_List_FileExplorer_max_w := temp_w
			}
			if (AltTab_ID_List_FileExplorer_max_h < temp_h) {
				AltTab_ID_List_FileExplorer_max_h := temp_h
			}
			
			index := A_Index
			; It's needed to spread windows across all monitors 
			loop, %monitor_no% {
				if (monitor_%A_Index%_left <= temp_x + temp_w/2) and (temp_x + temp_w/2 <= monitor_%A_Index%_right - 1) and (monitor_%A_Index%_top <= temp_y + temp_h/2) and (temp_y + temp_h/2 <= monitor_%A_Index%_bottom - 1) {		; monitors' lefts and rights are like 0 ~ 2560, -1920 ~ 0.
					AltTab_ID_List_FileExplorer_%index%_mon := A_Index
					AltTab_ID_List_FileExplorer_inMon_%A_Index%_all_w += temp_w 	; Sum of widths of all File Explorers in each monitor
					AltTab_ID_List_FileExplorer_inMon_%A_Index%_all_h += temp_h 	; Sum of heights of all File Explorers in each monitor
				}
			}
		}


		if (AltTab_ID_List_FileExplorer_all_w <= monitor_%monitor_no_prm%_workarea_width) { 	; Putting horizontally. (instead of monitor_%A_Index%_workarea_width)
			; putting horizontally all together
			spreadFExp_left := monitor_%monitor_no_prm%_workarea_center_x - AltTab_ID_List_FileExplorer_all_w/2
			spreadFExp_top := monitor_%monitor_no_prm%_workarea_center_y - AltTab_ID_List_FileExplorer_max_h/2
			Loop, % AltTab_ID_List_FileExplorer_0 {
				temp_index := AltTab_ID_List_FileExplorer_0 - A_Index + 1
				WinMove, % "ahk_id " AltTab_ID_List_FileExplorer_%temp_index%, , spreadFExp_left, spreadFExp_top
				WinSet, AlwaysOnTop, On, % "ahk_id " AltTab_ID_List_FileExplorer_%temp_index%
				WinSet, AlwaysOnTop, Off, % "ahk_id " AltTab_ID_List_FileExplorer_%temp_index%
				WinActivate, % "ahk_id " AltTab_ID_List_FileExplorer_%temp_index%
				spreadFExp_left += AltTab_ID_List_FileExplorer_%temp_index%_w
			}
		} else if (AltTab_ID_List_FileExplorer_all_h <= monitor_%monitor_no_prm%_workarea_height) { 	; putting vertically all together
			spreadFExp_left := monitor_%monitor_no_prm%_workarea_center_x - AltTab_ID_List_FileExplorer_max_w/2
			spreadFExp_top := monitor_%monitor_no_prm%_workarea_center_y - AltTab_ID_List_FileExplorer_all_h/2
			Loop, % AltTab_ID_List_FileExplorer_0 {
				temp_index := AltTab_ID_List_FileExplorer_0 - A_Index + 1
				WinMove, % "ahk_id " AltTab_ID_List_FileExplorer_%temp_index%, , spreadFExp_left, spreadFExp_top
				;DllCall("MoveWindow", UInt, AltTab_ID_List_FileExplorer_%temp_index%, UInt, spreadFExpEach_x, UInt, spreadFExpEach_y, UInt, AltTab_ID_List_FileExplorer_%temp_index%_w, UInt, AltTab_ID_List_FileExplorer_%temp_index%_h, Int, 1)
				WinSet, AlwaysOnTop, On, % "ahk_id " AltTab_ID_List_FileExplorer_%temp_index%
				WinSet, AlwaysOnTop, Off, % "ahk_id " AltTab_ID_List_FileExplorer_%temp_index%
				WinActivate, % "ahk_id " AltTab_ID_List_FileExplorer_%temp_index%
				spreadFExp_top += AltTab_ID_List_FileExplorer_%temp_index%_h
			}
		} else if ((monitor_%monitor_no_prm%_grid_no_x <= 1) or (monitor_%monitor_no_prm%_grid_no_y <= 1)) {  	; in case the screen is so narrow
			; putting diagonally, overlapping
			spreadFExp_left := monitor_%monitor_no_prm%_workarea_left
			spreadFExp_top := monitor_%monitor_no_prm%_workarea_top
			spreadFExp_end_x := monitor_%monitor_no_prm%_workarea_right - AltTab_ID_List_FileExplorer_1_w		; The top one will be right down corner and top
			spreadFExp_end_y := monitor_%monitor_no_prm%_workarea_bottom - AltTab_ID_List_FileExplorer_1_h 	; The top one will be right down corner and top
			spreadFExp_step_width := (spreadFExp_end_x - spreadFExp_left) / (AltTab_ID_List_FileExplorer_0 - 1)
			spreadFExp_step_height := (spreadFExp_end_y - spreadFExp_top) /(AltTab_ID_List_FileExplorer_0 - 1)
			Loop, % AltTab_ID_List_FileExplorer_0 {
				temp_index := AltTab_ID_List_FileExplorer_0 - A_Index + 1
				spreadFExpEach_x := spreadFExp_left + spreadFExp_step_width * (A_Index - 1)
				spreadFExpEach_y := spreadFExp_top + spreadFExp_step_height * (A_Index - 1)
				WinMove, % "ahk_id " AltTab_ID_List_FileExplorer_%temp_index%, , spreadFExpEach_x, spreadFExpEach_y 	; When SetWinDelay, -1 is declared, WinMove is as fast as DllCall("MoveWindow".. .
				;DllCall("MoveWindow", UInt, AltTab_ID_List_FileExplorer_%temp_index%, UInt, spreadFExpEach_x, UInt, spreadFExpEach_y, UInt, AltTab_ID_List_FileExplorer_%temp_index%_w, UInt, AltTab_ID_List_FileExplorer_%temp_index%_h, Int, 1)
				WinSet, AlwaysOnTop, On, % "ahk_id " AltTab_ID_List_FileExplorer_%temp_index%
				WinSet, AlwaysOnTop, Off, % "ahk_id " AltTab_ID_List_FileExplorer_%temp_index%
			}
			WinActivate, % "ahk_id " AltTab_ID_List_FileExplorer_1
		} else if (AltTab_ID_List_FileExplorer_0 = 3) {
			Loop, %AltTab_ID_List_FileExplorer_0% {
				AltTab_ID_List_FileExplorer_%A_Index%_w_norm := AltTab_ID_List_FileExplorer_%A_Index%_w*monitor_%monitor_no_prm%_workarea_ratio
				AltTab_ID_List_FileExplorer_%A_Index%_h_norm := AltTab_ID_List_FileExplorer_%A_Index%_h
				AltTab_ID_List_FileExplorer_sortDsc_w_norm_%A_Index% := AltTab_ID_List_FileExplorer_%A_Index%_w_norm 	; preparation for sorting
				AltTab_ID_List_FileExplorer_sortDsc_h_norm_%A_Index% := AltTab_ID_List_FileExplorer_%A_Index%_h_norm	; preparation for sorting
				AltTab_ID_List_FileExplorer_sortDsc_w_norm_%A_Index%_ID := AltTab_ID_List_FileExplorer_%A_Index%  		; preparation for sorting - assigning ID
				AltTab_ID_List_FileExplorer_sortDsc_h_norm_%A_Index%_ID := AltTab_ID_List_FileExplorer_%A_Index%  		; preparation for sorting - assigning ID
			}

			; to sort
			Loop, % AltTab_ID_List_FileExplorer_0 - 1 {
				Loop, % AltTab_ID_List_FileExplorer_0 - A_Index {
					nextIndex := A_Index + 1
					if (AltTab_ID_List_FileExplorer_sortDsc_w_norm_%A_Index% < AltTab_ID_List_FileExplorer_sortDsc_w_norm_%nextIndex%) {
						swap := AltTab_ID_List_FileExplorer_sortDsc_w_norm_%A_Index%
						AltTab_ID_List_FileExplorer_sortDsc_w_norm_%A_Index% := AltTab_ID_List_FileExplorer_sortDsc_w_norm_%nextIndex%
						AltTab_ID_List_FileExplorer_sortDsc_w_norm_%nextIndex% := swap
						swap := AltTab_ID_List_FileExplorer_sortDsc_w_norm_%A_Index%_ID 														; assigning ID
						AltTab_ID_List_FileExplorer_sortDsc_w_norm_%A_Index%_ID := AltTab_ID_List_FileExplorer_sortDsc_w_norm_%nextIndex%_ID 	; assigning ID
						AltTab_ID_List_FileExplorer_sortDsc_w_norm_%nextIndex%_ID := swap  														; assigning ID
					}
					if (AltTab_ID_List_FileExplorer_sortDsc_h_norm_%A_Index% < AltTab_ID_List_FileExplorer_sortDsc_h_norm_%nextIndex%) {
						swap := AltTab_ID_List_FileExplorer_sortDsc_h_norm_%A_Index%
						AltTab_ID_List_FileExplorer_sortDsc_h_norm_%A_Index% := AltTab_ID_List_FileExplorer_sortDsc_h_norm_%nextIndex%
						AltTab_ID_List_FileExplorer_sortDsc_h_norm_%nextIndex% := swap
						swap := AltTab_ID_List_FileExplorer_sortDsc_h_norm_%A_Index%_ID 														; assigning ID
						AltTab_ID_List_FileExplorer_sortDsc_h_norm_%A_Index%_ID := AltTab_ID_List_FileExplorer_sortDsc_h_norm_%nextIndex%_ID 	; assigning ID
						AltTab_ID_List_FileExplorer_sortDsc_h_norm_%nextIndex%_ID := swap  														; assigning ID
					}
				}
			}
				
			Loop, % AltTab_ID_List_FileExplorer_0 {
				WinGetPos, temp_x, temp_y, temp_w, temp_h, % "ahk_id " AltTab_ID_List_FileExplorer_sortDsc_w_norm_%A_Index%_ID
				;AltTab_ID_List_FileExplorer_sortDsc_w_norm_%A_Index%_x := temp_x*monitor_%monitor_no_prm%_workarea_ratio
				AltTab_ID_List_FileExplorer_sortDsc_w_norm_%A_Index%_y := temp_y
				AltTab_ID_List_FileExplorer_sortDsc_w_norm_%A_Index%_w := temp_w*monitor_%monitor_no_prm%_workarea_ratio 	; Actually AltTab_ID_List_FileExplorer_sortDsc_w_norm_%A_Index% = AltTab_ID_List_FileExplorer_sortDsc_w_norm_%A_Index%_w
				AltTab_ID_List_FileExplorer_sortDsc_w_norm_%A_Index%_h := temp_h
				WinGetPos, temp_x, temp_y, temp_w, temp_h, % "ahk_id " AltTab_ID_List_FileExplorer_sortDsc_h_norm_%A_Index%_ID
				;AltTab_ID_List_FileExplorer_sortDsc_h_norm_%A_Index%_x := temp_x*monitor_%monitor_no_prm%_workarea_ratio
				AltTab_ID_List_FileExplorer_sortDsc_h_norm_%A_Index%_y := temp_y
				AltTab_ID_List_FileExplorer_sortDsc_h_norm_%A_Index%_w := temp_w*monitor_%monitor_no_prm%_workarea_ratio 	
				AltTab_ID_List_FileExplorer_sortDsc_h_norm_%A_Index%_h := temp_h	; Actually AltTab_ID_List_FileExplorer_sortDsc_h_norm_%A_Index% = AltTab_ID_List_FileExplorer_sortDsc_h_norm_%A_Index%_w
			}
			;;;;;;;;;;;;;;;;;;;;;;;;;; sorting is done.


			if (AltTab_ID_List_FileExplorer_sortDsc_w_norm_1 > AltTab_ID_List_FileExplorer_sortDsc_h_norm_1) { 	; horizontal max is bigger than vertical max (in normalized values)

				FExpStack_bottomFExp := AltTab_ID_List_FileExplorer_sortDsc_w_norm_1_ID
				FExpStack_bottomFExp_w_norm := AltTab_ID_List_FileExplorer_sortDsc_w_norm_1_w
				FExpStack_bottomFExp_h_norm := AltTab_ID_List_FileExplorer_sortDsc_w_norm_1_h
				FExpStack_leftFExp := ""
				FExpStack_rightFExp := ""

				sum_theOthers_w_norm := 0 	; sum of all the widths except the longest one.
				Loop, % AltTab_ID_List_FileExplorer_0 - 1 {
					nextIndex := A_Index + 1
					sum_theOthers_w_norm += AltTab_ID_List_FileExplorer_sortDsc_w_norm_%nextIndex%
				}
				over_w_norm := sum_theOthers_w_norm - monitor_%monitor_no_prm%_workarea_width*monitor_%monitor_no_prm%_workarea_ratio > 0 ? sum_theOthers_w_norm - monitor_%monitor_no_prm%_workarea_width*monitor_%monitor_no_prm%_workarea_ratio : 0
				horizontalLength_norm_net := sum_theOthers_w_norm - over_w_norm > AltTab_ID_List_FileExplorer_sortDsc_w_norm_1 ? sum_theOthers_w_norm - over_w_norm : AltTab_ID_List_FileExplorer_sortDsc_w_norm_1
				horizontalLength_norm_net := horizontalLength_norm_net < monitor_%monitor_no_prm%_workarea_width ? horizontalLength_norm_net : monitor_%monitor_no_prm%_workarea_width 	; in case AltTab_ID_List_FileExplorer_sortDsc_w_norm_1 > monitor_%monitor_no_prm%_workarea_width

				if (AltTab_ID_List_FileExplorer_sortDsc_w_norm_1_ID = AltTab_ID_List_FileExplorer_sortDsc_h_norm_1_ID) { 	; That window has the longest width and the longest height.
					FExpStack_rightFExp := AltTab_ID_List_FileExplorer_sortDsc_h_norm_2_ID
					FExpStack_rightFExp_w_norm := AltTab_ID_List_FileExplorer_sortDsc_h_norm_2_w
					FExpStack_rightFExp_h_norm := AltTab_ID_List_FileExplorer_sortDsc_h_norm_2_h
					FExpStack_leftFExp := AltTab_ID_List_FileExplorer_sortDsc_h_norm_3_ID
					FExpStack_leftFExp_w_norm := AltTab_ID_List_FileExplorer_sortDsc_h_norm_3_w
					FExpStack_leftFExp_h_norm := AltTab_ID_List_FileExplorer_sortDsc_h_norm_3_h

					verticalLength := AltTab_ID_List_FileExplorer_sortDsc_w_norm_1_h + AltTab_ID_List_FileExplorer_sortDsc_h_norm_2_h
					over_h := verticalLength - monitor_%monitor_no_prm%_workarea_height > 0 ? verticalLength - monitor_%monitor_no_prm%_workarea_height : 0
					verticalLength_net := verticalLength - over_h

;;;;;===================================00000000000000000000000000000
				} else { 	; That window has the longest width but not the longest height.
					FExpStack_rightFExp := AltTab_ID_List_FileExplorer_sortDsc_h_norm_1_ID
					FExpStack_rightFExp_w_norm := AltTab_ID_List_FileExplorer_sortDsc_h_norm_1_w
					FExpStack_rightFExp_h_norm := AltTab_ID_List_FileExplorer_sortDsc_h_norm_1_h
					; to find the remaining ID which should be at the upper left position.
					Loop, % AltTab_ID_List_FileExplorer_0 {
						if ((AltTab_ID_List_FileExplorer_%A_Index% != FExpStack_rightFExp) and (AltTab_ID_List_FileExplorer_%A_Index% != FExpStack_bottomFExp)) {
							FExpStack_leftFExp := AltTab_ID_List_FileExplorer_%A_Index%
							FExpStack_leftFExp_w_norm := AltTab_ID_List_FileExplorer_%A_Index%_w_norm
							FExpStack_leftFExp_h_norm := AltTab_ID_List_FileExplorer_%A_Index%_h_norm
							Break
						}
					}

					verticalLength := AltTab_ID_List_FileExplorer_sortDsc_w_norm_1_h + AltTab_ID_List_FileExplorer_sortDsc_h_norm_1_h
					over_h := verticalLength - monitor_%monitor_no_prm%_workarea_height > 0 ? verticalLength - monitor_%monitor_no_prm%_workarea_height : 0
					verticalLength_net := verticalLength - over_h

				}
;;;;;===================================00000000000000000000000000000
				
				if (((over_w_norm > 0) and !(over_h > 0)) or ((over_w_norm > 0) and (over_h > 0))) {
					WinMove, % "ahk_id " FExpStack_leftFExp, , monitor_%monitor_no_prm%_workarea_left, monitor_%monitor_no_prm%_workarea_top
					WinMove, % "ahk_id " FExpStack_bottomFExp, , monitor_%monitor_no_prm%_workarea_left, monitor_%monitor_no_prm%_workarea_bottom - FExpStack_bottomFExp_h_norm 	; FExpStack_bottomFExp = AltTab_ID_List_FileExplorer_sortDsc_w_norm_1_ID
					FExpStack_rightFExp_yAdj := (AltTab_ID_List_FileExplorer_all_h - monitor_%monitor_no_prm%_workarea_height)/2 * 1.5 	; 1.5 is an adjustment ratio
					WinMove, % "ahk_id " FExpStack_rightFExp, , monitor_%monitor_no_prm%_workarea_right - FExpStack_rightFExp_w_norm/monitor_%monitor_no_prm%_workarea_ratio, FExpStack_leftFExp_h_norm - FExpStack_rightFExp_yAdj
				} else if (!(over_w_norm > 0) and (over_h > 0)) {
					if ((FExpStack_leftFExp_h_norm + FExpStack_bottomFExp_h_norm) < monitor_%monitor_no_prm%_workarea_height) {
						WinMove, % "ahk_id " FExpStack_leftFExp, , monitor_%monitor_no_prm%_workarea_right - (FExpStack_rightFExp_w_norm + FExpStack_leftFExp_w_norm)/monitor_%monitor_no_prm%_workarea_ratio, monitor_%monitor_no_prm%_workarea_bottom - FExpStack_bottomFExp_h_norm - FExpStack_leftFExp_h_norm
					} else {
						WinMove, % "ahk_id " FExpStack_leftFExp, , monitor_%monitor_no_prm%_workarea_right - (FExpStack_rightFExp_w_norm + FExpStack_leftFExp_w_norm)/monitor_%monitor_no_prm%_workarea_ratio, monitor_%monitor_no_prm%_workarea_top
					}
					WinMove, % "ahk_id " FExpStack_bottomFExp, , monitor_%monitor_no_prm%_workarea_left, monitor_%monitor_no_prm%_workarea_bottom - FExpStack_bottomFExp_h_norm 	; FExpStack_bottomFExp = AltTab_ID_List_FileExplorer_sortDsc_w_norm_1_ID
					WinMove, % "ahk_id " FExpStack_rightFExp, , monitor_%monitor_no_prm%_workarea_right - FExpStack_rightFExp_w_norm/monitor_%monitor_no_prm%_workarea_ratio, monitor_%monitor_no_prm%_workarea_top
				;} else if ((over_w_norm > 0) and (over_h > 0)) {
				} else if (!(over_w_norm > 0) and !(over_h > 0)) {
					;ToolTip, % "over_w_norm " over_w_norm " FExpStack_rightFExp_yAdj " FExpStack_rightFExp_yAdj 
					spreadFExp_left := monitor_%monitor_no_prm%_workarea_center_x - horizontalLength_norm_net/monitor_%monitor_no_prm%_workarea_ratio/2
					spreadFExp_top := monitor_%monitor_no_prm%_workarea_center_y - verticalLength_net/2
					spreadFExp_right := spreadFExp_left + horizontalLength_norm_net/monitor_%monitor_no_prm%_workarea_ratio
					spreadFExp_bottom := spreadFExp_top + verticalLength_net

					WinMove, % "ahk_id " FExpStack_leftFExp, , spreadFExp_right - (FExpStack_rightFExp_w_norm + FExpStack_leftFExp_w_norm)/monitor_%monitor_no_prm%_workarea_ratio, spreadFExp_bottom - FExpStack_bottomFExp_h_norm - FExpStack_leftFExp_h_norm
					WinMove, % "ahk_id " FExpStack_bottomFExp, , spreadFExp_left, spreadFExp_bottom - FExpStack_bottomFExp_h_norm 	; FExpStack_bottomFExp = AltTab_ID_List_FileExplorer_sortDsc_w_norm_1_ID
					WinMove, % "ahk_id " FExpStack_rightFExp, , spreadFExp_right - FExpStack_rightFExp_w_norm/monitor_%monitor_no_prm%_workarea_ratio, spreadFExp_top
				}
				

				WinSet, AlwaysOnTop, On, % "ahk_id " FExpStack_leftFExp
				WinSet, AlwaysOnTop, Off, % "ahk_id " FExpStack_leftFExp
				WinSet, AlwaysOnTop, On, % "ahk_id " FExpStack_rightFExp
				WinSet, AlwaysOnTop, Off, % "ahk_id " FExpStack_rightFExp
				WinSet, AlwaysOnTop, On, % "ahk_id " FExpStack_bottomFExp
				WinSet, AlwaysOnTop, Off, % "ahk_id " FExpStack_bottomFExp
				WinActivate, % "ahk_id " AltTab_ID_List_FileExplorer_1

;;;;;===================================00000000000000000000000000000

			} else { 	; vertical max is bigger than horizontal max
				FExpStack_rightFExp := AltTab_ID_List_FileExplorer_sortDsc_h_norm_1_ID
				FExpStack_rightFExp_h_norm := AltTab_ID_List_FileExplorer_sortDsc_h_norm_1_h
				FExpStack_rightFExp_w_norm := AltTab_ID_List_FileExplorer_sortDsc_h_norm_1_w
				FExpStack_topFExp := ""
				FExpStack_bottomFExp := ""

				sum_theOthers_h := 0 	; sum of all the widths except the longest one.
				Loop, % AltTab_ID_List_FileExplorer_0 - 1 {
					nextIndex := A_Index + 1
					sum_theOthers_h += AltTab_ID_List_FileExplorer_sortDsc_h_norm_%nextIndex%
				}
				over_h := sum_theOthers_h - monitor_%monitor_no_prm%_workarea_height > 0 ? sum_theOthers_h - monitor_%monitor_no_prm%_workarea_height : 0
				verticalLength_net := sum_theOthers_h - over_h > AltTab_ID_List_FileExplorer_sortDsc_h_norm_1 ? sum_theOthers_h - over_h : AltTab_ID_List_FileExplorer_sortDsc_h_norm_1
				verticalLength_net := verticalLength_net < monitor_%monitor_no_prm%_workarea_height ? verticalLength_net : monitor_%monitor_no_prm%_workarea_height 	; in case AltTab_ID_List_FileExplorer_sortDsc_h_norm_1 > monitor_%monitor_no_prm%_workarea_height

				if (AltTab_ID_List_FileExplorer_sortDsc_h_norm_1_ID = AltTab_ID_List_FileExplorer_sortDsc_w_norm_1_ID) { 	; That window has the longest width and the longest height.
					FExpStack_bottomFExp := AltTab_ID_List_FileExplorer_sortDsc_w_norm_2_ID
					FExpStack_bottomFExp_h_norm := AltTab_ID_List_FileExplorer_sortDsc_w_norm_2_h
					FExpStack_bottomFExp_w_norm := AltTab_ID_List_FileExplorer_sortDsc_w_norm_2_w
					FExpStack_topFExp := AltTab_ID_List_FileExplorer_sortDsc_w_norm_3_ID
					FExpStack_topFExp_h_norm := AltTab_ID_List_FileExplorer_sortDsc_w_norm_3_h
					FExpStack_topFExp_w_norm := AltTab_ID_List_FileExplorer_sortDsc_w_norm_3_w

					horizontalLength_norm := AltTab_ID_List_FileExplorer_sortDsc_h_norm_1_w + AltTab_ID_List_FileExplorer_sortDsc_w_norm_2_w
					over_w_norm := horizontalLength_norm - monitor_%monitor_no_prm%_workarea_width * monitor_%monitor_no_prm%_workarea_ratio > 0 ? horizontalLength_norm - monitor_%monitor_no_prm%_workarea_width * monitor_%monitor_no_prm%_workarea_ratio : 0
					horizontalLength_norm_net := horizontalLength_norm - over_w_norm

;;;;;===================================00000000000000000000000000000
				} else { 	; That window has the longest width but not the longest height.
					FExpStack_bottomFExp := AltTab_ID_List_FileExplorer_sortDsc_w_norm_1_ID
					FExpStack_bottomFExp_h_norm := AltTab_ID_List_FileExplorer_sortDsc_w_norm_1_h
					FExpStack_bottomFExp_w_norm := AltTab_ID_List_FileExplorer_sortDsc_w_norm_1_w
					; to find the remaining ID which should be at the upper left position.
					Loop, % AltTab_ID_List_FileExplorer_0 {
						if ((AltTab_ID_List_FileExplorer_%A_Index% != FExpStack_bottomFExp) and (AltTab_ID_List_FileExplorer_%A_Index% != FExpStack_rightFExp)) {
							FExpStack_topFExp := AltTab_ID_List_FileExplorer_%A_Index%
							FExpStack_topFExp_h_norm := AltTab_ID_List_FileExplorer_%A_Index%_h_norm
							FExpStack_topFExp_w_norm := AltTab_ID_List_FileExplorer_%A_Index%_w_norm
							Break
						}
					}

					horizontalLength_norm := AltTab_ID_List_FileExplorer_sortDsc_h_norm_1_w + AltTab_ID_List_FileExplorer_sortDsc_w_norm_1_w
					over_w_norm := horizontalLength_norm - monitor_%monitor_no_prm%_workarea_width * monitor_%monitor_no_prm%_workarea_ratio > 0 ? horizontalLength_norm - monitor_%monitor_no_prm%_workarea_width * monitor_%monitor_no_prm%_workarea_ratio : 0
					horizontalLength_norm_net := horizontalLength_norm - over_w_norm

				}
;;;;;===================================00000000000000000000000000000
				
				if (((over_h > 0) and !(over_w_norm > 0)) or ((over_h > 0) and (over_w_norm > 0))) {
					WinMove, % "ahk_id " FExpStack_topFExp, , monitor_%monitor_no_prm%_workarea_left, monitor_%monitor_no_prm%_workarea_top
					WinMove, % "ahk_id " FExpStack_rightFExp, , monitor_%monitor_no_prm%_workarea_right - FExpStack_rightFExp_w_norm / monitor_%monitor_no_prm%_workarea_ratio, monitor_%monitor_no_prm%_workarea_top
					FExpStack_bottomFExp_xAdj := (AltTab_ID_List_FileExplorer_all_w - monitor_%monitor_no_prm%_workarea_width)/2 * 1.5 	; 1.5 is an adjustment ratio. It's not a normalized value
					WinMove, % "ahk_id " FExpStack_bottomFExp, , FExpStack_topFExp_w_norm / monitor_%monitor_no_prm%_workarea_ratio - FExpStack_bottomFExp_xAdj, monitor_%monitor_no_prm%_workarea_bottom - FExpStack_bottomFExp_h_norm
				} else if (!(over_h > 0) and (over_w_norm > 0)) {
					if ((FExpStack_topFExp_w_norm + FExpStack_rightFExp_w_norm) < monitor_%monitor_no_prm%_workarea_width * monitor_%monitor_no_prm%_workarea_ratio) {
						WinMove, % "ahk_id " FExpStack_topFExp, , monitor_%monitor_no_prm%_workarea_right - (FExpStack_rightFExp_w_norm + FExpStack_topFExp_w_norm) /  monitor_%monitor_no_prm%_workarea_ratio, monitor_%monitor_no_prm%_workarea_bottom - (FExpStack_bottomFExp_h_norm + FExpStack_topFExp_h_norm)
					} else {
						WinMove, % "ahk_id " FExpStack_topFExp, , monitor_%monitor_no_prm%_workarea_left, monitor_%monitor_no_prm%_workarea_bottom - (FExpStack_bottomFExp_h_norm + FExpStack_topFExp_h_norm)
					}
					WinMove, % "ahk_id " FExpStack_rightFExp, , monitor_%monitor_no_prm%_workarea_right - FExpStack_rightFExp_w_norm / monitor_%monitor_no_prm%_workarea_ratio, monitor_%monitor_no_prm%_workarea_top
					WinMove, % "ahk_id " FExpStack_bottomFExp, , monitor_%monitor_no_prm%_workarea_left, monitor_%monitor_no_prm%_workarea_bottom - FExpStack_bottomFExp_h_norm
				;} else if ((over_h > 0) and (over_w_norm > 0)) {
				} else if (!(over_h > 0) and !(over_w_norm > 0)) {
					;ToolTip, % "over_h " over_h " FExpStack_bottomFExp_xAdj " FExpStack_bottomFExp_xAdj 
					spreadFExp_top := monitor_%monitor_no_prm%_workarea_center_y - verticalLength_net / 2
					spreadFExp_left := monitor_%monitor_no_prm%_workarea_center_x - horizontalLength_norm_net / monitor_%monitor_no_prm%_workarea_ratio / 2 	; It's not a normalized value
					spreadFExp_bottom := spreadFExp_top + verticalLength_net
					spreadFExp_right := spreadFExp_left + horizontalLength_norm_net / monitor_%monitor_no_prm%_workarea_ratio

					WinMove, % "ahk_id " FExpStack_topFExp, , spreadFExp_right - (FExpStack_rightFExp_w_norm + FExpStack_topFExp_w_norm) / monitor_%monitor_no_prm%_workarea_ratio, spreadFExp_bottom - (FExpStack_bottomFExp_h_norm + FExpStack_topFExp_h_norm)
					WinMove, % "ahk_id " FExpStack_rightFExp, , spreadFExp_right - FExpStack_rightFExp_w_norm / monitor_%monitor_no_prm%_workarea_ratio, spreadFExp_left
					WinMove, % "ahk_id " FExpStack_bottomFExp, , spreadFExp_left, spreadFExp_bottom - FExpStack_bottomFExp_h_norm
				}
				

				WinSet, AlwaysOnTop, On, % "ahk_id " FExpStack_topFExp
				WinSet, AlwaysOnTop, Off, % "ahk_id " FExpStack_topFExp
				WinSet, AlwaysOnTop, On, % "ahk_id " FExpStack_bottomFExp
				WinSet, AlwaysOnTop, Off, % "ahk_id " FExpStack_bottomFExp
				WinSet, AlwaysOnTop, On, % "ahk_id " FExpStack_rightFExp
				WinSet, AlwaysOnTop, Off, % "ahk_id " FExpStack_rightFExp
				WinActivate, % "ahk_id " AltTab_ID_List_FileExplorer_1

;;;;;===================================00000000000000000000000000000
			}
		} else if (AltTab_ID_List_FileExplorer_0 = 4) {
			;   (1,2)-(2,2)  1 - 2
			;   (1,1)-(2,1)  4 - 3

			; sort by height descending
			; to sort AltTab_ID_List_FileExplorer_sortDsc_h_%A_Index%_h
			Loop, %AltTab_ID_List_FileExplorer_0% {
				AltTab_ID_List_FileExplorer_sortDsc_h_%A_Index%_h := AltTab_ID_List_FileExplorer_%A_Index%_h	; preparation for sorting
				AltTab_ID_List_FileExplorer_sortDsc_h_%A_Index%_ID := AltTab_ID_List_FileExplorer_%A_Index%  		; preparation for sorting - assigning ID
			}
			Loop, % AltTab_ID_List_FileExplorer_0 - 1 {
				Loop, % AltTab_ID_List_FileExplorer_0 - A_Index {
					nextIndex := A_Index + 1
					if (AltTab_ID_List_FileExplorer_sortDsc_h_%A_Index%_h < AltTab_ID_List_FileExplorer_sortDsc_h_%nextIndex%_h) {
						swap := AltTab_ID_List_FileExplorer_sortDsc_h_%A_Index%_h
						AltTab_ID_List_FileExplorer_sortDsc_h_%A_Index%_h := AltTab_ID_List_FileExplorer_sortDsc_h_%nextIndex%_h
						AltTab_ID_List_FileExplorer_sortDsc_h_%nextIndex%_h := swap
						swap := AltTab_ID_List_FileExplorer_sortDsc_h_%A_Index%_ID 														; assigning ID
						AltTab_ID_List_FileExplorer_sortDsc_h_%A_Index%_ID := AltTab_ID_List_FileExplorer_sortDsc_h_%nextIndex%_ID 		; assigning ID
						AltTab_ID_List_FileExplorer_sortDsc_h_%nextIndex%_ID := swap  													; assigning ID
					}
				}
			}
			Loop, % AltTab_ID_List_FileExplorer_0 {
				WinGetPos, , , temp_w, , % "ahk_id " AltTab_ID_List_FileExplorer_sortDsc_h_%A_Index%_ID
				AltTab_ID_List_FileExplorer_sortDsc_h_%A_Index%_w := temp_w 	
			}
			;;;;;;;;;;;;;;;;;;;;;;;;;; sorting is done.

			; From now on, working with location-based windows
			; initial setting: 4 windows (all edges) are all put together at the center of the screen
			spreadFExp_4_1_1_ID := AltTab_ID_List_FileExplorer_sortDsc_h_4_ID
			spreadFExp_4_1_1_w := AltTab_ID_List_FileExplorer_sortDsc_h_4_w
			spreadFExp_4_1_1_h := AltTab_ID_List_FileExplorer_sortDsc_h_4_h
			spreadFExp_4_1_1_x := monitor_%monitor_no_prm%_workarea_center_x - spreadFExp_4_1_1_w
			spreadFExp_4_1_1_y := monitor_%monitor_no_prm%_workarea_center_y 

			spreadFExp_4_2_1_ID := AltTab_ID_List_FileExplorer_sortDsc_h_3_ID
			spreadFExp_4_2_1_w := AltTab_ID_List_FileExplorer_sortDsc_h_3_w
			spreadFExp_4_2_1_h := AltTab_ID_List_FileExplorer_sortDsc_h_3_h
			spreadFExp_4_2_1_x := monitor_%monitor_no_prm%_workarea_center_x
			spreadFExp_4_2_1_y := monitor_%monitor_no_prm%_workarea_center_y

			spreadFExp_4_1_2_ID := AltTab_ID_List_FileExplorer_sortDsc_h_1_ID
			spreadFExp_4_1_2_w := AltTab_ID_List_FileExplorer_sortDsc_h_1_w
			spreadFExp_4_1_2_h := AltTab_ID_List_FileExplorer_sortDsc_h_1_h
			spreadFExp_4_1_2_x := monitor_%monitor_no_prm%_workarea_center_x - spreadFExp_4_1_2_w
			spreadFExp_4_1_2_y := monitor_%monitor_no_prm%_workarea_center_y - spreadFExp_4_1_2_h

			spreadFExp_4_2_2_ID := AltTab_ID_List_FileExplorer_sortDsc_h_2_ID
			spreadFExp_4_2_2_w := AltTab_ID_List_FileExplorer_sortDsc_h_2_w
			spreadFExp_4_2_2_h := AltTab_ID_List_FileExplorer_sortDsc_h_2_h
			spreadFExp_4_2_2_x := monitor_%monitor_no_prm%_workarea_center_x
			spreadFExp_4_2_2_y := monitor_%monitor_no_prm%_workarea_center_y - spreadFExp_4_2_2_h

			; Compare left and right on each row, and put a wider one on the left.
			if (spreadFExp_4_1_1_w < spreadFExp_4_2_1_w) {
				swap := spreadFExp_4_1_1_ID
				spreadFExp_4_1_1_ID := spreadFExp_4_2_1_ID
				spreadFExp_4_2_1_ID := swap
				swap := spreadFExp_4_1_1_w
				spreadFExp_4_1_1_w := spreadFExp_4_2_1_w
				spreadFExp_4_2_1_w := swap
				swap := spreadFExp_4_1_1_h
				spreadFExp_4_1_1_h := spreadFExp_4_2_1_h
				spreadFExp_4_2_1_h := swap

				spreadFExp_4_1_1_x := monitor_%monitor_no_prm%_workarea_center_x - spreadFExp_4_1_1_w
				spreadFExp_4_1_1_y := monitor_%monitor_no_prm%_workarea_center_y 
				spreadFExp_4_2_1_x := monitor_%monitor_no_prm%_workarea_center_x
				spreadFExp_4_2_1_y := monitor_%monitor_no_prm%_workarea_center_y
			}
			if (spreadFExp_4_1_2_w < spreadFExp_4_2_2_w) {
				swap := spreadFExp_4_1_2_ID
				spreadFExp_4_1_2_ID := spreadFExp_4_2_2_ID
				spreadFExp_4_2_2_ID := swap
				swap := spreadFExp_4_1_2_w
				spreadFExp_4_1_2_w := spreadFExp_4_2_2_w
				spreadFExp_4_2_2_w := swap
				swap := spreadFExp_4_1_2_h
				spreadFExp_4_1_2_h := spreadFExp_4_2_2_h
				spreadFExp_4_2_2_h := swap

				spreadFExp_4_1_2_x := monitor_%monitor_no_prm%_workarea_center_x - spreadFExp_4_1_2_w
				spreadFExp_4_1_2_y := monitor_%monitor_no_prm%_workarea_center_y - spreadFExp_4_1_2_h
				spreadFExp_4_2_2_x := monitor_%monitor_no_prm%_workarea_center_x
				spreadFExp_4_2_2_y := monitor_%monitor_no_prm%_workarea_center_y - spreadFExp_4_2_2_h
			}

			; Adjusting process starts.

			;  - Adjusting x axis direction

			; first. Check if only one of the two bottom windows is wider than the half width of the screen
			if (((spreadFExp_4_1_1_w > monitor_%monitor_no_prm%_workarea_width / 2) and !(spreadFExp_4_2_1_w > monitor_%monitor_no_prm%_workarea_width / 2)) or (!(spreadFExp_4_1_1_w > monitor_%monitor_no_prm%_workarea_width / 2) and (spreadFExp_4_2_1_w > monitor_%monitor_no_prm%_workarea_width / 2))) {
				; sum of the two widths are bigger than the screen
				if (spreadFExp_4_1_1_w + spreadFExp_4_2_1_w > monitor_%monitor_no_prm%_workarea_width) { 	
					spreadFExp_4_1_1_x := monitor_%monitor_no_prm%_workarea_left 	; This is actually useless because it's useful when the right window may be longer than the left one.
					spreadFExp_4_2_1_x := monitor_%monitor_no_prm%_workarea_center_x > monitor_%monitor_no_prm%_workarea_right - spreadFExp_4_2_1_w ? monitor_%monitor_no_prm%_workarea_center_x : monitor_%monitor_no_prm%_workarea_right - spreadFExp_4_2_1_w 	; This is actually useless because it's useful when the right window may be longer than the left one.
				} else {
					spreadFExp_4_1_1_x := monitor_%monitor_no_prm%_workarea_left
					spreadFExp_4_2_1_x := spreadFExp_4_1_1_x + spreadFExp_4_1_1_w
				}
			} 
			; Check if both are wider than half width of the screen
			else if ((spreadFExp_4_1_1_w > monitor_%monitor_no_prm%_workarea_width / 2) and (spreadFExp_4_2_1_w > monitor_%monitor_no_prm%_workarea_width / 2)) {
				spreadFExp_4_1_1_x := monitor_%monitor_no_prm%_workarea_left
				spreadFExp_4_2_1_x := monitor_%monitor_no_prm%_workarea_center_x
			}

			; Second. Check if only one of the two upper windows is wider than the half width of the screen
			if (((spreadFExp_4_1_2_w > monitor_%monitor_no_prm%_workarea_width / 2) and !(spreadFExp_4_2_2_w > monitor_%monitor_no_prm%_workarea_width / 2)) or (!(spreadFExp_4_1_2_w > monitor_%monitor_no_prm%_workarea_width / 2) and (spreadFExp_4_2_2_w > monitor_%monitor_no_prm%_workarea_width / 2))) {
				if (spreadFExp_4_1_2_w + spreadFExp_4_2_2_w > monitor_%monitor_no_prm%_workarea_width) { 	
					spreadFExp_4_1_2_x := monitor_%monitor_no_prm%_workarea_left 	; This is actually useless because it's useful when the right window may be longer than the left one.
					spreadFExp_4_2_2_x := spreadFExp_4_2_2_w > monitor_%monitor_no_prm%_workarea_width / 2 ? monitor_%monitor_no_prm%_workarea_center_x : monitor_%monitor_no_prm%_workarea_right - spreadFExp_4_2_2_w 	; This is actually useless because it's useful when the right window may be longer than the left one.
				} else {
					spreadFExp_4_1_2_x := monitor_%monitor_no_prm%_workarea_left
					spreadFExp_4_2_2_x := spreadFExp_4_1_2_x + spreadFExp_4_1_2_w
				}
			}
			; Check if both are wider than half width of the screen
			else if ((spreadFExp_4_1_2_w > monitor_%monitor_no_prm%_workarea_width / 2) and (spreadFExp_4_2_2_w > monitor_%monitor_no_prm%_workarea_width / 2)) {
				spreadFExp_4_1_2_x := monitor_%monitor_no_prm%_workarea_left
				spreadFExp_4_2_2_x := monitor_%monitor_no_prm%_workarea_center_x
			}

			;  - Adjusting y axis direction

			; first. Check if only one of the two bottom windows is wider than the half width of the screen
			if (((spreadFExp_4_1_2_h > monitor_%monitor_no_prm%_workarea_height / 2) and !(spreadFExp_4_1_1_h > monitor_%monitor_no_prm%_workarea_height / 2)) or (!(spreadFExp_4_1_2_h > monitor_%monitor_no_prm%_workarea_height / 2) and (spreadFExp_4_1_1_h > monitor_%monitor_no_prm%_workarea_height / 2))) {
				; sum of the two widths are bigger than the screen
				if (spreadFExp_4_1_2_h + spreadFExp_4_1_1_h > monitor_%monitor_no_prm%_workarea_height) {
					spreadFExp_4_1_2_y := monitor_%monitor_no_prm%_workarea_top 	; Like the x axis direction case, this and following line are useless because the upper window is already has longer height
					spreadFExp_4_1_1_y := monitor_%monitor_no_prm%_workarea_center_y > monitor_%monitor_no_prm%_workarea_bottom - spreadFExp_4_1_1_h ? monitor_%monitor_no_prm%_workarea_center_y : monitor_%monitor_no_prm%_workarea_bottom - spreadFExp_4_1_1_h
				} else {
					spreadFExp_4_1_2_y := monitor_%monitor_no_prm%_workarea_top
					spreadFExp_4_1_1_y := spreadFExp_4_1_2_y + spreadFExp_4_1_2_h
				}
			} 
			; Check if both are wider than half width of the screen
			else if ((spreadFExp_4_1_2_h > monitor_%monitor_no_prm%_workarea_height / 2) and (spreadFExp_4_1_1_h > monitor_%monitor_no_prm%_workarea_height / 2)) {
				spreadFExp_4_1_2_y := monitor_%monitor_no_prm%_workarea_top
				spreadFExp_4_1_1_y := monitor_%monitor_no_prm%_workarea_center_y
			}

			; Second. Check if only one of the two upper windows is wider than the half width of the screen
			if (((spreadFExp_4_2_2_h > monitor_%monitor_no_prm%_workarea_height / 2) and !(spreadFExp_4_2_1_h > monitor_%monitor_no_prm%_workarea_height / 2)) or (!(spreadFExp_4_2_2_h > monitor_%monitor_no_prm%_workarea_height / 2) and (spreadFExp_4_2_1_h > monitor_%monitor_no_prm%_workarea_height / 2))) {
				if (spreadFExp_4_2_2_h + spreadFExp_4_2_1_h > monitor_%monitor_no_prm%_workarea_height) {
					spreadFExp_4_2_2_y := monitor_%monitor_no_prm%_workarea_top 	; Like the x axis direction case, this and following line are useless because the upper window is already has longer height
					spreadFExp_4_2_1_y := spreadFExp_4_2_1_h > monitor_%monitor_no_prm%_workarea_height / 2 ? monitor_%monitor_no_prm%_workarea_center_y : monitor_%monitor_no_prm%_workarea_bottom - spreadFExp_4_2_1_h
				} else {
					spreadFExp_4_2_2_y := monitor_%monitor_no_prm%_workarea_top
					spreadFExp_4_2_1_y := spreadFExp_4_2_2_y + spreadFExp_4_2_2_h
				}
			}
			; Check if both are wider than half width of the screen
			else if ((spreadFExp_4_2_2_h > monitor_%monitor_no_prm%_workarea_height / 2) and (spreadFExp_4_2_1_h > monitor_%monitor_no_prm%_workarea_height / 2)) {
				spreadFExp_4_2_2_y := monitor_%monitor_no_prm%_workarea_top
				spreadFExp_4_2_1_y := monitor_%monitor_no_prm%_workarea_center_y
			}

			; Adjusting done.

			; Now move and put windows

				WinMove, % "ahk_id " spreadFExp_4_1_1_ID, , spreadFExp_4_1_1_x, spreadFExp_4_1_1_y 
				WinMove, % "ahk_id " spreadFExp_4_1_2_ID, , spreadFExp_4_1_2_x, spreadFExp_4_1_2_y 
				WinMove, % "ahk_id " spreadFExp_4_2_1_ID, , spreadFExp_4_2_1_x, spreadFExp_4_2_1_y 
				WinMove, % "ahk_id " spreadFExp_4_2_2_ID, , spreadFExp_4_2_2_x, spreadFExp_4_2_2_y 
				
				

				WinSet, AlwaysOnTop, On, % "ahk_id " spreadFExp_4_1_2_ID
				WinSet, AlwaysOnTop, On, % "ahk_id " spreadFExp_4_2_2_ID
				WinSet, AlwaysOnTop, On, % "ahk_id " spreadFExp_4_1_1_ID
				WinSet, AlwaysOnTop, On, % "ahk_id " spreadFExp_4_2_1_ID
				WinSet, AlwaysOnTop, Off, % "ahk_id " spreadFExp_4_1_2_ID
				WinSet, AlwaysOnTop, Off, % "ahk_id " spreadFExp_4_2_2_ID
				WinSet, AlwaysOnTop, Off, % "ahk_id " spreadFExp_4_1_1_ID
				WinSet, AlwaysOnTop, Off, % "ahk_id " spreadFExp_4_2_1_ID

				WinActivate, % "ahk_id " AltTab_ID_List_FileExplorer_1


		} else if (AltTab_ID_List_FileExplorer_0 >= 5) {
			;   (1,2)-(2,2)   n - 3
			;       mid     ..,5,4      ; 1st one is the largest one. n-th one is the smallest one.         
			;   (1,1)-(2,1)   2 - 1

			FExp_onDiag_no := AltTab_ID_List_FileExplorer_0 - 4
			
			; sort by areas in descending order 
			; the last windows are smallest windows
			
			; preparation for sorting - assigning ID
		 	Loop, % AltTab_ID_List_FileExplorer_0 { 
				AltTab_ID_List_FileExplorer_sort_area_dsc_%A_Index%_ID := AltTab_ID_List_FileExplorer_%A_Index%  		
				AltTab_ID_List_FileExplorer_sort_area_dsc_%A_Index%_wh := AltTab_ID_List_FileExplorer_%A_Index%_w * AltTab_ID_List_FileExplorer_%A_Index%_h
			}
			Loop, % AltTab_ID_List_FileExplorer_0 - 1 {
				Loop, % AltTab_ID_List_FileExplorer_0 - A_Index {
					nextIndex := A_Index + 1
					if (AltTab_ID_List_FileExplorer_sort_area_dsc_%A_Index%_wh < AltTab_ID_List_FileExplorer_sort_area_dsc_%nextIndex%_wh) {
						swap := AltTab_ID_List_FileExplorer_sort_area_dsc_%A_Index%_wh
						AltTab_ID_List_FileExplorer_sort_area_dsc_%A_Index%_wh := AltTab_ID_List_FileExplorer_sort_area_dsc_%nextIndex%_wh
						AltTab_ID_List_FileExplorer_sort_area_dsc_%nextIndex%_wh := swap
						swap := AltTab_ID_List_FileExplorer_sort_area_dsc_%A_Index%_ID 														; assigning ID
						AltTab_ID_List_FileExplorer_sort_area_dsc_%A_Index%_ID := AltTab_ID_List_FileExplorer_sort_area_dsc_%nextIndex%_ID 					; assigning ID
						AltTab_ID_List_FileExplorer_sort_area_dsc_%nextIndex%_ID := swap  													; assigning ID
					}
				}
			}
			Loop, % AltTab_ID_List_FileExplorer_0 {
				WinGetPos, , , temp_w, temp_h , % "ahk_id " AltTab_ID_List_FileExplorer_sort_area_dsc_%A_Index%_ID
				AltTab_ID_List_FileExplorer_sort_area_dsc_%A_Index%_w := temp_w 	
				AltTab_ID_List_FileExplorer_sort_area_dsc_%A_Index%_h := temp_h
			}
			;;;;;;;;;;;;;;;;;;;;;;;;;; sorting is done.

			; 4th, 5th, ... , (n-1)th will be put diagonally.

			; From now on, working with location-based windows
			; initial setting: 4 windows are all put at the corner of the screen (differently from when there are only 4 windows)
			spreadFExp_4_1_1_ID := AltTab_ID_List_FileExplorer_sort_area_dsc_2_ID
			spreadFExp_4_1_1_w := AltTab_ID_List_FileExplorer_sort_area_dsc_2_w
			spreadFExp_4_1_1_h := AltTab_ID_List_FileExplorer_sort_area_dsc_2_h
			spreadFExp_4_1_1_x := monitor_%monitor_no_prm%_workarea_left
			spreadFExp_4_1_1_y := monitor_%monitor_no_prm%_workarea_bottom - spreadFExp_4_1_1_h 

			spreadFExp_4_2_1_ID := AltTab_ID_List_FileExplorer_sort_area_dsc_1_ID
			spreadFExp_4_2_1_w := AltTab_ID_List_FileExplorer_sort_area_dsc_1_w
			spreadFExp_4_2_1_h := AltTab_ID_List_FileExplorer_sort_area_dsc_1_h
			spreadFExp_4_2_1_x := monitor_%monitor_no_prm%_workarea_right - spreadFExp_4_2_1_w
			spreadFExp_4_2_1_y := monitor_%monitor_no_prm%_workarea_bottom - spreadFExp_4_2_1_h

			spreadFExp_4_1_2_ID := AltTab_ID_List_FileExplorer_sort_area_dsc_%AltTab_ID_List_FileExplorer_0%_ID
			spreadFExp_4_1_2_w := AltTab_ID_List_FileExplorer_sort_area_dsc_%AltTab_ID_List_FileExplorer_0%_w
			spreadFExp_4_1_2_h := AltTab_ID_List_FileExplorer_sort_area_dsc_%AltTab_ID_List_FileExplorer_0%_h
			spreadFExp_4_1_2_x := monitor_%monitor_no_prm%_workarea_left
			spreadFExp_4_1_2_y := monitor_%monitor_no_prm%_workarea_top

			spreadFExp_4_2_2_ID := AltTab_ID_List_FileExplorer_sort_area_dsc_3_ID
			spreadFExp_4_2_2_w := AltTab_ID_List_FileExplorer_sort_area_dsc_3_w
			spreadFExp_4_2_2_h := AltTab_ID_List_FileExplorer_sort_area_dsc_3_h
			spreadFExp_4_2_2_x := monitor_%monitor_no_prm%_workarea_right - spreadFExp_4_2_2_w
			spreadFExp_4_2_2_y := monitor_%monitor_no_prm%_workarea_top

			WinMove, % "ahk_id " spreadFExp_4_1_1_ID, , spreadFExp_4_1_1_x, spreadFExp_4_1_1_y 
			WinMove, % "ahk_id " spreadFExp_4_1_2_ID, , spreadFExp_4_1_2_x, spreadFExp_4_1_2_y 
			WinMove, % "ahk_id " spreadFExp_4_2_1_ID, , spreadFExp_4_2_1_x, spreadFExp_4_2_1_y 
			WinMove, % "ahk_id " spreadFExp_4_2_2_ID, , spreadFExp_4_2_2_x, spreadFExp_4_2_2_y 

			WinSet, AlwaysOnTop, On, % "ahk_id " spreadFExp_4_1_2_ID
			WinSet, AlwaysOnTop, Off, % "ahk_id " spreadFExp_4_1_2_ID
			WinSet, AlwaysOnTop, On, % "ahk_id " spreadFExp_4_2_2_ID
			WinSet, AlwaysOnTop, Off, % "ahk_id " spreadFExp_4_2_2_ID
			WinSet, AlwaysOnTop, On, % "ahk_id " spreadFExp_4_1_1_ID
			WinSet, AlwaysOnTop, Off, % "ahk_id " spreadFExp_4_1_1_ID

			; finding positions for the windows to put diagonally
			; putting diagonally, overlapping
			spreadFExp_left := monitor_%monitor_no_prm%_workarea_left
			spreadFExp_top := monitor_%monitor_no_prm%_workarea_top
			spreadFExp_end_x := monitor_%monitor_no_prm%_workarea_right - spreadFExp_4_2_1_w		; The top one will be right down corner and top
			spreadFExp_end_y := monitor_%monitor_no_prm%_workarea_bottom - spreadFExp_4_2_1_h 		; The top one will be right down corner and top
			spreadFExp_step_width := (spreadFExp_end_x - spreadFExp_left) / (FExp_onDiag_no + 1)
			spreadFExp_step_height := (spreadFExp_end_y - spreadFExp_top) / (FExp_onDiag_no + 1)
			Loop, % FExp_onDiag_no {
				temp_index := AltTab_ID_List_FileExplorer_0 - A_Index
				spreadFExpEach_x := spreadFExp_left + spreadFExp_step_width * A_Index
				spreadFExpEach_y := spreadFExp_top + spreadFExp_step_height * A_Index
				WinMove, % "ahk_id " AltTab_ID_List_FileExplorer_sort_area_dsc_%temp_index%_ID, , spreadFExpEach_x, spreadFExpEach_y 
				WinSet, AlwaysOnTop, On, % "ahk_id " AltTab_ID_List_FileExplorer_sort_area_dsc_%temp_index%_ID
				WinSet, AlwaysOnTop, Off, % "ahk_id " AltTab_ID_List_FileExplorer_sort_area_dsc_%temp_index%_ID
			}

				WinSet, AlwaysOnTop, On, % "ahk_id " spreadFExp_4_2_1_ID
				WinSet, AlwaysOnTop, Off, % "ahk_id " spreadFExp_4_2_1_ID

				WinActivate, % "ahk_id " AltTab_ID_List_FileExplorer_1

		;} else if (AltTab_ID_List_FileExplorer_0 <= monitor_%monitor_no_prm%_grid_no_xy) {
		} else {
			; putting diagonally, overlapping
			spreadFExp_left := monitor_%monitor_no_prm%_workarea_left
			spreadFExp_top := monitor_%monitor_no_prm%_workarea_top
			spreadFExp_end_x := monitor_%monitor_no_prm%_workarea_right - AltTab_ID_List_FileExplorer_1_w		; The top one will be right down corner and top
			spreadFExp_end_y := monitor_%monitor_no_prm%_workarea_bottom - AltTab_ID_List_FileExplorer_1_h 	; The top one will be right down corner and top
			spreadFExp_step_width := (spreadFExp_end_x - spreadFExp_left) / (AltTab_ID_List_FileExplorer_0 - 1)
			spreadFExp_step_height := (spreadFExp_end_y - spreadFExp_top) /(AltTab_ID_List_FileExplorer_0 - 1)
			Loop, % AltTab_ID_List_FileExplorer_0 {
				temp_index := AltTab_ID_List_FileExplorer_0 - A_Index + 1
				spreadFExpEach_x := spreadFExp_left + spreadFExp_step_width * (A_Index - 1)
				spreadFExpEach_y := spreadFExp_top + spreadFExp_step_height * (A_Index - 1)
				WinMove, % "ahk_id " AltTab_ID_List_FileExplorer_%temp_index%, , spreadFExpEach_x, spreadFExpEach_y 	; When SetWinDelay, -1 is declared, WinMove is as fast as DllCall("MoveWindow".. .
				WinSet, AlwaysOnTop, On, % "ahk_id " AltTab_ID_List_FileExplorer_%temp_index%
				WinSet, AlwaysOnTop, Off, % "ahk_id " AltTab_ID_List_FileExplorer_%temp_index%
			}
			WinActivate, % "ahk_id " AltTab_ID_List_FileExplorer_1
		}
	}
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


	loop {
		WinGetPos, X,Y,W,H,A  ; "A" to get the active window's pos.

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
					WinMove,A,, X + SETTING_CONSTANT_WINMOV_PX_S,
					KeyWait, Right, % "T" "0.005"
				} 
				if (is_left = "D") {
					WinMove,A,, X - SETTING_CONSTANT_WINMOV_PX_S,
					KeyWait, Left, % "T" "0.005"
				} 
				if (is_up = "D") {
					WinMove,A,,, Y - SETTING_CONSTANT_WINMOV_PX_S
					KeyWait, Up, % "T" "0.005"
				} 
				if (is_down = "D") {
					WinMove,A,,, Y + SETTING_CONSTANT_WINMOV_PX_S
					KeyWait, Down, % "T" "0.005"
				}



			} else {

				;; move by 20 px
				;; CapsLock + Win + Arrow Key

				if (is_right = "D") {
					WinMove,A,, X + SETTING_CONSTANT_WINMOV_PX_S,
					KeyWait, Right, % "T" SETTING_CONSTANT_WINMOV_PX_S_RepSec
				} 
				if (is_left = "D") {
					WinMove,A,, X - SETTING_CONSTANT_WINMOV_PX_S,
					KeyWait, Left, % "T" SETTING_CONSTANT_WINMOV_PX_S_RepSec
				} 
				if (is_up = "D") {
					WinMove,A,,, Y - SETTING_CONSTANT_WINMOV_PX_S
					KeyWait, Up, % "T" SETTING_CONSTANT_WINMOV_PX_S_RepSec
				} 
				if (is_down = "D") {
					WinMove,A,,, Y + SETTING_CONSTANT_WINMOV_PX_S
					KeyWait, Down, % "T" SETTING_CONSTANT_WINMOV_PX_S_RepSec
				}
			}
		} else { 	; Without Win key.
			; to collect the displays info about each monitor:
			; SysGet: Retrieves screen resolution, multi-monitor info, dimensions of system objects, and other system properties.
			; Sub-command: MonitorCount, Monitor [, N], MonitorWorkArea, etc.
			SysGet, monitor_no, MonitorCount	
			Loop, %monitor_no% {
			    SysGet, Monitor_%A_Index%_, Monitor, %A_Index%
			    SysGet, Monitor_%A_Index%_WorkArea_, MonitorWorkArea, %A_Index%
				monitor_%A_Index%_workarea_width := monitor_%A_Index%_workarea_right - monitor_%A_Index%_workarea_left
				monitor_%A_Index%_workarea_height := monitor_%A_Index%_workarea_bottom - monitor_%A_Index%_workarea_top
			}

			if (is_shift = "D") {

				;; move to an edge
				;; Win+Ctrl+Alt+Arrow Key (이거 아닌데)
				;; ~((screen_top > window_botom) v (screen_bottom < window_top)) => the window overlaps the screen

				if (is_right = "D") {
					i := 0	; to consider the right side of a window to put a right side of a screen
					loop, %monitor_no% {
						if (X + W < monitor_%A_Index%_workarea_right) and (monitor_%A_Index%_workarea_top < Y + H) and (Y < monitor_%A_Index%_workarea_bottom) {		; monitors' lefts and rights are like 0 ~ 2560, -1920 ~ 0. And mouse point is like (0, 0) ~ (2559, 1439). So adding + 0.5 will make the cases finally exclusive.
							i++
							x%i% := monitor_%A_Index%_workarea_right
						}
					}
					min_i := x1
					loop, %i% {
						if (x%i% < min_i) {
							min_i := x%i%
						}
					}
				
					j := 0	; to consider the left side of a window to put a left side of a screen
					loop, %monitor_no% {
						if (X < monitor_%A_Index%_workarea_left) and (monitor_%A_Index%_workarea_top < Y + H) and (Y < monitor_%A_Index%_workarea_bottom) {		; monitors' lefts and rights are like 0 ~ 2560, -1920 ~ 0. And mouse point is like (0, 0) ~ (2559, 1439). So adding + 0.5 will make the cases finally exclusive.
							j++
							x%j% := monitor_%A_Index%_workarea_left
						}
					}
					min_j := x1
					loop, %j% {
						if (x%j% < min_j) {
							min_j := x%j%
						}
					}
				
					if (i > 0) and (j > 0) {
						if (min_i - X - W < min_j - X) {
							WinMove, A, , min_i - W
						} else {
							WinMove, A, , min_j
						}
					} else if (i > 0) {				; generally at the most right side
						WinMove, A, , min_i - W
					} else if (j > 0) {				; if a window is so big that its right side is over the screen. But its left side can go further right to attach an edge of a screen (it happens when using multi screens or its left is also over the screen)
						WinMove, A, , min_j
					}
					KeyWait, Right, % "T" SETTING_CONSTANT_WINMOV_STEP_REP
				}
				if (is_left = "D") {
					i := 0
					loop, %monitor_no% {
						if (monitor_%A_Index%_workarea_left < X) and (monitor_%A_Index%_workarea_top < Y + H) and (Y < monitor_%A_Index%_workarea_bottom) {		; monitors' lefts and rights are like 0 ~ 2560, -1920 ~ 0. And mouse point is like (0, 0) ~ (2559, 1439). So adding + 0.5 will make the cases finally exclusive.
							i++
							x%i% := monitor_%A_Index%_workarea_left
						}
					}
					max_i := x1
					loop, %i% {
						if (x%i% > max_i) {
							max_i := x%i%
						}
					}

					j := 0	; to consider the right side of a window to put a right side of a screen
					loop, %monitor_no% {
						if (monitor_%A_Index%_workarea_right < X + W) and (monitor_%A_Index%_workarea_top < Y + H) and (Y < monitor_%A_Index%_workarea_bottom) {		; monitors' lefts and rights are like 0 ~ 2560, -1920 ~ 0. And mouse point is like (0, 0) ~ (2559, 1439). So adding + 0.5 will make the cases finally exclusive.
							j++
							x%j% := monitor_%A_Index%_workarea_right
						}
					}
					max_j := x1
					loop, %j% {
						if (x%j% > max_j) {
							max_j := x%j%
						}
					}

					if (i > 0) and (j > 0) {
						if (X - max_i < X + W - max_j) {
							WinMove, A, , max_i
						} else {
							WinMove, A, , max_j - W
						}
					} else if (i > 0) {
						WinMove, A, , max_i
					} else if (j > 0) {
						WinMove, A, , max_j - W
					}
					KeyWait, Left, % "T" SETTING_CONSTANT_WINMOV_STEP_REP
				}
				if (is_up = "D") {
					i := 0
					loop, %monitor_no% {
						if (monitor_%A_Index%_workarea_left < X + W) and (X < monitor_%A_Index%_workarea_right) and (monitor_%A_Index%_workarea_top < Y) {		; monitors' lefts and rights are like 0 ~ 2560, -1920 ~ 0. And mouse point is like (0, 0) ~ (2559, 1439). So adding + 0.5 will make the cases finally exclusive.
							i++
							x%i% := monitor_%A_Index%_workarea_top
						}
					}
					max_i := x1
					loop, %i% {
						if (x%i% > max_i) {
							max_i := x%i%
						}
					}

					j := 0	; to consider the bottom side of a window to put a bottom side of a screen
					loop, %monitor_no% {
						if (monitor_%A_Index%_workarea_left < X + W) and (X < monitor_%A_Index%_workarea_right) and (monitor_%A_Index%_workarea_bottom < Y + H) {		; monitors' lefts and rights are like 0 ~ 2560, -1920 ~ 0. And mouse point is like (0, 0) ~ (2559, 1439). So adding + 0.5 will make the cases finally exclusive.
							j++
							x%j% := monitor_%A_Index%_workarea_bottom
						}
					}
					max_j := x1
					loop, %j% {
						if (x%j% > max_j) {
							max_j := x%j%
						}
					}

					if (i > 0) and (j > 0) {
						if (Y - max_i < Y + H - max_j) {
							WinMove, A, , , max_i
						} else {
							WinMove, A, , , max_j - H
						}
					} else if (i > 0) {
						WinMove, A, , , max_i
					} else if (j > 0) {
						WinMove, A, , , max_j - H
					}
					KeyWait, Up, % "T" SETTING_CONSTANT_WINMOV_STEP_REP
				}
				if (is_down = "D") {
					i := 0
					loop, %monitor_no% {
						if (monitor_%A_Index%_workarea_left < X + W) and (X < monitor_%A_Index%_workarea_right) and (Y + H < monitor_%A_Index%_workarea_bottom) {		; monitors' lefts and rights are like 0 ~ 2560, -1920 ~ 0. And mouse point is like (0, 0) ~ (2559, 1439). So adding + 0.5 will make the cases finally exclusive.
							i++
							x%i% := monitor_%A_Index%_workarea_bottom
						}
					}
					min_i := x1
					loop, %i% {
						if (x%i% < min_i) {
							min_i := x%i%
						}
					}

					j := 0	; to consider the top side of a window to put a top side of a screen
					loop, %monitor_no% {
						if (monitor_%A_Index%_workarea_left < X + W) and (X < monitor_%A_Index%_workarea_right) and (Y < monitor_%A_Index%_workarea_top) {		; monitors' lefts and rights are like 0 ~ 2560, -1920 ~ 0. And mouse point is like (0, 0) ~ (2559, 1439). So adding + 0.5 will make the cases finally exclusive.
							j++
							x%j% := monitor_%A_Index%_workarea_top
						}
					}
					min_j := x1
					loop, %j% {
						if (x%j% < min_j) {
							min_j := x%j%
						}
					}

					if (i > 0) and (j > 0) {
						if (min_i - Y - H < min_j - Y) {
							WinMove, A, , , min_i - H
						} else {
							WinMove, A, , , min_j
						}
					} else if (i > 0) {
						WinMove, A, , , min_i - H
					} else if (j > 0) {
						WinMove, A, , , min_j
					}
					KeyWait, Down, % "T" SETTING_CONSTANT_WINMOV_STEP_REP
				}
				;Continue		
			} else {

				;; moving in grid with Arrow Key

				loop, %monitor_no% {
					if (monitor_%A_Index%_left <= X) and (X <= monitor_%A_Index%_right - 1) and (monitor_%A_Index%_top <= Y) and (Y <= monitor_%A_Index%_bottom - 1) {		; monitors' lefts and rights are like 0 ~ 2560, -1920 ~ 0.
						ScreenWoTaskbar_X := monitor_%A_Index%_workarea_left
						ScreenWoTaskbar_Y := monitor_%A_Index%_workarea_top
						ScreenWoTaskbar_W := monitor_%A_Index%_workarea_width
						ScreenWoTaskbar_H := monitor_%A_Index%_workarea_height
					}
				}

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
					WinRestore, A

					; to check how many controls were pushed and so as to set girdNo.
					if (control_triggered = 0) {
						currentTime := A_TickCount
						control_triggered := 1
						control_repushCheck := 0
						gridNo := 1
						loop, % timeStamp_modfr_max {
							if (currentTime - timeStamp_Control_%A_Index% < 1500) {
								gridNo ++
							}
						}
					}

					if (is_up = "D") {
						WinMove, A,, , ScreenWoTaskbar_Y + Ceil((Y - ScreenWoTaskbar_Y - 1)/ScreenWoTaskbar_H * gridNo - 1)*ScreenWoTaskbar_H / gridNo, ScreenWoTaskbar_W / gridNo, ScreenWoTaskbar_H / gridNo 
						KeyWait, Up, % "T" SETTING_CONSTANT_WINMOV_STEP_REP
					}
					if (is_down = "D") {
						WinMove, A,, , ScreenWoTaskbar_Y + Ceil((Y - ScreenWoTaskbar_Y + 1)/ScreenWoTaskbar_H * gridNo)*ScreenWoTaskbar_H / gridNo, ScreenWoTaskbar_W / gridNo, ScreenWoTaskbar_H / gridNo 
						KeyWait, Down, % "T" SETTING_CONSTANT_WINMOV_STEP_REP
					}
					if (is_left = "D") {
						WinMove, A,, ScreenWoTaskbar_X + Ceil((X - ScreenWoTaskbar_X - 1)/ScreenWoTaskbar_W * gridNo - 1)*ScreenWoTaskbar_W / gridNo, , ScreenWoTaskbar_W / gridNo, ScreenWoTaskbar_H / gridNo
						KeyWait, Left, % "T" SETTING_CONSTANT_WINMOV_STEP_REP
					}
					if (is_right = "D") {
						WinMove, A,, ScreenWoTaskbar_X + Ceil((X - ScreenWoTaskbar_X + 1)/ScreenWoTaskbar_W * gridNo)*ScreenWoTaskbar_W / gridNo, , ScreenWoTaskbar_W / gridNo, ScreenWoTaskbar_H / gridNo
						KeyWait, Right, % "T" SETTING_CONSTANT_WINMOV_STEP_REP
					}
				} else {
					; to check how many Shifts were pushed and so as to set speedup.
					if (!capSpeedUpArrowKey) {
						currentTime := A_TickCount
						capSpeedUpArrowKey := 1 	; The last CapsLock stroke is not stamped. So we start at 1.
						loop, % timeStamp_modfr_max {
							if (currentTime - timeStamp_CapsLock_%A_Index% < 1500) {
								capSpeedUpArrowKey ++
							}
						}
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
	}
return

; It's for a test.
#^!+K::
	Tooltip, % " " GetKeyState("Down", "P") " " GetKeyState("up", "P") " " GetKeyState("right", "P") " " GetKeyState("left", "P") " " GetKeyState("CapsLock", "P")	
Return

~Right & CapsLock::
	;tooltip, asdf
Return

;; RESIZING WINDOW

;; resize by 20 px
;; Win+Alt+Arrow Key
#!Right::
#!Left::
#!Down::
#!Up::
	DllCall("SystemParametersInfo", UInt, 0x0001, UInt, 0, UIntP, initial_beep_setting, UInt,0) 
	DllCall("SystemParametersInfo", UInt, 0x0002, UInt, 0, UInt,0, UInt,0) 	; SPI_SETBEEP : 0x0002
	loop {
		GetKeyState, is_up, Up, P
		GetKeyState, is_down, Down, P
		GetKeyState, is_left, Left, P
		GetKeyState, is_right, Right, P

		GetKeyState, is_x, x, P

		if (is_right = "D") {
			WinGetPos, X,Y,W,H,A
			if (is_x = "D") {
				WinMove,A,,X+20,,W-20,
				KeyWait, Right, % "T" SETTING_CONSTANT_WINMOV_PX_S_RepSec
			} else {
				WinMove,A,,,,W+20,
				WinGetPos, X,,W2,,A
				if (W = W2) {
					WinMove,A,, X+20,,,
				}
				KeyWait, Right, % "T" SETTING_CONSTANT_WINMOV_PX_S_RepSec
			}
		}
		if (is_left = "D") {
			WinGetPos, X,Y,W,H,A
			if (is_x = "D") {
				WinMove,A,,,,W-20,
				WinGetPos, X,,W2,,A
				if (W = W2) {
					WinMove,A,, X-20,,,
				}
				KeyWait, Left, % "T" SETTING_CONSTANT_WINMOV_PX_S_RepSec
			} else {

				WinMove,A,,X-20,,W+20,
				KeyWait, Left, % "T" SETTING_CONSTANT_WINMOV_PX_S_RepSec
			}
		}
		if (is_down = "D") {
			WinGetPos, X,Y,W,H,A
			if (is_x = "D") {
				WinMove,A,,,Y+20,,H-20
				KeyWait, Down, % "T" SETTING_CONSTANT_WINMOV_PX_S_RepSec
			} else {
				WinMove,A,,,,,H+20
				WinGetPos, ,Y,,H2,A
				if (H = H2) {
					WinMove,A,,,Y+20,,
				}
				KeyWait, Down, % "T" SETTING_CONSTANT_WINMOV_PX_S_RepSec
			}
		}
		if (is_up = "D") {
			WinGetPos, X,Y,W,H,A
			if (is_x = "D") {
				WinMove,A,,,,,H-20
				WinGetPos, ,Y,,H2,A
				if (H = H2) {
					WinMove,A,,,Y-20,,
				}
				KeyWait, Up, % "T" SETTING_CONSTANT_WINMOV_PX_S_RepSec
			} else {
				WinMove,A,,,Y-20,,H+20
				KeyWait, Up, % "T" SETTING_CONSTANT_WINMOV_PX_S_RepSec
			}
		}

		if (!GetKeyState("Alt", "P")) {
			Break
		}
	}
	DllCall("SystemParametersInfo", UInt, 0x0002, UInt, initial_beep_setting, UInt,0, UInt,0) 	; SPI_SETBEEP : 0x0002
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
	WinGetPos, X,Y,W,H,A  ; "A" to get the active window's pos.
	; SysGet: Retrieves screen resolution, multi-monitor info, dimensions of system objects, and other system properties.
	; Sub-command: MonitorCount, Monitor [, N], MonitorWorkArea, etc.
	SysGet, monitor_no, MonitorCount	
	Loop, %monitor_no% {
	    SysGet, Monitor_%A_Index%_, Monitor, %A_Index%
	    SysGet, Monitor_%A_Index%_WorkArea_, MonitorWorkArea, %A_Index%
	}
	i := 0	
	loop, %monitor_no% {
		if (X + W < monitor_%A_Index%_workarea_right) and (monitor_%A_Index%_workarea_top < Y + H) and (Y < monitor_%A_Index%_workarea_bottom) {		; monitors' lefts and rights are like 0 ~ 2560, -1920 ~ 0. And mouse point is like (0, 0) ~ (2559, 1439). So adding + 0.5 will make the cases finally exclusive.
			i++
			x%i% := monitor_%A_Index%_workarea_right
		}
	}
	min_i := x1
	loop, %i% {
		if (x%i% < min_i) {
			min_i := x%i%
		}
	}
	if (i > 0) {
		WinMove, A, , , , min_i - X,
	}
return

#!+Left::
	WinGetPos, X,Y,W,H,A  ; "A" to get the active window's pos.
	; SysGet: Retrieves screen resolution, multi-monitor info, dimensions of system objects, and other system properties.
	; Sub-command: MonitorCount, Monitor [, N], MonitorWorkArea, etc.
	SysGet, monitor_no, MonitorCount	
	Loop, %monitor_no% {
	    SysGet, Monitor_%A_Index%_, Monitor, %A_Index%
	    SysGet, Monitor_%A_Index%_WorkArea_, MonitorWorkArea, %A_Index%
	}
	i := 0	
	loop, %monitor_no% {
		if (monitor_%A_Index%_workarea_left < X) and (monitor_%A_Index%_workarea_top < Y + H) and (Y < monitor_%A_Index%_workarea_bottom) {		; monitors' lefts and rights are like 0 ~ 2560, -1920 ~ 0. And mouse point is like (0, 0) ~ (2559, 1439). So adding + 0.5 will make the cases finally exclusive.
			i++
			x%i% := monitor_%A_Index%_workarea_left
		}
	}
	max_i := x1
	loop, %i% {
		if (x%i% > max_i) {
			max_i := x%i%
		}
	}
	if (i > 0) {
		WinMove, A, , max_i, , X + W - max_i,
	}
return

#!+Up::
	WinGetPos, X,Y,W,H,A  ; "A" to get the active window's pos.
	; SysGet: Retrieves screen resolution, multi-monitor info, dimensions of system objects, and other system properties.
	; Sub-command: MonitorCount, Monitor [, N], MonitorWorkArea, etc.
	SysGet, monitor_no, MonitorCount	
	Loop, %monitor_no% {
	    SysGet, Monitor_%A_Index%_, Monitor, %A_Index%
	    SysGet, Monitor_%A_Index%_WorkArea_, MonitorWorkArea, %A_Index%
	}
	i := 0
	loop, %monitor_no% {
		if (monitor_%A_Index%_workarea_left < X + W) and (X < monitor_%A_Index%_workarea_right) and (monitor_%A_Index%_workarea_top < Y) {		; monitors' lefts and rights are like 0 ~ 2560, -1920 ~ 0. And mouse point is like (0, 0) ~ (2559, 1439). So adding + 0.5 will make the cases finally exclusive.
			i++
			x%i% := monitor_%A_Index%_workarea_top
		}
	}
	max_i := x1
	loop, %i% {
		if (x%i% > max_i) {
			max_i := x%i%
		}
	}
	if (i > 0) {
		WinMove, A, , , max_i, , Y + H - max_i
	}
return

#!+Down::
	WinGetPos, X,Y,W,H,A  ; "A" to get the active window's pos.
	; SysGet: Retrieves screen resolution, multi-monitor info, dimensions of system objects, and other system properties.
	; Sub-command: MonitorCount, Monitor [, N], MonitorWorkArea, etc.
	SysGet, monitor_no, MonitorCount	
	Loop, %monitor_no% {
	    SysGet, Monitor_%A_Index%_, Monitor, %A_Index%
	    SysGet, Monitor_%A_Index%_WorkArea_, MonitorWorkArea, %A_Index%
	}
	i := 0
	loop, %monitor_no% {
		if (monitor_%A_Index%_workarea_left < X + W) and (X < monitor_%A_Index%_workarea_right) and (Y + H < monitor_%A_Index%_workarea_bottom) {		; monitors' lefts and rights are like 0 ~ 2560, -1920 ~ 0. And mouse point is like (0, 0) ~ (2559, 1439). So adding + 0.5 will make the cases finally exclusive.
			i++
			x%i% := monitor_%A_Index%_workarea_bottom
		}
	}
	min_i := x1
	loop, %i% {
		if (x%i% < min_i) {
			min_i := x%i%
		}
	}
	if (i > 0) {
		WinMove, A, , , , , min_i - Y
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
	
	; to collect the displays info about each monitor:
	SysGet, monitor_no, MonitorCount
	Loop, %monitor_no% {
	    SysGet, Monitor_%A_Index%_, Monitor, %A_Index%
	    SysGet, Monitor_%A_Index%_WorkArea_, MonitorWorkArea, %A_Index%
		monitor_%A_Index%_workarea_width := monitor_%A_Index%_workarea_right - monitor_%A_Index%_workarea_left
		monitor_%A_Index%_workarea_height := monitor_%A_Index%_workarea_bottom - monitor_%A_Index%_workarea_top
	}
	
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
							WinMove, ahk_id %MouseWin%,, monitor_%A_Index%_workarea_left + 0, monitor_%A_Index%_workarea_top + 0, monitor_%A_Index%_workarea_width/2, monitor_%A_Index%_workarea_height/2
						} else if (MouseX > monitor_%A_Index%_workarea_right - SETTING_CONSTANT_CAPSMOVE_CORNER) and (MouseY < monitor_%A_Index%_workarea_top + SETTING_CONSTANT_CAPSMOVE_CORNER) {	; right up
							if (is_max = 1) {		; if the window is maximized 
								WinRestore, ahk_id %MouseWin% 	; In case it has touched the top	
								WinGetPos, , , W, H, ahk_id %MouseWin%
							}			
							WinMove, ahk_id %MouseWin%,, monitor_%A_Index%_workarea_left + monitor_%A_Index%_workarea_width/2, monitor_%A_Index%_workarea_top + 0, monitor_%A_Index%_workarea_width/2, monitor_%A_Index%_workarea_height/2
						} else if (MouseX > monitor_%A_Index%_workarea_right - SETTING_CONSTANT_CAPSMOVE_CORNER) and (MouseY > monitor_%A_Index%_workarea_bottom - SETTING_CONSTANT_CAPSMOVE_CORNER) {	; right bottom
							if (is_max = 1) {		; if the window is maximized 
								WinRestore, ahk_id %MouseWin% 	; In case it has touched the top	
								WinGetPos, , , W, H, ahk_id %MouseWin%
							} 
							WinMove, ahk_id %MouseWin%,, monitor_%A_Index%_workarea_left + monitor_%A_Index%_workarea_width/2, monitor_%A_Index%_workarea_top + monitor_%A_Index%_workarea_height/2, monitor_%A_Index%_workarea_width/2, monitor_%A_Index%_workarea_height/2
						} else if (MouseX < monitor_%A_Index%_workarea_left + SETTING_CONSTANT_CAPSMOVE_CORNER) and (MouseY > monitor_%A_Index%_workarea_bottom - SETTING_CONSTANT_CAPSMOVE_CORNER) {	; left bottom
							if (is_max = 1) {		; if the window is maximized 
								WinRestore, ahk_id %MouseWin% 	; In case it has touched the top	
								WinGetPos, , , W, H, ahk_id %MouseWin%
							} 
							WinMove, ahk_id %MouseWin%,, monitor_%A_Index%_workarea_left + 0, monitor_%A_Index%_workarea_top + monitor_%A_Index%_workarea_height/2, monitor_%A_Index%_workarea_width/2, monitor_%A_Index%_workarea_height/2
						} else if (MouseX < monitor_%A_Index%_workarea_left + SETTING_CONSTANT_CAPSMOVE_LRB){	; left
							if (is_max = 1) {		; if the window is maximized 
								WinRestore, ahk_id %MouseWin% 	; In case it has touched the top	
								WinGetPos, , , W, H, ahk_id %MouseWin%
							} 
							WinMove, ahk_id %MouseWin%,, monitor_%A_Index%_workarea_left + 0, monitor_%A_Index%_workarea_top + 0, monitor_%A_Index%_workarea_width/2, monitor_%A_Index%_workarea_height
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
							WinMove, ahk_id %MouseWin%,, monitor_%A_Index%_workarea_left + 0, monitor_%A_Index%_workarea_top + 0, monitor_%A_Index%_workarea_width, monitor_%A_Index%_workarea_height/2
						} else if (MouseX > monitor_%A_Index%_workarea_right - SETTING_CONSTANT_CAPSMOVE_LRB){	; right
							if (is_max = 1) {		; if the window is maximized 
								WinRestore, ahk_id %MouseWin% 	; In case it has touched the top	
								WinGetPos, , , W, H, ahk_id %MouseWin%
							} 
							WinMove, ahk_id %MouseWin%,, monitor_%A_Index%_workarea_left + monitor_%A_Index%_workarea_width/2, monitor_%A_Index%_workarea_top + 0, monitor_%A_Index%_workarea_width/2, monitor_%A_Index%_workarea_height
						} else if (MouseY > monitor_%A_Index%_workarea_bottom - SETTING_CONSTANT_CAPSMOVE_LRB){	; bottom
							if (is_max = 1) {		; if the window is maximized 
								WinRestore, ahk_id %MouseWin% 	; In case it has touched the top	
								WinGetPos, , , W, H, ahk_id %MouseWin%
							} 
							WinMove, ahk_id %MouseWin%,, monitor_%A_Index%_workarea_left + 0, monitor_%A_Index%_workarea_top + monitor_%A_Index%_workarea_height/2, monitor_%A_Index%_workarea_width, monitor_%A_Index%_workarea_height/2
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

;; function def. During resizing, to change the mouse cursor
SystemCursor(x_CursorIndicator, OnOff=1)   ; INIT = "I","Init"; OFF = 0,"Off"; TOGGLE = -1,"T","Toggle"; ON = others
{
    static AndMask, XorMask, $, h_cursor ; Variable names may be up to 253 characters long and may consist of letters, numbers and the following punctuation: # _ @ $
        ,c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13 ; system cursors
        , h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13   ; handles of default cursors
    if ($ = "") {      ; init when requested or at first call
        $ := 1                                          ; active default cursors
        VarSetCapacity( h_cursor,4444, 1 )
        system_cursors = 32646,32645,32643,32644,32642,32512,32513,32514,32515,32516,32648,32649,32650
        StringSplit c, system_cursors, `, ; c0:= 13, c1:=32646, c2:=32645 ... ( "c1= IDC_SIZEALL, c2=IDC_SIZENS, c3=IDC_SIZENESW, c4=IDC_SIZEWE, c5=IDC_SIZENWSE")
        Loop %c0% ; c0 is the number of substrings produced 
        {
            h_cursor   := DllCall( "LoadCursor", "Ptr",0, "Ptr",c%A_Index% ) 
            h%A_Index% := DllCall( "CopyImage", "Ptr",h_cursor, "UInt",2, "Int",0, "Int",0, "UInt",0 )
        }
    }
    if ($ = 1 and OnOff = "Toggle") {
		Loop %c0% {
			h_cursor := DllCall( "CopyImage", "Ptr", h%x_CursorIndicator%, "UInt", 2, "Int", 0, "Int", 0, "UInt", 0 )
			DllCall( "SetSystemCursor", "Ptr", h_cursor, "UInt", c%A_Index% )
		}
        $ := 0  ; 
    } else {
		Loop %c0% {
			h_cursor := DllCall( "CopyImage", "Ptr",h%A_Index%, "UInt",2, "Int",0, "Int",0, "UInt",0 )
			DllCall( "SetSystemCursor", "Ptr",h_cursor, "UInt",c%A_Index% )
		}
		$ := 1  ; use the saved cursors
	}
}



; op-./;:
CapsLock & o::
	DllCall("SystemParametersInfo", UInt, 0x0001, UInt, 0, UIntP, initial_beep_setting, UInt,0) 
	is_capslock_initial := 1 - getkeystate("capslock", "T")
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
	SysGet, monitor_no, MonitorCount	
	Loop, %monitor_no% {
		SysGet, Monitor_%A_Index%_, Monitor, %A_Index%
	    SysGet, Monitor_%A_Index%_WorkArea_, MonitorWorkArea, %A_Index%
		monitor_%A_Index%_workarea_width := monitor_%A_Index%_workarea_right - monitor_%A_Index%_workarea_left
		monitor_%A_Index%_workarea_height := monitor_%A_Index%_workarea_bottom - monitor_%A_Index%_workarea_top
	}
	loop, %monitor_no% {
		if (monitor_%A_Index%_left <= A_CaretX) and (A_CaretX <= monitor_%A_Index%_right - 1) and (monitor_%A_Index%_top <= A_CaretY) and (A_CaretY <= monitor_%A_Index%_bottom - 1) {		; monitors' lefts and rights are like 0 ~ 2560, -1920 ~ 0.
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
	DllCall("SystemParametersInfo", UInt, 0x0002, UInt, initial_beep_setting, UInt,0, UInt,0) 	; SPI_SETBEEP : 0x0002
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
		is_capslock_initial_mouseCoor := 1 - getkeystate("capslock", "T") 	; To store the initial toggle state of CapsLock
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
	is_capslock_initial := 1 - getkeystate("capslock", "T")

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
			ToolTip, % "Mouse control mode help`n`n- Type any number in pixel followed by an arrow key : Move the mouse to the direction`n- While holding CapsLock, hold any Arrow key : Move the mouse pointer by the keyboard (holding with Alt, Shift or Ctrl will change the speed)`n- + : Enter the mouse constrained mode. (Press SpaceBar to move the mouse pointer back to the original position.)`n- R : Enter the mouse ruler mode. (Then press SpaceBar to set the reference point.)`n- W : move the mouse pointer to the center of a current window`n- C : Show the current coordinates`n- ? : Open the help`n- Esc : close the help and finish the Mouse control mode", , mousey + 60, 3
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
			KeyWait, Space, D
			MouseGetPos, mouseInit_x, mouseInit_y
			BlockInput, Off
	
			; To show t he reference point
			Gui, mouseRulerRefPoint: New
			Gui, mouseRulerRefPoint: +Owner +Disabled -SysMenu -Caption +AlwaysOnTop
			Gui, mouseRulerRefPoint: Color, EEAA99
			Gui, mouseRulerRefPoint: Show, % "x" mouseInit_x - 5 " y" mouseInit_y - 5 " h11 w11 NoActivate"
	
			vtext := {}
			Loop, {
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

HotkyeAnalysis(vHotkey := "Ti voglio bene") {
	if (vHotkey = "Ti voglio bene") {
		vHotkey := A_ThisHotkey
	}
	hotkeyPart := Object()
	if (InStr(vHotkey, "&")) {
		RegExMatch(vHotkey, "O)(.*) & (.*)", match)
		hotkeyPart[1] := match
		hotkeypart[2] := {}
		hotkeypart[2][1] := hotkeyPart[1][1] 	; if vHotkey is CapsLock & F3, hotkeypart[2][1] := "CapsLock"
	} else {
		RegExMatch(vHotkey, "O)([\^!+#~*]*)(.+)", match) 	
		;  ~Alt 	=  [~]  	+  [Alt]
		;  #%  		=  [#]  	+  [%]
		;  #&  		=  [#]  	+  [&]
		;  *~!#^-  	=  [*~!#^]	+  [-]
		;  *~!#^F2  =  [*~!#^]  +  [F2]
		;  *~!#^R  	=  [*~!#^]  +  [R]
		;  CapsLock =  []  		+  [CapsLock]
		;  Alt  	=  []		+  [Alt]
		;  ~Alt  	=  [~]		+  [Alt]
		;  *Control =  [*]		+  [Control]
		;  !  		=  []		+  [!]
		;  ^  		=  []		+  [^]
		;  !^  		=  [!]		+  [^]
		hotkeyPart[1] := match
		hotkeypart[2] := StrSplit(hotkeyPart[1][1])
		Loop, % hotkeypart[1].Len(1) {
			if (hotkeyPart[2][A_Index] = "!") {
				hotkeyPart[2][A_Index] := "Alt"
			} else if (hotkeyPart[2][A_Index] = "^") {
					   hotkeyPart[2][A_Index] := "Control"
			} else if (hotkeyPart[2][A_Index] = "+") {
					   hotkeyPart[2][A_Index] := "Shift"
			} else if (hotkeyPart[2][A_Index] = "#") {
					   hotkeyPart[2][A_Index] := "Win"
			}
		}
	}
	; hotkeyPart[1][1] = CapsLock or !#^
	; hotkeyPart[1][2] = F3, R, Right, etc.
	; hotkeyPart[2][1] = CapsLock, !, #, etc.
	; hotkeyPart[2][2] = !, ^, #, etc.
	Return hotkeyPart
}

WindowBookmark_setup(windowBookmark_no) {
	toReturn := ""
	WinGet, vID, ID, A
	AltTab_window_list()
	if (AltTab_window_list_findID(vID)) {
		toReturn := WindowInfo()
		ProcessNameSplt := StrSplit(toReturn.ProcessName, ".") 
		TrayTip
		TrayTip, % "Window bookmark - " windowBookmark_no " saved", % ProcessNameSplt[1] " (" toReturn.title ")", , 16
	} else {
		toReturn := 0
		TrayTip
		TrayTip, % "Window bookmark - " windowBookmark_no " is not saved", % "Please select a window first.", , 16
	}
	Return toReturn
}


WindowBookmark_operation(modifier1, modifier2, windowBookmark_no, thisWindowBookmark) {
	altTab_List := AltTab_window_list()
	if (thisWindowBookmark.ID = "") {
		TrayTip, % "There is no window bookmark at " windowBookmark_no ".", % "You can boomark a window by pressing " modifier1 " + " modifier2 " + " windowBookmark_no, , 16
	} else if (thisWindowBookmark.ID = WinExist("A")) {
		WinMinimize, A
/* 	
; 2022/07/07: 아래 주석처리 한 부분을 비주석으로 유효하게 코딩에 넣으면 예를들어 제1바탕화면의 한컴사전에 CapsLock & F1으로 윈도우 북마크를 했을 때, 제2바탕화면에서 CapsLock & F1을 눌르면 바로 아래 ID도 없고 ProcessName도 없는 것에 걸려서
; 새로 해당 프로세스를 실행시키려하고, 그러다보니 자연스럽게 제1바탕화면으로 넘어와서 한컴사전이 활성화된다.
; 그런데 같은 작업을 크롬으로 할 때는 다소 다른 양상이다. 만약 제2바탕화면에 크롬이 하나도 없으면 크롬 프로세스를 실행하게 되는데 그게 제1바탕화면으로 넘어와서 활성화되는게 아니라, 제2바탕화면에서 새로운 크롬 인스턴스를 생성한다. 
; 그리고 만약 제2바탕화면에 크롬이 하나 이상 있다면 아래아래의 ID는 없지만 processName은 있는 경우에 속해서 열려져있는 크롬 하나를 잡아다가 CapsLock & F1에 할당해버린다. 
; 하지만 우리가 원하는 것은 제1바탕화면으로 넘어와서 원래 북마크 됐던 크롬의 인스턴스를 activate하는 것이다. 그런데 현재로서 어떻게 하는지 모르겠다.
; 아래를 주석처리하면 제2바탕화면에서 CapsLock & F1을 해도 아무 반응이 없다. 제1바탕화면으로 전환되지 않는다.

	} else if (!WinExist("ahk_id " thisWindowBookmark.ID) and !WinExist("ahk_exe " thisWindowBookmark.ProcessName)) { 	; there is no even the same process name window
		Run, % thisWindowBookmark.ProcessPath
		; to reset a bookmark as the newly run window
		isActivated := 0
		Loop, { 	; to wait until it exists. 
			altTab_List := AltTab_window_list()
			Loop, % altTab_List.length() {
				if (thisWindowBookmark.ProcessName = altTab_List[A_Index].ProcessName) {
					WinActivate, % "ahk_id " altTab_List[A_Index].id
					isActivated := 1
					thisWindowBookmark := WindowInfo()
					Break
				}
			}
			if (isActivated = 1) {
				Break
			}
		}
	} else if (!WinExist("ahk_id " thisWindowBookmark.ID) and WinExist("ahk_exe " thisWindowBookmark.ProcessName)) { 	; the ID doesn't exist. But there is a same process name process (but it may not exist as a valid window)

		isActivated := 0
		altTab_List := AltTab_window_list()
		Loop, % altTab_List.length() {
			if (thisWindowBookmark.ProcessName = altTab_List[A_Index].ProcessName) {
				;tooltip here?
				WinActivate, % "ahk_id " altTab_List[A_Index].id
				WinWaitActive, % "ahk_id " altTab_List[A_Index].id

				;tooltip go~!
				;Sleep, 2000
				;tooltip enough?
				altTab_List := AltTab_window_list()
				Loop, % altTab_List.length() { 		; To look for the bookmarked window one more time (like Photoshop, Illustrator)
					if (WinExist("ahk_id " thisWindowBookmark.ID)) { ;;;
						WinActivate, % "ahk_id " thisWindowBookmark.ID
						isActivated := 1
						Break
					}
				}

				if (isActivated = 0) {
					isActivated := 1
					; to reset a bookmark as the newly run window
					thisWindowBookmark := WindowInfo()
				}
				Break
			}
		}
		if (isActivated = 0) { 	; For example, in case there is no File Explorer when the bookmark was a File Explorer window. (because of ahk_class Shell_TrayWnd)
			Run, % thisWindowBookmark.ProcessPath
			; to reset a bookmark as the newly run window
			Loop, { 	; to wait until it exists. 
				altTab_List := AltTab_window_list()
				Loop, % altTab_List.length() {
					if (thisWindowBookmark.ProcessName = altTab_List[A_Index].ProcessName) {
						;WinActivate, % "ahk_id " altTab_List[A_Index].id
						isActivated := 1
						; to reset a bookmark as the newly run window
						thisWindowBookmark := WindowInfo()
						Break
					}
				}
				if (isActivated = 1) {
					Break
				}
			}
		}
*/
	} else {
		WinActivate, % "ahk_id " thisWindowBookmark.ID

	}
	
	global SETTING_CONSTANT_TOOLTIPDUR_S
	SetTimer, RemoveToolTip, % SETTING_CONSTANT_TOOLTIPDUR_S
	Return thisWindowBookmark
}

WindowInfo(vID := "A") {
	if (vID != "A") {
		vID := "ahk_id " . vID
	}
	tempObj := Object()
	WinGet, vProcessPath, ProcessPath, % vID
	WinGet, vProcessName, ProcessName, % vID
	WinGetClass, vclass, % vID
	WinGetTitle, vtitle, % vID
	tempObj.ProcessPath := vProcessPath
	tempObj.ProcessName := vProcessName
	tempObj.class := vclass
	tempObj.title := vtitle
	tempObj.ID := WinExist(vID) 	; the same as ;WinGet, windowBookmark_%windowBookmark_no%_ID, ID, A
	Return tempObj
}

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
	Thread, NoTimers 	; Without this, often error occurs: the first-hotkey thread started -> called the SetTimer-subroutine -> the second-hotkey thread started -> before the second one finished, the SetTimer-subroutine started.
	if (!WheelScroll_fast_lv1_started) {
		WheelScroll_fast_lv1_started := 1
		WheelScroll_fast_triggered_time := A_TickCount
		wheelScroll_speedUp := wheelScroll_speedUp_default
		loop, % timeStamp_modfr_max{
			if (WheelScroll_fast_triggered_time - timeStamp_CapsLock_%A_Index% < 1500) { 	;the last CapsLock key right before WheelUp/Down is not listed in timeStamp_CapsLock_%A_Index%
				wheelScroll_speedUp += wheelScroll_speedUp_default		
			}
		}
	}
	if ((AltTab_window_list_findID(WinExist("A")).Class = "XLMAIN") and GetKeyState("Shift")) { 
		wheelScroll_speedUp_Excel := wheelScroll_speedUp + wheelScroll_speedUp_default
		ComObjActive("Excel.Application").ActiveWindow.SmallScroll(0,0, wheelScroll_speedUp_Excel)  ; Scroll right.   (credit: Learning one  https://autohotkey.com/board/topic/35292-horizontal-scroll-in-excel-2007/)
		if (WheelScroll_fast_lv1_started = 1) {
			SetTimer, WheelScroll_fast_first, -1
		}
	} else {
		Click WheelDown %wheelScroll_speedUp%
		if (WheelScroll_fast_lv1_started = 1) {
			SetTimer, WheelScroll_fast_first, -1 ; Instead of putting this later: SetTimer, WheelScroll_fast_first, off
		}
	}
Return

CapsLock & WheelUp::
	Thread, NoTimers 	; Without this, often error occurs: the first-hotkey thread started -> called the SetTimer-subroutine -> the second-hotkey thread started -> before the second one finished, the SetTimer-subroutine started.
	if (!WheelScroll_fast_lv1_started) {
		WheelScroll_fast_lv1_started := 1
		WheelScroll_fast_triggered_time := A_TickCount
		wheelScroll_speedUp := wheelScroll_speedUp_default
		loop, % timeStamp_modfr_max{
			if (WheelScroll_fast_triggered_time - timeStamp_CapsLock_%A_Index% < 1500) {
				wheelScroll_speedUp += wheelScroll_speedUp_default
			}
		}
	}
	if ((AltTab_window_list_findID(WinExist("A")).Class = "XLMAIN") and GetKeyState("Shift")) { 
		wheelScroll_speedUp_Excel := wheelScroll_speedUp + wheelScroll_speedUp_default
		ComObjActive("Excel.Application").ActiveWindow.SmallScroll(0,0,0,wheelScroll_speedUp_Excel)  ; Scroll left. (credit: Learning one  https://autohotkey.com/board/topic/35292-horizontal-scroll-in-excel-2007/)
		if (WheelScroll_fast_lv1_started = 1) {
			SetTimer, WheelScroll_fast_first, -1
		}
	} else {
		Click WheelUp %wheelScroll_speedUp%
		if (WheelScroll_fast_lv1_started = 1) {
			SetTimer, WheelScroll_fast_first, -1
		}
	}
Return	




;SetTitleMatchMode, RegEx
;#IfWinActive ahk_class XLMAIN
;#IfWinActive ahk_class OpusApp
#if WinActive("ahk_class XLMAIN") or WinActive("ahk_class OpusApp")
	+WheelUp::
	;+F2::
		Thread, NoTimers 	; Without this, often error occurs: the first-hotkey thread started -> called the SetTimer-subroutine -> the second-hotkey thread started -> before the second one finished, the SetTimer-subroutine started.
		if (!WheelScroll_fast_lv1_started) {
			WheelScroll_fast_lv1_started := 1
			WheelScroll_fast_triggered_time := A_TickCount
			wheelScroll_speedUp := 0 ;wheelScroll_speedUp_default
			loop, % timeStamp_modfr_max{
				if (WheelScroll_fast_triggered_time - timeStamp_Shift_%A_Index% < 1500) {
					wheelScroll_speedUp += wheelScroll_speedUp_default
				}
			}
			wheelScroll_speedUp_Excel := wheelScroll_speedUp = 0 ? wheelScroll_speedUp_default : wheelScroll_speedUp
			wheelScroll_speedUp := wheelScroll_speedUp - wheelScroll_speedUp_default
		}
		ComObjActive((AltTab_window_list_findID(WinExist("A")).Class = "XLMAIN"? "Excel":"Word") ".Application").ActiveWindow.SmallScroll(0,0,0,wheelScroll_speedUp_Excel)  ; Scroll left
		if (wheelScroll_speedUp_Excel/wheelScroll_speedUp_default < 2) {
			WheelScroll_fast_lv1_started := 0
		} else if (WheelScroll_fast_lv1_started = 1) {
			SetTimer, WheelScroll_fast_first, -1
		}
	Return

	+WheelDown::
	;+F3::
		Thread, NoTimers 	; Without this, often error occurs: the first-hotkey thread started -> called the SetTimer-subroutine -> the second-hotkey thread started -> before the second one finished, the SetTimer-subroutine started.
		if (!WheelScroll_fast_lv1_started) {
			WheelScroll_fast_lv1_started := 1
			WheelScroll_fast_triggered_time := A_TickCount
			wheelScroll_speedUp := 0 ;wheelScroll_speedUp_default
			loop, % timeStamp_modfr_max{
				if (WheelScroll_fast_triggered_time - timeStamp_Shift_%A_Index% < 1500) {
					wheelScroll_speedUp += wheelScroll_speedUp_default
				}
			}
			wheelScroll_speedUp_Excel := wheelScroll_speedUp = 0 ? wheelScroll_speedUp_default : wheelScroll_speedUp
			wheelScroll_speedUp := wheelScroll_speedUp - wheelScroll_speedUp_default
		}
		ComObjActive((AltTab_window_list_findID(WinExist("A")).Class = "XLMAIN"? "Excel":"Word") ".Application").ActiveWindow.SmallScroll(0,0,wheelScroll_speedUp_Excel)  ; Scroll right. 
		if (wheelScroll_speedUp_Excel/wheelScroll_speedUp_default < 2) {
			WheelScroll_fast_lv1_started := 0
		} else if (WheelScroll_fast_lv1_started = 1) {
			SetTimer, WheelScroll_fast_first, -1
		}
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
	KeyWait, CapsLock
	KeyWait, Shift
	SetCapsLockState, Off 	; This is the only way for user to anticipate the result of the value of CapsLock. Or we need to use Alt or Ctrl. Or we need to use Ctrl to speed up while holding CapsLock.
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
Shift::
~LWin::
~RWin::
CapsLock::
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
	} else if (vHotkey = "Shift") {
		Send, {Shift}
	}
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



; The following AltTab_window_list() and Decimal_to_Hex(var)'s credit: evl (https://autohotkey.com/board/topic/21657-alttab-window-list-get-a-list-of-alt-tab-windows/)

; NOTE: Calling the AltTab_window_list() function makes an array of window IDs:
; AltTab_ID_List_0 = the number of windows found
; AltTab_ID_List_1 to AltTab_ID_List_%AltTab_ID_List_0% contain the window IDs.

AltTab_window_list() {
  global
  WS_EX_CONTROLPARENT =0x10000
  WS_EX_APPWINDOW =0x40000
  WS_EX_TOOLWINDOW =0x80
  WS_DISABLED =0x8000000
  WS_POPUP =   0x80000000
  AltTab_ID_List_0 =0
  altTab_List := {} 	; object. KDR
  WinGet, Window_List, List ; Gather a list of running programs
  Loop, %Window_List%
    {
		wid := Window_List%A_Index%
		WinGetTitle, wid_Title, ahk_id %wid%
		WinGet, vStyle, Style, ahk_id %wid%
		
		If ((vStyle & WS_DISABLED) or ! (wid_Title)) ; skip unimportant windows ; ! wid_Title or 
    		Continue
		
		WinGet, es, ExStyle, ahk_id %wid%
		vParent := Decimal_to_Hex( DllCall( "GetParent", "uint", wid ) )
		WinGetClass, Win_Class, ahk_id %wid%
		WinGet, Style_parent, Style, ahk_id %vParent%
		WinGet, var_ProcessName, ProcessName, % "ahk_id " wid
		
		If (es & WS_EX_TOOLWINDOW)
			continue
  	   	if ((es & ws_ex_controlparent) and ! (vStyle & WS_POPUP) and !(Win_Class ="#32770") and ! (es & WS_EX_APPWINDOW))  ; pspad child window excluded (??)
    		Continue 																									; class = "#32770" : Find of Notepad, Find of Notepad++, Kakao Talk main, Kakao Talk chatting windows
	   	if ((vStyle & WS_POPUP) and (vParent) and ((Style_parent & WS_DISABLED) =0) and !(var_ProcessName = "Photoshop.exe") and !(var_ProcessName = "Illustrator.exe"))    		 ; notepad find window excluded ; note - some windows result in blank value so must test for zero instead of using NOT operator!
   			Continue 																		; KDR note: Notepad's find window, Photoshops canvas windows .
		
		if (wid_Title = "Windows Shell Experience Host") { 	; Kim Dongryeong added
    		continue
		}
		; Kim Dongryeong added (Xbox, Movies & TV, Photos are always there and can't recognize if it's really on the desktop or kind of hidden by Style or ExStyle or positions, etc. So for now, simply exclude them.)
		if ( ((wid_Title = "Xbox") and (("Windows.UI.Core.CoreWindow") or ("ApplicationFrameWindow"))) or ((wid_Title = "Movies & TV") and (("Windows.UI.Core.CoreWindow") or ("ApplicationFrameWindow"))) or ((wid_Title = "Photos") and (("Windows.UI.Core.CoreWindow") or ("ApplicationFrameWindow")))) {
			continue
		}

		;; Stile Find and Replace of Word and Excel are not excluded.

    	AltTab_ID_List_0 ++
    	AltTab_ID_List_%AltTab_ID_List_0% := wid

		WinGet, var_PID, PID, % "ahk_id " wid
		WinGetPos, temp_x, temp_y, temp_w, temp_h, % "ahk_id " wid
		WinGet, vProcessPath, ProcessPath, % "ahk_id " wid

    	altTab_List[AltTab_ID_List_0] := {}
    	altTab_List[AltTab_ID_List_0].id := wid
		altTab_List[AltTab_ID_List_0].Title := wid_Title
		altTab_List[AltTab_ID_List_0].Class := Win_Class
		altTab_List[AltTab_ID_List_0].Style := decimal_to_hex(vStyle)
		altTab_List[AltTab_ID_List_0].ExStyle := decimal_to_hex(es)	
		altTab_List[AltTab_ID_List_0].ProcessName := var_ProcessName
		altTab_List[AltTab_ID_List_0].PID := var_PID
		altTab_List[AltTab_ID_List_0].x := temp_x
		altTab_List[AltTab_ID_List_0].y := temp_y
		altTab_List[AltTab_ID_List_0].width := temp_w
		altTab_List[AltTab_ID_List_0].height := temp_h
		altTab_List[AltTab_ID_List_0].ParentID := vParent
		altTab_List[AltTab_ID_List_0].ProcessPath := vProcessPath
		altTab_List[AltTab_ID_List_0].index := AltTab_ID_List_0
		altTab_List[AltTab_ID_List_0].Topmost := es & 0x8 ? 1 : 0 	; 0x8 is WS_EX_TOPMOST (always on top)
		altTab_List[AltTab_ID_List_0].area := temp_w * temp_h

		if (WinExist("A") = wid) {
			altTab_List.active := altTab_List[AltTab_ID_List_0]
		}
	}
	altTab_List.len := AltTab_ID_List_0
	Return altTab_List

}

Decimal_to_Hex(var) {
	SetFormat, integer, hex
	var += 0
	SetFormat, integer, d
	return var
}

AltTab_window_list_findID(vID) {
	isFound := 0
	altTab_List := AltTab_window_list()
	Loop, % altTab_List.length() {
		if (vID = altTab_List[A_Index].id) {
			isFound := {}
			isFound := altTab_List[A_Index]
			Break
		}
	}
	Return isFound
}

AltTab_List_SameType(vID := "", vProcessName := "") {
	toReturn := ""
	toReturn := {}
	atList := AltTab_window_list()
	
	if (StrLen(vID) > 0) {
		vProcessName := AltTab_window_list_findID(vID).ProcessName
		vClass := AltTab_window_list_findID(vID).Class
		Loop, % atList.length() {
			if ((vProcessName = atList[A_Index].ProcessName) and (vClass = atList[A_Index].Class)) {
				aObject := atList[A_Index].Clone()
				aObject.MomIndex := A_Index
				toReturn.push(aObject) 	; toReturn[1].id, toReturn.length()
			}
		}
	} else if (StrLen(vProcessName) > 0) {
		Loop, % atList.length() {
			if (vProcessName = atList[A_Index].ProcessName) {
				aObject := atList[A_Index].Clone()
				aObject.MomIndex := A_Index
				toReturn.push(aObject) 	; toReturn[1].id, toReturn.length()
			}
		}
	}
	Return toReturn
}


Print_Windows_ListView(windowsList, GuiName := "Tanti Auguri for last year", LVtitle := "another list", vKey1 := "", vKey2 := "") {
	if (GuiName = "Tanti Auguri for last year") {
		GuiName := A_TickCount 	; to make it possible to open another new GUI even without any GUI name variable passed
	}
	Gui, aGui%GuiName%: New
	column := "#|i|ID|PID|Style|ExStyle|Parent|x|y|w|h|area|ProcessName|class|Title|ProcessPath"
	if (StrLen(vKey1))
		column .= "|" vKey1
	if (StrLen(vKey2))
		column .= "|" vKey2
	
	/*
	For key, value in windowsList[1] {
		column .= key "|"
	}
	column := SubStr(column, 1, StrLen(column) - 1)

*/	
	Gui, aGui%GuiName%: New, , % LVtitle
	Gui, aGui%GuiName%: Add, ListView, r25 w1200, % column
	Loop, % windowsList.length() {
		LV_Add("", A_Index, windowsList[A_Index].index, windowsList[A_Index].id, windowsList[A_Index].PID, windowsList[A_Index].Style, windowsList[A_Index].ExStyle, windowsList[A_Index].ParentID, windowsList[A_Index].x, windowsList[A_Index].y, windowsList[A_Index].width, windowsList[A_Index].height, windowsList[A_Index].area, windowsList[A_Index].ProcessName, windowsList[A_Index].class, windowsList[A_Index].title, windowsList[A_Index].ProcessPath, windowsList[A_Index][vKey1], windowsList[A_Index][vKey2])
	}
	LV_Add("", , "active")
	LV_Add("", "A", windowsList.active.index, windowsList.active.id, windowsList.active.PID, windowsList.active.Style, windowsList.active.ExStyle, windowsList.active.ParentID, windowsList.active.x, windowsList.active.y, windowsList.active.width, windowsList.active.height, windowsList.active.area, windowsList.active.ProcessName, windowsList.active.class, windowsList.active.title, windowsList.active.ProcessPath, windowsList.active[vKey1], windowsList.active[vKey2])
	LV_ModifyCol()  ; Auto-size each column to fit its contents.
	Gui, aGui%GuiName%: Show
}

Print_Object(vObj, isFirst) {
	print := ""
	For key, value in vObj {
		if (IsObject(value)) {
			print .= key " {" Print_Object(value, 0) "} "
		} else {
			print .= key " {" value "} "
		}
		if (isFirst = 1) {
			print .= "`n"
		}
	}
	Return print
}

; ===================== To show list of programs which you can see with Alt Tab =========================
#^K::
	altTab_List := AltTab_window_list()
	Print_Windows_ListView(altTab_List, , "List of programs on the Alt Tab list")
	newObj := altTab_List.Clone()
	Sort_Object(newObj, "width", 1)	; to sort only among integr keys
	Print_Windows_ListView(newObj, , "new Object")
	Print_Windows_ListView(altTab_List, , "even altTab original")
return
; ===================== To show list of programs which you can see with Alt Tab ================== ends ====


Sort_Object(vObj, vKey, mode, test := "") {	; to sort only among integr keys
	; mode = 1 : ascending
	; mode = 0 : descending
	if (vKey = "") { 	; to be fixed. not necessary to be an 1-dim array
		Loop, % vObj.length() - 1 {
			Loop, % vObj.length() - A_Index {
				nextIndex := A_Index + 1
				if (mode = 1) {
					if (vObj[A_Index] > vObj[nextIndex]) {
						swap := vObj[A_Index]
						vObj[A_Index] := vObj[nextIndex]
						vObj[nextIndex] := swap
					}
				} else if (mode = 0) {
					if (vObj[A_Index] < vObj[nextIndex]) {
						swap := vObj[A_Index]
						vObj[A_Index] := vObj[nextIndex]
						vObj[nextIndex] := swap
					}
				}
			}
		}
	} else {
		Loop, % vObj.length() - 1 {
			Loop, % vObj.length() - A_Index {
				nextIndex := A_Index + 1
				if (mode = 1) {
					if (vObj[A_Index][vKey] > vObj[nextIndex][vKey]) {
						swap := vObj[A_Index]
						vObj[A_Index] := vObj[nextIndex]
						vObj[nextIndex] := swap
					}
				} else if (mode = 0) {
					if (vObj[A_Index][vKey] < vObj[nextIndex][vKey]) {
						swap := vObj[A_Index]
						vObj[A_Index] := vObj[nextIndex]
						vObj[nextIndex] := swap
					}
				}
			}
		}
	}
	Return vObj
}
/*
ObjFullyClone(obj) {
    nobj := ObjClone(obj)
    for k,v in nobj
        if IsObject(v)
            nobj[k] := ObjFullyClone(v)
    return nobj
}
*/
ObjectClone(vObj) { 	; DOENS'T WORK
	newObj := {}
	newObj := vObj.clone()
	For key, value in newObj {
		if IsObject(value) {
			newObj.key := ObjectClone(value)
		}
	Return newObj
	}
}

fct_RemoveToolTip_time(_toolTipNo := 0, _update := false) {
    static s_toolTipNo := 0
    If (_update) {
        s_toolTipNo := _toolTipNo
    }
    else {
        ToolTip, , , , s_toolTipNo
    }
    return
}


;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------

+F5::
	Show_Windows("Explorer.exe", "", 0)
Return

+F6::
	Show_Windows("Explorer.exe", "", 1)
Return

+F3::
	Show_Windows("", WinExist("A"), 0)
Return

+F4::
	Show_Windows("", WinExist("A"), 1)
Return


Show_Windows(vProcessName, vID, girdMode) {

; ================= Showing only File Explorer - into grid, changing size ======= starts ==================
; Currently only on the primary Screen
; to add with a modifier: put windows on their Screens
; to add with a modifier: put windows only on the screen where mouse cursor is.

	SysGet, monitor_no, MonitorCount	
	SysGet, monitor_no_prm, MonitorPrimary
	Loop, %monitor_no% {
	    SysGet, Monitor_%A_Index%_, Monitor, %A_Index%
	    SysGet, Monitor_%A_Index%_WorkArea_, MonitorWorkArea, %A_Index%
		monitor_%A_Index%_workarea_width := monitor_%A_Index%_workarea_right - monitor_%A_Index%_workarea_left
		monitor_%A_Index%_workarea_height := monitor_%A_Index%_workarea_bottom - monitor_%A_Index%_workarea_top
		monitor_%A_Index%_workarea_ratio := monitor_%A_Index%_workarea_height/monitor_%A_Index%_workarea_width
		monitor_%A_Index%_workarea_center_x := (monitor_%A_Index%_workarea_right + monitor_%A_Index%_workarea_left)/2
		monitor_%A_Index%_workarea_center_y := (monitor_%A_Index%_workarea_bottom + monitor_%A_Index%_workarea_top)/2
		monitor_%A_Index%_grid_no_x := monitor_%A_Index%_workarea_width // 800 		; the numbers of grid along with x axis. 1920/2 = 960, 2560/3 = 853, 1920/800 = 2.xx, 2560/800 = 3.xx, 3840/800 = 4.8
		monitor_%A_Index%_grid_no_y := monitor_%A_Index%_workarea_height // 450 	; the numbers of grid along with y axis. 1080/2 = 540, 1440/3 = 480, 1080/450 = 2.xx, 1440/450 = 3.xx, 2160/450 = 4.8
		monitor_%A_Index%_grid_no_xy := monitor_%A_Index%_grid_no_x * monitor_%A_Index%_grid_no_y 			; the numbers of grids
		monitor_%A_Index%_grid_width := monitor_%A_Index%_workarea_width / monitor_%A_Index%_grid_no_x 		; width of a grid
		monitor_%A_Index%_grid_height := monitor_%A_Index%_workarea_height / monitor_%A_Index%_grid_no_y 	; height of a grid
	}


	if (StrLen(vProcessName) > 0) {
		AltTabListSameType := AltTab_List_SameType("", vProcessName)
	} else if (StrLen(vID) > 0) {
		AltTabListSameType := AltTab_List_SameType(vID, "")
	}




	vClass := AltTabListSameType[1].Class
	AltTab_List := AltTab_window_list() 


	; When there is no File Explorer.
	if ((AltTabListSameType.length() < 1) and (StrLen(vProcessName))) {
		Run, % vProcessName
	} 


	; To send all File Explorers to the bottom if they are on the top currently
	windowsSentToBottom := 0
	WinGetClass, class_currentActive, A
	;if class_currentActive in CabinetWClass, ExploreWClass 	; 
	;if ((vProcess != "Explorer.exe") or ((vProcess = "Explorer.exe") and ((class_currentActive = "CabinetWClass") or (class_currentActive = "ExploreWClass")))) {
		WinGet, activeWin_ID, ID, A
		Loop, % AltTabListSameType.length() {
			if (AltTabListSameType[A_Index].ID = activeWin_ID) { 	; If there is a File Explorer with TOPMOST, then the current window may not be AltTabListSameType[1]
				activeWin_momIndex := AltTabListSameType[A_Index].MomIndex
				activeWin_FExpIndex := A_Index
				activeWin_FExpIndex_nexts := A_Index + 1
				if (AltTabListSameType[A_Index + 1].momIndex = activeWin_momIndex + 1) { ; if the next window after the current active File Explorer is another File Explorer, we keep the current File Explorer and send the others back.
					Loop, % AltTabListSameType.length() {
						if (A_Index = activeWin_FExpIndex)
							Continue
						WinSet, Bottom, , % "ahk_id " AltTabListSameType[A_Index].ID
						windowsSentToBottom := 1
					}
				} 
				else if (StrLen(vProcessName)) {
					Loop, % AltTabListSameType.length() {
						WinSet, Bottom, , % "ahk_id " AltTabListSameType[A_Index].ID
						windowsSentToBottom := 1
						if (AltTabListSameType[A_Index].ID = activeWin_ID) { 	; If there is a File Explorer with TOPMOST, then the current window may not be AltTabListSameType[1]
							activeWin_FExpIndex := A_Index
							activeWin_momIndex := AltTabListSameType[A_Index].MomIndex
							Loop, {
								activeWin_FExpIndex_nexts := activeWin_FExpIndex + A_Index
								if (AltTabListSameType[activeWin_FExpIndex_nexts].momIndex != activeWin_momIndex + A_Index) {
									toActivate := activeWin_momIndex + A_Index
									WinActivate, % "ahk_id " AltTab_List[toActivate].ID
									break
								}
							}
						}
					}
				}
				Break
			}
		}
	;}


	; putting windows

	if (!windowsSentToBottom and girdMode = 1) { 	; putting windows only on the primary screen
		Loop, % AltTabListSameType.length() {
			; first unminimize or unmaximize all File Explorers in order to prevent WinMove from not working, and in order to get proper width and height.
			WinRestore, % "ahk_id " AltTabListSameType[A_Index].ID

			index1 := A_Index
			WinGetPos, temp_x, temp_y, temp_w, temp_h, % "ahk_id " AltTabListSameType[A_Index].ID
			; It's needed to spread windows across all monitors 
			loop, %monitor_no% {
				if (monitor_%A_Index%_left <= temp_x + temp_w/2) and (temp_x + temp_w/2 <= monitor_%A_Index%_right - 1) and (monitor_%A_Index%_top <= temp_y + temp_h/2) and (temp_y + temp_h/2 <= monitor_%A_Index%_bottom - 1) {		; monitors' lefts and rights are like 0 ~ 2560, -1920 ~ 0.
					AltTabListSameType[index1].mon := A_Index
					AltTabListSameTypeinMon_%A_Index%_all_w += temp_w 	; Sum of widths of all File Explorers in each monitor
					AltTabListSameTypeinMon_%A_Index%_all_h += temp_h 	; Sum of heights of all File Explorers in each monitor
				}
			}
		}
		if (AltTabListSameType.length() > monitor_%monitor_no_prm%_grid_no_xy) {
			; to create more grid
			Loop, {
				Loop, {
					monitor_%monitor_no_prm%_grid_no_x ++
					monitor_%monitor_no_prm%_grid_no_xy := monitor_%monitor_no_prm%_grid_no_x * monitor_%monitor_no_prm%_grid_no_y
					monitor_%monitor_no_prm%_grid_width := monitor_%monitor_no_prm%_workarea_width / monitor_%monitor_no_prm%_grid_no_x
					break
				}
				if (AltTabListSameType.length() <= monitor_%monitor_no_prm%_grid_no_xy) {
					break
				}
				monitor_%monitor_no_prm%_grid_no_y ++
				monitor_%monitor_no_prm%_grid_no_xy := monitor_%monitor_no_prm%_grid_no_x * monitor_%monitor_no_prm%_grid_no_y
				monitor_%monitor_no_prm%_grid_height := monitor_%monitor_no_prm%_workarea_height / monitor_%monitor_no_prm%_grid_no_y
				if (AltTabListSameType.length() <= monitor_%monitor_no_prm%_grid_no_xy) {
					break
				}
			}
		}
		counter := 0
		isLoopDone := 0
		counterRvs := AltTabListSameType.length()

		lastFExp_gridX := Ceil(AltTabListSameType.length() / monitor_%monitor_no_prm%_grid_no_y)
		lastFExp_gridY := Mod(AltTabListSameType.length(), monitor_%monitor_no_prm%_grid_no_y) = 0 ? monitor_%monitor_no_prm%_grid_no_y : Mod(AltTabListSameType.length(), monitor_%monitor_no_prm%_grid_no_y)

		stillEmptyLoop := 1
		Loop, % lastFExp_gridX {
			loop_1_indexRev := lastFExp_gridX - A_Index + 1
			
			Loop, % monitor_%monitor_no_prm%_grid_no_y {
				loop_2_indexRev := monitor_%monitor_no_prm%_grid_no_y - A_Index + 1
				if ((loop_2_indexRev > lastFExp_gridY) and (stillEmptyLoop = 1)) {
					Continue
				}
				stillEmptyLoop := 0
				WinMove, % "ahk_id " AltTabListSameType[counterRvs].ID, 	, monitor_%monitor_no_prm%_workarea_left + monitor_%monitor_no_prm%_grid_width * (loop_1_indexRev - 1)
																				, monitor_%monitor_no_prm%_workarea_top + monitor_%monitor_no_prm%_grid_height * (loop_2_indexRev - 1)
																				, monitor_%monitor_no_prm%_grid_width
																				, monitor_%monitor_no_prm%_grid_height
				WinSet, AlwaysOnTop, On, % "ahk_id " AltTabListSameType[counterRvs].ID
				WinSet, AlwaysOnTop, Off, % "ahk_id " AltTabListSameType[counterRvs].ID
				counterRvs --
			}
		} 
		WinActivate, % "ahk_id " AltTabListSameType[1].ID
	}

	else if (!windowsSentToBottom and girdMode = 0) { 	; putting windows only on the primary screen

		AltTabListSameType.all_w := 0 	; Sum of widths of all File Explorers across all monitors
		AltTabListSameType.all_h := 0 	; Sum of heights of all File Explorers across all monitors
		AltTabListSameType.max_w := 0
		AltTabListSameType.max_h := 0
		AltTabListSameType.monitor := {}
		Loop, %monitor_no% {
			AltTabListSameType.monitor[A_Index] := {}
			AltTabListSameType.monitor[A_Index].all_w := 0 	; Sum of widths of all File Explorers in each monitor
			AltTabListSameType.monitor[A_Index].all_h := 0 	; Sum of heights of all File Explorers in each monitor
		}

		; to get coordinates and measures of File Explorer (should be in the else statement.)
		Loop, % AltTabListSameType.length() { 
			; first unminimize or unmaximize all File Explorers in order to prevent WinMove from not working, and in order to get proper width and height.
			WinRestore, % "ahk_id " AltTabListSameType[A_Index].ID 	; this is the problem.

			WinGetPos, temp_x, temp_y, temp_w, temp_h, % "ahk_id " AltTabListSameType[A_Index].ID
			;AltTabListSameType[A_Index].x := temp_x  
			;AltTabListSameType[A_Index].y := temp_y
			;AltTabListSameType[A_Index].width := temp_w
			;AltTabListSameType[A_Index].height := temp_h  
			AltTabListSameType.all_w += temp_w
			AltTabListSameType.all_h += temp_h
			if (AltTabListSameType.max_w < temp_w) {
				AltTabListSameType.max_w := temp_w
			}
			if (AltTabListSameType.max_h < temp_h) {
				AltTabListSameType.max_h := temp_h
			}
			
			index := A_Index
			; It's needed to spread windows across all monitors 
			loop, %monitor_no% {
				if (monitor_%A_Index%_left <= temp_x + temp_w/2) and (temp_x + temp_w/2 <= monitor_%A_Index%_right - 1) and (monitor_%A_Index%_top <= temp_y + temp_h/2) and (temp_y + temp_h/2 <= monitor_%A_Index%_bottom - 1) {		; monitors' lefts and rights are like 0 ~ 2560, -1920 ~ 0.
					AltTabListSameType[A_Index].mon := A_Index
					AltTabListSameType.monitor[A_Index].all_w += temp_w 	; Sum of widths of all File Explorers in each monitor
					AltTabListSameType.monitor[A_Index].all_h += temp_h 	; Sum of heights of all File Explorers in each monitor
				}
			}
		}


		if (AltTabListSameType.all_w <= monitor_%monitor_no_prm%_workarea_width) { 	; Putting horizontally. (instead of monitor_%A_Index%_workarea_width)
			; putting horizontally all together
			spreadFExp_left := monitor_%monitor_no_prm%_workarea_center_x - AltTabListSameType.all_w / 2
			spreadFExp_top := monitor_%monitor_no_prm%_workarea_center_y - AltTabListSameType.max_h / 2
			Loop, % AltTabListSameType.length() {
				temp_index := AltTabListSameType.length() - A_Index + 1
				WinMove, % "ahk_id " AltTabListSameType[temp_index].ID, , spreadFExp_left, spreadFExp_top
				WinSet, AlwaysOnTop, On, % "ahk_id " AltTabListSameType[temp_index].ID
				WinSet, AlwaysOnTop, Off, % "ahk_id " AltTabListSameType[temp_index].ID
				WinActivate, % "ahk_id " AltTabListSameType[temp_index].ID
				spreadFExp_left += AltTabListSameType[temp_index].width
			}
		} else if (AltTabListSameType.all_h <= monitor_%monitor_no_prm%_workarea_height) { 	; putting vertically all together
			spreadFExp_left := monitor_%monitor_no_prm%_workarea_center_x - AltTabListSameType.max_w / 2
			spreadFExp_top := monitor_%monitor_no_prm%_workarea_center_y - AltTabListSameType.all_h / 2
			Loop, % AltTabListSameType.length() {
				temp_index := AltTabListSameType.length() - A_Index + 1
				WinMove, % "ahk_id " AltTabListSameType[temp_index].ID, , spreadFExp_left, spreadFExp_top
				;DllCall("MoveWindow", UInt, AltTabListSameType[temp_index].ID, UInt, spreadFExpEach_x, UInt, spreadFExpEach_y, UInt, AltTabListSameType[temp_index].width, UInt, AltTabListSameType[temp_index].height, Int, 1)
				WinSet, AlwaysOnTop, On, % "ahk_id " AltTabListSameType[temp_index].ID
				WinSet, AlwaysOnTop, Off, % "ahk_id " AltTabListSameType[temp_index].ID
				WinActivate, % "ahk_id " AltTabListSameType[temp_index].ID
				spreadFExp_top += AltTabListSameType[temp_index].height
			}
		} else if ((monitor_%monitor_no_prm%_grid_no_x <= 1) or (monitor_%monitor_no_prm%_grid_no_y <= 1)) {  	; in case the screen is so narrow
			; putting diagonally, overlapping
			spreadFExp_left := monitor_%monitor_no_prm%_workarea_left
			spreadFExp_top := monitor_%monitor_no_prm%_workarea_top
			spreadFExp_end_x := monitor_%monitor_no_prm%_workarea_right - AltTabListSameType[1].width		; The top one will be right down corner and top
			spreadFExp_end_y := monitor_%monitor_no_prm%_workarea_bottom - AltTabListSameType[1].height 	; The top one will be right down corner and top
			spreadFExp_step_width := (spreadFExp_end_x - spreadFExp_left) / (AltTabListSameType.length() - 1)
			spreadFExp_step_height := (spreadFExp_end_y - spreadFExp_top) /(AltTabListSameType.length() - 1)
			Loop, % AltTabListSameType.length() {
				temp_index := AltTabListSameType.length() - A_Index + 1
				spreadFExpEach_x := spreadFExp_left + spreadFExp_step_width * (A_Index - 1)
				spreadFExpEach_y := spreadFExp_top + spreadFExp_step_height * (A_Index - 1)
				WinMove, % "ahk_id " AltTabListSameType[temp_index].ID, , spreadFExpEach_x, spreadFExpEach_y 	; When SetWinDelay, -1 is declared, WinMove is as fast as DllCall("MoveWindow".. .
				;DllCall("MoveWindow", UInt, AltTabListSameType[temp_index].ID, UInt, spreadFExpEach_x, UInt, spreadFExpEach_y, UInt, AltTabListSameType[temp_index].width, UInt, AltTabListSameType[temp_index].height, Int, 1)
				WinSet, AlwaysOnTop, On, % "ahk_id " AltTabListSameType[temp_index].ID
				WinSet, AlwaysOnTop, Off, % "ahk_id " AltTabListSameType[temp_index].ID
			}
			WinActivate, % "ahk_id " AltTabListSameType[1].ID

			
		} else if (AltTabListSameType.length() = 3) { 	; When there are only 3 windows
			Loop, % AltTabListSameType.length() {
				AltTabListSameType[A_Index].width_norm := AltTabListSameType[A_Index].width * monitor_%monitor_no_prm%_workarea_ratio
				AltTabListSameType[A_Index].height_norm := AltTabListSameType[A_Index].height
;				AltTabListSameType_sorted_w_norm_desc[A_Index] := AltTabListSameType[A_Index].width_norm 	; preparation for sorting
;				AltTabListSameType_sorted_h_norm_desc[A_Index] := AltTabListSameType[A_Index].height_norm	; preparation for sorting
;				AltTabListSameType_sorted_w_norm_desc[A_Index].ID := AltTabListSameType[A_Index].ID  		; preparation for sorting - assigning ID
;				AltTabListSameType_sorted_h_norm_desc[A_Index].ID := AltTabListSameType[A_Index].ID  		; preparation for sorting - assigning ID
			}

	Print_Windows_ListView(AltTabListSameType, , "AltTabListSameType original")
	ttt := AltTabListSameType.Clone()
	OOO := AltTabListSameType.Clone()
	ttt[1].width := 888
	Print_Windows_ListView(ttt, , "ttt")
	Print_Windows_ListView(OOO, , "OOO")



			;AltTabListSameType_sorted_w_norm_desc := {}
			;AltTabListSameType_sorted_h_norm_desc := {}
			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; the problem
			AltTabListSameType_sorted_w_norm_desc := AltTabListSameType.Clone()
			AltTabListSameType_sorted_h_norm_desc := AltTabListSameType_sorted_w_norm_desc.Clone()
			;Sort_Object(AltTabListSameType_sorted_w_norm_desc, "width_norm", 0)
			;Sort_Object(AltTabListSameType_sorted_h_norm_desc, "height_norm", 0)
			
			AltTabListSameType_sorted_w_norm_desc[1].width := 99999			
			Print_Windows_ListView(AltTabListSameType_sorted_w_norm_desc, , "AltTabListSameType_sorted_w_norm_desc", "width_norm")
			Print_Windows_ListView(AltTabListSameType_sorted_h_norm_desc, , "AltTabListSameType_sorted_h_norm_desc", "width_norm")
			Print_Windows_ListView(AltTabListSameType, , "AltTabListSameType", "width_norm")


			;AltTabListSameType_sorted_h_norm_desc := Sort_Object(AltTabListSameType, "height_norm", 0)


			Loop, % AltTabListSameType.length() {
;				WinGetPos, temp_x, temp_y, temp_w, temp_h, % "ahk_id " AltTabListSameType_sorted_w_norm_desc[A_Index].ID
;				;AltTabListSameType_sorted_w_norm_desc[A_Index].x := temp_x*monitor_%monitor_no_prm%_workarea_ratio
;				AltTabListSameType_sorted_w_norm_desc[A_Index].y := temp_y
;				AltTabListSameType_sorted_w_norm_desc[A_Index].width := temp_w*monitor_%monitor_no_prm%_workarea_ratio 	
;				AltTabListSameType_sorted_w_norm_desc[A_Index].height := temp_h
;				WinGetPos, temp_x, temp_y, temp_w, temp_h, % "ahk_id " AltTabListSameType_sorted_h_norm_desc[A_Index].ID
;				;AltTabListSameType_sorted_h_norm_desc[A_Index].x := temp_x*monitor_%monitor_no_prm%_workarea_ratio
;				AltTabListSameType_sorted_h_norm_desc[A_Index].y := temp_y
;				AltTabListSameType_sorted_h_norm_desc[A_Index].width := temp_w*monitor_%monitor_no_prm%_workarea_ratio 	
;				AltTabListSameType_sorted_h_norm_desc[A_Index].height := temp_h	; Actually AltTabListSameType_sorted_h_norm_desc[A_Index].height = AltTabListSameType_sorted_h_norm_desc[A_Index].width
				AltTabListSameType_sorted_w_norm_desc[A_Index].width := AltTabListSameType_sorted_w_norm_desc[A_Index].width * monitor_%monitor_no_prm%_workarea_ratio 	
				AltTabListSameType_sorted_h_norm_desc[A_Index].width := AltTabListSameType_sorted_h_norm_desc[A_Index].width * monitor_%monitor_no_prm%_workarea_ratio 	
			}
			;;;;;;;;;;;;;;;;;;;;;;;;;; sorting is done.

			msgbox, % AltTabListSameType_sorted_w_norm_desc[1].width " =< " AltTabListSameType_sorted_h_norm_desc[1].height
			if (AltTabListSameType_sorted_w_norm_desc[1].width > AltTabListSameType_sorted_h_norm_desc[1].height) { 	; horizontal max is bigger than vertical max (in normalized values)
				FExpStack_bottomFExp := AltTabListSameType_sorted_w_norm_desc[1].ID
				FExpStack_bottomFExp_w_norm := AltTabListSameType_sorted_w_norm_desc[1].width
				FExpStack_bottomFExp_h_norm := AltTabListSameType_sorted_w_norm_desc[1].height
				FExpStack_leftFExp := ""
				FExpStack_rightFExp := ""

				sum_theOthers_w_norm := 0 	; sum of all the widths except the longest one.
				Loop, % AltTabListSameType.length() - 1 {
					nextIndex := A_Index + 1
					sum_theOthers_w_norm += AltTabListSameType_sorted_w_norm_desc[nextIndex]
				}
				over_w_norm := sum_theOthers_w_norm - monitor_%monitor_no_prm%_workarea_width * monitor_%monitor_no_prm%_workarea_ratio > 0 ? sum_theOthers_w_norm - monitor_%monitor_no_prm%_workarea_width * monitor_%monitor_no_prm%_workarea_ratio : 0
				horizontalLength_norm_net := sum_theOthers_w_norm - over_w_norm > AltTabListSameType_sorted_w_norm_desc[1].width ? sum_theOthers_w_norm - over_w_norm : AltTabListSameType_sorted_w_norm_desc[1].width
				horizontalLength_norm_net := horizontalLength_norm_net < monitor_%monitor_no_prm%_workarea_width ? horizontalLength_norm_net : monitor_%monitor_no_prm%_workarea_width 	; in case AltTabListSameType_sorted_w_norm_desc[1].width > monitor_%monitor_no_prm%_workarea_width

				if (AltTabListSameType_sorted_w_norm_desc[1].ID = AltTabListSameType_sorted_h_norm_desc[1].ID) { 	; That window has the longest width and the longest height.
					FExpStack_rightFExp := AltTabListSameType_sorted_h_norm_desc[2].ID
					FExpStack_rightFExp_w_norm := AltTabListSameType_sorted_h_norm_desc[2].width
					FExpStack_rightFExp_h_norm := AltTabListSameType_sorted_h_norm_desc[2].height
					FExpStack_leftFExp := AltTabListSameType_sorted_h_norm_desc[3].ID
					FExpStack_leftFExp_w_norm := AltTabListSameType_sorted_h_norm_desc[3].width
					FExpStack_leftFExp_h_norm := AltTabListSameType_sorted_h_norm_desc[3].height

					verticalLength := AltTabListSameType_sorted_w_norm_desc[1].height + AltTabListSameType_sorted_h_norm_desc[2].height
					over_h := verticalLength - monitor_%monitor_no_prm%_workarea_height > 0 ? verticalLength - monitor_%monitor_no_prm%_workarea_height : 0
					verticalLength_net := verticalLength - over_h

;;;;;===================================00000000000000000000000000000
				} else { 	; That window has the longest width but not the longest height.
					FExpStack_rightFExp := AltTabListSameType_sorted_h_norm_desc[1].ID
					FExpStack_rightFExp_w_norm := AltTabListSameType_sorted_h_norm_desc[1].width
					FExpStack_rightFExp_h_norm := AltTabListSameType_sorted_h_norm_desc[1].height
					; to find the remaining ID which should be at the upper left position.
					Loop, % AltTabListSameType.length() {
						if ((AltTabListSameType[A_Index].ID != FExpStack_rightFExp) and (AltTabListSameType[A_Index].ID != FExpStack_bottomFExp)) {
							FExpStack_leftFExp := AltTabListSameType[A_Index].ID
							FExpStack_leftFExp_w_norm := AltTabListSameType[A_Index].width_norm
							FExpStack_leftFExp_h_norm := AltTabListSameType[A_Index].height_norm
							Break
						}
					}

					verticalLength := AltTabListSameType_sorted_w_norm_desc[1].height + AltTabListSameType_sorted_h_norm_desc[1].height
					over_h := verticalLength - monitor_%monitor_no_prm%_workarea_height > 0 ? verticalLength - monitor_%monitor_no_prm%_workarea_height : 0
					verticalLength_net := verticalLength - over_h

				}
;;;;;===================================00000000000000000000000000000
				

				if (((over_w_norm > 0) and !(over_h > 0)) or ((over_w_norm > 0) and (over_h > 0))) {
					WinMove, % "ahk_id " FExpStack_leftFExp, , monitor_%monitor_no_prm%_workarea_left, monitor_%monitor_no_prm%_workarea_top
					WinMove, % "ahk_id " FExpStack_bottomFExp, , monitor_%monitor_no_prm%_workarea_left, monitor_%monitor_no_prm%_workarea_bottom - FExpStack_bottomFExp_h_norm 	; FExpStack_bottomFExp = AltTabListSameType_sorted_w_norm_desc[1].ID
					FExpStack_rightFExp_yAdj := (AltTabListSameType.all_h - monitor_%monitor_no_prm%_workarea_height)/2 * 1.5 	; 1.5 is an adjustment ratio
					WinMove, % "ahk_id " FExpStack_rightFExp, , monitor_%monitor_no_prm%_workarea_right - FExpStack_rightFExp_w_norm/monitor_%monitor_no_prm%_workarea_ratio, FExpStack_leftFExp_h_norm - FExpStack_rightFExp_yAdj
				} else if (!(over_w_norm > 0) and (over_h > 0)) {
					if ((FExpStack_leftFExp_h_norm + FExpStack_bottomFExp_h_norm) < monitor_%monitor_no_prm%_workarea_height) {
						WinMove, % "ahk_id " FExpStack_leftFExp, , monitor_%monitor_no_prm%_workarea_right - (FExpStack_rightFExp_w_norm + FExpStack_leftFExp_w_norm)/monitor_%monitor_no_prm%_workarea_ratio, monitor_%monitor_no_prm%_workarea_bottom - FExpStack_bottomFExp_h_norm - FExpStack_leftFExp_h_norm
					} else {
						WinMove, % "ahk_id " FExpStack_leftFExp, , monitor_%monitor_no_prm%_workarea_right - (FExpStack_rightFExp_w_norm + FExpStack_leftFExp_w_norm)/monitor_%monitor_no_prm%_workarea_ratio, monitor_%monitor_no_prm%_workarea_top
					}
					WinMove, % "ahk_id " FExpStack_bottomFExp, , monitor_%monitor_no_prm%_workarea_left, monitor_%monitor_no_prm%_workarea_bottom - FExpStack_bottomFExp_h_norm 	; FExpStack_bottomFExp = AltTabListSameType_sorted_w_norm_desc[1].ID
					WinMove, % "ahk_id " FExpStack_rightFExp, , monitor_%monitor_no_prm%_workarea_right - FExpStack_rightFExp_w_norm/monitor_%monitor_no_prm%_workarea_ratio, monitor_%monitor_no_prm%_workarea_top
				;} else if ((over_w_norm > 0) and (over_h > 0)) {
				} else if (!(over_w_norm > 0) and !(over_h > 0)) {
					;ToolTip, % "over_w_norm " over_w_norm " FExpStack_rightFExp_yAdj " FExpStack_rightFExp_yAdj 
					spreadFExp_left := monitor_%monitor_no_prm%_workarea_center_x - horizontalLength_norm_net/monitor_%monitor_no_prm%_workarea_ratio/2
					spreadFExp_top := monitor_%monitor_no_prm%_workarea_center_y - verticalLength_net/2
					spreadFExp_right := spreadFExp_left + horizontalLength_norm_net/monitor_%monitor_no_prm%_workarea_ratio
					spreadFExp_bottom := spreadFExp_top + verticalLength_net

					WinMove, % "ahk_id " FExpStack_leftFExp, , spreadFExp_right - (FExpStack_rightFExp_w_norm + FExpStack_leftFExp_w_norm)/monitor_%monitor_no_prm%_workarea_ratio, spreadFExp_bottom - FExpStack_bottomFExp_h_norm - FExpStack_leftFExp_h_norm
					WinMove, % "ahk_id " FExpStack_bottomFExp, , spreadFExp_left, spreadFExp_bottom - FExpStack_bottomFExp_h_norm 	; FExpStack_bottomFExp = AltTabListSameType_sorted_w_norm_desc[1].ID
					WinMove, % "ahk_id " FExpStack_rightFExp, , spreadFExp_right - FExpStack_rightFExp_w_norm/monitor_%monitor_no_prm%_workarea_ratio, spreadFExp_top
				}
				

				WinSet, AlwaysOnTop, On, % "ahk_id " FExpStack_leftFExp
				WinSet, AlwaysOnTop, Off, % "ahk_id " FExpStack_leftFExp
				WinSet, AlwaysOnTop, On, % "ahk_id " FExpStack_rightFExp
				WinSet, AlwaysOnTop, Off, % "ahk_id " FExpStack_rightFExp
				WinSet, AlwaysOnTop, On, % "ahk_id " FExpStack_bottomFExp
				WinSet, AlwaysOnTop, Off, % "ahk_id " FExpStack_bottomFExp
				WinActivate, % "ahk_id " AltTabListSameType[1].ID

;;;;;===================================00000000000000000000000000000

			} else { 	; vertical max is bigger than horizontal max
				FExpStack_rightFExp := AltTabListSameType_sorted_h_norm_desc[1].ID
				FExpStack_rightFExp_h_norm := AltTabListSameType_sorted_h_norm_desc[1].height
				FExpStack_rightFExp_w_norm := AltTabListSameType_sorted_h_norm_desc[1].width
				FExpStack_topFExp := ""
				FExpStack_bottomFExp := ""

				sum_theOthers_h := 0 	; sum of all the widths except the longest one.
				Loop, % AltTabListSameType.length() - 1 {
					nextIndex := A_Index + 1
					sum_theOthers_h += AltTabListSameType_sorted_h_norm_desc[nextIndex]
				}
				over_h := sum_theOthers_h - monitor_%monitor_no_prm%_workarea_height > 0 ? sum_theOthers_h - monitor_%monitor_no_prm%_workarea_height : 0
				verticalLength_net := sum_theOthers_h - over_h > AltTabListSameType_sorted_h_norm_desc[1].height ? sum_theOthers_h - over_h : AltTabListSameType_sorted_h_norm_desc[1].height
				verticalLength_net := verticalLength_net < monitor_%monitor_no_prm%_workarea_height ? verticalLength_net : monitor_%monitor_no_prm%_workarea_height 	; in case AltTabListSameType_sorted_h_norm_desc[1].height > monitor_%monitor_no_prm%_workarea_height

				if (AltTabListSameType_sorted_h_norm_desc[1].ID = AltTabListSameType_sorted_w_norm_desc[1].ID) { 	; That window has the longest width and the longest height.
					FExpStack_bottomFExp := AltTabListSameType_sorted_w_norm_desc[2].ID
					FExpStack_bottomFExp_h_norm := AltTabListSameType_sorted_w_norm_desc[2].height
					FExpStack_bottomFExp_w_norm := AltTabListSameType_sorted_w_norm_desc[2].width
					FExpStack_topFExp := AltTabListSameType_sorted_w_norm_desc[3].ID
					FExpStack_topFExp_h_norm := AltTabListSameType_sorted_w_norm_desc[3].height
					FExpStack_topFExp_w_norm := AltTabListSameType_sorted_w_norm_desc[3].width

					horizontalLength_norm := AltTabListSameType_sorted_h_norm_desc[1].width + AltTabListSameType_sorted_w_norm_desc[2].width
					over_w_norm := horizontalLength_norm - monitor_%monitor_no_prm%_workarea_width * monitor_%monitor_no_prm%_workarea_ratio > 0 ? horizontalLength_norm - monitor_%monitor_no_prm%_workarea_width * monitor_%monitor_no_prm%_workarea_ratio : 0
					horizontalLength_norm_net := horizontalLength_norm - over_w_norm
;;;;;===================================00000000000000000000000000000
				} else { 	; That window has the longest width but not the longest height.
					FExpStack_bottomFExp := AltTabListSameType_sorted_w_norm_desc[1].ID
					FExpStack_bottomFExp_h_norm := AltTabListSameType_sorted_w_norm_desc[1].height
					FExpStack_bottomFExp_w_norm := AltTabListSameType_sorted_w_norm_desc[1].width
					; to find the remaining ID which should be at the upper left position.
					Loop, % AltTabListSameType.length() {
						if ((AltTabListSameType[A_Index].ID != FExpStack_bottomFExp) and (AltTabListSameType[A_Index].ID != FExpStack_rightFExp)) {
							FExpStack_topFExp := AltTabListSameType[A_Index].ID
							FExpStack_topFExp_h_norm := AltTabListSameType[A_Index].height_norm
							FExpStack_topFExp_w_norm := AltTabListSameType[A_Index].width_norm
							Break
						}
					}

					horizontalLength_norm := AltTabListSameType_sorted_h_norm_desc[1].width + AltTabListSameType_sorted_w_norm_desc[1].width
					over_w_norm := horizontalLength_norm - monitor_%monitor_no_prm%_workarea_width * monitor_%monitor_no_prm%_workarea_ratio > 0 ? horizontalLength_norm - monitor_%monitor_no_prm%_workarea_width * monitor_%monitor_no_prm%_workarea_ratio : 0
					horizontalLength_norm_net := horizontalLength_norm - over_w_norm

				}
;;;;;===================================00000000000000000000000000000
				
				if (((over_h > 0) and !(over_w_norm > 0)) or ((over_h > 0) and (over_w_norm > 0))) {
					WinMove, % "ahk_id " FExpStack_topFExp, , monitor_%monitor_no_prm%_workarea_left, monitor_%monitor_no_prm%_workarea_top
					WinMove, % "ahk_id " FExpStack_rightFExp, , monitor_%monitor_no_prm%_workarea_right - FExpStack_rightFExp_w_norm / monitor_%monitor_no_prm%_workarea_ratio, monitor_%monitor_no_prm%_workarea_top
					FExpStack_bottomFExp_xAdj := (AltTabListSameType.all_w - monitor_%monitor_no_prm%_workarea_width)/2 * 1.5 	; 1.5 is an adjustment ratio. It's not a normalized value
					WinMove, % "ahk_id " FExpStack_bottomFExp, , FExpStack_topFExp_w_norm / monitor_%monitor_no_prm%_workarea_ratio - FExpStack_bottomFExp_xAdj, monitor_%monitor_no_prm%_workarea_bottom - FExpStack_bottomFExp_h_norm
				} else if (!(over_h > 0) and (over_w_norm > 0)) {
					if ((FExpStack_topFExp_w_norm + FExpStack_rightFExp_w_norm) < monitor_%monitor_no_prm%_workarea_width * monitor_%monitor_no_prm%_workarea_ratio) {
						WinMove, % "ahk_id " FExpStack_topFExp, , monitor_%monitor_no_prm%_workarea_right - (FExpStack_rightFExp_w_norm + FExpStack_topFExp_w_norm) /  monitor_%monitor_no_prm%_workarea_ratio, monitor_%monitor_no_prm%_workarea_bottom - (FExpStack_bottomFExp_h_norm + FExpStack_topFExp_h_norm)
					} else {
						WinMove, % "ahk_id " FExpStack_topFExp, , monitor_%monitor_no_prm%_workarea_left, monitor_%monitor_no_prm%_workarea_bottom - (FExpStack_bottomFExp_h_norm + FExpStack_topFExp_h_norm)
					}
					WinMove, % "ahk_id " FExpStack_rightFExp, , monitor_%monitor_no_prm%_workarea_right - FExpStack_rightFExp_w_norm / monitor_%monitor_no_prm%_workarea_ratio, monitor_%monitor_no_prm%_workarea_top
					WinMove, % "ahk_id " FExpStack_bottomFExp, , monitor_%monitor_no_prm%_workarea_left, monitor_%monitor_no_prm%_workarea_bottom - FExpStack_bottomFExp_h_norm
				;} else if ((over_h > 0) and (over_w_norm > 0)) {
				} else if (!(over_h > 0) and !(over_w_norm > 0)) {
					;ToolTip, % "over_h " over_h " FExpStack_bottomFExp_xAdj " FExpStack_bottomFExp_xAdj 
					spreadFExp_top := monitor_%monitor_no_prm%_workarea_center_y - verticalLength_net / 2
					spreadFExp_left := monitor_%monitor_no_prm%_workarea_center_x - horizontalLength_norm_net / monitor_%monitor_no_prm%_workarea_ratio / 2 	; It's not a normalized value
					spreadFExp_bottom := spreadFExp_top + verticalLength_net
					spreadFExp_right := spreadFExp_left + horizontalLength_norm_net / monitor_%monitor_no_prm%_workarea_ratio

					WinMove, % "ahk_id " FExpStack_topFExp, , spreadFExp_right - (FExpStack_rightFExp_w_norm + FExpStack_topFExp_w_norm) / monitor_%monitor_no_prm%_workarea_ratio, spreadFExp_bottom - (FExpStack_bottomFExp_h_norm + FExpStack_topFExp_h_norm)
					WinMove, % "ahk_id " FExpStack_rightFExp, , spreadFExp_right - FExpStack_rightFExp_w_norm / monitor_%monitor_no_prm%_workarea_ratio, spreadFExp_left
					WinMove, % "ahk_id " FExpStack_bottomFExp, , spreadFExp_left, spreadFExp_bottom - FExpStack_bottomFExp_h_norm					
				}
				

				WinSet, AlwaysOnTop, On, % "ahk_id " FExpStack_topFExp
				WinSet, AlwaysOnTop, Off, % "ahk_id " FExpStack_topFExp
				WinSet, AlwaysOnTop, On, % "ahk_id " FExpStack_bottomFExp
				WinSet, AlwaysOnTop, Off, % "ahk_id " FExpStack_bottomFExp
				WinSet, AlwaysOnTop, On, % "ahk_id " FExpStack_rightFExp
				WinSet, AlwaysOnTop, Off, % "ahk_id " FExpStack_rightFExp
				WinActivate, % "ahk_id " AltTabListSameType[1].ID

;;;;;===================================00000000000000000000000000000
			}
		} else if (AltTabListSameType.length() = 4) {
			;   (1,2)-(2,2)  1 - 2
			;   (1,1)-(2,1)  4 - 3

			; sort by height descending
			AltTabListSameType_sorted_height_desc := AltTabListSameType.Clone()
			Sort_Object(AltTabListSameType_sorted_height_desc, "height", 0)
			; to sort AltTab_ID_List_FileExplorer_sortDsc_h_%A_Index%_h
;			Loop, % AltTabListSameType.length() {
;				AltTab_ID_List_FileExplorer_sortDsc_h_%A_Index%_h := AltTabListSameType[A_Index].height	; preparation for sorting
;				AltTab_ID_List_FileExplorer_sortDsc_h_%A_Index%_ID := AltTabListSameType[A_Index].ID  		; preparation for sorting - assigning ID
;			}
;			Loop, % AltTabListSameType.length() - 1 {
;				Loop, % AltTabListSameType.length() - A_Index {
;					nextIndex := A_Index + 1
;					if (AltTab_ID_List_FileExplorer_sortDsc_h_%A_Index%_h < AltTab_ID_List_FileExplorer_sortDsc_h_%nextIndex%_h) {
;						swap := AltTab_ID_List_FileExplorer_sortDsc_h_%A_Index%_h
;						AltTab_ID_List_FileExplorer_sortDsc_h_%A_Index%_h := AltTab_ID_List_FileExplorer_sortDsc_h_%nextIndex%_h
;						AltTab_ID_List_FileExplorer_sortDsc_h_%nextIndex%_h := swap
;						swap := AltTab_ID_List_FileExplorer_sortDsc_h_%A_Index%_ID 														; assigning ID
;						AltTab_ID_List_FileExplorer_sortDsc_h_%A_Index%_ID := AltTab_ID_List_FileExplorer_sortDsc_h_%nextIndex%_ID 		; assigning ID
;						AltTab_ID_List_FileExplorer_sortDsc_h_%nextIndex%_ID := swap  													; assigning ID
;					}
;				}
;			}
;			Loop, % AltTabListSameType.length() {
;				WinGetPos, , , temp_w, , % "ahk_id " AltTab_ID_List_FileExplorer_sortDsc_h_%A_Index%_ID
;				AltTab_ID_List_FileExplorer_sortDsc_h_%A_Index%_w := temp_w 	
;			}
			;;;;;;;;;;;;;;;;;;;;;;;;;; sorting is done.

			; From now on, working with location-based windows
			; initial setting: 4 windows (all edges) are all put together at the center of the screen
			spreadFExp_4_1_1_ID := AltTabListSameType_sorted_height_desc[4].ID
			spreadFExp_4_1_1_w := AltTabListSameType_sorted_height_desc[4].width
			spreadFExp_4_1_1_h := AltTabListSameType_sorted_height_desc[4].height
			spreadFExp_4_1_1_x := monitor_%monitor_no_prm%_workarea_center_x - spreadFExp_4_1_1_w
			spreadFExp_4_1_1_y := monitor_%monitor_no_prm%_workarea_center_y 

			spreadFExp_4_2_1_ID := AltTabListSameType_sorted_height_desc[3].ID
			spreadFExp_4_2_1_w := AltTabListSameType_sorted_height_desc[3].width
			spreadFExp_4_2_1_h := AltTabListSameType_sorted_height_desc[3].height
			spreadFExp_4_2_1_x := monitor_%monitor_no_prm%_workarea_center_x
			spreadFExp_4_2_1_y := monitor_%monitor_no_prm%_workarea_center_y

			spreadFExp_4_1_2_ID := AltTabListSameType_sorted_height_desc[1].ID
			spreadFExp_4_1_2_w := AltTabListSameType_sorted_height_desc[1].width
			spreadFExp_4_1_2_h := AltTabListSameType_sorted_height_desc[1].height
			spreadFExp_4_1_2_x := monitor_%monitor_no_prm%_workarea_center_x - spreadFExp_4_1_2_w
			spreadFExp_4_1_2_y := monitor_%monitor_no_prm%_workarea_center_y - spreadFExp_4_1_2_h

			spreadFExp_4_2_2_ID := AltTabListSameType_sorted_height_desc[2].ID
			spreadFExp_4_2_2_w := AltTabListSameType_sorted_height_desc[2].width
			spreadFExp_4_2_2_h := AltTabListSameType_sorted_height_desc[2].height
			spreadFExp_4_2_2_x := monitor_%monitor_no_prm%_workarea_center_x
			spreadFExp_4_2_2_y := monitor_%monitor_no_prm%_workarea_center_y - spreadFExp_4_2_2_h

			; Compare left and right on each row, and put a wider one on the left.
			if (spreadFExp_4_1_1_w < spreadFExp_4_2_1_w) {
				swap := spreadFExp_4_1_1_ID
				spreadFExp_4_1_1_ID := spreadFExp_4_2_1_ID
				spreadFExp_4_2_1_ID := swap
				swap := spreadFExp_4_1_1_w
				spreadFExp_4_1_1_w := spreadFExp_4_2_1_w
				spreadFExp_4_2_1_w := swap
				swap := spreadFExp_4_1_1_h
				spreadFExp_4_1_1_h := spreadFExp_4_2_1_h
				spreadFExp_4_2_1_h := swap

				spreadFExp_4_1_1_x := monitor_%monitor_no_prm%_workarea_center_x - spreadFExp_4_1_1_w
				spreadFExp_4_1_1_y := monitor_%monitor_no_prm%_workarea_center_y 
				spreadFExp_4_2_1_x := monitor_%monitor_no_prm%_workarea_center_x
				spreadFExp_4_2_1_y := monitor_%monitor_no_prm%_workarea_center_y
			}
			if (spreadFExp_4_1_2_w < spreadFExp_4_2_2_w) {
				swap := spreadFExp_4_1_2_ID
				spreadFExp_4_1_2_ID := spreadFExp_4_2_2_ID
				spreadFExp_4_2_2_ID := swap
				swap := spreadFExp_4_1_2_w
				spreadFExp_4_1_2_w := spreadFExp_4_2_2_w
				spreadFExp_4_2_2_w := swap
				swap := spreadFExp_4_1_2_h
				spreadFExp_4_1_2_h := spreadFExp_4_2_2_h
				spreadFExp_4_2_2_h := swap

				spreadFExp_4_1_2_x := monitor_%monitor_no_prm%_workarea_center_x - spreadFExp_4_1_2_w
				spreadFExp_4_1_2_y := monitor_%monitor_no_prm%_workarea_center_y - spreadFExp_4_1_2_h
				spreadFExp_4_2_2_x := monitor_%monitor_no_prm%_workarea_center_x
				spreadFExp_4_2_2_y := monitor_%monitor_no_prm%_workarea_center_y - spreadFExp_4_2_2_h
			}

			; Adjusting process starts.

			;  - Adjusting x axis direction

			; first. Check if only one of the two bottom windows is wider than the half width of the screen
			if (((spreadFExp_4_1_1_w > monitor_%monitor_no_prm%_workarea_width / 2) and !(spreadFExp_4_2_1_w > monitor_%monitor_no_prm%_workarea_width / 2)) or (!(spreadFExp_4_1_1_w > monitor_%monitor_no_prm%_workarea_width / 2) and (spreadFExp_4_2_1_w > monitor_%monitor_no_prm%_workarea_width / 2))) {
				; sum of the two widths are bigger than the screen
				if (spreadFExp_4_1_1_w + spreadFExp_4_2_1_w > monitor_%monitor_no_prm%_workarea_width) { 	
					spreadFExp_4_1_1_x := monitor_%monitor_no_prm%_workarea_left 	; This is actually useless because it's useful when the right window may be longer than the left one.
					spreadFExp_4_2_1_x := monitor_%monitor_no_prm%_workarea_center_x > monitor_%monitor_no_prm%_workarea_right - spreadFExp_4_2_1_w ? monitor_%monitor_no_prm%_workarea_center_x : monitor_%monitor_no_prm%_workarea_right - spreadFExp_4_2_1_w 	; This is actually useless because it's useful when the right window may be longer than the left one.
				} else {
					spreadFExp_4_1_1_x := monitor_%monitor_no_prm%_workarea_left
					spreadFExp_4_2_1_x := spreadFExp_4_1_1_x + spreadFExp_4_1_1_w
				}
			} 
			; Check if both are wider than half width of the screen
			else if ((spreadFExp_4_1_1_w > monitor_%monitor_no_prm%_workarea_width / 2) and (spreadFExp_4_2_1_w > monitor_%monitor_no_prm%_workarea_width / 2)) {
				spreadFExp_4_1_1_x := monitor_%monitor_no_prm%_workarea_left
				spreadFExp_4_2_1_x := monitor_%monitor_no_prm%_workarea_center_x
			}

			; Second. Check if only one of the two upper windows is wider than the half width of the screen
			if (((spreadFExp_4_1_2_w > monitor_%monitor_no_prm%_workarea_width / 2) and !(spreadFExp_4_2_2_w > monitor_%monitor_no_prm%_workarea_width / 2)) or (!(spreadFExp_4_1_2_w > monitor_%monitor_no_prm%_workarea_width / 2) and (spreadFExp_4_2_2_w > monitor_%monitor_no_prm%_workarea_width / 2))) {
				if (spreadFExp_4_1_2_w + spreadFExp_4_2_2_w > monitor_%monitor_no_prm%_workarea_width) { 	
					spreadFExp_4_1_2_x := monitor_%monitor_no_prm%_workarea_left 	; This is actually useless because it's useful when the right window may be longer than the left one.
					spreadFExp_4_2_2_x := spreadFExp_4_2_2_w > monitor_%monitor_no_prm%_workarea_width / 2 ? monitor_%monitor_no_prm%_workarea_center_x : monitor_%monitor_no_prm%_workarea_right - spreadFExp_4_2_2_w 	; This is actually useless because it's useful when the right window may be longer than the left one.
				} else {
					spreadFExp_4_1_2_x := monitor_%monitor_no_prm%_workarea_left
					spreadFExp_4_2_2_x := spreadFExp_4_1_2_x + spreadFExp_4_1_2_w
				}
			}
			; Check if both are wider than half width of the screen
			else if ((spreadFExp_4_1_2_w > monitor_%monitor_no_prm%_workarea_width / 2) and (spreadFExp_4_2_2_w > monitor_%monitor_no_prm%_workarea_width / 2)) {
				spreadFExp_4_1_2_x := monitor_%monitor_no_prm%_workarea_left
				spreadFExp_4_2_2_x := monitor_%monitor_no_prm%_workarea_center_x
			}

			;  - Adjusting y axis direction

			; first. Check if only one of the two bottom windows is wider than the half width of the screen
			if (((spreadFExp_4_1_2_h > monitor_%monitor_no_prm%_workarea_height / 2) and !(spreadFExp_4_1_1_h > monitor_%monitor_no_prm%_workarea_height / 2)) or (!(spreadFExp_4_1_2_h > monitor_%monitor_no_prm%_workarea_height / 2) and (spreadFExp_4_1_1_h > monitor_%monitor_no_prm%_workarea_height / 2))) {
				; sum of the two widths are bigger than the screen
				if (spreadFExp_4_1_2_h + spreadFExp_4_1_1_h > monitor_%monitor_no_prm%_workarea_height) {
					spreadFExp_4_1_2_y := monitor_%monitor_no_prm%_workarea_top 	; Like the x axis direction case, this and following line are useless because the upper window is already has longer height
					spreadFExp_4_1_1_y := monitor_%monitor_no_prm%_workarea_center_y > monitor_%monitor_no_prm%_workarea_bottom - spreadFExp_4_1_1_h ? monitor_%monitor_no_prm%_workarea_center_y : monitor_%monitor_no_prm%_workarea_bottom - spreadFExp_4_1_1_h
				} else {
					spreadFExp_4_1_2_y := monitor_%monitor_no_prm%_workarea_top
					spreadFExp_4_1_1_y := spreadFExp_4_1_2_y + spreadFExp_4_1_2_h
				}
			} 
			; Check if both are wider than half width of the screen
			else if ((spreadFExp_4_1_2_h > monitor_%monitor_no_prm%_workarea_height / 2) and (spreadFExp_4_1_1_h > monitor_%monitor_no_prm%_workarea_height / 2)) {
				spreadFExp_4_1_2_y := monitor_%monitor_no_prm%_workarea_top
				spreadFExp_4_1_1_y := monitor_%monitor_no_prm%_workarea_center_y
			}

			; Second. Check if only one of the two upper windows is wider than the half width of the screen
			if (((spreadFExp_4_2_2_h > monitor_%monitor_no_prm%_workarea_height / 2) and !(spreadFExp_4_2_1_h > monitor_%monitor_no_prm%_workarea_height / 2)) or (!(spreadFExp_4_2_2_h > monitor_%monitor_no_prm%_workarea_height / 2) and (spreadFExp_4_2_1_h > monitor_%monitor_no_prm%_workarea_height / 2))) {
				if (spreadFExp_4_2_2_h + spreadFExp_4_2_1_h > monitor_%monitor_no_prm%_workarea_height) {
					spreadFExp_4_2_2_y := monitor_%monitor_no_prm%_workarea_top 	; Like the x axis direction case, this and following line are useless because the upper window is already has longer height
					spreadFExp_4_2_1_y := spreadFExp_4_2_1_h > monitor_%monitor_no_prm%_workarea_height / 2 ? monitor_%monitor_no_prm%_workarea_center_y : monitor_%monitor_no_prm%_workarea_bottom - spreadFExp_4_2_1_h
				} else {
					spreadFExp_4_2_2_y := monitor_%monitor_no_prm%_workarea_top
					spreadFExp_4_2_1_y := spreadFExp_4_2_2_y + spreadFExp_4_2_2_h
				}
			}
			; Check if both are wider than half width of the screen
			else if ((spreadFExp_4_2_2_h > monitor_%monitor_no_prm%_workarea_height / 2) and (spreadFExp_4_2_1_h > monitor_%monitor_no_prm%_workarea_height / 2)) {
				spreadFExp_4_2_2_y := monitor_%monitor_no_prm%_workarea_top
				spreadFExp_4_2_1_y := monitor_%monitor_no_prm%_workarea_center_y
			}

			; Adjusting done.

			; Now move and put windows

				WinMove, % "ahk_id " spreadFExp_4_1_1_ID, , spreadFExp_4_1_1_x, spreadFExp_4_1_1_y 
				WinMove, % "ahk_id " spreadFExp_4_1_2_ID, , spreadFExp_4_1_2_x, spreadFExp_4_1_2_y 
				WinMove, % "ahk_id " spreadFExp_4_2_1_ID, , spreadFExp_4_2_1_x, spreadFExp_4_2_1_y 
				WinMove, % "ahk_id " spreadFExp_4_2_2_ID, , spreadFExp_4_2_2_x, spreadFExp_4_2_2_y 
				
				

				WinSet, AlwaysOnTop, On, % "ahk_id " spreadFExp_4_1_2_ID
				WinSet, AlwaysOnTop, On, % "ahk_id " spreadFExp_4_2_2_ID
				WinSet, AlwaysOnTop, On, % "ahk_id " spreadFExp_4_1_1_ID
				WinSet, AlwaysOnTop, On, % "ahk_id " spreadFExp_4_2_1_ID
				WinSet, AlwaysOnTop, Off, % "ahk_id " spreadFExp_4_1_2_ID
				WinSet, AlwaysOnTop, Off, % "ahk_id " spreadFExp_4_2_2_ID
				WinSet, AlwaysOnTop, Off, % "ahk_id " spreadFExp_4_1_1_ID
				WinSet, AlwaysOnTop, Off, % "ahk_id " spreadFExp_4_2_1_ID

				WinActivate, % "ahk_id " AltTabListSameType[1].ID


		} else if (AltTabListSameType.length() >= 5) {
			;   (1,2)-(2,2)   n - 3
			;       mid     ..,5,4      ; 1st one is the largest one. n-th one is the smallest one.         
			;   (1,1)-(2,1)   2 - 1

			FExp_onDiag_no := AltTabListSameType.length() - 4
			
			; sort by areas in descending order 
			; the last windows are smallest windows
			AltTabListSameType_sorted_area_desc := AltTabListSameType.Clone()
			Sort_Object(AltTabListSameType_sorted_area_desc, "area", 0)
			
			; preparation for sorting - assigning ID
;		 	Loop, % AltTabListSameType.length() { 
;				AltTabListSameType_sorted_area_desc[A_Index].ID := AltTabListSameType[A_Index].ID  		
;				AltTabListSameType_sorted_area_desc[A_Index].area := AltTabListSameType[A_Index].width * AltTabListSameType[A_Index].height
;			}
;			Loop, % AltTabListSameType.length() - 1 {
;				Loop, % AltTabListSameType.length() - A_Index {
;					nextIndex := A_Index + 1
;					if (AltTabListSameType_sorted_area_desc[A_Index].area < AltTabListSameType_sorted_area_desc[nextIndex].area) {
;						swap := AltTabListSameType_sorted_area_desc[A_Index].area
;						AltTabListSameType_sorted_area_desc[A_Index].area := AltTabListSameType_sorted_area_desc[nextIndex].area
;						AltTabListSameType_sorted_area_desc[nextIndex].area := swap
;						swap := AltTabListSameType_sorted_area_desc[A_Index].ID 														; assigning ID
;						AltTabListSameType_sorted_area_desc[A_Index].ID := AltTabListSameType_sorted_area_desc[nextIndex].ID 					; assigning ID
;						AltTabListSameType_sorted_area_desc[nextIndex].ID := swap  													; assigning ID
;					}
;				}
;			}
;			Loop, % AltTabListSameType.length() {
;				WinGetPos, , , temp_w, temp_h , % "ahk_id " AltTabListSameType_sorted_area_desc[A_Index].ID
;				AltTabListSameType_sorted_area_desc[A_Index].width := temp_w 	
;				AltTabListSameType_sorted_area_desc[A_Index].height := temp_h
;			}
			;;;;;;;;;;;;;;;;;;;;;;;;;; sorting is done.

			; 4th, 5th, ... , (n-1)th will be put diagonally.

			; From now on, working with location-based windows
			; initial setting: 4 windows are all put at the corner of the screen (differently from when there are only 4 windows)
			spreadFExp_4_1_1_ID := AltTabListSameType_sorted_area_desc[2].ID
			spreadFExp_4_1_1_w := AltTabListSameType_sorted_area_desc[2].width
			spreadFExp_4_1_1_h := AltTabListSameType_sorted_area_desc[2].height
			spreadFExp_4_1_1_x := monitor_%monitor_no_prm%_workarea_left
			spreadFExp_4_1_1_y := monitor_%monitor_no_prm%_workarea_bottom - spreadFExp_4_1_1_h 

			spreadFExp_4_2_1_ID := AltTabListSameType_sorted_area_desc[1].ID
			spreadFExp_4_2_1_w := AltTabListSameType_sorted_area_desc[1].width
			spreadFExp_4_2_1_h := AltTabListSameType_sorted_area_desc[1].height
			spreadFExp_4_2_1_x := monitor_%monitor_no_prm%_workarea_right - spreadFExp_4_2_1_w
			spreadFExp_4_2_1_y := monitor_%monitor_no_prm%_workarea_bottom - spreadFExp_4_2_1_h

			SameTypeWinNo := AltTabListSameType.length()
			spreadFExp_4_1_2_ID := AltTabListSameType_sorted_area_desc[SameTypeWinNo].ID
			spreadFExp_4_1_2_w := AltTabListSameType_sorted_area_desc[SameTypeWinNo].width
			spreadFExp_4_1_2_h := AltTabListSameType_sorted_area_desc[SameTypeWinNo].height
			spreadFExp_4_1_2_x := monitor_%monitor_no_prm%_workarea_left
			spreadFExp_4_1_2_y := monitor_%monitor_no_prm%_workarea_top

			spreadFExp_4_2_2_ID := AltTabListSameType_sorted_area_desc[3].ID
			spreadFExp_4_2_2_w := AltTabListSameType_sorted_area_desc[3].width
			spreadFExp_4_2_2_h := AltTabListSameType_sorted_area_desc[3].height
			spreadFExp_4_2_2_x := monitor_%monitor_no_prm%_workarea_right - spreadFExp_4_2_2_w
			spreadFExp_4_2_2_y := monitor_%monitor_no_prm%_workarea_top

			WinMove, % "ahk_id " spreadFExp_4_1_1_ID, , spreadFExp_4_1_1_x, spreadFExp_4_1_1_y 
			WinMove, % "ahk_id " spreadFExp_4_1_2_ID, , spreadFExp_4_1_2_x, spreadFExp_4_1_2_y 
			WinMove, % "ahk_id " spreadFExp_4_2_1_ID, , spreadFExp_4_2_1_x, spreadFExp_4_2_1_y 
			WinMove, % "ahk_id " spreadFExp_4_2_2_ID, , spreadFExp_4_2_2_x, spreadFExp_4_2_2_y 

			WinSet, AlwaysOnTop, On, % "ahk_id " spreadFExp_4_1_2_ID
			WinSet, AlwaysOnTop, Off, % "ahk_id " spreadFExp_4_1_2_ID
			WinSet, AlwaysOnTop, On, % "ahk_id " spreadFExp_4_2_2_ID
			WinSet, AlwaysOnTop, Off, % "ahk_id " spreadFExp_4_2_2_ID
			WinSet, AlwaysOnTop, On, % "ahk_id " spreadFExp_4_1_1_ID
			WinSet, AlwaysOnTop, Off, % "ahk_id " spreadFExp_4_1_1_ID

			; finding positions for the windows to put diagonally
			; putting diagonally, overlapping
			spreadFExp_left := monitor_%monitor_no_prm%_workarea_left
			spreadFExp_top := monitor_%monitor_no_prm%_workarea_top
			spreadFExp_end_x := monitor_%monitor_no_prm%_workarea_right - spreadFExp_4_2_1_w		; The top one will be right down corner and top
			spreadFExp_end_y := monitor_%monitor_no_prm%_workarea_bottom - spreadFExp_4_2_1_h 		; The top one will be right down corner and top
			spreadFExp_step_width := (spreadFExp_end_x - spreadFExp_left) / (FExp_onDiag_no + 1)
			spreadFExp_step_height := (spreadFExp_end_y - spreadFExp_top) / (FExp_onDiag_no + 1)
			Loop, % FExp_onDiag_no {
				temp_index := AltTabListSameType.length() - A_Index
				spreadFExpEach_x := spreadFExp_left + spreadFExp_step_width * A_Index
				spreadFExpEach_y := spreadFExp_top + spreadFExp_step_height * A_Index
				WinMove, % "ahk_id " AltTabListSameType_sorted_area_desc[temp_index].ID, , spreadFExpEach_x, spreadFExpEach_y 
				WinSet, AlwaysOnTop, On, % "ahk_id " AltTabListSameType_sorted_area_desc[temp_index].ID
				WinSet, AlwaysOnTop, Off, % "ahk_id " AltTabListSameType_sorted_area_desc[temp_index].ID
			}

				WinSet, AlwaysOnTop, On, % "ahk_id " spreadFExp_4_2_1_ID
				WinSet, AlwaysOnTop, Off, % "ahk_id " spreadFExp_4_2_1_ID

				WinActivate, % "ahk_id " AltTabListSameType[1].ID

		;} else if (AltTabListSameType.length() <= monitor_%monitor_no_prm%_grid_no_xy) {
		} else {
			; putting diagonally, overlapping
			spreadFExp_left := monitor_%monitor_no_prm%_workarea_left
			spreadFExp_top := monitor_%monitor_no_prm%_workarea_top
			spreadFExp_end_x := monitor_%monitor_no_prm%_workarea_right - AltTabListSameType[1].width		; The top one will be right down corner and top
			spreadFExp_end_y := monitor_%monitor_no_prm%_workarea_bottom - AltTabListSameType[1].height 	; The top one will be right down corner and top
			spreadFExp_step_width := (spreadFExp_end_x - spreadFExp_left) / (AltTabListSameType.length() - 1)
			spreadFExp_step_height := (spreadFExp_end_y - spreadFExp_top) /(AltTabListSameType.length() - 1)
			Loop, % AltTabListSameType.length() {
				temp_index := AltTabListSameType.length() - A_Index + 1
				spreadFExpEach_x := spreadFExp_left + spreadFExp_step_width * (A_Index - 1)
				spreadFExpEach_y := spreadFExp_top + spreadFExp_step_height * (A_Index - 1)
				WinMove, % "ahk_id " AltTabListSameType[temp_index].ID, , spreadFExpEach_x, spreadFExpEach_y 	; When SetWinDelay, -1 is declared, WinMove is as fast as DllCall("MoveWindow".. .
				WinSet, AlwaysOnTop, On, % "ahk_id " AltTabListSameType[temp_index].ID
				WinSet, AlwaysOnTop, Off, % "ahk_id " AltTabListSameType[temp_index].ID
			}
			WinActivate, % "ahk_id " AltTabListSameType[1].ID
		}
	}

}