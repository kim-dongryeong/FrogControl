; FrogControl lib - window arrangement engine (moved out of FrogControl.ahk 2026-07-05).

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
	}
	; (grid dimensions are computed in the girdMode=1 branch below, from the window count and the screen aspect ratio)


	if (StrLen(vProcessName) > 0) {
		AltTabListSameType := AltTab_List_SameType("", vProcessName)
	} else if (StrLen(vID) > 0) {
		AltTabListSameType := AltTab_List_SameType(vID, "")
	}




	; When there is no matching window: optionally launch the process, then stop (the layout code below assumes a non-empty list).
	if (AltTabListSameType.length() < 1) {
		if (StrLen(vProcessName))
			Run, % vProcessName
		Return
	}

	vClass := AltTabListSameType[1].Class
	AltTab_List := AltTab_window_list()


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
		; grid derived from the window count and the screen aspect ratio
		; (replaces the old fixed 800x450-per-cell heuristic and its grid-growing loop)
		SameTypeWinCount := AltTabListSameType.length()
		monitor_%monitor_no_prm%_grid_no_x := Ceil(Sqrt(SameTypeWinCount * monitor_%monitor_no_prm%_workarea_width / monitor_%monitor_no_prm%_workarea_height))
		if (monitor_%monitor_no_prm%_grid_no_x < 1)
			monitor_%monitor_no_prm%_grid_no_x := 1
		monitor_%monitor_no_prm%_grid_no_y := Ceil(SameTypeWinCount / monitor_%monitor_no_prm%_grid_no_x)
		if (monitor_%monitor_no_prm%_grid_no_y < 1)
			monitor_%monitor_no_prm%_grid_no_y := 1
		monitor_%monitor_no_prm%_grid_width := monitor_%monitor_no_prm%_workarea_width / monitor_%monitor_no_prm%_grid_no_x
		monitor_%monitor_no_prm%_grid_height := monitor_%monitor_no_prm%_workarea_height / monitor_%monitor_no_prm%_grid_no_y
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
				DWM_WinMove("ahk_id " AltTabListSameType[counterRvs].ID, monitor_%monitor_no_prm%_workarea_left + monitor_%monitor_no_prm%_grid_width * (loop_1_indexRev - 1), monitor_%monitor_no_prm%_workarea_top + monitor_%monitor_no_prm%_grid_height * (loop_2_indexRev - 1), monitor_%monitor_no_prm%_grid_width, monitor_%monitor_no_prm%_grid_height)
				PulseTop(AltTabListSameType[counterRvs].ID)
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
			DWM_GetVisibleRect(AltTabListSameType[A_Index].ID, temp_x, temp_y, temp_w, temp_h) 	; measure the VISIBLE frame so spread layouts sit flush
			AltTabListSameType[A_Index].x := temp_x  
			AltTabListSameType[A_Index].y := temp_y
			AltTabListSameType[A_Index].width := temp_w
			AltTabListSameType[A_Index].height := temp_h  
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
					AltTabListSameType[index].mon := A_Index 	; (A_Index here is the monitor loop's index; "index" is the window index captured above)
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
				DWM_WinMove("ahk_id " AltTabListSameType[temp_index].ID, spreadFExp_left, spreadFExp_top)
				PulseTop(AltTabListSameType[temp_index].ID)
				spreadFExp_left += AltTabListSameType[temp_index].width
			}
			WinActivate, % "ahk_id " AltTabListSameType[1].ID 	; activate once after the loop (was per-window inside the loop: focus churn and flicker)
		} else if (AltTabListSameType.all_h <= monitor_%monitor_no_prm%_workarea_height) { 	; putting vertically all together
			spreadFExp_left := monitor_%monitor_no_prm%_workarea_center_x - AltTabListSameType.max_w / 2
			spreadFExp_top := monitor_%monitor_no_prm%_workarea_center_y - AltTabListSameType.all_h / 2
			Loop, % AltTabListSameType.length() {
				temp_index := AltTabListSameType.length() - A_Index + 1
				DWM_WinMove("ahk_id " AltTabListSameType[temp_index].ID, spreadFExp_left, spreadFExp_top)
				;DllCall("MoveWindow", UInt, AltTabListSameType[temp_index].ID, UInt, spreadFExpEach_x, UInt, spreadFExpEach_y, UInt, AltTabListSameType[temp_index].width, UInt, AltTabListSameType[temp_index].height, Int, 1)
				PulseTop(AltTabListSameType[temp_index].ID)
				spreadFExp_top += AltTabListSameType[temp_index].height
			}
			WinActivate, % "ahk_id " AltTabListSameType[1].ID 	; activate once after the loop (was per-window inside the loop: focus churn and flicker)
		} else if ((monitor_%monitor_no_prm%_workarea_width // 800 <= 1) or (monitor_%monitor_no_prm%_workarea_height // 450 <= 1)) {  	; in case the screen is so narrow
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
				DWM_WinMove("ahk_id " AltTabListSameType[temp_index].ID, spreadFExpEach_x, spreadFExpEach_y) 	; When SetWinDelay, -1 is declared, WinMove is as fast as DllCall("MoveWindow".. .
				;DllCall("MoveWindow", UInt, AltTabListSameType[temp_index].ID, UInt, spreadFExpEach_x, UInt, spreadFExpEach_y, UInt, AltTabListSameType[temp_index].width, UInt, AltTabListSameType[temp_index].height, Int, 1)
				PulseTop(AltTabListSameType[temp_index].ID)
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




			;AltTabListSameType_sorted_w_norm_desc := {}
			;AltTabListSameType_sorted_h_norm_desc := {}
			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; the problem
			; Clone() is shallow: both sorted lists share the element objects with AltTabListSameType.
			; Sort_Object only reorders references, so sharing is fine as long as elements are not mutated.
			; Reads below use .width_norm/.height_norm (set above) instead of mutating .width in place,
			; which corrupted the shared objects (this was "the problem").
			AltTabListSameType_sorted_w_norm_desc := AltTabListSameType.Clone()
			AltTabListSameType_sorted_h_norm_desc := AltTabListSameType.Clone()
			Sort_Object(AltTabListSameType_sorted_w_norm_desc, "width_norm", 0)
			Sort_Object(AltTabListSameType_sorted_h_norm_desc, "height_norm", 0)
			


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
			}
			;;;;;;;;;;;;;;;;;;;;;;;;;; sorting is done.

			if (AltTabListSameType_sorted_w_norm_desc[1].width_norm > AltTabListSameType_sorted_h_norm_desc[1].height) { 	; horizontal max is bigger than vertical max (in normalized values)
				FExpStack_bottomFExp := AltTabListSameType_sorted_w_norm_desc[1].ID
				FExpStack_bottomFExp_w_norm := AltTabListSameType_sorted_w_norm_desc[1].width_norm
				FExpStack_bottomFExp_h_norm := AltTabListSameType_sorted_w_norm_desc[1].height
				FExpStack_leftFExp := ""
				FExpStack_rightFExp := ""

				sum_theOthers_w_norm := 0 	; sum of all the widths except the longest one.
				Loop, % AltTabListSameType.length() - 1 {
					nextIndex := A_Index + 1
					sum_theOthers_w_norm += AltTabListSameType_sorted_w_norm_desc[nextIndex].width_norm 	; (was adding the object itself, not its width)
				}
				over_w_norm := sum_theOthers_w_norm - monitor_%monitor_no_prm%_workarea_width * monitor_%monitor_no_prm%_workarea_ratio > 0 ? sum_theOthers_w_norm - monitor_%monitor_no_prm%_workarea_width * monitor_%monitor_no_prm%_workarea_ratio : 0
				horizontalLength_norm_net := sum_theOthers_w_norm - over_w_norm > AltTabListSameType_sorted_w_norm_desc[1].width_norm ? sum_theOthers_w_norm - over_w_norm : AltTabListSameType_sorted_w_norm_desc[1].width_norm
				horizontalLength_norm_net := horizontalLength_norm_net < monitor_%monitor_no_prm%_workarea_width ? horizontalLength_norm_net : monitor_%monitor_no_prm%_workarea_width 	; in case AltTabListSameType_sorted_w_norm_desc[1].width_norm > monitor_%monitor_no_prm%_workarea_width

				if (AltTabListSameType_sorted_w_norm_desc[1].ID = AltTabListSameType_sorted_h_norm_desc[1].ID) { 	; That window has the longest width and the longest height.
					FExpStack_rightFExp := AltTabListSameType_sorted_h_norm_desc[2].ID
					FExpStack_rightFExp_w_norm := AltTabListSameType_sorted_h_norm_desc[2].width_norm
					FExpStack_rightFExp_h_norm := AltTabListSameType_sorted_h_norm_desc[2].height
					FExpStack_leftFExp := AltTabListSameType_sorted_h_norm_desc[3].ID
					FExpStack_leftFExp_w_norm := AltTabListSameType_sorted_h_norm_desc[3].width_norm
					FExpStack_leftFExp_h_norm := AltTabListSameType_sorted_h_norm_desc[3].height

					verticalLength := AltTabListSameType_sorted_w_norm_desc[1].height + AltTabListSameType_sorted_h_norm_desc[2].height
					over_h := verticalLength - monitor_%monitor_no_prm%_workarea_height > 0 ? verticalLength - monitor_%monitor_no_prm%_workarea_height : 0
					verticalLength_net := verticalLength - over_h

;;;;;===================================00000000000000000000000000000
				} else { 	; That window has the longest width but not the longest height.
					FExpStack_rightFExp := AltTabListSameType_sorted_h_norm_desc[1].ID
					FExpStack_rightFExp_w_norm := AltTabListSameType_sorted_h_norm_desc[1].width_norm
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
					DWM_WinMove("ahk_id " FExpStack_leftFExp, monitor_%monitor_no_prm%_workarea_left, monitor_%monitor_no_prm%_workarea_top)
					DWM_WinMove("ahk_id " FExpStack_bottomFExp, monitor_%monitor_no_prm%_workarea_left, monitor_%monitor_no_prm%_workarea_bottom - FExpStack_bottomFExp_h_norm) 	; FExpStack_bottomFExp = AltTabListSameType_sorted_w_norm_desc[1].ID
					FExpStack_rightFExp_yAdj := (AltTabListSameType.all_h - monitor_%monitor_no_prm%_workarea_height)/2 * 1.5 	; 1.5 is an adjustment ratio
					DWM_WinMove("ahk_id " FExpStack_rightFExp, monitor_%monitor_no_prm%_workarea_right - FExpStack_rightFExp_w_norm/monitor_%monitor_no_prm%_workarea_ratio, FExpStack_leftFExp_h_norm - FExpStack_rightFExp_yAdj)
				} else if (!(over_w_norm > 0) and (over_h > 0)) {
					if ((FExpStack_leftFExp_h_norm + FExpStack_bottomFExp_h_norm) < monitor_%monitor_no_prm%_workarea_height) {
						DWM_WinMove("ahk_id " FExpStack_leftFExp, monitor_%monitor_no_prm%_workarea_right - (FExpStack_rightFExp_w_norm + FExpStack_leftFExp_w_norm)/monitor_%monitor_no_prm%_workarea_ratio, monitor_%monitor_no_prm%_workarea_bottom - FExpStack_bottomFExp_h_norm - FExpStack_leftFExp_h_norm)
					} else {
						DWM_WinMove("ahk_id " FExpStack_leftFExp, monitor_%monitor_no_prm%_workarea_right - (FExpStack_rightFExp_w_norm + FExpStack_leftFExp_w_norm)/monitor_%monitor_no_prm%_workarea_ratio, monitor_%monitor_no_prm%_workarea_top)
					}
					DWM_WinMove("ahk_id " FExpStack_bottomFExp, monitor_%monitor_no_prm%_workarea_left, monitor_%monitor_no_prm%_workarea_bottom - FExpStack_bottomFExp_h_norm) 	; FExpStack_bottomFExp = AltTabListSameType_sorted_w_norm_desc[1].ID
					DWM_WinMove("ahk_id " FExpStack_rightFExp, monitor_%monitor_no_prm%_workarea_right - FExpStack_rightFExp_w_norm/monitor_%monitor_no_prm%_workarea_ratio, monitor_%monitor_no_prm%_workarea_top)
				;} else if ((over_w_norm > 0) and (over_h > 0)) {
				} else if (!(over_w_norm > 0) and !(over_h > 0)) {
					;ToolTip, % "over_w_norm " over_w_norm " FExpStack_rightFExp_yAdj " FExpStack_rightFExp_yAdj 
					spreadFExp_left := monitor_%monitor_no_prm%_workarea_center_x - horizontalLength_norm_net/monitor_%monitor_no_prm%_workarea_ratio/2
					spreadFExp_top := monitor_%monitor_no_prm%_workarea_center_y - verticalLength_net/2
					spreadFExp_right := spreadFExp_left + horizontalLength_norm_net/monitor_%monitor_no_prm%_workarea_ratio
					spreadFExp_bottom := spreadFExp_top + verticalLength_net

					DWM_WinMove("ahk_id " FExpStack_leftFExp, spreadFExp_right - (FExpStack_rightFExp_w_norm + FExpStack_leftFExp_w_norm)/monitor_%monitor_no_prm%_workarea_ratio, spreadFExp_bottom - FExpStack_bottomFExp_h_norm - FExpStack_leftFExp_h_norm)
					DWM_WinMove("ahk_id " FExpStack_bottomFExp, spreadFExp_left, spreadFExp_bottom - FExpStack_bottomFExp_h_norm) 	; FExpStack_bottomFExp = AltTabListSameType_sorted_w_norm_desc[1].ID
					DWM_WinMove("ahk_id " FExpStack_rightFExp, spreadFExp_right - FExpStack_rightFExp_w_norm/monitor_%monitor_no_prm%_workarea_ratio, spreadFExp_top)
				}
				

				PulseTop(FExpStack_leftFExp)
				PulseTop(FExpStack_rightFExp)
				PulseTop(FExpStack_bottomFExp)
				WinActivate, % "ahk_id " AltTabListSameType[1].ID

;;;;;===================================00000000000000000000000000000

			} else { 	; vertical max is bigger than horizontal max
				FExpStack_rightFExp := AltTabListSameType_sorted_h_norm_desc[1].ID
				FExpStack_rightFExp_h_norm := AltTabListSameType_sorted_h_norm_desc[1].height
				FExpStack_rightFExp_w_norm := AltTabListSameType_sorted_h_norm_desc[1].width_norm
				FExpStack_topFExp := ""
				FExpStack_bottomFExp := ""

				sum_theOthers_h := 0 	; sum of all the widths except the longest one.
				Loop, % AltTabListSameType.length() - 1 {
					nextIndex := A_Index + 1
					sum_theOthers_h += AltTabListSameType_sorted_h_norm_desc[nextIndex].height 	; (was adding the object itself, not its height)
				}
				over_h := sum_theOthers_h - monitor_%monitor_no_prm%_workarea_height > 0 ? sum_theOthers_h - monitor_%monitor_no_prm%_workarea_height : 0
				verticalLength_net := sum_theOthers_h - over_h > AltTabListSameType_sorted_h_norm_desc[1].height ? sum_theOthers_h - over_h : AltTabListSameType_sorted_h_norm_desc[1].height
				verticalLength_net := verticalLength_net < monitor_%monitor_no_prm%_workarea_height ? verticalLength_net : monitor_%monitor_no_prm%_workarea_height 	; in case AltTabListSameType_sorted_h_norm_desc[1].height > monitor_%monitor_no_prm%_workarea_height

				if (AltTabListSameType_sorted_h_norm_desc[1].ID = AltTabListSameType_sorted_w_norm_desc[1].ID) { 	; That window has the longest width and the longest height.
					FExpStack_bottomFExp := AltTabListSameType_sorted_w_norm_desc[2].ID
					FExpStack_bottomFExp_h_norm := AltTabListSameType_sorted_w_norm_desc[2].height
					FExpStack_bottomFExp_w_norm := AltTabListSameType_sorted_w_norm_desc[2].width_norm
					FExpStack_topFExp := AltTabListSameType_sorted_w_norm_desc[3].ID
					FExpStack_topFExp_h_norm := AltTabListSameType_sorted_w_norm_desc[3].height
					FExpStack_topFExp_w_norm := AltTabListSameType_sorted_w_norm_desc[3].width_norm

					horizontalLength_norm := AltTabListSameType_sorted_h_norm_desc[1].width_norm + AltTabListSameType_sorted_w_norm_desc[2].width_norm
					over_w_norm := horizontalLength_norm - monitor_%monitor_no_prm%_workarea_width * monitor_%monitor_no_prm%_workarea_ratio > 0 ? horizontalLength_norm - monitor_%monitor_no_prm%_workarea_width * monitor_%monitor_no_prm%_workarea_ratio : 0
					horizontalLength_norm_net := horizontalLength_norm - over_w_norm
;;;;;===================================00000000000000000000000000000
				} else { 	; That window has the longest width but not the longest height.
					FExpStack_bottomFExp := AltTabListSameType_sorted_w_norm_desc[1].ID
					FExpStack_bottomFExp_h_norm := AltTabListSameType_sorted_w_norm_desc[1].height
					FExpStack_bottomFExp_w_norm := AltTabListSameType_sorted_w_norm_desc[1].width_norm
					; to find the remaining ID which should be at the upper left position.
					Loop, % AltTabListSameType.length() {
						if ((AltTabListSameType[A_Index].ID != FExpStack_bottomFExp) and (AltTabListSameType[A_Index].ID != FExpStack_rightFExp)) {
							FExpStack_topFExp := AltTabListSameType[A_Index].ID
							FExpStack_topFExp_h_norm := AltTabListSameType[A_Index].height_norm
							FExpStack_topFExp_w_norm := AltTabListSameType[A_Index].width_norm
							Break
						}
					}

					horizontalLength_norm := AltTabListSameType_sorted_h_norm_desc[1].width_norm + AltTabListSameType_sorted_w_norm_desc[1].width_norm
					over_w_norm := horizontalLength_norm - monitor_%monitor_no_prm%_workarea_width * monitor_%monitor_no_prm%_workarea_ratio > 0 ? horizontalLength_norm - monitor_%monitor_no_prm%_workarea_width * monitor_%monitor_no_prm%_workarea_ratio : 0
					horizontalLength_norm_net := horizontalLength_norm - over_w_norm

				}
;;;;;===================================00000000000000000000000000000
				
				if (((over_h > 0) and !(over_w_norm > 0)) or ((over_h > 0) and (over_w_norm > 0))) {
					DWM_WinMove("ahk_id " FExpStack_topFExp, monitor_%monitor_no_prm%_workarea_left, monitor_%monitor_no_prm%_workarea_top)
					DWM_WinMove("ahk_id " FExpStack_rightFExp, monitor_%monitor_no_prm%_workarea_right - FExpStack_rightFExp_w_norm / monitor_%monitor_no_prm%_workarea_ratio, monitor_%monitor_no_prm%_workarea_top)
					FExpStack_bottomFExp_xAdj := (AltTabListSameType.all_w - monitor_%monitor_no_prm%_workarea_width)/2 * 1.5 	; 1.5 is an adjustment ratio. It's not a normalized value
					DWM_WinMove("ahk_id " FExpStack_bottomFExp, FExpStack_topFExp_w_norm / monitor_%monitor_no_prm%_workarea_ratio - FExpStack_bottomFExp_xAdj, monitor_%monitor_no_prm%_workarea_bottom - FExpStack_bottomFExp_h_norm)
				} else if (!(over_h > 0) and (over_w_norm > 0)) {
					if ((FExpStack_topFExp_w_norm + FExpStack_rightFExp_w_norm) < monitor_%monitor_no_prm%_workarea_width * monitor_%monitor_no_prm%_workarea_ratio) {
						DWM_WinMove("ahk_id " FExpStack_topFExp, monitor_%monitor_no_prm%_workarea_right - (FExpStack_rightFExp_w_norm + FExpStack_topFExp_w_norm) /  monitor_%monitor_no_prm%_workarea_ratio, monitor_%monitor_no_prm%_workarea_bottom - (FExpStack_bottomFExp_h_norm + FExpStack_topFExp_h_norm))
					} else {
						DWM_WinMove("ahk_id " FExpStack_topFExp, monitor_%monitor_no_prm%_workarea_left, monitor_%monitor_no_prm%_workarea_bottom - (FExpStack_bottomFExp_h_norm + FExpStack_topFExp_h_norm))
					}
					DWM_WinMove("ahk_id " FExpStack_rightFExp, monitor_%monitor_no_prm%_workarea_right - FExpStack_rightFExp_w_norm / monitor_%monitor_no_prm%_workarea_ratio, monitor_%monitor_no_prm%_workarea_top)
					DWM_WinMove("ahk_id " FExpStack_bottomFExp, monitor_%monitor_no_prm%_workarea_left, monitor_%monitor_no_prm%_workarea_bottom - FExpStack_bottomFExp_h_norm)
				;} else if ((over_h > 0) and (over_w_norm > 0)) {
				} else if (!(over_h > 0) and !(over_w_norm > 0)) {
					;ToolTip, % "over_h " over_h " FExpStack_bottomFExp_xAdj " FExpStack_bottomFExp_xAdj 
					spreadFExp_top := monitor_%monitor_no_prm%_workarea_center_y - verticalLength_net / 2
					spreadFExp_left := monitor_%monitor_no_prm%_workarea_center_x - horizontalLength_norm_net / monitor_%monitor_no_prm%_workarea_ratio / 2 	; It's not a normalized value
					spreadFExp_bottom := spreadFExp_top + verticalLength_net
					spreadFExp_right := spreadFExp_left + horizontalLength_norm_net / monitor_%monitor_no_prm%_workarea_ratio

					DWM_WinMove("ahk_id " FExpStack_topFExp, spreadFExp_right - (FExpStack_rightFExp_w_norm + FExpStack_topFExp_w_norm) / monitor_%monitor_no_prm%_workarea_ratio, spreadFExp_bottom - (FExpStack_bottomFExp_h_norm + FExpStack_topFExp_h_norm))
					DWM_WinMove("ahk_id " FExpStack_rightFExp, spreadFExp_right - FExpStack_rightFExp_w_norm / monitor_%monitor_no_prm%_workarea_ratio, spreadFExp_top) 	; (was spreadFExp_left — an X value pasted into the Y slot)
					DWM_WinMove("ahk_id " FExpStack_bottomFExp, spreadFExp_left, spreadFExp_bottom - FExpStack_bottomFExp_h_norm)
				}
				

				PulseTop(FExpStack_topFExp)
				PulseTop(FExpStack_bottomFExp)
				PulseTop(FExpStack_rightFExp)
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

				DWM_WinMove("ahk_id " spreadFExp_4_1_1_ID, spreadFExp_4_1_1_x, spreadFExp_4_1_1_y)
				DWM_WinMove("ahk_id " spreadFExp_4_1_2_ID, spreadFExp_4_1_2_x, spreadFExp_4_1_2_y)
				DWM_WinMove("ahk_id " spreadFExp_4_2_1_ID, spreadFExp_4_2_1_x, spreadFExp_4_2_1_y)
				DWM_WinMove("ahk_id " spreadFExp_4_2_2_ID, spreadFExp_4_2_2_x, spreadFExp_4_2_2_y)
				
				

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

			DWM_WinMove("ahk_id " spreadFExp_4_1_1_ID, spreadFExp_4_1_1_x, spreadFExp_4_1_1_y)
			DWM_WinMove("ahk_id " spreadFExp_4_1_2_ID, spreadFExp_4_1_2_x, spreadFExp_4_1_2_y)
			DWM_WinMove("ahk_id " spreadFExp_4_2_1_ID, spreadFExp_4_2_1_x, spreadFExp_4_2_1_y)
			DWM_WinMove("ahk_id " spreadFExp_4_2_2_ID, spreadFExp_4_2_2_x, spreadFExp_4_2_2_y)

			PulseTop(spreadFExp_4_1_2_ID)
			PulseTop(spreadFExp_4_2_2_ID)
			PulseTop(spreadFExp_4_1_1_ID)

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
				DWM_WinMove("ahk_id " AltTabListSameType_sorted_area_desc[temp_index].ID, spreadFExpEach_x, spreadFExpEach_y)
				PulseTop(AltTabListSameType_sorted_area_desc[temp_index].ID)
			}

				PulseTop(spreadFExp_4_2_1_ID)

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
				DWM_WinMove("ahk_id " AltTabListSameType[temp_index].ID, spreadFExpEach_x, spreadFExpEach_y) 	; When SetWinDelay, -1 is declared, WinMove is as fast as DllCall("MoveWindow".. .
				PulseTop(AltTabListSameType[temp_index].ID)
			}
			WinActivate, % "ahk_id " AltTabListSameType[1].ID
		}
	}

}
