# FrogControl 정적 분석 보고서

작성일: 2026-07-05  
대상 저장소: `C:\Users\Kim Dongryeong\dev\FrogControl`  
주요 대상 파일: `FrogControl.ahk`

이 문서는 FrogControl 프로젝트를 다른 개발자나 코드 수정 에이전트가 바로 이어서 고칠 수 있도록 작성한 상세 분석 보고서다. 분석은 현재 작업 폴더의 파일 상태를 기준으로 한 정적 분석이며, 이 환경에서는 AutoHotkey 실행 파일이 PATH에서 발견되지 않아 실제 실행 테스트는 수행하지 못했다.

## 1. 분석 범위와 전제

### 1.1 분석한 파일

현재 프로젝트 폴더에는 다음 주요 파일이 있다.

| 파일 | 역할 |
| --- | --- |
| `FrogControl.ahk` | 실제 열려 있는 주 스크립트. AutoHotkey v1 문법 기반 |
| `README.md` | 프로젝트 소개 |
| `history.txt` | 버전 히스토리와 최근 수정 내역 |
| `shortcut list-en.txt` | 영어 단축키 도움말 데이터 |
| `shortcut list-ko.txt` | 한국어 단축키 도움말 데이터 |
| `frog face icon 3.ico` | 트레이/도움말 아이콘 |

### 1.2 Git 작업트리 상태

정적 분석 시점에서 `git status --short`는 다음과 같은 상태였다.

```text
 D "FrogControl v1.15.alpha.4.ahk"
?? FrogControl.ahk
```

하지만 `FrogControl.ahk`의 blob hash는 HEAD에 있던 `FrogControl v1.15.alpha.4.ahk`와 동일했다. 따라서 내용이 사라진 것은 아니고, 기존 파일이 `FrogControl.ahk`로 이름이 바뀐 상태가 Git에 아직 rename으로 staging되지 않은 것으로 보인다.

수정 담당자는 커밋 전 반드시 다음을 확인해야 한다.

```powershell
git status --short
git add -A
git status --short
```

의도한 rename이면 staged 상태에서 삭제와 추가가 rename으로 인식되는지 확인한다. Git이 rename으로 표시하지 않더라도 실제 커밋에는 같은 내용의 새 파일과 기존 파일 삭제가 들어갈 수 있으니, 릴리스/배포 문서에서 참조하는 파일명이 `FrogControl.ahk`로 바뀌는 것이 맞는지 확인해야 한다.

### 1.3 실행 환경 전제

`FrogControl.ahk`는 AutoHotkey v1 문법으로 작성되어 있다. 예를 들어 다음과 같은 v1 문법이 사용된다.

```ahk
Menu, Tray, Icon, ...
Gui, helpEn: Add, ...
WinGet, curtrans, Transparent, A
Loop, read, ...
```

현재 파일 상단에는 `#Requires AutoHotkey v1.1`가 없다. AutoHotkey v2가 기본 연결된 컴퓨터에서는 파일을 더블클릭했을 때 구문 오류가 발생할 가능성이 높다.

권장 조치:

```ahk
#Requires AutoHotkey v1.1
```

이 지시문을 파일 최상단, 앱 메타데이터 할당보다 앞쪽에 추가한다. 만약 특정 최소 버전을 요구한다면 `#Requires AutoHotkey v1.1.33+`처럼 더 정확히 쓴다.

## 2. 코드 규모와 구조

### 2.1 전체 규모

`FrogControl.ahk`는 단일 파일 중심 구조다.

| 항목 | 수치 |
| --- | ---: |
| 전체 줄 수 | 5,276 |
| 비어 있지 않은 줄 | 4,729 |
| 주석 줄 | 786 |
| 함수 선언 | 15개 |
| 라벨 선언 | 15개 안팎 |
| 핫키 선언 | 약 120개 수준 |

단일 파일 스크립트로 시작한 프로젝트가 오랜 기간 기능을 추가하면서 커진 구조다. 핵심 문제는 기능 수 자체보다, 같은 문제를 해결하는 코드가 여러 버전으로 공존하고 있고 공통 작업이 helper로 분리되지 않았다는 점이다.

### 2.2 주요 함수 목록

현재 명시적 함수는 대략 다음과 같다.

| 함수 | 시작 줄 | 대략 줄 수 | 역할 |
| --- | ---: | ---: | --- |
| `HotkyeAnalysis()` | 3726 | 46 | `A_ThisHotkey` 문자열을 modifier와 key로 분해 |
| `WindowBookmark_setup()` | 3772 | 18 | 현재 창을 window bookmark 객체로 저장 |
| `WindowBookmark_operation()` | 3790 | 92 | 저장된 window bookmark 활성화/최소화 |
| `WindowInfo()` | 3882 | 340 | 창 정보 객체 생성. 실제 함수 범위 안에 휠/핫키 로직이 이어지는 구조라 정리 필요 |
| `AltTab_window_list()` | 4222 | 76 | Alt-Tab 후보 창 목록 생성 |
| `Decimal_to_Hex()` | 4298 | 7 | 정수 값을 hex 문자열로 변환 |
| `AltTab_window_list_findID()` | 4305 | 13 | Alt-Tab 목록에서 ID 존재 여부 확인 |
| `AltTab_List_SameType()` | 4318 | 36 | 같은 process/class 창 목록 필터링 |
| `Print_Windows_ListView()` | 4354 | 30 | 창 목록 디버그 GUI 출력 |
| `Print_Object()` | 4384 | 27 | 객체 문자열화 |
| `Sort_Object()` | 4411 | 45 | 객체 배열 bubble sort |
| `ObjFullyClone()` | 4456 | 8 | 주석 블록 안에 있는 clone 시도 |
| `ObjectClone()` | 4464 | 11 | 동작하지 않는 clone 함수. 현재 호출처 없음 |
| `fct_RemoveToolTip_time()` | 4475 | 34 | 특정 tooltip 번호 제거 timer helper |
| `Show_Windows()` | 4509 | 768 | 같은 타입 또는 Explorer 창 배열 |

주의할 점은 `WindowInfo()`가 시작된 뒤 실제 함수 끝이 코드 구조상 명확하지 않게 보일 수 있다는 점이다. AutoHotkey v1에서 함수 brace 구조는 맞더라도, 함수와 핫키/라벨이 한 파일 안에 긴밀히 섞여 있어 독자가 구조를 파악하기 어렵다. 리팩터링 시 함수와 핫키 본문을 물리적으로 분리하는 것이 좋다.

### 2.3 큰 기능 블록

정적 위치 기준 주요 블록은 다음과 같다.

