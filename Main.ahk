; Main.ahk 1
#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn All, Off

; --- 全局变量和配置 ---

; 默认配置
global config := Map(
"hotkeys", Map(
"autoClick", "F1",
"autoOpenBox", "F4",
"timer", "F2",
"antiKick", "F3",
"pasteChat", "F5",
"defense", "F7"
),
"delays", Map(
"down", 50,
"up", 150,
"autoClickModel", 1,
"defensePause", 4
),
"app", Map(
"version", "0.0.0",
"isAutoClickAltStopEnabled", true,
"isInitialCheckVersion", true
),
)

; 功能状态变量
global isAutoClickEnabled := false
global isAutoClickLSEnabled := false
global isAutoOpenBoxEnabled := false
global isAutoClickToggleModeEnabled := false
global autoOpenBoxRunning := false
global timerRunning := false
global timerEndTime := 0
global isRandomKeyEnabled := false
global randomKeyTimer := 0
global isPasteChatEnabled := false
global isDefenseEnabled := false

; GUI句柄 (用于在不同函数中访问GUI控件)
global MainGui
global lv ; 使 lv 成为全局变量，以便其他函数可以访问 GUI 控件
global delayGui := 0 ; 全局初始化 GUI 句柄以管理其状态
global timerGui := 0
global antiKickGui := 0
global configGui := 0
global defenseGui := 0
global AboutGui := 0 ; 也全局化 AboutGui 以管理其状态

; --- 导入模块 ---
#Include Lib\ConfigHelper.ahk
#Include Lib\Config.ahk
#Include Lib\GUI_Main.ahk
#Include Lib\GUI_Configs.ahk
#Include Lib\Hotkeys.ahk
#Include Lib\Resources.ahk
#Include Lib\About.ahk
#Include Lib\PluginManager.ahk

; --- 初始化流程 ---
try {
    LoadConfig()

    CheckResources()

    ; 加载已安装的插件
    LoadPlugins()

    CreateMainGui()

    ApplyHotkeys()

    ; 启动插件进程状态轮询监控，保证主界面列表及快捷键接管状态实时同步
    SetTimer(MonitorPlugins, 1000)

    if config["app"]["isInitialCheckVersion"] {
        CheckForUpdate(false)
    }
} catch as e {
    MsgBox("初始化失败: " e.Message "`n在 " e.What "`n行号: " e.Line, "错误", 0x10)
    ExitApp()
}
