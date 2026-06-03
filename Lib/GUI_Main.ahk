; Lib\GUI_Main.ahk

global lastDoubleClickTime := 0

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
    FunMenu.Add("&粘贴聊天 " config["hotkeys"]["pasteChat"], (*) => TogglePasteChat())
    FunMenu.Add("&间歇防御 " config["hotkeys"]["defense"], (*) => ToggleDefense())

    ; 插件菜单
    PluginMenu := Menu()
    PluginMenu.Add("&导入插件", (*) => ImportPlugin())
    PluginMenu.Add("&插件管理", (*) => ShowPluginManager())

    HelpMenu := Menu()
    HelpMenu.Add("&关于", (*) => ShowAbout())

    MainMenu.Add("&程序", FileMenu)
    MainMenu.Add("&功能", FunMenu)
    MainMenu.Add("&插件", PluginMenu)
    MainMenu.Add("&帮助", HelpMenu)

    ; 创建主窗口
    MainGui := Gui()
    MainGui.MenuBar := MainMenu
    MainGui.Title := "碧海黑帆小助手 v" GetAppConfig("App", "Version", config["app"]["version"])
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
    lv := MainGui.Add("ListView", "x130 y30 w390 h240 -Multi AltSubmit Grid", ["功能", "版本", "作者", "快捷键", "状态"])
    lv.ModifyCol(1, 120)
    lv.ModifyCol(2, 60)
    lv.ModifyCol(3, 80)
    lv.ModifyCol(4, 70)
    lv.ModifyCol(5, 60)

    ; 使用初始数据填充ListView
    UpdateFunctionList()

    ; 双击事件
    lv.OnEvent("DoubleClick", (*) => ConfigureFunction(lv))

    ; 复选框事件
    lv.OnEvent("ItemCheck", ListView_ItemCheck)

    MainGui.Show("w530 h280")
}

; 点击复选框时切换对应插件的运行状态
ListView_ItemCheck(lv_ctrl, itemIndex, checked) {
    global lastDoubleClickTime

    ; 如果是双击引起的复选框改变，我们直接还原并不执行任何激活/停用逻辑
    if (A_TickCount - lastDoubleClickTime < 300) {
        static isReverting := false
        if (isReverting) {
            return
        }
        isReverting := true
        lv_ctrl.Modify(itemIndex, checked ? "-Check" : "Check")
        isReverting := false
        return
    }

    functionName := lv_ctrl.GetText(itemIndex, 1)
    
    folderName := ""
    switch functionName {
        case "左键自动": folderName := "AutoClick"
        case "计时器": folderName := "Timer"
        case "防踢状态": folderName := "AntiKick"
        case "自动打开箱子": folderName := "AutoOpenBox"
        case "粘贴聊天": folderName := "PasteChat"
        case "间歇防御": folderName := "Defense"
    }
    
    if (folderName != "") {
        isAlreadyActive := IsPluginActive(folderName)
        if (checked != isAlreadyActive) {
            if (checked) {
                StartPlugin(folderName, "/active")
            } else {
                StopPlugin(folderName)
            }
        }
    }
}

; 更新ListView中功能列表的显示
UpdateFunctionList() {
    global config, lv

    lv.Delete() ; AutoHotkey v2 中清除所有项目的正确方法

    ; 添加功能条目，根据插件激活状态显示 Check 和状态文本
    local autoClickActive := IsPluginActive("AutoClick")
    lv.Add(autoClickActive ? "Check" : "", "左键自动", "1.0.0", "cabbagelol", config["hotkeys"]["autoClick"], autoClickActive ? "运行中" : "已关闭")

    local timerActive := IsPluginActive("Timer")
    lv.Add(timerActive ? "Check" : "", "计时器", "1.0.0", "cabbagelol", config["hotkeys"]["timer"], timerActive ? "运行中" : "已关闭")

    local antiKickActive := IsPluginActive("AntiKick")
    lv.Add(antiKickActive ? "Check" : "", "防踢状态", "1.0.0", "cabbagelol", config["hotkeys"]["antiKick"], antiKickActive ? "运行中" : "已关闭")

    local autoOpenBoxActive := IsPluginActive("AutoOpenBox")
    lv.Add(autoOpenBoxActive ? "Check" : "", "自动打开箱子", "1.0.0", "cabbagelol", config["hotkeys"]["autoOpenBox"], autoOpenBoxActive ? "运行中" : "已关闭")

    local pasteChatActive := IsPluginActive("PasteChat")
    lv.Add(pasteChatActive ? "Check" : "", "粘贴聊天", "1.0.0", "cabbagelol", config["hotkeys"]["pasteChat"], pasteChatActive ? "运行中" : "已关闭")

    local defenseActive := IsPluginActive("Defense")
    lv.Add(defenseActive ? "Check" : "", "间歇防御", "1.0.0", "cabbagelol", config["hotkeys"]["defense"], defenseActive ? "运行中" : "已关闭")
}

; 更新ListView中的快捷键显示
UpdateListViewHotkeys() {
    global lv, config
    if (row := GetRowIndexByFunctionName("左键自动"))
        lv.Modify(row, , , , , config["hotkeys"]["autoClick"])
    if (row := GetRowIndexByFunctionName("计时器"))
        lv.Modify(row, , , , , config["hotkeys"]["timer"])
    if (row := GetRowIndexByFunctionName("防踢状态"))
        lv.Modify(row, , , , , config["hotkeys"]["antiKick"])
    if (row := GetRowIndexByFunctionName("自动打开箱子"))
        lv.Modify(row, , , , , config["hotkeys"]["autoOpenBox"])
    if (row := GetRowIndexByFunctionName("粘贴聊天"))
        lv.Modify(row, , , , , config["hotkeys"]["pasteChat"])
    if (row := GetRowIndexByFunctionName("间歇防御"))
        lv.Modify(row, , , , , config["hotkeys"]["defense"])
}

; 配置功能 (决定显示哪个配置GUI)
ConfigureFunction(lv_ctrl) {
    global lastDoubleClickTime
    lastDoubleClickTime := A_TickCount
    row := lv_ctrl.GetNext() ; 获取选定的行
    if (!row)
        return

    functionName := lv_ctrl.GetText(row, 1) ; 获取功能名称

    switch functionName {
        case "左键自动":
            ToggleAutoClick()
        case "计时器":
            ToggleTimer()
        case "防踢状态":
            ToggleAntiKick()
        case "自动打开箱子":
            ToggleAutoOpenBox()
        case "粘贴聊天":
            TogglePasteChat()
        case "间歇防御":
            ToggleDefense()
    }
}

; 根据功能名称获取 ListView 中的行索引
GetRowIndexByFunctionName(funcName) {
    global lv
    if (!IsSet(lv) || !lv)
        return 0
    Loop lv.GetCount() {
        if (lv.GetText(A_Index, 1) = funcName) {
            return A_Index
        }
    }
    return 0
}