| 블록 | 시작 줄 | 끝 줄 | 대략 줄 수 | 비고 |
| --- | ---: | ---: | ---: | --- |
| 창 방향 탐색 | 707 | 1010 | 304 | Win+Alt+Ctrl+Arrow |
| Explorer grid 구버전 | 1039 | 1187 | 149 | `+F2` |
| Explorer spread 구버전 | 1193 | 1888 | 696 | `+F1` |
| 키보드 창 이동/격자 | 1893 | 2305 | 413 | CapsLock+Arrow 계열 |
| Win+Alt resize | 2321 | 2567 | 247 | 방향별 반복 구현 |
| 마우스 드래그 창 이동 | 2570 | 2792 | 223 | CapsLock+LButton |
| 마우스 드래그 창 resize | 2794 | 2868 | 75 | CapsLock+RButton |
| 날짜/시간 입력 | 2904 | 3013 | 110 | CapsLock+O |
| 마우스 컨트롤 모드 | 3169 | 3503 | 335 | CapsLock+M |
| 마우스/창 북마크 | 3507 | 3880 | 374 | CapsLock+숫자/F키 |
| 휠 스크롤 가속 | 3905 | 4103 | 199 | CapsLock+Wheel, Shift+Wheel |
| Alt-Tab helper | 4222 | 4353 | 132 | 창 목록 생성/필터 |
| 일반화된 창 배열 | 4509 | 5276 | 768 | `Show_Windows()` |

가장 큰 중복은 `+F1/+F2`의 Explorer 전용 구버전 배열 코드와 `Show_Windows()`의 일반화된 배열 코드가 동시에 존재한다는 점이다.

## 3. 현재 동작 모델

### 3.1 전역 상태

스크립트는 많은 전역 변수를 사용한다.

대표 예:

```ahk
FLAG_HALFTRANS := ""
FLAG_CONSTRAINEDMOUSE := ""
FLAG_MOUSECONTROL := ""
FLAG_COOR_CONSTRAINED_MOUSE := 0
FLAG_HELP_LANG := 1
global_wheel_count := 0
timeStamp_CapsLock_index := 0
timeStamp_modfr_max := 20
windowBookmark := {}
mousePosBookmark := {}
```

전역 상태 자체는 AutoHotkey 스크립트에서는 흔하지만, 현재는 상태 이름과 소유 기능이 분산되어 있어 부작용 추적이 어렵다. 특히 wheel scroll, modifier timestamp, CapsLock 상태, tooltip timer, bookmark 상태가 서로 다른 위치에서 변경된다.

권장 구조:

```ahk
FC := {}
FC.settings := {}
FC.state := {}
FC.cache := {}

FC.settings.tooltipShort := 1000
FC.settings.tooltipLong := 10000
FC.settings.winMovePxLarge := 200
FC.settings.winMovePxSmall := 20

FC.state.wheel := { fastStarted: 0 }
FC.state.bookmarks := { windows: {}, mouse: {} }
FC.cache.monitors := ""
```

AutoHotkey v1에서는 객체 접근이 다소 장황하지만, 기능별 상태 소유권이 분명해진다는 장점이 크다.

### 3.2 동적 변수 사용

코드에는 `monitor_%A_Index%_workarea_left`, `AltTab_ID_List_%A_Index%`, `timeStamp_CapsLock_%A_Index%` 같은 동적 변수가 많다.

동적 변수는 AHK v1에서 흔히 쓰는 방식이지만, 다음 문제가 있다.

1. IDE/검색으로 참조 관계를 추적하기 어렵다.
2. 잘못된 인덱스를 써도 런타임 전에는 거의 알 수 없다.
3. 구조를 바꾸거나 helper로 분리하기 어렵다.
4. 같은 자료구조를 객체와 동적 변수 두 방식으로 동시에 유지하게 된다.

현재 `AltTab_window_list()`는 구형 동적 변수 `AltTab_ID_List_%n%`와 객체 배열 `altTab_List[n]`를 동시에 채운다. 과도기 구조로 보이며, 최종적으로는 객체 배열 하나만 남기는 것이 좋다.

### 3.3 창 목록 모델

`AltTab_window_list()`는 다음 정보를 수집한다.

- window ID
- title
- class
- style/exstyle
- process name
- PID
- position
- process path

문제는 모든 호출에서 모든 정보가 필요한 것은 아니라는 점이다. 예를 들어 빠른 창 회전이나 같은 타입 필터링에는 process path가 필요 없고, bookmark 저장에는 process path가 필요하다.

권장 API:

```ahk
GetAltTabWindows(options := "") {
    ; options 예: "basic", "withPath", "withPosition"
}
```

또는 AHK v1에서 문자열 옵션 대신 boolean 인자를 둔다.

```ahk
GetAltTabWindows(includePath := false, includePosition := true)
```

## 4. 결함 분석

### 4.1 AHK v1 요구사항 미명시

위치: 파일 최상단  
심각도: 높음  
영향: AHK v2 기본 연결 환경에서 실행 실패

현재 스크립트에는 `#Requires AutoHotkey v1.1`가 없다. README에도 구체적인 AutoHotkey major version이 명시되어 있지 않다.

권장 수정:

```ahk
#Requires AutoHotkey v1.1
```

위 줄을 파일 최상단에 추가한다. README에는 다음처럼 적는다.

```markdown
Requires AutoHotkey v1.1. This script is not compatible with AutoHotkey v2.
```

### 4.2 Git rename 상태 미정리

위치: 저장소 상태  
심각도: 높음  
영향: 커밋/배포 시 메인 스크립트 누락 또는 파일명 혼란

현재 Git은 기존 `FrogControl v1.15.alpha.4.ahk` 삭제와 새 `FrogControl.ahk` 추가로 본다. 내용은 동일하므로 큰 위험은 아니지만, 커밋 전 의도가 분명해야 한다.

권장 작업:

```powershell
git add -A
git status --short
```

의도한 변경이면 README, history, 배포 문서, shortcut help에서 참조하는 파일명을 함께 정리한다.

### 4.3 `^+!RButton` 무한 대기 가능성

위치: `FrogControl.ahk:358-363`  
심각도: 중간에서 높음  
영향: 특정 창에서 핫키 스레드가 끝나지 않음

현재 코드:

```ahk
^+!RButton::
    MouseGetPos, , , mousewin
    WinActivate, ahk_id %mousewin%
    WinWaitActive, ahk_id %mousewin%
    SendEvent, !{F4}
Return
```

