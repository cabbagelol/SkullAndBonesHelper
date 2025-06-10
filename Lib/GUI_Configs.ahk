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

    delayGui.Add("Button", "x20 y120 w80 Default", "保存").OnEvent("Click", (*) => SaveDelaySettings_Handler(downEdit, upEdit, delayGui))

    delayGui.Add("Button", "x150 y120 w80", "取消").OnEvent("Click", (*) => delayGui.Destroy())
    delayGui.Show("Center h160")
}

SaveDelaySettings_Handler(downEdit, upEdit, currentDelayGui) {
    global config, lv

    config["delays"]["down"] := downEdit.Value
    config["delays"]["up"] := upEdit.Value
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
ShowHotkeyConfig(*) {
    global MainGui, config, configGui

    configGui := Gui("+ToolWindow +Border +Owner" MainGui.Hwnd, "快捷键设置")
    configGui.OnEvent("Close", (*) => configGui.Destroy())

    configGui.Add("Text", "x20 y20 w100", "左键自动:")
    autoClickHotkey := configGui.Add("Hotkey", "x120 y20 w100", config["hotkeys"]["autoClick"])

    configGui.Add("Text", "x20 y60 w100", "计时功能:")
    timerHotkey := configGui.Add("Hotkey", "x120 y60 w100", config["hotkeys"]["timer"])

    configGui.Add("Text", "x20 y100 w100", "防踢功能:")
    antiKickHotkey := configGui.Add("Hotkey", "x120 y100 w100", config["hotkeys"]["antiKick"])

    configGui.Add("Button", "x50 y150 w80 Default", "保存").OnEvent("Click", (*) => SaveHotkeys_Handler(autoClickHotkey, timerHotkey, antiKickHotkey, configGui))

    configGui.Add("Button", "x150 y150 w80", "取消").OnEvent("Click", (*) => configGui.Destroy())
    configGui.Show("Center")
}

SaveHotkeys_Handler(autoClickHotkey, timerHotkey, antiKickHotkey, currentConfigGui) {
     global config

     local autoClickVal := autoClickHotkey.Value
     local timerVal := timerHotkey.Value
     local antiKickVal := antiKickHotkey.Value

     local newHotkeys := Map(
         "autoClick", autoClickVal,
         "timer", timerVal,
         "antiKick", antiKickVal
     )

     if newHotkeys["autoClick"] = "" || newHotkeys["timer"] = "" || newHotkeys["antiKick"] = "" {
         MsgBox("快捷键不能为空！", "错误", 0x10)
         return
     }

     if (newHotkeys["autoClick"] = newHotkeys["timer"] ||
         newHotkeys["autoClick"] = newHotkeys["antiKick"] ||
         newHotkeys["timer"] = newHotkeys["antiKick"]) {
         MsgBox("快捷键不能重复！", "错误", 0x10)
         return
     }

     config["hotkeys"] := newHotkeys.Clone()
     SaveConfig()
     ApplyHotkeys()
     UpdateListViewHotkeys()
     currentConfigGui.Destroy()
}