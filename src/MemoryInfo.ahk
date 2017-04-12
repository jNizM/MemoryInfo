; ===============================================================================================================================
; AHK Version ...: AHK_L 1.1.19.03 x64 Unicode
; Win Version ...: Windows 7 Professional x64 SP1
; Description ...: Shows Info about Total, Free, Used Memory in MB;
;                  Total Memory in Percentage & Clear unused Memory Function
; Version .......: v0.2
; Modified ......: 2015.02.15-1527
; Author ........: jNizM
; Licence .......: WTFPL (http://www.wtfpl.net/txt/copying/)
; ===============================================================================================================================
;@Ahk2Exe-SetName MemoryInfo
;@Ahk2Exe-SetDescription MemoryInfo
;@Ahk2Exe-SetVersion v0.2
;@Ahk2Exe-SetCopyright Copyright (c) 2013-2015`, jNizM
;@Ahk2Exe-SetOrigFilename MemoryInfo.ahk
; ===============================================================================================================================

; GLOBAL SETTINGS ===============================================================================================================

#Warn
#NoEnv
#SingleInstance Force

global name       := "MemoryInfo"
global version    := "v0.2"
global love       := chr(9829)

; GUI ===========================================================================================================================

Gui, Margin, 10, 10
Gui, Font, s9, Courier New

Gui, Add, Text, xm ym w110 h20 0x200, % "Total Memory:"
Gui, Add, Text, x+5 ym w100 h20 0x202 vTMemory

Gui, Add, Text, xm y+6 w110 h20 0x200, % "Free Memory:"
Gui, Add, Text, x+5 yp w100 h20 0x202 vFMemory
Gui, Add, Progress, x+5 yp h20 r0-10 0x01 BackgroundC9C9C9 c5BB75E vPFMemory
Gui, Add, Text, xp yp w135 h20 0x201 +BackgroundTrans vFreePerc

Gui, Add, Text, xm y+6 w110 h20 0x200, % "Used Memory:"
Gui, Add, Text, x+5 yp w100 h20 0x202 vUMemory
Gui, Add, Progress, x+5 yp h20 r0-10 0x01 BackgroundC9C9C9 cDA4F49 vPUMemory
Gui, Add, Text, xp yp w135 h20 0x201 +BackgroundTrans vUsedPerc
Gui, Add, Text, xm y+10 w358 h1 0x10

Gui, Add, Text, xm y+10 w110 h20 0x200, % "Cleared Memory:"
Gui, Add, Text, x+5 yp w100 h20 0x202 vCMMemory
Gui, Add, Button, x+41 yp-3 w100 gClearMem, % "Clear Memory"

Gui, Font, cSilver
Gui, Add, Text, xm y+6 w356 0x200, % "made with " love " and AHK 2013-" A_YYYY ", jNizM"

Gui, Show, AutoSize, % name " " version

GoSub, GetMemory
SetTimer, GetMemory, 1000
return

; SCRIPT ========================================================================================================================

GetMemory:
    GMSEx := GlobalMemoryStatusEx()
    , TPM := Round(GMSEx[3] / 1024**2, 2), APM := Round(GMSEx[4] / 1024**2, 2)
    , UPM := Round(TPM - APM, 2), UPP := Round(UPM / TPM * 100, 2)
    , CLR := ((UPP < 70) ? "+c5BB75E" : ((UPP < 80) ? "+cFFC266" : "+cDA4F49"))

    GuiControl,, TMemory, % TPM " MB"
    GuiControl,, FMemory, % APM " MB"
    GuiControl,, UMemory, % UPM " MB"
    GuiControl,, FreePerc, % Round((100 - (TPM - APM) / TPM * 100), 2) " %"
    GuiControl,, UsedPerc, % Round(((TPM - APM) / TPM * 100), 2) " %"

    GuiControl +Range0-%TPM%, PFMemory
    GuiControl,, PFMemory, % APM
    GuiControl, % CLR, PFMemory

    GuiControl +Range0-%TPM%, PUMemory
    GuiControl,, PUMemory, % UPM
    GuiControl, % CLR, PUMemory
return

ClearMem:
    GMSCA := Round(GlobalMemoryStatusEx().4 / 1024**2, 2)
    ClearMemory(), FreeMemory()
    GMSCB := Round(GlobalMemoryStatusEx().4 / 1024**2, 2)
    GuiControl,, CMMemory, % Round(GMSCB - GMSCA, 2) " MB"
return

; FUNCTIONS =====================================================================================================================

GlobalMemoryStatusEx()
{
    static MSEX, init := VarSetCapacity(MSEX, 64, 0) && NumPut(64, MSEX, "UInt")
    if !(DllCall("kernel32.dll\GlobalMemoryStatusEx", "Ptr", &MSEX))
        return "*" DllCall("kernel32.dll\GetLastError")
    return { 3 : NumGet(MSEX, 8, "UInt64"), 4 : NumGet(MSEX, 16, "UInt64") }
}

ClearMemory()
{
    for objItem in ComObjGet("winmgmts:").ExecQuery("SELECT * FROM Win32_Process")
    {
        hProcess := DllCall("kernel32.dll\OpenProcess", "UInt", 0x001F0FFF, "Int", 0, "UInt", objItem.ProcessID)
        , DllCall("kernel32.dll\SetProcessWorkingSetSize", "Ptr", hProcess, "UPtr", -1, "UPtr", -1)
        , DllCall("psapi.dll\EmptyWorkingSet", "Ptr", hProcess)
        , DllCall("kernel32.dll\CloseHandle", "Ptr", hProcess)
    }
    return
}

FreeMemory()
{
    return DllCall("psapi.dll\EmptyWorkingSet", "Ptr", -1)
}

; EXIT ==========================================================================================================================

Close:
GuiClose:
GuiEscape:
    ExitApp
