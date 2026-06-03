; public\AntiKick\GUI_Configs.ahk
; 防踢设置GUI (原 Lib\GUI_Configs.ahk 迁移)

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
    StartAntiKick(interval)
    currentAntiKickGui.Destroy()
}
