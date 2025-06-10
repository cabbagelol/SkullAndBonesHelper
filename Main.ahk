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
global lv ; 使 lv 成为全局变量，以便其他函数可以访问 GUI 控件
global delayGui := 0 ; 全局初始化 GUI 句柄以管理其状态
global timerGui := 0
global antiKickGui := 0
global configGui := 0
global AboutGui := 0 ; 也全局化 AboutGui 以管理其状态

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
    LoadConfig()

    CheckResources()

    CreateMainGui()

    ApplyHotkeys()

} catch as e {
    MsgBox("初始化失败: " e.Message "`n在 " e.What "`n行号: " e.Line, "错误", 0x10)
    ExitApp()
}

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