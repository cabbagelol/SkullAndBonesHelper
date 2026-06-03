; 示例插件 - main.ahk
; 这是一个演示插件，展示插件系统的基本结构
#Requires AutoHotkey v2.0
#SingleInstance Force

; --- 插件初始化 ---
pluginName := "示例插件"
pluginVersion := "1.0.0"

; 创建插件 GUI 窗口
SampleGui := Gui("+ToolWindow", pluginName " v" pluginVersion)
SampleGui.OnEvent("Close", (*) => ExitApp())
SampleGui.BackColor := "F2F2F2"

SampleGui.SetFont("s12 bold")
SampleGui.Add("Text", "x20 y15 w260", "🔌 " pluginName)
SampleGui.SetFont("s9 norm")
SampleGui.Add("Text", "x20 y45 w260 c666666", "版本: " pluginVersion)

SampleGui.Add("Text", "x20 y70 w260 0x10")  ; 分隔线

SampleGui.Add("Text", "x20 y85 w260", "这是一个示例插件，用于演示")
SampleGui.Add("Text", "x20 y105 w260", "碧海黑帆小助手的插件系统。")
SampleGui.Add("Text", "x20 y130 w260 c888888", "你可以参考这个模板来开发自己的插件。")

; 示例按钮
SampleGui.Add("Button", "x20 y165 w120 h30", "测试提示").OnEvent("Click", (*) => (
    ToolTip("示例插件: 功能正常运行中！", 10, 50),
    SetTimer(() => ToolTip(), -3000)
))

SampleGui.Add("Button", "x160 y165 w120 h30", "关闭插件").OnEvent("Click", (*) => ExitApp())

SampleGui.Show("w300 h210 Center")
