; 示例插件 - main.ahk
; 这是一个演示插件，展示插件系统的基本结构
#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn All, Off

#Include ..\..\Lib\ConfigHelper.ahk

class SamplePlugin extends PluginLifecycle {
    myGui := 0

    Init() {
        ; --- 创建 GUI ---
        this.myGui := Gui("+ToolWindow", this.name " v" this.version)
        this.myGui.OnEvent("Close", (*) => (this.myGui.Hide(), this.showGui := false, (!this.isActive ? ExitApp() : 0)))
        this.myGui.BackColor := "F2F2F2"

        this.myGui.SetFont("s12 bold")
        this.myGui.Add("Text", "x20 y15 w260", "🔌 " this.name)
        this.myGui.SetFont("s9 norm")
        this.myGui.Add("Text", "x20 y45 w260 c666666", "版本: " this.version)

        this.myGui.Add("Text", "x20 y70 w260 0x10")  ; 分隔线

        this.myGui.Add("Text", "x20 y85 w260", "这是一个示例插件，用于演示")
        this.myGui.Add("Text", "x20 y105 w260", "碧海黑帆小助手的插件系统。")
        this.myGui.Add("Text", "x20 y130 w260 c888888", "你可以参考这个模板来开发自己的插件。")

        ; 示例按钮
        this.myGui.Add("Button", "x20 y165 w120 h30", "测试提示").OnEvent("Click", (*) => (
            ToolTip("示例插件: 功能正常运行中！", 10, 50),
            SetTimer(() => ToolTip(), -3000)
        ))

        this.myGui.Add("Button", "x160 y165 w120 h30", "关闭插件").OnEvent("Click", (*) => ExitApp())

        if this.showGui {
            this.myGui.Show("w300 h210 Center")
        }
    }
}

global plugin := SamplePlugin()
plugin.Init()