`WinWaitActive`에 timeout이 없다. 대상 창이 활성화되지 않으면 스레드가 무기한 대기한다. 바로 위 `^+RButton`에서는 이미 timeout을 넣어 같은 위험을 줄였다.

권장 수정:

```ahk
^+!RButton::
    MouseGetPos, , , mousewin
    WinActivate, ahk_id %mousewin%
    WinWaitActive, ahk_id %mousewin%, , 0.5
    if (!ErrorLevel)
        SendEvent, !{F4}
Return
```

추가로 `mousewin`이 비어 있는 경우도 방어할 수 있다.

```ahk
if (!mousewin)
    Return
```

### 4.4 그리드 계산에서 0 나눗셈 가능성

위치:

- `FrogControl.ahk:1052-1056`
- `FrogControl.ahk:1205-1209`
- `FrogControl.ahk:4526-4530`

심각도: 중간  
영향: 작은 해상도, 원격 데스크톱, 세로 화면에서 창 배열 오류

현재 패턴:

```ahk
monitor_%A_Index%_grid_no_x := monitor_%A_Index%_workarea_width // 800
monitor_%A_Index%_grid_no_y := monitor_%A_Index%_workarea_height // 450
monitor_%A_Index%_grid_width := monitor_%A_Index%_workarea_width / monitor_%A_Index%_grid_no_x
monitor_%A_Index%_grid_height := monitor_%A_Index%_workarea_height / monitor_%A_Index%_grid_no_y
```

`workarea_width < 800`이면 `grid_no_x`가 0이다. `workarea_height < 450`이면 `grid_no_y`가 0이다.

즉시 수정:

```ahk
monitor_%A_Index%_grid_no_x := Max(1, monitor_%A_Index%_workarea_width // 800)
monitor_%A_Index%_grid_no_y := Max(1, monitor_%A_Index%_workarea_height // 450)
```

더 나은 수정은 고정 threshold 대신 창 개수 기반으로 계산하는 것이다. 알고리즘 개선 챕터에서 별도로 설명한다.

### 4.5 `Show_Windows()` 빈 목록 접근

위치: `FrogControl.ahk:4534-4549`  
심각도: 중간  
영향: 매칭 창이 없을 때 빈 객체 접근

현재 흐름:

```ahk
if (StrLen(vProcessName) > 0) {
    AltTabListSameType := AltTab_List_SameType("", vProcessName)
} else if (StrLen(vID) > 0) {
    AltTabListSameType := AltTab_List_SameType(vID, "")
}

vClass := AltTabListSameType[1].Class
AltTab_List := AltTab_window_list()

if ((AltTabListSameType.length() < 1) and (StrLen(vProcessName))) {
    Run, % vProcessName
}
```

목록이 비었는지 확인하기 전에 `AltTabListSameType[1].Class`를 읽는다.

권장 흐름:

```ahk
if (AltTabListSameType.length() < 1) {
    if (StrLen(vProcessName)) {
        Run, % vProcessName
    }
    Return
}

vClass := AltTabListSameType[1].Class
```

만약 Explorer가 없을 때 실행 후 배열까지 이어가고 싶다면, `Run` 후 짧은 timeout 동안 새 창을 기다리고 목록을 다시 수집해야 한다.

### 4.6 Ruler mode의 `BlockInput` cleanup 위험

위치: `FrogControl.ahk:3257-3263`  
심각도: 중간  
영향: Space 입력 대기 중 입력 차단 지속 가능성

현재 코드:

```ahk
ToolTip, % "Press SpaceBar to set the first point"
BlockInput, on
KeyWait, Space, D
MouseGetPos, mouseInit_x, mouseInit_y
BlockInput, Off
```

`KeyWait, Space, D`는 timeout이 없다. 사용자가 Space를 누르지 않으면 입력 차단 상태가 유지된다. Esc도 이 구간에서는 처리되지 않는다.

권장 수정 방향:

1. timeout을 둔다.
2. timeout이면 `BlockInput, Off` 후 모드로 복귀한다.
3. 어떤 예외 경로에서도 cleanup이 실행되게 라벨 또는 작은 helper를 둔다.

예:

```ahk
BlockInput, on
KeyWait, Space, D T5
if (ErrorLevel) {
    BlockInput, Off
    ToolTip, % "Ruler mode canceled."
    SetTimer, RemoveToolTip, % SETTING_CONSTANT_TOOLTIPDUR_S
    Continue
}
MouseGetPos, mouseInit_x, mouseInit_y
BlockInput, Off
```

더 안전하게는 이 기능에서 `BlockInput` 자체를 제거하고, Space 입력이 다른 앱에 전달될 수 있는 문제를 다른 방식으로 완화하는 방법도 검토한다.

### 4.7 COM 호출 예외 미보호

위치:

- `FrogControl.ahk:3938`
- `FrogControl.ahk:3965`
- `FrogControl.ahk:4000`
- `FrogControl.ahk:4024`
- 블록 주석 안 `4037-4038`은 실제 실행 대상은 아님

심각도: 중간  
영향: Excel/Word COM 상태 이상 시 오류 대화상자

현재 코드 예:

```ahk
ComObjActive("Excel.Application").ActiveWindow.SmallScroll(0,0, wheelScroll_speedUp_Excel)
```

활성 클래스가 Excel로 보이더라도 COM 서버를 얻지 못하거나 ActiveWindow가 없는 상태가 있을 수 있다.

권장 helper:

```ahk
ScrollOfficeHorizontal(appName, leftNotRight, amount) {
    try {
        app := ComObjActive(appName ".Application")
        if (leftNotRight)
            app.ActiveWindow.SmallScroll(0, 0, 0, amount)
        else
            app.ActiveWindow.SmallScroll(0, 0, amount)
        return true
    } catch e {
        return false
    }
}
```

호출부는 실패 시 일반 wheel click으로 fallback한다.

### 4.8 도움말 파일 누락 처리

위치:

- `FrogControl.ahk:141-143`
- `FrogControl.ahk:189-191`

심각도: 낮음에서 중간  
영향: shortcut list 파일이 없을 때 읽기 루프 실패 가능성

현재 구조:

```ahk
if (!FileExist(A_ScriptDir . "\shortcut list-en.txt"))
    LV_Add("", "(file not found)", A_ScriptDir . "\shortcut list-en.txt")
Loop, read, %A_ScriptDir%\shortcut list-en.txt
{
    ...
}
```

파일이 없다는 메시지를 추가한 뒤에도 `Loop, read`는 실행된다.

권장 수정:

```ahk
helpFile := A_ScriptDir . "\shortcut list-en.txt"
if (!FileExist(helpFile)) {
    LV_Add("", "(file not found)", helpFile)
} else {
    Loop, read, %helpFile%
    {
        ...
    }
}
```

