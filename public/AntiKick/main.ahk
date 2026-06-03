; 防踢插件 - main.ahk
; 防止AFK踢出，定时发送随机按键保持活动状态
#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn All, Off

#Include ..\..\Lib\ConfigHelper.ahk

class AntiKickPlugin extends PluginLifecycle {
    interval := 60000
    pluginHotkey := ""
    randomKeyTimer := 0

    myGui := 0
    statusText := 0
    lastKeyText := 0
    intervalEdit := 0
    hotkeyCtrl := 0

    Init() {
        this.interval := GetPluginConfig("Settings", "Interval", 60) * 1000
        this.hotkeyName := "antiKick"
        this.hotkeyCallback := (*) => this.Toggle()
        this.pluginHotkey := RegisterPluginHotkey(this.hotkeyName, this.hotkeyCallback)

        ; --- 创建 GUI ---
        this.myGui := Gui("+ToolWindow", this.name " v" this.version)
        this.myGui.OnEvent("Close", (*) => (this.myGui.Hide(), this.showGui := false, (!this.isActive ? ExitApp() : 0)))
        this.myGui.BackColor := "F2F2F2"

        this.myGui.SetFont("s11 bold")
        this.myGui.Add("Text", "x15 y10 w280", "🛡️ " this.name)
        this.myGui.SetFont("s9 norm")

        ; 状态显示
        this.statusText := this.myGui.Add("Text", "x15 y35 w280 c888888", "状态: " (this.isActive ? "已启用 ✅" : "已关闭 ❌") " | 快捷键: " this.pluginHotkey)

        ; 最近按键显示
        this.lastKeyText := this.myGui.Add("Text", "x15 y55 w280 c888888", "最近发送: 无")

        this.myGui.Add("Text", "x15 y75 w280 0x10")  ; 分隔线

        ; 设置区域
        this.myGui.Add("Text", "x15 y90", "按键间隔(秒):")
        this.intervalEdit := this.myGui.Add("Edit", "x120 y88 w70 Number", this.interval // 1000)
        this.myGui.Add("UpDown", "Range10-600", this.interval // 1000)

        this.myGui.Add("Text", "x15 y120", "快捷键:")
        this.hotkeyCtrl := this.myGui.Add("Hotkey", "x120 y118 w70", this.pluginHotkey)

        this.myGui.Add("Text", "x15 y150 w280 0x10")  ; 分隔线

        ; 按钮区域
        this.myGui.Add("Button", "x15 y165 w80 h30", "启动").OnEvent("Click", (*) => this.StartAntiKickFromGui())
        this.myGui.Add("Button", "x105 y165 w80 h30", "停止").OnEvent("Click", (*) => this.Close())
        this.myGui.Add("Button", "x195 y165 w80 h30", "保存设置").OnEvent("Click", (*) => this.SaveSettings())

        if this.showGui {
            this.myGui.Show("w300 h210 Center")
        }

        ; 如果启动时要求激活
        if this.isActive {
            this.Run()
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
        this.RunAntiKick(this.interval)
    }

    RunAntiKick(intervalMs) {
        super.Run()
        this.interval := intervalMs
        
        ; 使用 Class 方法作为 SetTimer 目标
        this.randomKeyTimer := () => this.SendRandomKey()
        SetTimer(this.randomKeyTimer, this.interval)

        if this.statusText {
            this.statusText.Value := "状态: 运行中 ✅ (每" (this.interval // 1000) "秒) | 快捷键: " this.pluginHotkey
        }
        ToolTip("防踢模式已启动", 10, 50)
        SetTimer(() => ToolTip(), -2000)
    }

    Close() {
        super.Close()
        if this.randomKeyTimer {
            SetTimer(this.randomKeyTimer, 0)
            this.randomKeyTimer := 0
        }

        if this.statusText {
            this.statusText.Value := "状态: 已关闭 ❌ | 快捷键: " this.pluginHotkey
        }
        ToolTip("防踢模式已关闭", 10, 50)
        SetTimer(() => ToolTip(), -2000)
    }

    SendRandomKey() {
        if !this.isActive
            return

        randomKey := Random(1, 2) = 1 ? "%" : "+"
        SendEvent("{" randomKey " down}")
        Sleep(50)
        SendEvent("{" randomKey " up}")

        if this.lastKeyText {
            this.lastKeyText.Value := "最近发送: " randomKey " (" FormatTime(, "HH:mm:ss") ")"
        }
        ToolTip("防踢按键: " randomKey, 10, 50)
        SetTimer(() => ToolTip(), -1000)
    }

    StartAntiKickFromGui() {
        if this.isActive {
            MsgBox("防踢已在运行中！", "提示", 0x40)
            return
        }

        actualInterval := this.intervalEdit.Value * 1000
        if (actualInterval < 10000) {
            MsgBox("间隔必须不小于10秒！", "错误", 0x10)
            return
        }

        this.RunAntiKick(actualInterval)
    }

    SaveSettings() {
        newHotkey := this.hotkeyCtrl.Value
        if (newHotkey = "") {
            MsgBox("快捷键不能为空！", "错误", 0x10)
            return
        }

        this.interval := this.intervalEdit.Value * 1000
        SetPluginConfig("Settings", "Interval", this.interval // 1000)
        SavePluginHotkey("antiKick", newHotkey)

        ; 重新绑定快捷键
        this.pluginHotkey := RegisterPluginHotkey("antiKick", (*) => this.Toggle())
        if this.statusText {
            this.statusText.Value := "状态: " (this.isActive ? "已启用 ✅" : "已关闭 ❌") " | 快捷键: " this.pluginHotkey
        }
        MsgBox("设置已保存！", "提示", 0x40)
    }
}

global plugin := AntiKickPlugin()
plugin.Init()
