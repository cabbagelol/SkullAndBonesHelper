; Lib\GUI_Configs.ahk
; 主程序快捷键设置 GUI

global tempHotkeys := Map()

ShowHotkeyConfig(*) {
    global MainGui, config, configGui, lvConfig, tempHotkeys

    ; 临时存储当前快捷键的修改
    tempHotkeys := Map(
        "左键自动", config["hotkeys"]["autoClick"],
        "计时器", config["hotkeys"]["timer"],
        "防踢状态", config["hotkeys"]["antiKick"],
        "自动打开箱子", config["hotkeys"]["autoOpenBox"],
        "粘贴聊天", config["hotkeys"]["pasteChat"],
        "间歇防御", config["hotkeys"]["defense"]
    )

    configGui := Gui("+ToolWindow +Border +Owner" MainGui.Hwnd, "快捷键设置")
    configGui.OnEvent("Close", (*) => configGui.Destroy())

    local transparentColor := "F2F2F2"
    configGui.BackColor := transparentColor

    ; 左侧背景图
    if FileExist("UI_MainMenu_Background.png") {
        try {
            configGui.Add("Picture", "x0 y0 w120 h280", "UI_MainMenu_Background.png")
        } catch {
            configGui.Add("Text", "x0 y0 w120 h280 BackgroundSilver", "背景图")
        }
    } else {
        configGui.Add("Text", "x0 y0 w120 h280 BackgroundSilver", "背景图")
    }

    ; 功能列表提示文本
    configGui.Add("Text", "x130 y10 w200 c555555", "快捷键列表 (双击修改)")

    ; 创建ListView
    lvConfig := configGui.Add("ListView", "x130 y30 w270 h200 -Multi AltSubmit Grid", ["功能", "快捷键"])
    lvConfig.ModifyCol(1, 140)
    lvConfig.ModifyCol(2, 106)

    ; 使用固定顺序填充ListView，使其与主界面顺序一致
    orderedFunctions := ["左键自动", "计时器", "防踢状态", "自动打开箱子", "粘贴聊天", "间歇防御"]
    for name in orderedFunctions {
        lvConfig.Add(, name, tempHotkeys[name])
    }

    ; 绑定双击事件进行修改
    lvConfig.OnEvent("DoubleClick", (*) => ModifyHotkeyDlg(lvConfig))

    ; 保存和取消按钮
    configGui.Add("Button", "x160 y240 w80 Default", "保存").OnEvent("Click", (*) => SaveHotkeys_Handler(configGui))
    configGui.Add("Button", "x290 y240 w80", "取消").OnEvent("Click", (*) => configGui.Destroy())

    configGui.Show("w410 h280")
}

; 弹出单个快捷键修改对话框
ModifyHotkeyDlg(lv_ctrl) {
    global tempHotkeys, configGui
    row := lv_ctrl.GetNext() ; 获取选定的行
    if (!row)
        return

    funcName := lv_ctrl.GetText(row, 1) ; 获取功能名称
    currentKey := lv_ctrl.GetText(row, 2) ; 获取当前快捷键

    ; 创建修改单个快捷键的对话框
    dlg := Gui("+ToolWindow +Border +Owner" configGui.Hwnd, "修改快捷键")
    dlg.BackColor := "F2F2F2"
    dlg.Add("Text", "x20 y20 w200", "请为【" funcName "】按下新快捷键:")

    ; 使用 AHK 自带的 Hotkey 控件
    hkCtrl := dlg.Add("Hotkey", "x20 y50 w160", currentKey)

    dlg.Add("Button", "x20 y95 w70 Default", "确定").OnEvent("Click", (*) => ConfirmHotkey(dlg, lv_ctrl, row, funcName, hkCtrl.Value))
    dlg.Add("Button", "x110 y95 w70", "取消").OnEvent("Click", (*) => dlg.Destroy())
    dlg.Show("w200 h140 Center")
}

; 确认单个快捷键的修改
ConfirmHotkey(dlg, lv_ctrl, row, funcName, newVal) {
    global tempHotkeys
    if (newVal = "") {
        MsgBox("快捷键不能为空！", "错误", 0x10)
        return
    }

    ; 检查是否与其他功能的快捷键冲突
    for name, key in tempHotkeys {
        if (name != funcName && key == newVal) {
            MsgBox("该快捷键已被【" name "】使用，请设置其他快捷键！", "错误", 0x10)
            return
        }
    }

    ; 更新临时存储并刷新ListView中的显示
    tempHotkeys[funcName] := newVal
    lv_ctrl.Modify(row,, funcName, newVal)
    dlg.Destroy()
}

; 保存全部快捷键设置
SaveHotkeys_Handler(currentConfigGui) {
    global config, tempHotkeys

    local autoClickVal := tempHotkeys["左键自动"]
    local timerVal := tempHotkeys["计时器"]
    local antiKickVal := tempHotkeys["防踢状态"]
    local autoOpenBoxVal := tempHotkeys["自动打开箱子"]
    local pasteChatVal := tempHotkeys["粘贴聊天"]
    local defenseVal := tempHotkeys["间歇防御"]

    local newHotkeys := Map(
        "autoClick", autoClickVal,
        "timer", timerVal,
        "antiKick", antiKickVal,
        "autoOpenBox", autoOpenBoxVal,
        "pasteChat", pasteChatVal,
        "defense", defenseVal
    )

    ; 再次验证不能为空（防呆设计）
    for key, val in newHotkeys {
        if val = "" {
            MsgBox("快捷键不能为空！", "错误", 0x10)
            return
        }
    }

    ; 验证不能重复
    local seenVals := Map()
    for key, val in newHotkeys {
        if seenVals.Has(val) {
            MsgBox("快捷键不能重复！", "错误", 0x10)
            return
        }
        seenVals[val] := true
    }

    config["hotkeys"] := newHotkeys.Clone()
    SaveConfig()
    ApplyHotkeys()
    UpdateListViewHotkeys()
    currentConfigGui.Destroy()
    MsgBox("快捷键设置已成功保存！", "提示", 0x40)
}