한국어 도움말도 동일하게 고친다.

### 4.9 `Show_Windows()`의 monitor index 저장 오류 가능성

위치: `FrogControl.ahk:4695-4700`  
심각도: 낮음에서 중간  
영향: 향후 `.mon` 사용 시 잘못된 창에 모니터 번호 저장

현재 코드:

```ahk
index := A_Index
loop, %monitor_no% {
    if (...) {
        AltTabListSameType[A_Index].mon := A_Index
        AltTabListSameType.monitor[A_Index].all_w += temp_w
        AltTabListSameType.monitor[A_Index].all_h += temp_h
    }
}
```

내부 모니터 루프의 `A_Index`가 외부 창 index를 덮는다. `index` 변수를 만들어 둔 것으로 보아 의도는 다음에 가깝다.

```ahk
AltTabListSameType[index].mon := A_Index
```

현재 `.mon`의 실사용이 제한적이라 즉시 큰 문제는 아닐 수 있지만, 리팩터링 전에 고쳐야 한다.

### 4.10 `ObjectClone()`은 동작하지 않는 코드

위치: `FrogControl.ahk:4464-4473`  
심각도: 낮음  
영향: 호출 시 잘못된 clone 객체 반환

현재 코드:

```ahk
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
```

문제:

1. `newObj.key`는 literal `key` property를 쓴다.
2. `Return newObj`가 `For` 루프 내부에 있어 첫 항목 후 반환한다.
3. 함수명이 있는데도 주석이 "DOESN'T WORK"다.

현재 호출처가 없으므로 제거하거나 아래처럼 고친다.

```ahk
DeepClone(obj) {
    clone := obj.Clone()
    for key, value in clone {
        if IsObject(value)
            clone[key] := DeepClone(value)
    }
    return clone
}
```

### 4.11 Date input mode의 caret 좌표 fallback 부재

위치: `FrogControl.ahk:2928-2990`  
심각도: 낮음에서 중간  
영향: caret 좌표가 없는 앱에서 tooltip 위치 이상

`A_CaretX`, `A_CaretY`가 항상 신뢰 가능한 것은 아니다. 주소창, 일부 Electron 앱, 관리자 권한 앱, 게임/터미널류에서는 caret 좌표가 비어 있거나 0일 수 있다.

권장 fallback:

```ahk
if (A_CaretX = "" or A_CaretY = "") {
    MouseGetPos, mousex, mousey
    caretX := mousex
    caretY := mousey
} else {
    caretX := A_CaretX
    caretY := A_CaretY
}
```

`monitor_current`가 설정되지 않은 경우 primary monitor를 fallback으로 쓴다.

## 5. 중복 분석과 코드 효율화 챕터

### 5.1 가장 큰 중복: Explorer 전용 배열 코드와 `Show_Windows()`

현재 구조:

- `+F2`는 `FrogControl.ahk:1039`부터 Explorer를 grid로 배열한다.
- `+F1`은 `FrogControl.ahk:1193`부터 Explorer를 spread 방식으로 배열한다.
- `+F5`는 `Show_Windows("Explorer.exe", "", 0)`를 호출한다.
- `+F6`은 `Show_Windows("Explorer.exe", "", 1)`를 호출한다.
- `+F3/+F4`는 현재 활성 창과 같은 타입 창을 `Show_Windows()`로 배열한다.

즉 같은 기능군이 두 개 방식으로 구현되어 있다.

정리 목표:

```ahk
+F1::ArrangeWindows({processName: "Explorer.exe"}, "spread")
+F2::ArrangeWindows({processName: "Explorer.exe"}, "grid")
+F3::ArrangeWindows({sameAsHwnd: WinExist("A")}, "spread")
+F4::ArrangeWindows({sameAsHwnd: WinExist("A")}, "grid")
```

`+F5/+F6`가 임시 테스트 핫키였다면 제거하거나 문서화한다. 아니면 `+F1/+F2`를 새 구현으로 옮긴 뒤 `+F5/+F6`는 alias로 남길 수 있다.

### 5.2 `WinMove`/`WinRestore`/`AlwaysOnTop` 반복 제거

반복 패턴:

```ahk
WinRestore, % "ahk_id " id
WinMove, % "ahk_id " id, , x, y, w, h
WinSet, AlwaysOnTop, On, % "ahk_id " id
WinSet, AlwaysOnTop, Off, % "ahk_id " id
WinActivate, % "ahk_id " someId
```

권장 helper:

```ahk
MoveWindowRect(hwnd, rect, restore := true) {
    if (restore)
        WinRestore, % "ahk_id " hwnd
    WinMove, % "ahk_id " hwnd, , rect.x, rect.y, rect.w, rect.h
}

PulseTop(hwnd) {
    WinSet, AlwaysOnTop, On, % "ahk_id " hwnd
    WinSet, AlwaysOnTop, Off, % "ahk_id " hwnd
}

ActivateWindowSafe(hwnd, timeout := 0.5) {
    if (!hwnd)
        return false
    WinActivate, % "ahk_id " hwnd
    WinWaitActive, % "ahk_id " hwnd, , %timeout%
    return !ErrorLevel
}
```

수정 시 주의:

- `WinSet, AlwaysOnTop On/Off`는 기존 topmost 상태를 망가뜨릴 수 있다.
- topmost였던 창을 Off로 바꾸는 부작용이 있다.
- 가능하면 `WinSet, Top` 또는 Win32 `SetWindowPos`로 대체하는 것이 좋다.

### 5.3 모니터 정보 helper

현재 `SysGet, monitor_no`와 `SysGet, Monitor_%A_Index%_WorkArea_` 패턴이 반복된다.

권장 helper:

```ahk
GetMonitors(refresh := false) {
    global FC
    if (!refresh && IsObject(FC.cache.monitors))
        return FC.cache.monitors

    SysGet, count, MonitorCount
    SysGet, primary, MonitorPrimary
    monitors := {}
    monitors.count := count
    monitors.primary := primary

    Loop, %count% {
        SysGet, mon, Monitor, %A_Index%
        SysGet, work, MonitorWorkArea, %A_Index%
        m := {}
        m.left := monLeft
        m.right := monRight
        m.top := monTop
        m.bottom := monBottom
        m.workLeft := workLeft
        m.workRight := workRight
        m.workTop := workTop
        m.workBottom := workBottom
        m.workW := workRight - workLeft
        m.workH := workBottom - workTop
        m.centerX := (workLeft + workRight) / 2
        m.centerY := (workTop + workBottom) / 2
        monitors[A_Index] := m
    }

    FC.cache.monitors := monitors
    return monitors
}
```

