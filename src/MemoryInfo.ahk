; GLOBAL SETTINGS ===============================================================================================================

#NoEnv
#SingleInstance Force
SetBatchLines -1

global TaskbarProgressEnabled := true     ; false -> off     |   true -> on
global TaskbarProgressColored := false    ; false -> green   |   true -> green > yellow > red

; GUI ===========================================================================================================================

Gui, +hWndhMainGUI
Gui, Margin, 10, 10
Gui, Color, FFFFFF
Gui, Font, s10, Lucida Console

Gui, Add, Text, xm     ym  w120 h23 0x200, % "Total Memory:"
Gui, Add, Text, xm+125 ym  w115 h23 0x202 vEdtTotalPhys

Gui, Add, Text, xm     y+5 w120 h23 0x200, % "Free Memory:"
Gui, Add, Text, xm+125 yp  w115 h23 0x202 vEdtAvailPhys

Gui, Add, Text, xm     y+5 w120 h23 0x200, % "Used Memory:"
Gui, Add, Text, xm+125 yp  w115 h23 0x202 vEdtFreePhys

Gui, Add, Progress, xm y+5 w240 h23 r0-100 BackgroundFFFFFF cCCE8FF vPrgMemLoad
Gui, Add, Text, xp yp  w240 h23 0x201 +BackgroundTrans border vEdtMemLoad

Gui, Add, Text, xm y+5 w240 h1 0x5

Gui, Add, Button, xm-1 y+4 w120 h25 gFREE_MEMORY, % "Clear Memory"
Gui, Add, Text,   xm+125  yp+1 w115 h23 0x202 vEdtFreeMem

Gui, Show, AutoSize
SetTimer, GET_MEMORY, 2000

; SCRIPT ========================================================================================================================

GET_MEMORY:
    GSMEx := GlobalMemoryStatusEx()
    GuiControl,, EdtTotalPhys, % GetNumberFormat((TP := GSMEx.TotalPhys) / 1048576) " MB"
    GuiControl,, EdtAvailPhys, % GetNumberFormat((AP := GSMEx.AvailPhys) / 1048576) " MB"
    GuiControl,, EdtFreePhys,  % GetNumberFormat((TP - AP) / 1048576) " MB"
    GuiControl,, PrgMemLoad,   % ML := GSMEx.MemoryLoad
    GuiControl,, EdtMemLoad,   % ML " %"
    DllCall("user32\SetWindowText", "ptr", hMainGUI, "str", "Mem: " ML " %")
    if (TaskbarProgressEnabled) {
        if (TaskbarProgressColored)
            SetTaskbarProgress(hMainGUI, ML, (ML > 84) ? 4 : (ML > 74) ? 8 : 2)
        else
            SetTaskbarProgress(hMainGUI, ML)
    }
return

FREE_MEMORY:
    APBefore := GlobalMemoryStatusEx().AvailPhys
    FreeMemory()
    APAfter  := GlobalMemoryStatusEx().AvailPhys
    GuiControl,, EdtFreeMem, % GetNumberFormat((APAfter - APBefore) / 1048576) " MB"
return

; FUNCTIONS =====================================================================================================================

CtlColorBtns()
{
    static init := OnMessage(0x0135, "CtlColorBtns")
    return DllCall("gdi32\CreateSolidBrush", "uint", 0xFFFFFF, "uptr")
}

GlobalMemoryStatusEx()                                          ; https://msdn.microsoft.com/en-us/library/aa366589(v=vs.85).aspx
{
    static MSEX, init := NumPut(VarSetCapacity(MSEX, 64, 0), MSEX, "uint")
    if !(DllCall("GlobalMemoryStatusEx", "ptr", &MSEX))
        throw Exception("Call to GlobalMemoryStatusEx failed: " A_LastError, -1)
    return { MemoryLoad: NumGet(MSEX, 4, "uint"), TotalPhys: NumGet(MSEX, 8, "uint64"), AvailPhys: NumGet(MSEX, 16, "uint64") }
}

FreeMemory()
{
    for objItem in ComObjGet("winmgmts:").ExecQuery("SELECT * FROM Win32_Process") {
        try {
            hProcess := DllCall("OpenProcess", "uint", 0x001F0FFF, "int", 0, "uint", objItem.ProcessID, "ptr")
            DllCall("SetProcessWorkingSetSize", "ptr", hProcess, "uptr", -1, "uptr", -1)
            DllCall("psapi.dll\EmptyWorkingSet", "ptr", hProcess)
            DllCall("CloseHandle", "ptr", hProcess)
        }
    }
    return, DllCall("psapi.dll\EmptyWorkingSet", "ptr", -1)
}

GetNumberFormat(VarIn, locale := 0x0400)                        ; https://msdn.microsoft.com/en-us/library/dd318110(v=vs.85).aspx
{
    if !(size := DllCall("GetNumberFormat", "UInt", locale, "UInt", 0, "Ptr", &VarIn, "Ptr", 0, "Ptr", 0, "Int", 0))
        throw Exception("GetNumberFormat", -1)
    VarSetCapacity(buf, size * (A_IsUnicode ? 2 : 1), 0)
    if !(DllCall("GetNumberFormat", "UInt", locale, "UInt", 0, "Ptr", &VarIn, "Ptr", 0, "Str", buf, "Int", size))
        throw Exception("GetNumberFormat", -1)
    return buf
}

SetTaskbarProgress(handle, value := 0, state := 0)              ; https://msdn.microsoft.com/en-us/library/dd391692(v=vs.85).aspx
{
    static ITaskbarList3 := ""
    if !(ITaskbarList3)
        try ITaskbarList3 := ComObjCreate("{56FDF344-FD6D-11D0-958A-006097C9A090}", "{EA1AFB91-9E28-4B86-90E9-9E9F8A5EEFAF}")
    DllCall(NumGet(NumGet(ITaskbarList3 + 0) + 10 * A_PtrSize), "ptr", ITaskbarList3, "ptr", handle, "int", state)
    DllCall(NumGet(NumGet(ITaskbarList3 + 0) +  9 * A_PtrSize), "ptr", ITaskbarList3, "ptr", handle, "int64", value, "int64", 100)
    return (ITaskbarList3 ? 0 : 1)
}

; EXIT ==========================================================================================================================

GuiClose:
GuiEscape:
    ExitApp