; FrogControl lib - shared helper functions (moved out of FrogControl.ahk 2026-07-05).
; Functions only: no hotkeys, no auto-execute code.

; =====================================================================================
; ===================== Helper functions (2026-07-05 refactor) ========================
; =====================================================================================

CollectMonitorInfo() {
	; Fills the global monitor_* pseudo-arrays used across the script:
	;   monitor_no, monitor_no_prm,
	;   monitor_<i>_left/right/top/bottom, monitor_<i>_workarea_left/right/top/bottom,
	;   monitor_<i>_workarea_width/height/ratio/center_x/center_y
	global
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
	}
}

CountRecentTaps(vKey, windowMs := 1500) {
	; Counts how many time stamps of the given modifier (in the timeStamp_<key>_* ring,
	; written by the ~Alt::/~Control::/~Shift::/~LWin::/~RWin::/CapsLock:: block)
	; are younger than windowMs. Used by all "tap N times to speed up" features.
	global
	crt_count := 0
	crt_now := A_TickCount
	loop, % timeStamp_modfr_max {
		if (crt_now - timeStamp_%vKey%_%A_Index% < windowMs)
			crt_count++
	}
	Return crt_count
}

Volume_Adjust(delta) {
	; delta is a relative adjustment string like "+10" or "-1" (SoundSet treats a leading +/- as relative).
	global SETTING_CONSTANT_TOOLTIPDUR_S
	SoundSet, %delta%
	SoundGet, va_volume
	ToolTip, % "volume: " Round(va_volume)
	SetTimer, RemoveToolTip, % SETTING_CONSTANT_TOOLTIPDUR_S
}