AHK v1의 `SysGet, mon, Monitor`는 `monLeft`, `monRight` 같은 변수를 생성한다. helper 내부에서만 이 동적 접미사 변수를 쓰고, 외부에는 객체를 넘기는 구조가 이상적이다.

### 5.4 Tooltip 반복 제거

`SetTimer, RemoveToolTip, % SETTING_CONSTANT_TOOLTIPDUR_S`가 매우 많이 반복된다. 작은 helper 하나로 의미를 명확히 만들 수 있다.

```ahk
ShowTempTooltip(text, duration := "") {
    global SETTING_CONSTANT_TOOLTIPDUR_S
    if (duration = "")
        duration := SETTING_CONSTANT_TOOLTIPDUR_S
    ToolTip, % text
    SetTimer, RemoveToolTip, % duration
}
```

좌표와 tooltip 번호까지 지원하려면:

```ahk
ShowTempTooltip(text, x := "", y := "", which := 1, duration := "") {
    global SETTING_CONSTANT_TOOLTIPDUR_S
    if (duration = "")
        duration := SETTING_CONSTANT_TOOLTIPDUR_S
    ToolTip, % text, %x%, %y%, %which%
    fct_RemoveToolTip_time(which, true)
    SetTimer, fct_RemoveToolTip_time, % duration
}
```

단, 기존 `RemoveToolTip`과 `fct_RemoveToolTip_time`의 역할이 겹치므로 하나로 통합하는 것이 좋다.

### 5.5 Hotkey 분석 helper 개선

현재 함수명은 `HotkyeAnalysis`로 오타가 있다. 동작이 널리 쓰이면 당장 rename은 부담이지만, 새 이름 wrapper를 추가할 수 있다.

```ahk
HotkeyAnalysis(vHotkey := "") {
    if (vHotkey = "")
        vHotkey := A_ThisHotkey
    return HotkyeAnalysis(vHotkey)
}
```

이후 호출부를 점진적으로 `HotkeyAnalysis()`로 바꾼 뒤, 마지막에 기존 함수를 제거한다.

### 5.6 방향별 resize/move 반복 제거

`#!Right`, `#!Left`, `#!Up`, `#!Down`, `#!+Right` 등 방향별 코드가 거의 같은 구조로 반복된다.

권장 방식:

```ahk
ResizeActiveWindow(direction, outward := true, step := 20) {
    WinGetPos, x, y, w, h, A
    if (direction = "Right") {
        if (outward)
            w += step
        else
            w -= step
    } else if (direction = "Left") {
        if (outward) {
            x -= step
            w += step
        } else {
            x += step
            w -= step
        }
    }
    ; Up/Down도 같은 방식
    WinMove, A, , x, y, w, h
}
```

핫키 본문은 방향만 전달하게 만든다.

```ahk
#!Right::ResizeActiveWindow("Right", true)
#!Left::ResizeActiveWindow("Left", true)
#!+Right::ResizeActiveWindow("Right", false)
#!+Left::ResizeActiveWindow("Left", false)
```

## 6. 알고리즘 및 속도 개선 챕터

### 6.1 그리드 배열 알고리즘 개선

현재 그리드는 화면 크기를 800x450 기준으로 나눈다. 이 방식은 화면 크기에 따라 0 나눗셈 위험이 있고, 창 개수와 화면 비율을 잘 반영하지 못한다.

추천 알고리즘:

```text
cols = ceil(sqrt(n * workW / workH))
rows = ceil(n / cols)
cellW = workW / cols
cellH = workH / rows
```

장점:

1. 창 개수 `n`에 따라 자연스럽게 grid가 결정된다.
2. 화면 비율이 넓으면 열이 많아지고, 세로형이면 행이 많아진다.
3. 최소 1행/1열 보장이 쉽다.
4. 800/450 magic number를 제거할 수 있다.

AHK v1 예시:

```ahk
ComputeGrid(n, workW, workH) {
    grid := {}
    if (n < 1) {
        grid.cols := 1
        grid.rows := 1
        return grid
    }
    grid.cols := Ceil(Sqrt(n * workW / workH))
    grid.cols := Max(1, grid.cols)
    grid.rows := Ceil(n / grid.cols)
    grid.rows := Max(1, grid.rows)
    grid.cellW := workW / grid.cols
    grid.cellH := workH / grid.rows
    return grid
}
```

배열 적용:

```ahk
PlaceWindowsGrid(windows, monitor) {
    grid := ComputeGrid(windows.Length(), monitor.workW, monitor.workH)
    Loop, % windows.Length() {
        idx := A_Index - 1
        col := Mod(idx, grid.cols)
        row := Floor(idx / grid.cols)
        rect := { x: monitor.workLeft + col * grid.cellW
                , y: monitor.workTop + row * grid.cellH
                , w: grid.cellW
                , h: grid.cellH }
        MoveWindowRect(windows[A_Index].id, rect)
    }
}
```

### 6.2 방향키 창 탐색 알고리즘 개선

현재 Win+Alt+Ctrl+Arrow 창 탐색은 오른쪽, 왼쪽, 위, 아래에 대해 유사한 코드를 따로 수행한다. 기존 코드는 slope와 거리 제곱을 사용해 방향별 후보를 고르는 구조다. 최근 history에는 division by zero를 고친 기록이 있다.

권장 일반화:

```text
direction Right = (1, 0)
direction Left  = (-1, 0)
direction Down  = (0, 1)
direction Up    = (0, -1)

candidate vector = candidate.center - current.center
projection = dot(candidate vector, direction)
lateral = abs(cross(candidate vector, direction))

projection <= 0이면 후보 제외
score = projection + lateral * lateralWeight
score가 가장 낮은 창 선택
```

장점:

1. 네 방향을 하나의 함수로 처리한다.
2. division by zero가 없다.
3. 바로 위/아래/좌/우 창도 자연스럽게 잡힌다.
4. 방향별 복붙 코드가 사라진다.

AHK v1 형태:

```ahk
FindNearestWindow(windows, current, dir) {
    best := ""
    bestScore := ""
    curCx := current.x + current.width / 2
    curCy := current.y + current.height / 2

    Loop, % windows.Length() {
        w := windows[A_Index]
        if (w.id = current.id)
            Continue

        cx := w.x + w.width / 2
        cy := w.y + w.height / 2
        dx := cx - curCx
        dy := cy - curCy

        projection := dx * dir.x + dy * dir.y
        if (projection <= 0)
            Continue

        lateral := Abs(dx * dir.y - dy * dir.x)
        score := projection + lateral * 2

        if (best = "" or score < bestScore) {
            best := w
            bestScore := score
        }
    }
    return best
}
```

