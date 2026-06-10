#Requires AutoHotkey v1.1.35+
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
    return

    HideTooltip:
        tooltip
        return

    ;  Basic usage.
    F1::
        result := msgBoxHelp("Click Help to return ""Help"".", "Basic Example")
        setTimer % "HideTooltip", -1000
        tooltip % "Result: " . result
        switch (result)
        {
            case "OK":
                ;  TO DO
            case "Help":
                ;  TO DO
        }
        return

    ;  Run a callback and keep the message box open.
    F2::msgBoxHelp("Click Help to open the AutoHotkey website."
        ,"Open Website"
        ,MB_TOPMOST
        ,func("openAutoHotkeyWebsite")
        ,false)
    openAutoHotkeyWebsite(lphi)    {
        run % "https://www.autohotkey.com/"
    }
    
    F3::msgBoxHelp("Click Help to open the AutoHotkey documentation."
        ,"Open Documentation"
        ,MB_TOPMOST
        ,func("openAutoHotkeyDocumentation")
        ,false)
    openAutoHotkeyDocumentation(lphi)    {
        run % "https://www.autohotkey.com/docs/v2/"
    }

    ;  Use an owner window.
    F4::
        gui +hwndhGui +OwnDialogs
        gui Show, % "w300 h200"
        result := msgBoxHelp("This message box is owned by the GUI window.", "Owner Example", "Owner" . hGui)
        setTimer % "HideTooltip", -1000
        tooltip % "Result: " . result
        sleep 500
        gui Destroy
        return
*/