WheelScroll_CapsFast(dirDown) {
	; CapsLock + WheelDown/WheelUp: accelerated scrolling; tap CapsLock repeatedly beforehand to raise the level.
	; In Excel with Shift held, scrolls horizontally via COM instead.
	global
	if (!WheelScroll_fast_lv1_started) {
		WheelScroll_fast_lv1_started := 1
		wheelScroll_speedUp := wheelScroll_speedUp_default * (1 + CountRecentTaps("CapsLock")) 	; the last CapsLock press (still held) is not stamped, hence 1 +
	}
	WinGetClass, wheelScroll_activeClass, A 	; one cheap query instead of enumerating every window per wheel tick
	if ((wheelScroll_activeClass = "XLMAIN") and GetKeyState("Shift")) {
		wheelScroll_speedUp_Excel := wheelScroll_speedUp + wheelScroll_speedUp_default
		try {
			if (dirDown)
				ComObjActive("Excel.Application").ActiveWindow.SmallScroll(0,0, wheelScroll_speedUp_Excel)  ; Scroll right.   (credit: Learning one  https://autohotkey.com/board/topic/35292-horizontal-scroll-in-excel-2007/)
			else
				ComObjActive("Excel.Application").ActiveWindow.SmallScroll(0,0,0, wheelScroll_speedUp_Excel)  ; Scroll left.
		} catch e { 	; COM unavailable (Excel busy/not registered): fall back to plain wheel clicks
			if (dirDown)
				Click WheelDown %wheelScroll_speedUp%
			else
				Click WheelUp %wheelScroll_speedUp%
		}
	} else {
		if (dirDown)
			Click WheelDown %wheelScroll_speedUp%
		else
			Click WheelUp %wheelScroll_speedUp%
	}
	if (WheelScroll_fast_lv1_started = 1)
		SetTimer, WheelScroll_fast_first, -1
}

WheelScroll_OfficeFast(dirDown) {
	; Shift + WheelDown/WheelUp inside Excel/Word (#if context): horizontal scroll via COM;
	; tap Shift repeatedly beforehand to raise the level.
	global
	if (!WheelScroll_fast_lv1_started) {
		WheelScroll_fast_lv1_started := 1
		wheelScroll_speedUp := wheelScroll_speedUp_default * CountRecentTaps("Shift")
		wheelScroll_speedUp_Excel := wheelScroll_speedUp = 0 ? wheelScroll_speedUp_default : wheelScroll_speedUp
		wheelScroll_speedUp := wheelScroll_speedUp - wheelScroll_speedUp_default
	}
	WinGetClass, wheelScroll_activeClass, A
	try {
		if (dirDown)
			ComObjActive((wheelScroll_activeClass = "XLMAIN"? "Excel":"Word") ".Application").ActiveWindow.SmallScroll(0,0,wheelScroll_speedUp_Excel)  ; Scroll right.
		else
			ComObjActive((wheelScroll_activeClass = "XLMAIN"? "Excel":"Word") ".Application").ActiveWindow.SmallScroll(0,0,0,wheelScroll_speedUp_Excel)  ; Scroll left.
	} catch e { 	; COM unavailable: fall back to a plain wheel click
		if (dirDown)
			Click WheelDown
		else
			Click WheelUp
	}
	if (wheelScroll_speedUp_Excel/wheelScroll_speedUp_default < 2) {
		WheelScroll_fast_lv1_started := 0
	} else if (WheelScroll_fast_lv1_started = 1) {
		SetTimer, WheelScroll_fast_first, -1
	}
}

ShowHelp(lang) {
	; Builds the help window (shared by the tray menu items and CapsLock & ?).
	global AppName, AppVersion, AppUpdateDate, AppSite, AppAuthor, AppAuthorEmail, FLAG_HELP_LANG
	if (lang = "ko") {
		guiName := "helpKo"
		listFile := A_ScriptDir . "\shortcut list-ko.txt"
		helpTitle := "프로그 컨트롤(FrogControl) 도움말"
		listLabel := "단축키 목록"
		authorLabel := "제작자 : " AppAuthor
		FLAG_HELP_LANG := 2
	} else {
		guiName := "helpEn"
		listFile := A_ScriptDir . "\shortcut list-en.txt"
		helpTitle := AppName " Help"
		listLabel := "Shortcut list"
		authorLabel := "Created by " AppAuthor
		FLAG_HELP_LANG := 1
	}
	Gui, %guiName%: Destroy 	; Gui New does NOT replace an existing same-name window; without this, windows accumulate
	Gui, %guiName%: New
	If (!A_IsCompiled && FileExist(A_ScriptDir . "\frog face icon 3.ico")) {
		Gui, %guiName%: Add, Picture, w40 h40, %A_ScriptDir%\frog face icon 3.ico
	} else {
		Gui, %guiName%: Add, Picture, icon1, %A_WorkingDir%\FrogControl.exe
	}
	Gui, %guiName%: Font, s15
	Gui, %guiName%: Add, Text, x+10 yp+10, % helpTitle
	Gui, %guiName%: Font
	Gui, %guiName%: Add, Text, xm, % listLabel
	Gui, %guiName%: Font, , Consolas
	Gui, %guiName%: Add, ListView, r25 w1111, Hotkey|Action
	if (!FileExist(listFile)) {
		LV_Add("", "(file not found)", listFile)
	} else {
		Loop, read, %listFile%
		{
			inLine_1 := ""
			inLine_2 := ""
			Loop, parse, A_LoopReadLine, %A_Tab%
			{
				inLine_%A_Index% := A_LoopField
			}
			LV_Add("", inLine_1, inLine_2)
		}
	}
	LV_ModifyCol()  ; Auto-size each column to fit its contents.

	Gui, %guiName%: Font
	Gui, %guiName%: Add, Text,,
	Gui, %guiName%: Add, Text, xm, % "Version " AppVersion " (" AppUpdateDate ")"
	Gui, %guiName%: Add, Link, y+3, % "<a href=""" AppSite """>" AppSite "</a>"
	Gui, %guiName%: Add, Text, x+10 yp+10,
	Gui, %guiName%: Font
	Gui, %guiName%: Add, Text, xm, % authorLabel
	Gui, %guiName%: Add, Link, y+3, % "<a href=""mailto:" AppAuthorEmail """>" AppAuthorEmail "</a>"
	Gui, %guiName%: Add, Text, xm, % "Free software under the GNU GPL v3."
	Gui, %guiName%: Font
	Gui, %guiName%: Add, Text, y+0, `t
	Gui, %guiName%: Add, Button, GABOUTOK Default w75, &OK
	GuiControl, Focus, &OK
	Gui, %guiName%: Show, , FrogControl Help
}

DWM_WinMove(winTitle, x := "", y := "", w := "", h := "") {
	; Moves/resizes a window so its VISIBLE frame (DWMWA_EXTENDED_FRAME_BOUNDS) lands exactly on the
	; given rectangle, compensating for the invisible resize borders of Windows 10/11 (~7 px per side).
	; Empty parameters leave that dimension unchanged, like WinMove. Used by the snap/grid placements.
	hwnd := WinExist(winTitle)
	if (!hwnd)
		Return
	VarSetCapacity(rect, 16, 0)
	VarSetCapacity(ext, 16, 0)
	DllCall("GetWindowRect", "Ptr", hwnd, "Ptr", &rect)
	if (DllCall("dwmapi\DwmGetWindowAttribute", "Ptr", hwnd, "UInt", 9, "Ptr", &ext, "UInt", 16) != 0) { 	; 9 = DWMWA_EXTENDED_FRAME_BOUNDS
		WinMove, ahk_id %hwnd%, , %x%, %y%, %w%, %h% 	; DWM info unavailable: behave like a plain WinMove
		Return
	}
	bL := NumGet(ext, 0, "Int") - NumGet(rect, 0, "Int")
	bT := NumGet(ext, 4, "Int") - NumGet(rect, 4, "Int")
	bR := NumGet(rect, 8, "Int") - NumGet(ext, 8, "Int")
	bB := NumGet(rect, 12, "Int") - NumGet(ext, 12, "Int")
	nx := (x = "") ? "" : x - bL
	ny := (y = "") ? "" : y - bT
	nw := (w = "") ? "" : w + bL + bR
	nh := (h = "") ? "" : h + bT + bB
	WinMove, ahk_id %hwnd%, , %nx%, %ny%, %nw%, %nh%
}

WindowRotate_OnWheel(isPopup, dirDown) {
	; Shared body of the four window-rotation hotkeys:
	;   !^Wheel / !^[ ] = rotate while stacking,   #!^Wheel / #!^[ ] = rotate as popup (temporary showing around)
	global
	if (isPopup ? window_rotate_firstcheck : window_rotate_firstcheck_popup) 	; the other mode's loop is live; don't touch the shared counters
		Return
	if (!(isPopup ? window_rotate_firstcheck_popup : window_rotate_firstcheck)) { 	; first wheel notch: initialize and start the rotation loop
		if (isPopup)
			window_rotate_firstcheck_popup := 1
		else
			window_rotate_firstcheck := 1
		wheel_count_down := dirDown ? 1 : -1
		wheel_count_check := 0
		AltTab_window_list()
		Loop, %AltTab_ID_List_0% {
			; Basically WinSet, Bottom revokes the WS_EX_TOPMOST (always on top) state.
			WinGet, var_ExStyle, ExStyle, % "ahk_id " AltTab_ID_List_%A_Index%
			if (!isPopup)
				Winset, AlwaysOnTop, Off, % "ahk_id " AltTab_ID_List_%A_Index% 	; when rotating with stacking, topmost windows must be coverable
			if !(var_ExStyle & 0x8) { 	; 0x8 is WS_EX_TOPMOST (always on top)
				AltTab_ID_List_topOfNontopmost := A_Index
				break
			}
		}
		window_rotate_current := (isPopup and dirDown) ? AltTab_ID_List_topOfNontopmost : 1
		if (isPopup)
			SetTimer, window_rotate_popup, -1
		else
			SetTimer, window_rotate_stacking, -1
		Return
	}
	wheel_count_down += dirDown ? 1 : -1
}

PulseTop(vID) {
	; Raises a window by momentarily making it AlwaysOnTop, then releasing.
	; NOTE: as with the original inline pairs, a window that was ALREADY topmost loses that state.
	WinSet, AlwaysOnTop, On, % "ahk_id " vID
	WinSet, AlwaysOnTop, Off, % "ahk_id " vID
}

SeekArrow_Step(dirX, dirY, keyName) {
	; One navigation step of the Win+Ctrl+Alt+Arrow window seeker: dim the current window,
	; pick the best window in the given direction, highlight and raise it.
	global
	WinSet, Transparent, % SETTING_CONSTANT_HALFTRANS, % "ahk_id " AltTab_ID_List_woMinWin_%window_current%
	sa_next := SeekArrow_FindNext(dirX, dirY)
	if (sa_next)
		window_current := sa_next
	WinSet, Transparent, % SETTING_CONSTANT_FOCUSTRANS, % "ahk_id " AltTab_ID_List_woMinWin_%window_current%
	PulseTop(AltTab_ID_List_woMinWin_%window_current%)
	WinGetTitle, sa_title, % "ahk_id " AltTab_ID_List_woMinWin_%window_current%
	tooltip % sa_title
	SetTimer, RemoveToolTip, % SETTING_CONSTANT_TOOLTIPDUR_S
	KeyWait, %keyName%, T0.2 	; wait for release of the arrow key, timeout for auto-repeat stepping
}

SeekArrow_FindNext(dirX, dirY) {
	; Returns the index (into AltTab_ID_List_woMinWin_*) of the best window in direction
	; (dirX,dirY) from the current one, or 0 if none. Scoring: projection along the
	; direction (must be positive) plus twice the lateral offset - the nearest window
	; that lies most directly in the pressed direction wins. Exactly-stacked windows
	; (same center) are reachable as a last resort, cycling in list order.
	global
	WinGetPos, sa_cx, sa_cy, sa_cw, sa_ch, % "ahk_id " AltTab_ID_List_woMinWin_%window_current%
	sa_cenx := sa_cx + sa_cw/2
	sa_ceny := sa_cy + sa_ch/2
	sa_best := 0
	sa_bestScore := ""
	Loop, %AltTab_ID_List_woMinWin_0% {
		if (A_Index = window_current)
			continue
		WinGetPos, sa_x, sa_y, sa_w, sa_h, % "ahk_id " AltTab_ID_List_woMinWin_%A_Index%
		sa_dx := sa_x + sa_w/2 - sa_cenx
		sa_dy := sa_y + sa_h/2 - sa_ceny
		if (sa_dx = 0 and sa_dy = 0) {
			sa_score := 999999999 + A_Index 	; same center: last-resort candidate
		} else {
			sa_proj := sa_dx*dirX + sa_dy*dirY
			if (sa_proj <= 0)
				continue
			sa_score := sa_proj + Abs(sa_dx*dirY - sa_dy*dirX)*2
		}
		if (sa_best = 0 or sa_score < sa_bestScore) {
			sa_best := A_Index
			sa_bestScore := sa_score
		}
	}
	Return sa_best
}

Monitor_EdgeScan(mode, X, Y, W, H) {
	; Scans all monitors' work areas (CollectMonitorInfo must have run) and returns the nearest
	; relevant edge coordinate for moving/resizing the window rect (X,Y,W,H) toward a direction,
	; or "" if no monitor qualifies. This replaces twelve near-identical collect-then-min/max loops.
	;   *_edge = attach the window's own side to that screen edge
	;   *_gap  = jump to the facing edge of the next monitor in that direction
	global
	mes_result := ""
	Loop, %monitor_no% {
		mes_vOv := (monitor_%A_Index%_workarea_top < Y + H) and (Y < monitor_%A_Index%_workarea_bottom)
		mes_hOv := (monitor_%A_Index%_workarea_left < X + W) and (X < monitor_%A_Index%_workarea_right)
		mes_cand := ""
		if (mode = "right_edge" and mes_vOv and X + W < monitor_%A_Index%_workarea_right)
			mes_cand := monitor_%A_Index%_workarea_right
		else if (mode = "right_gap" and mes_vOv and X < monitor_%A_Index%_workarea_left)
			mes_cand := monitor_%A_Index%_workarea_left
		else if (mode = "left_edge" and mes_vOv and monitor_%A_Index%_workarea_left < X)
			mes_cand := monitor_%A_Index%_workarea_left
		else if (mode = "left_gap" and mes_vOv and monitor_%A_Index%_workarea_right < X + W)
			mes_cand := monitor_%A_Index%_workarea_right
		else if (mode = "up_edge" and mes_hOv and monitor_%A_Index%_workarea_top < Y)
			mes_cand := monitor_%A_Index%_workarea_top
		else if (mode = "up_gap" and mes_hOv and monitor_%A_Index%_workarea_bottom < Y + H)
			mes_cand := monitor_%A_Index%_workarea_bottom
		else if (mode = "down_edge" and mes_hOv and Y + H < monitor_%A_Index%_workarea_bottom)
			mes_cand := monitor_%A_Index%_workarea_bottom
		else if (mode = "down_gap" and mes_hOv and Y < monitor_%A_Index%_workarea_top)
			mes_cand := monitor_%A_Index%_workarea_top
		if (mes_cand = "")
			continue
		if (mes_result = "")
			mes_result := mes_cand
		else if (InStr(mode, "right") or InStr(mode, "down"))
			mes_result := mes_cand < mes_result ? mes_cand : mes_result 	; toward increasing coordinates: nearest = minimum
		else
			mes_result := mes_cand > mes_result ? mes_cand : mes_result 	; toward decreasing coordinates: nearest = maximum
	}
	Return mes_result
}

DWM_GetBorders(vID, ByRef bL, ByRef bT, ByRef bR, ByRef bB) {
	; Measures the invisible DWM border thickness on each side of the window. Zeroes if unavailable.
	bL := 0
	bT := 0
	bR := 0
	bB := 0
	VarSetCapacity(dgb_rect, 16, 0)
	VarSetCapacity(dgb_ext, 16, 0)
	if (!DllCall("GetWindowRect", "Ptr", vID+0, "Ptr", &dgb_rect))
		Return
	if (DllCall("dwmapi\DwmGetWindowAttribute", "Ptr", vID+0, "UInt", 9, "Ptr", &dgb_ext, "UInt", 16) != 0) 	; 9 = DWMWA_EXTENDED_FRAME_BOUNDS
		Return
	bL := NumGet(dgb_ext, 0, "Int") - NumGet(dgb_rect, 0, "Int")
	bT := NumGet(dgb_ext, 4, "Int") - NumGet(dgb_rect, 4, "Int")
	bR := NumGet(dgb_rect, 8, "Int") - NumGet(dgb_ext, 8, "Int")
	bB := NumGet(dgb_rect, 12, "Int") - NumGet(dgb_ext, 12, "Int")
}

DWM_GetVisibleRect(vID, ByRef x, ByRef y, ByRef w, ByRef h) {
	; Replaces a WinGetPos-style rect with the window's VISIBLE frame rect
	; (DWMWA_EXTENDED_FRAME_BOUNDS). Leaves the values untouched if DWM info is unavailable.
	VarSetCapacity(dvr_ext, 16, 0)
	if (DllCall("dwmapi\DwmGetWindowAttribute", "Ptr", vID+0, "UInt", 9, "Ptr", &dvr_ext, "UInt", 16) = 0) {
		x := NumGet(dvr_ext, 0, "Int")
		y := NumGet(dvr_ext, 4, "Int")
		w := NumGet(dvr_ext, 8, "Int") - x
		h := NumGet(dvr_ext, 12, "Int") - y
	}
}

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