더 정교하게 하려면 `lateral` 가중치를 모니터 크기나 현재 창 크기에 따라 조정한다.

### 6.3 정렬 알고리즘 개선

현재 `Sort_Object()`는 bubble sort다.

```ahk
Loop, % vObj.length() - 1 {
    Loop, % vObj.length() - A_Index {
        ...
    }
}
```

창 수가 적으면 큰 병목은 아니지만, 이 함수가 여러 배열 로직에 반복 호출되고 코드도 장황하다. AHK v1에서 간단히 개선하려면 decorate-sort-undecorate 방식을 쓸 수 있다.

개념:

1. 각 객체의 sort key와 원래 index를 문자열로 만든다.
2. AHK `Sort` 명령을 사용한다.
3. 정렬된 index 순서로 새 배열을 만든다.

예시:

```ahk
SortByKey(arr, key, descending := false) {
    list := ""
    Loop, % arr.Length() {
        value := arr[A_Index][key]
        list .= Format("{:020.6f}", value) "|" A_Index "`n"
    }
    Sort, list, % descending ? "R" : ""

    result := {}
    Loop, Parse, list, `n
    {
        if (A_LoopField = "")
            Continue
        parts := StrSplit(A_LoopField, "|")
        result.Push(arr[parts[2]])
    }
    return result
}
```

숫자 정렬에서 음수, 문자열, 동일 key 처리까지 완전하게 하려면 별도 보정이 필요하다. 하지만 현재 width/height/area 등 양수 숫자 중심 정렬에는 적용 가능하다.

### 6.4 Alt-Tab 목록 생성 비용 줄이기

`AltTab_window_list()` 호출 수는 검색 기준 31회다. 이 함수는 모든 창을 열거하고 각 창에 대해 여러 WinGet을 호출한다.

개선 방향:

1. 한 hotkey 실행 중에는 목록 snapshot을 한 번만 만든다.
2. 필요 없는 정보는 조회하지 않는다.
3. 동일 process/class 필터링은 이미 만든 snapshot에서 수행한다.

현재 `AltTab_List_SameType()`은 `AltTab_window_list()`를 한 번만 호출하도록 최근 개선된 흔적이 있다. 이 방향을 전체 코드에 확장한다.

권장:

```ahk
windows := GetAltTabWindows("basic")
sameType := FilterWindowsSameType(windows, hwnd)
```

Bookmark 저장처럼 process path가 필요한 경우만:

```ahk
info := GetWindowInfo(hwnd, "withPath")
```

### 6.5 Monitor cache

디스플레이 구성은 자주 바뀌지 않는다. 그런데 현재 여러 핫키에서 매번 `SysGet`을 호출한다.

추천:

```ahk
GetMonitors(refresh := false)
InvalidateMonitorCache:
    FC.cache.monitors := ""
return
```

추가로 `OnMessage(0x007E, "OnDisplayChange")` 또는 `WM_DISPLAYCHANGE` 처리를 넣어 cache를 무효화할 수 있다. AHK v1에서 함수 callback을 쓰는 구조가 부담되면, 일단 hotkey 시작 시 한 번만 조회하는 형태로도 충분하다.

### 6.6 대량 창 이동 batch 처리

현재 여러 창을 이동할 때 `WinMove`를 창마다 순차 호출한다. 창이 많으면 깜빡임, 중간 z-order 변화, focus 변화가 발생할 수 있다.

고급 개선:

- Win32 `BeginDeferWindowPos`
- `DeferWindowPos`
- `EndDeferWindowPos`

이 방식은 여러 창 위치 변경을 하나의 batch로 적용한다. 구현 난도가 있으므로 1차 리팩터링 후 검토한다.

대체 저위험 개선:

1. 루프 안 `WinActivate` 제거
2. 모든 `WinMove` 수행
3. 마지막에 한 번만 대표 창 activate
4. 필요할 때만 z-order 보정

## 7. 기능별 상세 리팩터링 제안

### 7.1 트레이 메뉴와 도움말

현재 `MenuHandlerEn`과 `MenuHandlerKo`는 거의 같은 구조다. 차이는 다음뿐이다.

- title text
- shortcut list filename
- author label 언어

권장 함수:

```ahk
ShowHelp(lang) {
    if (lang = "ko") {
        guiName := "helpKo"
        listFile := A_ScriptDir . "\shortcut list-ko.txt"
        title := "프로그 컨트롤(FrogControl) 도움말"
        listTitle := "단축키 목록"
        createdBy := "제작자 : " AppAuthor
    } else {
        guiName := "helpEn"
        listFile := A_ScriptDir . "\shortcut list-en.txt"
        title := AppName " Help"
        listTitle := "Shortcut list"
        createdBy := "Created by " AppAuthor
    }
    ; 공통 GUI 구성
}
```

핫키/메뉴:

```ahk
MenuHandlerEn:
    ShowHelp("en")
Return

MenuHandlerKo:
    ShowHelp("ko")
Return
```

### 7.2 창 투명도

현재 `#!WheelUp`, `#!WheelDown`, `#![` , `#!]`가 직접 투명도를 조정한다.

권장 helper:

```ahk
AdjustActiveTransparency(delta) {
    WinGet, curtrans, Transparent, A
    if !curtrans {
        if curtrans != 0
            curtrans := 255
    }
    curtrans := Max(0, Min(255, curtrans + delta))
    WinSet, Transparent, %curtrans%, A
}
```

호출:

```ahk
#!WheelUp::
#!]::
    AdjustActiveTransparency(20)
return

#!WheelDown::
#![::
    AdjustActiveTransparency(-20)
return
```

### 7.3 볼륨 조절

볼륨 조절도 `SoundSet`, `SoundGet`, tooltip 조합이 반복된다.

권장 helper:

```ahk
AdjustVolume(delta) {
    SoundSet, %delta%
    SoundGet, master_volume
    ShowTempTooltip("volume: " Round(master_volume))
}
```

AHK v1에서 `SoundSet +10` 같은 구문을 함수 인자로 안전하게 전달하려면 `SoundSet, % delta` 방식이 동작하는지 테스트가 필요하다.

### 7.4 Window bookmark

현재 window bookmark는 object를 쓰고 있어 좋은 방향이다. 다만 `WindowBookmark_operation()` 안에는 주석 처리된 긴 대체 로직이 남아 있다.

