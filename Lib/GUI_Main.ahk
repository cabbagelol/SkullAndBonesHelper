; Lib\GUI_Main.ahk

; 创建主GUI
CreateMainGui() {
    global config, MainGui, lv

    ; 设置托盘图标
    if FileExist("UI_Main_Icon.ico") {
        try TraySetIcon("UI_Main_Icon.ico")
    }

    ; 创建主菜单
    MainMenu := MenuBar()
    FileMenu := Menu()
    FileMenu.Add("&快捷键设置", (*) => ShowHotkeyConfig())
    FileMenu.Add("&退出", (*) => ExitApp())
    FunMenu := Menu()
    FunMenu.Add("&左键自动 " config["hotkeys"]["autoClick"], (*) => ToggleAutoClick())
    FunMenu.Add("&计时器 " config["hotkeys"]["timer"], (*) => ToggleTimer())
    FunMenu.Add("&防踢状态 " config["hotkeys"]["antiKick"], (*) => ToggleAntiKick())
    FunMenu.Add("&自动打开箱子 " config["hotkeys"]["autoOpenBox"], (*) => ToggleAutoOpenBox())

    HelpMenu := Menu()
    HelpMenu.Add("&关于", (*) => ShowAbout())

    MainMenu.Add("&程序", FileMenu)
    MainMenu.Add("&功能", FunMenu)
    MainMenu.Add("&帮助", HelpMenu)

    ; 创建主窗口
    MainGui := Gui()
    MainGui.MenuBar := MainMenu
    MainGui.Title := IniRead(configFile, "App", "version", config["app"]["version"])
    local transparentColor := "F2F2F2"
    MainGui.BackColor := transparentColor
    MainGui.OnEvent("Close", (*) => ExitApp())

    ; 左侧背景图
    if FileExist("UI_MainMenu_Background.png") {
        try {
            MainGui.Add("Picture", "x0 y0 w120 h280", "UI_MainMenu_Background.png")
        } catch {
            MainGui.Add("Text", "x0 y0 w120 h300 BackgroundSilver", "背景图")
        }
    } else {
        MainGui.Add("Text", "x0 y0 w120 h300 BackgroundSilver", "背景图")
    }

    ; 功能列表
    MainGui.Add("Text", "x130 y10 w200 c555555", "功能列表 (双击配置)")

    ; 创建ListView
    lv := MainGui.Add("ListView", "x130 y30 w270 h240 -Multi AltSubmit Grid", ["功能", "快捷键", "状态"])
    lv.ModifyCol(1, 136)
    lv.ModifyCol(2, 70)
    lv.ModifyCol(3, 60)

    ; 使用初始数据填充ListView
    UpdateFunctionList()

    ; 双击事件
    lv.OnEvent("DoubleClick", (*) => ConfigureFunction(lv))

    MainGui.Show("w410 h280")
}

; 更新ListView中功能列表的显示
UpdateFunctionList() {
    global config, isAutoClickEnabled ,isAutoOpenBoxEnabled , timerRunning, isRandomKeyEnabled, lv

    lv.Delete() ; AutoHotkey v2 中清除所有项目的正确方法

    ; 添加功能条目
    lv.Add("Check", "左键自动", config["hotkeys"]["autoClick"], isAutoClickEnabled ? "开启" : "关闭")
    if isAutoClickEnabled
        lv.Modify(1, "Check")

    lv.Add("Check", "计时器", config["hotkeys"]["timer"], timerRunning ? "运行中" : "关闭")
    if timerRunning
        lv.Modify(2, "Check")

    lv.Add("Check", "防踢状态", config["hotkeys"]["antiKick"], isRandomKeyEnabled ? "开启" : "关闭")
    if isRandomKeyEnabled
        lv.Modify(3, "Check")

    lv.Add("Check", "自动打开箱子", config["hotkeys"]["autoOpenBox"], isAutoOpenBoxEnabled ? "开启" : "关闭")
    if isAutoOpenBoxEnabled
        lv.Modify(4, "Check")
}

; 更新ListView中的快捷键显示
UpdateListViewHotkeys() {
    global lv, config
    lv.Modify(1,,, config["hotkeys"]["autoClick"])
    lv.Modify(2,,, config["hotkeys"]["timer"])
    lv.Modify(3,,, config["hotkeys"]["antiKick"])
    lv.Modify(4,,, config["hotkeys"]["autoOpenBox"])
}

; 配置功能 (决定显示哪个配置GUI)
ConfigureFunction(lv_ctrl) {
    row := lv_ctrl.GetNext() ; 获取选定的行
    if (!row)
        return

    functionName := lv_ctrl.GetText(row, 1) ; 获取功能名称（来自第一列）

    ; 根据功能显示不同配置
    switch functionName {
        case "左键自动":
            ShowDelayConfig()
        case "计时器":
            ShowTimerConfig()
        case "防踢状态":
            ShowAntiKickConfig()
        case "自动打开箱子":
    }
}