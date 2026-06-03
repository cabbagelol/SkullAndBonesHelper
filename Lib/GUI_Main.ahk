; Lib\GUI_Main.ahk

global lastDoubleClickTime := 0

; 创建主GUI
CreateMainGui() {
    global config, MainGui, lv, pluginList

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
    for folderName, info in pluginList {
        if (!info.Has("visible") || info["visible"]) {
            hotkeyStr := ""
            if info.Has("hotkeys") && info["hotkeys"].Length > 0 {
                hkName := info["hotkeys"][1]["name"]
                defaultKey := info["hotkeys"][1]["default"]
                configKey := GetHotkeyConfigKey(folderName, hkName)
                hotkeyStr := GetUserConfig(configKey["section"], configKey["key"], defaultKey)
            }
            menuText := "&" info["name"] (hotkeyStr != "" ? " " hotkeyStr : "")
            targetFolder := folderName
            FunMenu.Add(menuText, (*) => (IsPluginRunning(targetFolder) ? ShowPluginGui(targetFolder) : StartPlugin(targetFolder, "/show")))
        }
    }

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
    global lastDoubleClickTime, pluginList

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
    for name, info in pluginList {
        if (info["name"] = functionName) {
            folderName := name
            break
        }
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
    global lv, pluginList
    if (!IsSet(lv) || !lv)
        return

    lv.Delete()

    for folderName, info in pluginList {
        if (info.Has("visible") && !info["visible"]) {
            continue
        }

        ; 获取快捷键
        hotkeyStr := ""
        if info.Has("hotkeys") && info["hotkeys"].Length > 0 {
            hkName := info["hotkeys"][1]["name"]
            defaultKey := info["hotkeys"][1]["default"]
            configKey := GetHotkeyConfigKey(folderName, hkName)
            hotkeyStr := GetUserConfig(configKey["section"], configKey["key"], defaultKey)
        }

        active := IsPluginActive(folderName)
        lv.Add(active ? "Check" : "", info["name"], info["version"], info["author"], hotkeyStr, active ? "运行中" : "已关闭")
    }
}

; 更新ListView中的快捷键显示
UpdateListViewHotkeys() {
    global lv, pluginList
    if (!IsSet(lv) || !lv)
        return
    for folderName, info in pluginList {
        if (info.Has("visible") && !info["visible"]) {
            continue
        }
        if (row := GetRowIndexByFunctionName(info["name"])) {
            hotkeyStr := ""
            if info.Has("hotkeys") && info["hotkeys"].Length > 0 {
                hkName := info["hotkeys"][1]["name"]
                defaultKey := info["hotkeys"][1]["default"]
                configKey := GetHotkeyConfigKey(folderName, hkName)
                hotkeyStr := GetUserConfig(configKey["section"], configKey["key"], defaultKey)
            }
            lv.Modify(row, , , , , hotkeyStr)
        }
    }
}

; 配置功能 (决定显示哪个配置GUI)
ConfigureFunction(lv_ctrl) {
    global lastDoubleClickTime, pluginList
    lastDoubleClickTime := A_TickCount
    row := lv_ctrl.GetNext() ; 获取选定的行
    if (!row)
        return

    functionName := lv_ctrl.GetText(row, 1) ; 获取功能名称

    for folderName, info in pluginList {
        if (info["name"] = functionName) {
            if IsPluginRunning(folderName) {
                ShowPluginGui(folderName)
            } else {
                StartPlugin(folderName, "/show")
            }
            break
        }
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