정리 방향:

1. 현재 의도한 동작을 문서화한다.
2. virtual desktop을 넘나드는 activate는 현재 제한사항으로 명시한다.
3. 오래된 주석 블록은 `docs/notes-window-bookmark.md` 같은 별도 문서로 옮긴다.
4. 함수 내부는 현재 실행되는 로직만 남긴다.

### 7.5 Mouse bookmark

Mouse bookmark는 객체 구조가 비교적 좋다.

현재 구조:

```ahk
mousePosBookmark[mouseBookmark_no].Push({x: mousex, y: mousey})
```

개선점:

- DPI awareness 설정 `DllCall("SetThreadDpiAwarenessContext", "ptr", -4, "ptr")`를 매번 호출하지 말고 초기화 시 한 번 호출하거나 helper로 감싼다.
- bookmark 표시 GUI 이름이 index만 기준이라, 다른 번호의 bookmark 표시와 충돌할 수 있다. `mousePosBookmark%mouseBookmark_no%_%A_Index%`처럼 번호를 포함한다.

### 7.6 Mouse drag move/resize

마우스 드래그 이동은 기능이 풍부하지만 snap zone이 하드코딩되어 있다.

현재 설정:

```ahk
SETTING_CONSTANT_CAPSMOVE_CORNER := 180
SETTING_CONSTANT_CAPSMOVE_LRB := 150
SETTING_CONSTANT_CAPSMOVE_HALFTOP := 150
SETTING_CONSTANT_CAPSMOVE_TOP := 60
```

추천:

1. snap 판정을 함수로 분리한다.
2. 반환값은 `"top-left"`, `"top"`, `"right"`, `"center"` 같은 문자열로 한다.
3. 실제 window rect 계산은 별도 함수가 맡는다.

예:

```ahk
GetSnapZone(mouseX, mouseY, mon) {
    ; return "top-left", "top-right", "bottom-right", "bottom-left",
    ;        "left", "right", "top", "bottom", "center"
}

GetSnapRect(zone, mon, originalRect) {
    ; zone에 따른 target rect 반환
}
```

이렇게 하면 snap zone 튜닝과 창 이동 로직을 분리할 수 있다.

### 7.7 Wheel scroll

Wheel scroll은 최근 성능 개선이 많이 들어간 것으로 보인다. 그래도 상태 변수가 여러 wheel mode에 공유되는 구조는 장기적으로 위험하다.

권장 상태:

```ahk
FC.state.wheel := {}
FC.state.wheel.capsFast := { started: 0, speed: 0, triggeredAt: 0 }
FC.state.wheel.shiftOffice := { started: 0, speed: 0, triggeredAt: 0 }
FC.state.wheel.rotateStacking := { active: 0, current: 0 }
FC.state.wheel.rotatePopup := { active: 0, current: 0 }
```

각 mode가 자기 상태만 읽고 쓰게 하면, 서로 다른 wheel 기능이 겹쳐 들어왔을 때 상태 오염을 줄일 수 있다.

## 8. 문서와 사용자 경험 개선

### 8.1 README 보강

현재 README는 프로젝트 소개 위주다. 실제 사용자가 필요한 정보가 부족하다.

추가 권장:

- AutoHotkey v1.1 필요
- 설치 방법
- 실행 방법
- 시작 프로그램 등록 방법
- 단축키 목록 파일 안내
- AHK v2 비호환 안내
- 알려진 제한사항

예:

```markdown
## Requirements

- Windows
- AutoHotkey v1.1

This script currently uses AutoHotkey v1 syntax and does not run on AutoHotkey v2.
```

### 8.2 Shortcut list와 실제 핫키 동기화

shortcut list에는 `Shift + F1/F2/F3/F4`가 배열 기능으로 설명되어 있다. 코드에는 `+F5/+F6`도 `Show_Windows("Explorer.exe", ...)`로 연결되어 있다. 이 핫키가 의도된 공개 기능인지, 테스트용 alias인지 결정해야 한다.

정리 방안:

1. 공개 기능이면 shortcut list에 추가한다.
2. 테스트용이면 제거한다.
3. `+F1/+F2`를 새 구현으로 옮긴 뒤 `+F5/+F6`를 제거한다.

### 8.3 `history.txt` 정책

최근 history는 매우 좋다. 다만 코드 정리 작업이 들어가면 다음을 구분해서 기록하는 것이 좋다.

- Behavior changes
- Bug fixes
- Refactoring only
- Performance changes
- Known limitations

## 9. 권장 수정 로드맵

### 9.1 1차: 안정성 패치

목표: 동작 변경을 최소화하면서 런타임 오류와 무한 대기 위험 제거

작업 목록:

1. `#Requires AutoHotkey v1.1` 추가
2. README에 AHK v1 요구사항 추가
3. `^+!RButton` `WinWaitActive` timeout 추가
4. 그리드 수 `Max(1, ...)` 보정
5. `Show_Windows()` 빈 목록 선검사
6. `BlockInput` 구간 timeout/cleanup 추가
7. Office COM 호출 `try/catch` 추가
8. 도움말 파일 누락 시 `Loop, read` 실행하지 않도록 수정

검증:

- 스크립트 시작
- 트레이 메뉴 열기
- 도움말 한국어/영어 열기
- `Ctrl+Shift+Alt+RightClick`
- `Shift+F1/F2/F3/F4`
- 작은 해상도나 임의로 낮춘 RDP 창에서 배열 기능

### 9.2 2차: helper 추출

목표: 중복 제거의 기반 마련

추출할 helper:

- `ShowTempTooltip`
- `ActivateWindowSafe`
- `MoveWindowRect`
- `PulseTop`
- `GetMonitors`
- `FindMonitorByPoint`
- `FindMonitorByWindow`
- `GetWindowInfo`
- `GetAltTabWindows`
- `FilterWindowsSameType`

이 단계에서는 알고리즘을 바꾸지 말고 기존 로직을 helper로 이동하는 데 집중한다.

### 9.3 3차: 창 배열 통합

목표: Explorer 전용 구버전 배열 코드 제거

작업:

1. `Show_Windows()`의 기능 parity 확인
2. `+F1/+F2`를 `Show_Windows("Explorer.exe", "", mode)`로 연결
3. 기존 `+F1/+F2` 대형 블록 제거
4. `+F5/+F6` alias 여부 결정
5. shortcut list 업데이트

주의:

- 기존 `+F1/+F2`와 `+F5/+F6`의 window ordering이 다를 수 있다.
- 기존 Explorer 전용 코드가 가진 특수 케이스가 새 함수에 모두 반영되어 있는지 테스트해야 한다.

