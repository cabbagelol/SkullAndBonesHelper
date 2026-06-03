; 粘贴聊天插件 - main.ahk
; 在碧海黑帆游戏内模拟打字粘贴剪贴板内容到聊天框
#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn All, Off

#Include ..\..\Lib\ConfigHelper.ahk

class PasteChatPlugin extends PluginLifecycle {
    pluginHotkey := ""
    myGui := 0
    statusText := 0
    hotkeyCtrl := 0

    Init() {
        this.hotkeyName := "pasteChat"
        this.hotkeyCallback := (*) => this.Toggle()
        this.pluginHotkey := RegisterPluginHotkey(this.hotkeyName, this.hotkeyCallback)

        ; --- 创建 GUI ---
        this.myGui := Gui("+ToolWindow", this.name " v" this.version)
        this.myGui.OnEvent("Close", (*) => (this.myGui.Hide(), this.showGui := false, (!this.isActive ? ExitApp() : 0)))
        this.myGui.BackColor := "F2F2F2"

        this.myGui.SetFont("s11 bold")
        this.myGui.Add("Text", "x15 y10 w280", "💬 " this.name)
        this.myGui.SetFont("s9 norm")

        ; 状态显示
        this.statusText := this.myGui.Add("Text", "x15 y35 w280 c888888", "状态: " (this.isActive ? "已开启 ✅" : "已关闭 ❌") " | 快捷键: " this
        .pluginHotkey)

        this.myGui.Add("Text", "x15 y55 w280 0x10")  ; 分隔线

        ; 说明
        this.myGui.Add("Text", "x15 y70 w280", "使用说明:")
        this.myGui.Add("Text", "x15 y90 w280 c535353", "1. 在游戏外复制文本 (Ctrl+C)")
        this.myGui.Add("Text", "x15 y110 w280 c535353", "2. 在游戏聊天框中按 Ctrl+V 粘贴")
        this.myGui.Add("Text", "x15 y130 w280 c535353", "3. 插件会模拟逐字输入到游戏中")
        this.myGui.Add("Text", "x15 y155 w280 c888888", "仅在碧海黑帆窗口激活时生效")

        this.myGui.Add("Text", "x15 y175 w280 0x10")  ; 分隔线

        ; 设置区域
        this.myGui.Add("Text", "x15 y190", "开关快捷键:")
        this.hotkeyCtrl := this.myGui.Add("Hotkey", "x120 y188 w70", this.pluginHotkey)

        this.myGui.Add("Text", "x15 y220 w280 0x10")  ; 分隔线

        ; 按钮区域
        this.myGui.Add("Button", "x15 y235 w80 h30", "开启/关闭").OnEvent("Click", (*) => this.Toggle())
        this.myGui.Add("Button", "x105 y235 w80 h30", "保存设置").OnEvent("Click", (*) => this.SaveSettings())
        this.myGui.Add("Button", "x195 y235 w80 h30", "关闭插件").OnEvent("Click", (*) => ExitApp())

        if this.showGui {
            this.myGui.Show("w300 h280 Center")
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
        super.Run()
        if this.statusText {
            this.statusText.Value := "状态: 已开启 ✅ | 快捷键: " this.pluginHotkey
        }
        ToolTip("粘贴聊天: 开", 10, 50)
        SetTimer(() => ToolTip(), -3000)
    }

    Close() {
        super.Close()
        if this.statusText {
            this.statusText.Value := "状态: 已关闭 ❌ | 快捷键: " this.pluginHotkey
        }
        ToolTip("粘贴聊天: 关", 10, 50)
        SetTimer(() => ToolTip(), -3000)
    }

    SaveSettings() {
        newHotkey := this.hotkeyCtrl.Value
        if (newHotkey = "") {
            MsgBox("快捷键不能为空！", "错误", 0x10)
            return
        }

        SavePluginHotkey("pasteChat", newHotkey)

        ; 重新绑定快捷键
        this.pluginHotkey := RegisterPluginHotkey("pasteChat", (*) => this.Toggle())
        if this.statusText {
            this.statusText.Value := "状态: " (this.isActive ? "已开启 ✅" : "已关闭 ❌") " | 快捷键: " this.pluginHotkey
        }
        MsgBox("设置已保存！", "提示", 0x40)
    }
}

global plugin := PasteChatPlugin()
plugin.Init()

#HotIf plugin.isActive and (WinActive("ahk_exe skullandbones.exe") or WinActive("Skull and Bones"))
~^c:: {
    Sleep(100)  ; 等待系统复制完成
    ToolTip("已准备模拟粘贴: " SubStr(A_Clipboard, 1, 20) (StrLen(A_Clipboard) > 20 ? "..." : ""), 10, 50)
    SetTimer(() => ToolTip(), -2000)
}

^v:: {
    clipText := A_Clipboard
    if (clipText = "") {
        ToolTip("剪切板为空", 10, 50)
        SetTimer(() => ToolTip(), -2000)
        return
    }

    ToolTip("正在模拟打字输出...", 10, 50)
    SetTimer(() => ToolTip(), -2000)

    ; 模拟打字过程
    SetKeyDelay(50, 50)  ; 设置按键延迟，适应游戏接收
    SendEvent("{Text}" clipText)
}
#HotIf