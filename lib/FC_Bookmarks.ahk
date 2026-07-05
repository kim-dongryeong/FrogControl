; FrogControl lib - hotkey parsing and window bookmarks (moved out of FrogControl.ahk 2026-07-05).

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