### 9.4 4차: 알고리즘 교체

목표: 코드 단순화와 일관된 동작

작업:

1. 그리드 계산을 창 개수/화면 비율 기반으로 변경
2. 방향 탐색을 `FindNearestWindow()`로 일반화
3. `Sort_Object()` 교체
4. `WinActivate` 루프 내부 호출 제거
5. 가능하면 `SetWindowPos` 또는 batch move 검토

### 9.5 5차: 구조 분리

목표: 장기 유지보수 가능한 파일 구조

추천 파일 분리:

```text
FrogControl.ahk
lib/
  FC_Monitors.ahk
  FC_Windows.ahk
  FC_AltTab.ahk
  FC_Arrange.ahk
  FC_Mouse.ahk
  FC_Tooltip.ahk
  FC_Bookmarks.ahk
docs/
  architecture.md
  shortcut-maintenance.md
```

AHK v1의 `#Include`를 사용한다. 처음부터 모든 것을 나누지 말고 helper 안정화 후 분리한다.

## 10. 테스트 매트릭스

### 10.1 기본 실행

- AHK v1.1 설치 환경에서 실행
- AHK v2만 설치된 환경에서 `#Requires` 메시지가 명확한지 확인
- compiled exe 환경에서 아이콘 표시 확인
- non-compiled `.ahk` 환경에서 아이콘 표시 확인

### 10.2 도움말

- 영어 도움말 열기
- 한국어 도움말 열기
- shortcut list 파일을 임시로 이름 변경한 뒤 file-not-found 행 표시 확인
- 도움말 창 반복 열기 시 GUI 누수 없는지 확인

### 10.3 창 닫기/최소화/top

- `Ctrl+Shift+RightClick`
- `Ctrl+Shift+Alt+RightClick`
- `Win+Ctrl+Shift+Alt+RightClick`
- 대상 창이 관리자 권한 창일 때
- 대상 창이 활성화 불가능한 overlay/window일 때

### 10.4 창 배열

테스트 조건:

- Explorer 0개
- Explorer 1개
- Explorer 2개
- Explorer 3개
- Explorer 4개
- Explorer 5개 이상
- 같은 앱 창 1/2/3/4/5개 이상
- 최소화된 창 포함
- 최대화된 창 포함
- always-on-top 창 포함

모니터 조건:

- 단일 1920x1080
- 단일 작은 RDP 해상도
- 2모니터 좌우
- 3모니터
- 주 모니터가 왼쪽이 아닌 구성
- 보조 모니터가 음수 좌표인 구성
- 125%, 150% DPI

### 10.5 마우스 기능

- CapsLock+Left drag 일반 이동
- corner snap
- edge snap
- top snap
- Esc cancel
- maximized window drag
- CapsLock+Right drag resize
- resize 중 Esc cancel
- cursor restore 확인

### 10.6 Wheel scroll

- 일반 앱에서 CapsLock+Wheel
- Excel에서 CapsLock+Shift+Wheel
- Word에서 Shift+Wheel
- Excel/Word가 응답 없음 상태일 때
- COM 접근 실패 시 오류 대화상자 없는지 확인

### 10.7 Bookmark

- mouse bookmark 저장/이동/클릭/삭제
- 여러 bookmark 번호 간 GUI 표시 충돌 여부
- window bookmark 저장/활성화/최소화
- 저장된 window가 닫힌 뒤 동작
- virtual desktop이 다른 경우 동작 제한 확인

## 11. 수정 담당자를 위한 작업 원칙

1. 먼저 안전 패치를 작게 커밋한다.
2. 동작 변경과 리팩터링을 같은 커밋에 섞지 않는다.
3. `AltTab_window_list()`와 `Show_Windows()` 주변은 수동 테스트 없이 대규모 변경하지 않는다.
4. 동적 변수에서 객체로 옮길 때는 한 자료구조를 canonical source로 정한다.
5. topmost 상태를 건드리는 코드는 원래 상태 보존 여부를 반드시 확인한다.
6. `BlockInput`, system cursor, system beep처럼 OS 전역 상태를 바꾸는 기능은 반드시 cleanup 경로를 둔다.
7. COM 호출은 항상 `try/catch`로 감싼다.
8. shortcut list와 실제 핫키를 함께 수정한다.

## 12. 우선순위 표

| 우선순위 | 작업 | 이유 |
| --- | --- | --- |
| P0 | `#Requires AutoHotkey v1.1` | v2 환경 즉시 실패 방지 |
| P0 | Git rename 상태 정리 | 커밋/배포 파일 누락 방지 |
| P1 | `WinWaitActive` timeout | 핫키 스레드 무한 대기 방지 |
| P1 | 그리드 0 나눗셈 방어 | 작은 화면/원격 환경 오류 방지 |
| P1 | `Show_Windows()` 빈 목록 선검사 | 매칭 창 없음 오류 방지 |
| P1 | `BlockInput` cleanup | 입력 차단 지속 방지 |
| P2 | COM try/fallback | Office 연동 오류 방지 |
| P2 | 도움말 파일 누락 처리 | 배포 누락 시 GUI 안정성 |
| P2 | monitor helper 추출 | 중복 제거 기반 |
| P2 | window move/top helper 추출 | 반복 버그 감소 |
| P3 | Explorer 배열 코드 통합 | 800줄 이상 중복 제거 |
| P3 | 방향 탐색 알고리즘 일반화 | 4방향 복붙 제거 |
| P3 | 정렬 함수 교체 | 단순화 및 성능 개선 |
| P4 | 파일 구조 분리 | 장기 유지보수성 |

## 13. 결론

현재 FrogControl은 기능 범위가 넓고, 최근 `history.txt` 기준으로 상당한 버그 수정과 성능 개선이 이미 들어간 상태다. 그러나 구조적으로는 여전히 단일 파일, 전역 상태, 동적 변수, 대형 복붙 블록에 의존한다. 가장 위험한 문제는 실행 환경 명시 부족, 일부 무한 대기, 작은 화면에서의 그리드 계산 오류, `Show_Windows()`의 빈 목록 접근이다.

가장 효과적인 개선 순서는 다음이다.

1. 안전성 결함을 먼저 고친다.
2. 공통 helper를 추출한다.
3. Explorer 전용 배열 코드와 `Show_Windows()`를 통합한다.
4. 방향 탐색과 그리드 알고리즘을 일반화한다.
5. 마지막으로 파일을 모듈화한다.

이 순서를 지키면 큰 동작 변경 없이도 코드량과 버그 표면을 크게 줄일 수 있다.
