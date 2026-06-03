; public\AutoClick\GUI_Configs.ahk
; 左键自动延迟设置GUI (原 Lib\GUI_Configs.ahk 迁移)

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

SaveDelaySettings_Handler(downEdit, upEdit, currentDelayGui, modelEdit) {
    global config, lv

    config["delays"]["down"] := downEdit.Value
    config["delays"]["up"] := upEdit.Value
    config["delays"]["autoClickModel"] := modelEdit.Value
    SaveConfig()
    currentDelayGui.Destroy()
    MsgBox("延迟设置已保存！", "提示", 0x40)
}
