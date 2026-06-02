; Lib\GUI_Configs.ahk

; --- 左键自动延迟设置GUI ---
ShowDelayConfig() {
    global config, MainGui, delayGui

    delayGui := Gui("+ToolWindow +Border +Owner" MainGui.Hwnd, "左键自动延迟设置")
    delayGui.OnEvent("Close", (*) => delayGui.Destroy())

    delayGui.Add("Text", "x10 y10", "间隙延迟(ms):")
    delayGui.Add("Text", "x10 y35 c535353", "左键按下和松开间隙延迟")

    downEdit := delayGui.Add("Edit", "x100 y8 w60 Number", config["delays"]["down"])
    delayGui.Add("UpDown", "Range1-1000", config["delays"]["down"])

    delayGui.Add("Text", "x10 y70", "组合延迟(ms):")
    delayGui.Add("Text", "x10 y90 c535353", "在完成一组单击事件后下次触发间隙时间")

    upEdit := delayGui.Add("Edit", "x100 y66 w60 Number", config["delays"]["up"])
    delayGui.Add("UpDown", "Range1-1000", config["delays"]["up"])

    delayGui.Add("Text", "x10 y120", "模式")
    delayGui.Add("Text", "x10 y140 c535353", "触发模式: (1)按住重复触发 (2)按下切换重复触发")

    modelEdit := delayGui.Add("Edit", "x100 y118 w50 Number", config["delays"]["autoClickModel"])
    delayGui.Add("UpDown", "Range1-1000", config["delays"]["autoClickModel"])

    delayGui.Add("Button", "x20 y170 w80 Default", "保存").OnEvent("Click", (*) => SaveDelaySettings_Handler(downEdit, upEdit, delayGui, modelEdit))
    delayGui.Add("Button", "x150 y170 w80", "取消").OnEvent("Click", (*) => delayGui.Destroy())

    delayGui.Show("Center h200")
}

SaveDelaySettings_Handler(downEdit, upEdit, currentDelayGui,modelEdit) {
    global config, lv

    config["delays"]["down"] := downEdit.Value
    config["delays"]["up"] := upEdit.Value
    config["delays"]["autoClickModel"] := modelEdit.Value
    SaveConfig() ; 调用 Lib\Config.ahk 中的函数
    currentDelayGui.Destroy()
    MsgBox("延迟设置已保存！", "提示", 0x40)
}

; --- 计时器设置GUI ---
ShowTimerConfig() {
    global timerRunning, MainGui, timerGui
    if timerRunning {
        MsgBox("计时器已经在运行中，请先停止它。", "提示", 0x40)
        return
    }

    timerGui := Gui("+ToolWindow +Border +Owner" MainGui.Hwnd, "计时器设置")
    timerGui.OnEvent("Close", (*) => timerGui.Destroy())

    timerGui.Add("Text", "x10 y10", "计时时长(秒):")
    durationEdit := timerGui.Add("Edit", "x100 y10 w60 Number", "60")
    timerGui.Add("UpDown", "Range10-3600", 60)

    timerGui.Add("Button", "x20 y50 w80 Default", "启动").OnEvent("Click", (*) => StartTimer_Handler(durationEdit, timerGui))

    timerGui.Add("Button", "x120 y50 w80", "取消").OnEvent("Click", (*) => timerGui.destroy())
    timerGui.Show("Center")
}

StartTimer_Handler(durationEdit, currentTimerGui) {
    global timerRunning
    if (!IsNumber(durationEdit.Value) || durationEdit.Value < 10) {
        MsgBox("计时时长必须为数字且不小于10秒！", "错误", 0x10)
        return
    }
    duration := durationEdit.Value * 1000
    StartTimer(duration) ; 调用 Lib\Functions.ahk 中的函数
    currentTimerGui.Destroy()
}

; --- 防踢设置GUI ---
ShowAntiKickConfig() {
    global isRandomKeyEnabled, MainGui, antiKickGui
    if isRandomKeyEnabled {
        MsgBox("防踢功能已经在运行中，请先停止它。", "提示", 0x40)
        return
    }

    antiKickGui := Gui("+ToolWindow +Border +Owner" MainGui.Hwnd, "防踢设置")
    antiKickGui.OnEvent("Close", (*) => antiKickGui.Destroy())

    antiKickGui.Add("Text", "x10 y10", "按键间隔(秒):")
    intervalEdit := antiKickGui.Add("Edit", "x100 y10 w60 Number", "60")
    antiKickGui.Add("UpDown", "Range10-600", 60)

    antiKickGui.Add("Button", "x20 y50 w80 Default", "启用").OnEvent("Click", (*) => StartAntiKick_Handler(intervalEdit, antiKickGui))

    antiKickGui.Add("Button", "x120 y50 w80", "取消").OnEvent("Click", (*) => antiKickGui.destroy())
    antiKickGui.Show("Center")
}

StartAntiKick_Handler(intervalEdit, currentAntiKickGui) {
    global isRandomKeyEnabled
    if (!IsNumber(intervalEdit.Value) || intervalEdit.Value < 10) {
        MsgBox("按键间隔必须为数字且不小于10秒！", "错误", 0x10)
        return
    }
    interval := intervalEdit.Value * 1000
    StartAntiKick(interval) ; 调用 Lib\Functions.ahk 中的函数
    currentAntiKickGui.Destroy()
}

; --- 快捷键设置GUI ---
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

    ; 使用 AHK 自带 of Hotkey 控件
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

; --- 间歇防御设置GUI ---
ShowDefenseConfig() {
    global config, MainGui, defenseGui

    defenseGui := Gui("+ToolWindow +Border +Owner" MainGui.Hwnd, "间歇防御设置")
    defenseGui.OnEvent("Close", (*) => defenseGui.Destroy())

    local transparentColor := "F2F2F2"
    defenseGui.BackColor := transparentColor

    defenseGui.Add("Text", "x20 y20", "空格按下防御时间(秒):")
    defenseGui.Add("Text", "x20 y45 c535353", "举盾时间，按照具体体力来决定")

    pauseEdit := defenseGui.Add("Edit", "x200 y18 w60 Number", config["delays"]["defensePause"])
    defenseGui.Add("UpDown", "Range1-60", config["delays"]["defensePause"])

    defenseGui.Add("Button", "x40 y90 w80 Default", "保存").OnEvent("Click", (*) => SaveDefenseSettings_Handler(pauseEdit, defenseGui))
    defenseGui.Add("Button", "x160 y90 w80", "取消").OnEvent("Click", (*) => defenseGui.Destroy())

    defenseGui.Show("Center h130 w280")
}

SaveDefenseSettings_Handler(pauseEdit, currentDefenseGui) {
    global config, lv, isDefenseEnabled

    if (!IsNumber(pauseEdit.Value) || pauseEdit.Value <= 0) {
        MsgBox("停顿时长必须为正数字！", "错误", 0x10)
        return
    }

    config["delays"]["defensePause"] := pauseEdit.Value
    SaveConfig()
    currentDefenseGui.Destroy()

    ; 动态更新 ListView 中的行状态显示（若功能已启用，则同步显示最新停顿秒数）
    if (row := GetRowIndexByFunctionName("间歇防御")) {
        lv.Modify(row,,, isDefenseEnabled ? "停顿" config["delays"]["defensePause"] "s" : "关闭")
    }

    MsgBox("停顿时间已保存并应用！", "提示", 0x40)
}