; FrogControl lib - Alt-Tab window list, sorting and list-view debug helpers
; (moved out of FrogControl.ahk 2026-07-05).

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
		if ( ((wid_Title = "Xbox") or (wid_Title = "Movies & TV") or (wid_Title = "Photos")) and ((Win_Class = "Windows.UI.Core.CoreWindow") or (Win_Class = "ApplicationFrameWindow")) ) { 	; the class was not actually compared before, so ANY window with these titles was excluded
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
		; look up in the already-built atList instead of enumerating every window twice more (AltTab_window_list_findID rebuilds the whole list per call)
		vProcessName := ""
		vClass := ""
		Loop, % atList.length() {
			if (vID = atList[A_Index].id) {
				vProcessName := atList[A_Index].ProcessName
				vClass := atList[A_Index].Class
				Break
			}
		}
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
	; (a redundant `Gui, aGui%GuiName%: New` was here — it orphaned one hidden window on every call,
	;  because the second New below takes over the name without destroying the first window)
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
; (removed ObjectClone() - it was broken and unused; the ObjFullyClone() recipe in the comment block above is the working approach)

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
