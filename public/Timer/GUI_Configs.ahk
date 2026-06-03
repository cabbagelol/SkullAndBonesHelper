; public\Timer\GUI_Configs.ahk
; 计时器设置GUI (原 Lib\GUI_Configs.ahk 迁移)

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
    StartTimer(duration)
    currentTimerGui.Destroy()
}
