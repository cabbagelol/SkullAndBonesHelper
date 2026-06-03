; 计时器插件 - main.ahk
; 倒计时功能，支持自定义时长，计时结束时播放提示音
#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn All, Off

#Include ..\..\Lib\ConfigHelper.ahk

class TimerPlugin extends PluginLifecycle {
    duration := 60
    pluginHotkey := ""
    timerEndTime := 0

    myGui := 0
    statusText := 0
    countdownText := 0
    durationEdit := 0
    hotkeyCtrl := 0

    Init() {
        this.duration := GetPluginConfig("Settings", "Duration", 60)
        this.hotkeyName := "timer"
        this.hotkeyCallback := (*) => this.Toggle()
        this.pluginHotkey := RegisterPluginHotkey(this.hotkeyName, this.hotkeyCallback)

        ; --- 创建 GUI ---
        this.myGui := Gui("+ToolWindow", this.name " v" this.version)
        this.myGui.OnEvent("Close", (*) => (this.myGui.Hide(), this.showGui := false, (!this.isActive ? ExitApp() : 0)))
        this.myGui.BackColor := "F2F2F2"

        this.myGui.SetFont("s11 bold")
        this.myGui.Add("Text", "x15 y10 w280", "⏱️ " this.name)
        this.myGui.SetFont("s9 norm")

        ; 状态显示
        this.statusText := this.myGui.Add("Text", "x15 y35 w280 c888888", "状态: " (this.isActive ? "运行中 ✅" : "已停止 ❌") " | 快捷键: " this
        .pluginHotkey)

        this.myGui.Add("Text", "x15 y55 w280 0x10")  ; 分隔线

        ; 倒计时显示区域
        this.myGui.SetFont("s24 bold")
        this.countdownText := this.myGui.Add("Text", "x15 y70 w280 h50 Center", "00:00")
        this.myGui.SetFont("s9 norm")

        this.myGui.Add("Text", "x15 y125 w280 0x10")  ; 分隔线

        ; 设置区域
        this.myGui.Add("Text", "x15 y140", "计时时长(秒):")
        this.durationEdit := this.myGui.Add("Edit", "x120 y138 w70 Number", this.duration)
        this.myGui.Add("UpDown", "Range10-3600", this.duration)

        this.myGui.Add("Text", "x15 y170", "快捷键:")
        this.hotkeyCtrl := this.myGui.Add("Hotkey", "x120 y168 w70", this.pluginHotkey)

        this.myGui.Add("Text", "x15 y200 w280 0x10")  ; 分隔线

        ; 按钮区域
        this.myGui.Add("Button", "x15 y215 w80 h30", "启动").OnEvent("Click", (*) => this.StartTimerFromGui())
        this.myGui.Add("Button", "x105 y215 w80 h30", "停止").OnEvent("Click", (*) => this.Close())
        this.myGui.Add("Button", "x195 y215 w80 h30", "保存设置").OnEvent("Click", (*) => this.SaveSettings())

        if this.showGui {
            this.myGui.Show("w300 h260 Center")
        }
    }

    Toggle() {
        if this.isActive {
            this.Close()
        } else {
            this.Run()
        }
    }

    Run() {
        this.RunTimer(this.duration * 1000)
    }

    RunTimer(durationMs) {
        super.Run()

        this.timerEndTime := A_TickCount + durationMs
        SetTimer(() => this.UpdateTimer(), 1000)

        if this.statusText {
            this.statusText.Value := "状态: 运行中 ✅ | 快捷键: " this.pluginHotkey
        }
        ToolTip("计时器已启动", 10, 30)
        SetTimer(() => ToolTip(), -2000)
    }

    Close() {
        super.Close()
        SetTimer(() => this.UpdateTimer(), 0)

        if this.countdownText {
            this.countdownText.Value := "00:00"
        }
        if this.statusText {
            this.statusText.Value := "状态: 已停止 ❌ | 快捷键: " this.pluginHotkey
        }
        ToolTip()
    }

    UpdateTimer() {
        if (!this.isActive) {
            SetTimer(() => this.UpdateTimer(), 0)
            return
        }

        remaining := this.timerEndTime - A_TickCount
        if (remaining <= 0) {
            this.Close()
            SoundPlay("*64")

            if (this.countdownText) {
                this.countdownText.Value := "00:00"
            }
            if (this.statusText) {
                this.statusText.Value := "状态: 已完成 ⏰ | 快捷键: " this.pluginHotkey
            }
            ToolTip("计时器结束！", 10, 30)
            SetTimer(() => ToolTip(), -5000)
            return
        }

        totalSeconds := Floor(remaining / 1000)
        minutes := Floor(totalSeconds / 60)
        seconds := Mod(totalSeconds, 60)
        if (this.countdownText) {
            this.countdownText.Value := Format("{:02d}:{:02d}", minutes, seconds)
        }
        ToolTip("倒计时: " totalSeconds "秒", 10, 30)
    }

    StartTimerFromGui() {
        if this.isActive {
            MsgBox("计时器已在运行中，请先停止。", "提示", 0x40)
            return
        }

        if (!IsNumber(this.durationEdit.Value) || this.durationEdit.Value < 10) {
            MsgBox("计时时长必须为数字且不小于10秒！", "错误", 0x10)
            return
        }

        this.RunTimer(this.durationEdit.Value * 1000)
    }

    SaveSettings() {
        newHotkey := this.hotkeyCtrl.Value
        if (newHotkey = "") {
            MsgBox("快捷键不能为空！", "错误", 0x10)
            return
        }

        this.duration := this.durationEdit.Value
        SetPluginConfig("Settings", "Duration", this.duration)
        SavePluginHotkey("timer", newHotkey)

        ; 重新绑定快捷键
        this.pluginHotkey := RegisterPluginHotkey("timer", (*) => this.Toggle())
        if this.statusText {
            this.statusText.Value := "状态: " (this.isActive ? "运行中 ✅" : "已停止 ❌") " | 快捷键: " this.pluginHotkey
        }
        MsgBox("设置已保存！", "提示", 0x40)
    }
}

global plugin := TimerPlugin()
plugin.Init()