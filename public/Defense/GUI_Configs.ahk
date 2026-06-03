; public\Defense\GUI_Configs.ahk
; 间歇防御设置GUI (原 Lib\GUI_Configs.ahk 迁移)

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
        lv.Modify(row, , , , , isDefenseEnabled ? "停顿" config["delays"]["defensePause"] "s" : "关闭")
    }

    MsgBox("停顿时间已保存并应用！", "提示", 0x40)
}
