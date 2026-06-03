; 间歇防御插件 - main.ahk
; 自动按住空格进行防御，间歇释放恢复体力
#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn All, Off

#Include ..\..\Lib\ConfigHelper.ahk

class DefensePlugin extends PluginLifecycle {
    defensePause := 4
    pluginHotkey := ""
    defenseTimer := 0

    myGui := 0
    statusText := 0
    pauseEdit := 0
    hotkeyCtrl := 0

    Init() {
        this.defensePause := GetPluginConfig("Settings", "DefensePause", 4)
        this.hotkeyName := "defense"
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
        this.statusText := this.myGui.Add("Text", "x15 y35 w280 c888888", "状态: " (this.isActive ? "已启用 ✅" : "已关闭 ❌") " | 快捷键: " this
        .pluginHotkey)

        this.myGui.Add("Text", "x15 y55 w280 0x10")  ; 分隔线

        ; 设置区域
        this.myGui.Add("Text", "x15 y70", "空格按下防御时间(秒):")
        this.myGui.Add("Text", "x15 y90 w200 c535353", "举盾时间，按照具体体力来决定")
        this.pauseEdit := this.myGui.Add("Edit", "x220 y68 w60 Number", this.defensePause)
        this.myGui.Add("UpDown", "Range1-60", this.defensePause)

        this.myGui.Add("Text", "x15 y115", "快捷键:")
        this.hotkeyCtrl := this.myGui.Add("Hotkey", "x220 y113 w60", this.pluginHotkey)

        this.myGui.Add("Text", "x15 y145 w280 0x10")  ; 分隔线

        ; 按钮区域
        this.myGui.Add("Button", "x15 y160 w80 h30", "开启").OnEvent("Click", (*) => this.StartDefenseFromGui())
        this.myGui.Add("Button", "x105 y160 w80 h30", "关闭").OnEvent("Click", (*) => this.Close())
        this.myGui.Add("Button", "x195 y160 w80 h30", "保存设置").OnEvent("Click", (*) => this.SaveSettings())

        if this.showGui {
            this.myGui.Show("w300 h205 Center")
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
        this.RunDefense(this.defensePause)
    }

    RunDefense(pauseSec) {
        super.Run()
        this.defensePause := pauseSec

        this.defenseTimer := () => this.PerformDefenseLoop()
        SetTimer(this.defenseTimer, 10)

        if this.statusText {
            this.statusText.Value := "状态: 运行中 ✅ | 快捷键: " this.pluginHotkey
        }
        SetTimer(() => ToolTip(), -3000)
    }

    PerformDefenseLoop() {
        if (!this.isActive) {
            if this.defenseTimer {
                SetTimer(this.defenseTimer, 0)
                this.defenseTimer := 0
            }
            Send "{Space up}"
            return
        }

        SetKeyDelay(50, 50)

        ; 按下空格
        Send "{Space down}"

        ; 循环休眠，支持中途退出
        loop this.defensePause * 10 {
            if (!this.isActive) {
                Send "{Space up}"
                return
            }
            Sleep(100)
        }

        ; 释放空格，等待0.5秒恢复体力
        Send "{Space up}"
        loop 5 {
            if (!this.isActive)
                return
            Sleep(100)
        }
    }

    Close() {
        super.Close()
        if this.defenseTimer {
            SetTimer(this.defenseTimer, 0)
            this.defenseTimer := 0
        }
        Send "{Space up}"

        if this.statusText {
            this.statusText.Value := "状态: 已关闭 ❌ | 快捷键: " this.pluginHotkey
        }
        ToolTip("间歇防御: 关", 10, 50)
        SetTimer(() => ToolTip(), -3000)
    }

    StartDefenseFromGui() {
        if this.isActive {
            MsgBox("间歇防御已在运行中！", "提示", 0x40)
            return
        }

        this.RunDefense(this.pauseEdit.Value)
    }

    SaveSettings() {
        newHotkey := this.hotkeyCtrl.Value
        if (newHotkey = "") {
            MsgBox("快捷键不能为空！", "错误", 0x10)
            return
        }

        this.defensePause := this.pauseEdit.Value
        SetPluginConfig("Settings", "DefensePause", this.defensePause)
        SavePluginHotkey("defense", newHotkey)

        ; 重新绑定快捷键
        this.pluginHotkey := RegisterPluginHotkey("defense", (*) => this.Toggle())
        if this.statusText {
            this.statusText.Value := "状态: " (this.isActive ? "已启用 ✅" : "已关闭 ❌") " | 快捷键: " this.pluginHotkey
        }
        MsgBox("设置已保存！", "提示", 0x40)
    }
}

global plugin := DefensePlugin()
plugin.Init()