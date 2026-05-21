#Requires AutoHotkey v2.0.0+
;==============================================================
; msgBoxHelp — MessageBox Help button handler with optional callback and close behavior
;
; GitHub: https://github.com/SevenKeyboard/msg-box-help
; Author: SevenKeyboard Ltd. (2026)
; License: MIT License
;
; Known limitation:
;   Multiple simultaneous msgBoxHelp() dialogs with the same owner are not supported.
;
; Documentation / References:
;   MENUITEMINFOW structure (winuser.h)
;     https://learn.microsoft.com/en-us/windows/win32/api/winuser/ns-winuser-menuiteminfow
;   How do I use the MsgBox "help" button Topic is solved
;     https://www.autohotkey.com/boards/viewtopic.php?t=129614
;==============================================================

/*
Example Usage:

    #SingleInstance Force

    MB_TOPMOST := 0x00040000

    ;  Basic usage.
    F1::  {
        result := msgBoxHelp('Click Help to return "Help".', 'Basic Example')
        setTimer(tooltip, -1000)
        tooltip('Result: ' . result)
        switch (result)
        {
            case 'OK':
                ;  TO DO
            case 'Help':
                ;  TO DO
        }
    }

    ;  Run a callback and keep the message box open.
    F2::msgBoxHelp('Click Help to open the AutoHotkey website.'
        ,'Open Website'
        ,MB_TOPMOST
        ,openAutoHotkeyWebsite
        ,false)
    openAutoHotkeyWebsite(lphi)    {
        run('https://www.autohotkey.com/')
    }

    ;  Run an inline callback and keep the message box open.
    F3::msgBoxHelp('Click Help to open the AutoHotkey documentation.'
        ,'Open Documentation'
        ,MB_TOPMOST
        ,(*) => run('https://www.autohotkey.com/docs/v2/')
        ,false)

    ;  Use an owner window.
    F4::  {
        myGui := gui()
        myGui.show('w300 h200')
        result := msgBoxHelp('This message box is owned by the GUI window.', 'Owner Example', 'Owner' . myGui.Hwnd)
        setTimer(tooltip, -1000)
        tooltip('Result: ' result)
        sleep(500)
        myGui.destroy()
    }
*/

class VersionManager_msgBoxHelp
{
    static _ := this._init()
    static _init()    {
        global
        MSGBOXHELP_VERSION := "1.0.0"
    }
}
msgBoxHelp(text?, title?, options := 0, callback := -1, closeOnHelp := true)    {
    return _MessageBoxHelp.show(text?, title?, options, callback, closeOnHelp)
}
class _MessageBoxHelp
{
    static _results := map()
    static show(text?, title?, options := 0, callback := -1, closeOnHelp := true)    {
        static WM_HELP := 0x0053, MB_HELP := 0x00004000
        hOwner := 0
        options .= " " . MB_HELP
        for opt in strSplit(options, [A_Space, A_Tab])    {
            if (opt ~= "\AOwner.")
                hOwner := integer(subStr(opt, 6)) & 0xFFFFFFFF
        }
        callId := this._createGuidString()
        if (hOwner)    {
            hRootWnd := hOwner
        }  else  {
            tempGui := gui("+OwnDialogs")
            hRootWnd := tempGui.Hwnd & 0xFFFFFFFF
        }
        this._results[callId] := ""
        objbm := objBindMethod(this, "_onHelp", hRootWnd, callId, callback, closeOnHelp)
        onMessage(WM_HELP, objbm, -1)
        try  {
            result := msgbox(text?, title?, options)
        }  finally  {
            onMessage(WM_HELP, objbm, 0)
            objbm := ""
            if (isSet(tempGui))
                tempGui.destroy()
        }
        result := (this._results.has(callId) && this._results[callId]
            ? this._results[callId]
            : result)
        if (this._results.has(callId))
            this._results.delete(callId)
        return result
    }
    static _onHelp(hRootWnd, callId, callback, closeOnHelp, _, lphi, *)    {
        static WM_SYSCOMMAND := 0x0112, SC_CLOSE := 0xF060
        prevDHW := detectHiddenWindows(true)
        msgParentWindow := winExist() & 0xFFFFFFFF
        detectHiddenWindows(prevDHW)
        if (msgParentWindow == hRootWnd)    {
            if (closeOnHelp)    {
                hItemHandle := numGet((lphi + (A_PtrSize == 8 ? 16 : 12)), "Ptr")
                hMenu := dllCall("User32.dll\GetSystemMenu", "Ptr",hItemHandle, "Int",false, "Ptr")
                lpmii := buffer(cbSize := (A_PtrSize == 8 ? 80 : 48), 0)
                numPut("UInt", cbSize, lpmii, 0)
                if (dllCall("User32.dll\GetMenuItemInfoW", "Ptr",hMenu, "UInt",SC_CLOSE, "Int",false, "Ptr",lpmii.Ptr, "Int"))
                    dllCall("User32.dll\PostMessageW", "Ptr",hItemHandle, "UInt",WM_SYSCOMMAND, "UPtr",SC_CLOSE, "Ptr",0, "Int")
                else
                    controlSend("{Space}", "Button1", "ahk_id " . hItemHandle)
                if (winWaitClose("ahk_id " . hItemHandle,, 0.5))
                    this._results[callId] := "Help"
            }
            if (callback !== -1)
                try callback.call(lphi)
            return true
        }
    }
    static _createGuidString()    {
        static S_OK := 0x00000000
        pguid := buffer(16, 0)
        if (dllCall("Ole32.dll\CoCreateGuid", "Ptr",pguid.Ptr, "Ptr") == S_OK)    {
            lpsz := buffer(2 * 39, 0)
            if (dllCall("Ole32.dll\StringFromGUID2", "Ptr",pguid.Ptr, "Ptr",lpsz.Ptr, "Int",39, "Int"))
                return strGet(lpsz, "UTF-16")
        }
    }
}