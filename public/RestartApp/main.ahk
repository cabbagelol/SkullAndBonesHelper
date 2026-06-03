; 重启程序插件 - main.ahk
; 按下快捷键瞬间重启主程序
#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn All, Off

#Include ..\..\Lib\ConfigHelper.ahk

class RestartAppPlugin extends PluginLifecycle {
    pluginHotkey := ""
    myGui := 0
    statusText := 0
    hotkeyCtrl := 0

    Init() {
        this.hotkeyName := "restartKey"
        this.hotkeyCallback := (*) => this.Run()
        this.pluginHotkey := RegisterPluginHotkey(this.hotkeyName, this.hotkeyCallback)

        ; --- 创建 GUI ---
        this.myGui := Gui("+ToolWindow", this.name " v" this.version)
        this.myGui.OnEvent("Close", (*) => (this.myGui.Hide(), this.showGui := false, (!this.isActive ? ExitApp() : 0)))
        this.myGui.BackColor := "F2F2F2"

        this.myGui.SetFont("s11 bold")
        this.myGui.Add("Text", "x15 y10 w280", "🔄 " this.name)
        this.myGui.SetFont("s9 norm")

        ; 状态显示
        this.statusText := this.myGui.Add("Text", "x15 y35 w280 c888888", "状态: " (this.isActive ? "已启用 ✅" : "已停用 ❌") " | 快捷键: " this
        .pluginHotkey)

        this.myGui.Add("Text", "x15 y55 w280 0x10")  ; 分隔线

        ; 说明
        this.myGui.Add("Text", "x15 y70 w280", "使用说明:")
        this.myGui.Add("Text", "x15 y90 w280 c535353", "1. 在任何时候按下快捷键可重启小助手主程序")
        this.myGui.Add("Text", "x15 y110 w280 c535353", "2. 常用于重新加载配置文件或界面")

        this.myGui.Add("Text", "x15 y140 w280 0x10")  ; 分隔线

        ; 设置区域
        this.myGui.Add("Text", "x15 y155", "设置快捷键:")
        this.hotkeyCtrl := this.myGui.Add("Hotkey", "x120 y153 w70", this.pluginHotkey)

        this.myGui.Add("Text", "x15 y185 w280 0x10")  ; 分隔线

        ; 按钮区域
        this.myGui.Add("Button", "x15 y200 w80 h30", "重启主程序").OnEvent("Click", (*) => this.Run())
        this.myGui.Add("Button", "x105 y200 w80 h30", "保存设置").OnEvent("Click", (*) => this.SaveSettings())
        this.myGui.Add("Button", "x195 y200 w80 h30", "关闭插件").OnEvent("Click", (*) => ExitApp())

        if this.showGui {
            this.myGui.Show("w300 h245 Center")
        }
    }

    Run() {
        super.Run()

        mainExe := A_ScriptDir "\..\..\Main.exe"
        mainAhk := A_ScriptDir "\..\..\Main.ahk"

        ; 尝试重启主程序
        if FileExist(mainExe) {
            Run('"' mainExe '"')
        } else if FileExist(mainAhk) {
            Run(A_AhkPath ' "' mainAhk '"')
        } else {
            MsgBox("错误: 未找到主程序 Main.exe 或 Main.ahk！", "重启失败", 0x10)
            this.Close()
            return
        }

        ToolTip("主程序重启中...", 10, 50)
        SetTimer(() => ToolTip(), -2000)

        ; 重启主程序后，该进程本身应退出（主程序会重新加载并管理它）
        ExitApp()
    }

    Close() {
        super.Close()
        if this.statusText {
            this.statusText.Value := "状态: 已停用 ❌ | 快捷键: " this.pluginHotkey
        }
    }

    SaveSettings() {
        newHotkey := this.hotkeyCtrl.Value
        if (newHotkey = "") {
            MsgBox("快捷键不能为空！", "错误", 0x10)
            return
        }

        SavePluginHotkey("restartKey", newHotkey)

        ; 重新绑定快捷键
        this.pluginHotkey := RegisterPluginHotkey("restartKey", (*) => this.Run())
        if this.statusText {
            this.statusText.Value := "状态: " (this.isActive ? "已启用 ✅" : "已停用 ❌") " | 快捷键: " this.pluginHotkey
        }
        MsgBox("设置已保存！", "提示", 0x40)
    }
}

global plugin := RestartAppPlugin()
plugin.Init()