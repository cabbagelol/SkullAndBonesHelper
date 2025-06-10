; Main.ahk
#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn All, Off

; --- Global Variables and Configuration ---
; 配置文件路径
configFile := A_ScriptDir "\config.ini"

; 默认配置
global config := Map(
    "hotkeys", Map(
        "autoClick", "F1",
        "timer", "F2",
        "antiKick", "F3"
    ),
    "delays", Map(
        "down", 50,
        "up", 150
    ),
   "app", Map(
        "version", "0.0.0"
    ),
)

; 功能状态变量
global isAutoClickEnabled := false
global timerRunning := false
global timerEndTime := 0
global isRandomKeyEnabled := false
global randomKeyTimer := 0

; GUI句柄 (用于在不同函数中访问GUI控件)
global MainGui
global lv ; Make lv global so it can be accessed by other functions
global delayGui := 0 ; Initialize GUI handles globally to manage their state
global timerGui := 0
global antiKickGui := 0
global configGui := 0
global AboutGui := 0 ; Also globalize AboutGui to manage its state

; --- Import Modules ---
#Include Lib\Config.ahk
#Include Lib\GUI_Main.ahk
#Include Lib\GUI_Configs.ahk
#Include Lib\Functions.ahk
#Include Lib\Hotkeys.ahk
#Include Lib\Resources.ahk
#Include Lib\About.ahk

; --- Initialization Sequence ---
try {
    ; Load configuration first
    LoadConfig()

    ; Check for necessary resources
    CheckResources()

    ; Build and show the main GUI
    CreateMainGui()

    ; Apply hotkeys
    ApplyHotkeys()

} catch as e {
    MsgBox("初始化失败: " e.Message "`n在 " e.What "`n行号: " e.Line, "错误", 0x10)
    ExitApp()
}

; --- AutoClick Hotkey Implementation (Must remain in the main script or a file included *after* global config is set) ---
; This specific hotkey uses the ~ prefix and global variables directly,
; it's often simplest to keep it here or ensure it's in a file that's included
; after all relevant global variables (like 'config' and 'isAutoClickEnabled') are defined.
~$LButton:: {
    global isAutoClickEnabled, config

    if !isAutoClickEnabled
        return

    local currentDownDelay := config["delays"]["down"]
    local currentUpDelay := config["delays"]["up"]

    while GetKeyState("LButton", "P") {
        Click("Down")
        Sleep(currentDownDelay)
        Click("Up")
        Sleep(currentUpDelay)
    }
}