class VersionManager_msgBoxHelp
{
    static _ := VersionManager_msgBoxHelp._init()
    _init()    {
        global
        MSGBOXHELP_VERSION := "1.0.1"
    }
}
msgBoxHelp(text := "", title := "", options := 0, callback := -1, closeOnHelp := true)    {
    return _MessageBoxHelp.show(text, title, options, callback, closeOnHelp)
}
class _MessageBoxHelp
{
    static _results := object()
    show(text := "", title := "", options := 0, callback := -1, closeOnHelp := true)    {
        static WM_HELP := 0x0053
            ,MB_OK                  := 0x00000000
            ,MB_OKCANCEL            := 0x00000001
            ,MB_ABORTRETRYIGNORE    := 0x00000002
            ,MB_YESNOCANCEL         := 0x00000003
            ,MB_YESNO               := 0x00000004
            ,MB_RETRYCANCEL         := 0x00000005
            ,MB_CANCELTRYCONTINUE   := 0x00000006
            ,MB_ICONHAND            := 0x00000010
            ,MB_ICONQUESTION        := 0x00000020
            ,MB_ICONEXCLAMATION     := 0x00000030
            ,MB_ICONASTERISK        := 0x00000040
            ,MB_DEFBUTTON2          := 0x00000100
            ,MB_DEFBUTTON3          := 0x00000200
            ,MB_DEFBUTTON4          := 0x00000300     
            ,MB_HELP                := 0x00004000
            ,MB_TYPEMASK            := 0x0000000F
            ,MB_ICONMASK            := 0x000000F0
            ,MB_DEFMASK             := 0x00000F00
            ,MB_MODEMASK            := 0x00003000
        uType   := 0
        hOwner  := 0
        timeout := ""
        for _,opt in strSplit(options, [A_Space, A_Tab])    {
            if (opt == "")    {
                continue
            }  else if (opt = "OK" || opt = "O")    {
                uType := (uType & ~MB_TYPEMASK) | MB_OK
            }  else if (opt = "OKCancel" || opt = "O/C" || opt = "OC")    {
                uType := (uType & ~MB_TYPEMASK) | MB_OKCANCEL
            }  else if (opt = "AbortRetryIgnore" || opt = "A/R/I" || opt = "ARI")    {
                uType := (uType & ~MB_TYPEMASK) | MB_ABORTRETRYIGNORE
            }  else if (opt = "YesNoCancel" || opt = "Y/N/C" || opt = "YNC")    {
                uType := (uType & ~MB_TYPEMASK) | MB_YESNOCANCEL
            }  else if (opt = "YesNo" || opt = "Y/N" || opt = "YN")    {
                uType := (uType & ~MB_TYPEMASK) | MB_YESNO
            }  else if (opt = "RetryCancel" || opt = "R/C" || opt = "RC")    {
                uType := (uType & ~MB_TYPEMASK) | MB_RETRYCANCEL
            }  else if (opt = "CancelTryAgainContinue" || opt = "C/T/C" || opt = "CTC")    {
                uType := (uType & ~MB_TYPEMASK) | MB_CANCELTRYCONTINUE
            }  else if (opt = "Iconx")    {
                uType := (uType & ~MB_ICONMASK) | MB_ICONHAND
            }  else if (opt = "Icon?")    {
                uType := (uType & ~MB_ICONMASK) | MB_ICONQUESTION
            }  else if (opt = "Icon!")    {
                uType := (uType & ~MB_ICONMASK) | MB_ICONEXCLAMATION
            }  else if (opt = "Iconi")    {
                uType := (uType & ~MB_ICONMASK) | MB_ICONASTERISK
            }  else if (opt = "Default2")    {
                uType := (uType & ~MB_DEFMASK) | MB_DEFBUTTON2
            }  else if (opt = "Default3")    {
                uType := (uType & ~MB_DEFMASK) | MB_DEFBUTTON3
            }  else if (opt = "Default4")    {
                uType := (uType & ~MB_DEFMASK) | MB_DEFBUTTON4
            }  else if (opt ~= "\A(?:[[:digit:]]+|0[Xx][[:xdigit:]]+)\z")    {
                if (opt & MB_TYPEMASK)
                    uType &= ~MB_TYPEMASK
                if (opt & MB_ICONMASK)
                    uType &= ~MB_ICONMASK
                if (opt & MB_DEFMASK)
                    uType &= ~MB_DEFMASK
                if (opt & MB_MODEMASK)
                    uType &= ~MB_MODEMASK
                uType |= opt
            }  else if (opt ~= "\AOwner.")    { ;  Owner and T use simple parsing.
                hOwner := (format("{:d}", subStr(opt, 6)) + 0) & 0xFFFFFFFF
            }  else if (opt ~= "\AT.")    {
                timeout := (format("{:d}", subStr(opt, 2)) + 0)
            }  else  {
                throw exception("Invalid option.", -1)
            }
        }
        options := uType | MB_HELP
        callId := this._createGuidString()
        if (hOwner)    {
            tempGuiName := ""
            hRootWnd := hOwner
        }  else  {
            tempGuiName := "MessageBoxHelp_TempOwner_"
                . regExReplace(callId, "\W+")
            gui %tempGuiName%:+hwndhGui +OwnDialogs
            hRootWnd := hGui & 0xFFFFFFFF
        }
        this._results[callId] := ""
        objbm := objBindMethod(this, "_onHelp", hRootWnd, callId, callback, closeOnHelp)
        onMessage(WM_HELP, objbm, -1)
        try  {
            msgbox % options, % title, % text, % timeout
            switch (options & 0x0000000F)
            {
                case MB_OK:
                    ifMsgBox OK
                        result := "OK"
                    ifMsgBox Timeout
                        result := "Timeout"
                case MB_OKCANCEL:
                    ifMsgBox OK
                        result := "OK"
                    ifMsgBox Cancel
                        result := "Cancel"
                    ifMsgBox Timeout
                        result := "Timeout"
                case MB_ABORTRETRYIGNORE:
                    ifMsgBox Abort
                        result := "Abort"
                    ifMsgBox Retry
                        result := "Retry"
                    ifMsgBox Ignore
                        result := "Ignore"
                    ifMsgBox Timeout
                        result := "Timeout"
                case MB_YESNOCANCEL:
                    ifMsgBox Yes
                        result := "Yes"
                    ifMsgBox No
                        result := "No"
                    ifMsgBox Cancel
                        result := "Cancel"
                    ifMsgBox Timeout
                        result := "Timeout"
                case MB_YESNO:
                    ifMsgBox Yes
                        result := "Yes"
                    ifMsgBox No
                        result := "No"
                    ifMsgBox Timeout
                        result := "Timeout"
                case MB_RETRYCANCEL:
                    ifMsgBox Retry
                        result := "Retry"
                    ifMsgBox Cancel
                        result := "Cancel"
                    ifMsgBox Timeout
                        result := "Timeout"
                case MB_CANCELTRYCONTINUE:
                    ifMsgBox Cancel
                        result := "Cancel"
                    ifMsgBox TryAgain
                        result := "TryAgain"
                    ifMsgBox Continue
                        result := "Continue"
                    ifMsgBox Timeout
                        result := "Timeout"
            }
        }  finally  {
            onMessage(WM_HELP, objbm, 0)
            objbm := ""
            if (tempGuiName)
                gui %tempGuiName%:Destroy
        }
        result := (this._results.hasKey(callId) && this._results[callId]
            ? this._results[callId]
            : result)
        if (this._results.hasKey(callId))
            this._results.delete(callId)
        return result
    }
    _onHelp(hRootWnd, callId, callback, closeOnHelp, _, lphi, __*)    {
        static WM_SYSCOMMAND := 0x0112, SC_CLOSE := 0xF060
        prevDHW := A_DetectHiddenWindows
        detectHiddenWindows % "On"
        msgParentWindow := winExist() & 0xFFFFFFFF
        detectHiddenWindows % prevDHW
        if (msgParentWindow == hRootWnd)    {
            if (closeOnHelp)    {
                hItemHandle := numGet((lphi + (A_PtrSize == 8 ? 16 : 12)), "Ptr")
                hMenu := dllCall("User32.dll\GetSystemMenu", "Ptr",hItemHandle, "Int",false, "Ptr")
                varSetCapacity(lpmii, cbSize := (A_PtrSize == 8 ? 80 : 48), 0)
                numPut(cbSize, &lpmii, 0, "UInt")
                if (dllCall("User32.dll\GetMenuItemInfoW", "Ptr",hMenu, "UInt",SC_CLOSE, "Int",false, "Ptr",&lpmii, "Int"))
                    dllCall("User32.dll\PostMessageW", "Ptr",hItemHandle, "UInt",WM_SYSCOMMAND, "UPtr",SC_CLOSE, "Ptr",0, "Int")
                else
                    controlSend % "Button1", % "{Space}", % "ahk_id " . hItemHandle
                winWaitClose % "ahk_id " . hItemHandle,, 0.5
                if (!errorLevel)
                    this._results[callId] := "Help"
            }
            if (callback !== -1)
                try callback.call(lphi)
            return true
        }
    }
    _createGuidString()    {
        static S_OK := 0x00000000
        varSetCapacity(pguid, 16, 0)
        if (dllCall("Ole32.dll\CoCreateGuid", "Ptr",&pguid, "Ptr") == S_OK)    {
            varSetCapacity(lpsz, 2 * 39, 0)
            if (dllCall("Ole32.dll\StringFromGUID2", "Ptr",&pguid, "Ptr",&lpsz, "Int",39, "Int"))
                return strGet(&lpsz, "UTF-16")
        }
    }
}