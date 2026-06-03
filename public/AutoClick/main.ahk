; 左键自动插件 - main.ahk
; 自动左键点击功能，支持按住触发和切换触发两种模式
#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn All, Off

#Include ..\..\Lib\ConfigHelper.ahk

class AutoClickPlugin extends PluginLifecycle {
    downDelay := 50
    upDelay := 150
    autoClickModel := 1
    pluginHotkey := ""
    isAutoClickToggleModeEnabled := false
    
    myGui := 0
    statusText := 0
    downEdit := 0
    upEdit := 0
    modelEdit := 0
    hotkeyCtrl := 0

    Init() {
        this.downDelay := GetPluginConfig("Settings", "DownDelay", 50)
        this.upDelay := GetPluginConfig("Settings", "UpDelay", 150)
        this.autoClickModel := GetPluginConfig("Settings", "AutoClickModel", 1)
        this.hotkeyName := "autoClick"
        this.hotkeyCallback := (*) => this.Toggle()
        this.pluginHotkey := RegisterPluginHotkey(this.hotkeyName, this.hotkeyCallback)

        ; --- 创建 GUI ---
        this.myGui := Gui("+ToolWindow", this.name " v" this.version)
        this.myGui.OnEvent("Close", (*) => (this.myGui.Hide(), this.showGui := false, (!this.isActive ? ExitApp() : 0)))
        this.myGui.BackColor := "F2F2F2"

        this.myGui.SetFont("s11 bold")
        this.myGui.Add("Text", "x15 y10 w280", "🖱️ " this.name)
        this.myGui.SetFont("s9 norm")

        ; 状态显示
        this.statusText := this.myGui.Add("Text", "x15 y35 w280 c888888", "状态: " (this.isActive ? "已开启 ✅" : "已关闭 ❌") " | 快捷键: " this.pluginHotkey)

        this.myGui.Add("Text", "x15 y55 w280 0x10")  ; 分隔线

        ; 延迟设置
        this.myGui.Add("Text", "x15 y70", "间隙延迟(ms):")
        this.myGui.Add("Text", "x15 y90 w200 c535353", "左键按下和松开间隙延迟")
        this.downEdit := this.myGui.Add("Edit", "x210 y68 w70 Number", this.downDelay)
        this.myGui.Add("UpDown", "Range1-1000", this.downDelay)

        this.myGui.Add("Text", "x15 y115", "组合延迟(ms):")
        this.myGui.Add("Text", "x15 y135 w200 c535353", "完成一组单击后下次触发间隙")
        this.upEdit := this.myGui.Add("Edit", "x210 y113 w70 Number", this.upDelay)
        this.myGui.Add("UpDown", "Range1-1000", this.upDelay)

        this.myGui.Add("Text", "x15 y160", "触发模式:")
        this.myGui.Add("Text", "x15 y180 w200 c535353", "(1)按住触发 (2)切换触发")
        this.modelEdit := this.myGui.Add("Edit", "x210 y158 w70 Number", this.autoClickModel)
        this.myGui.Add("UpDown", "Range1-2", this.autoClickModel)

        this.myGui.Add("Text", "x15 y205", "快捷键:")
        this.hotkeyCtrl := this.myGui.Add("Hotkey", "x210 y203 w70", this.pluginHotkey)

        this.myGui.Add("Text", "x15 y235 w280 0x10")  ; 分隔线

        ; 按钮区域
        this.myGui.Add("Button", "x15 y250 w90 h30", "保存设置").OnEvent("Click", (*) => this.SaveSettings())
        this.myGui.Add("Button", "x115 y250 w90 h30", "开启/关闭").OnEvent("Click", (*) => this.Toggle())
        this.myGui.Add("Button", "x215 y250 w70 h30", "关闭").OnEvent("Click", (*) => ExitApp())

        if this.showGui {
            this.myGui.Show("w300 h295 Center")
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
        super.Run()
        if this.statusText {
            this.statusText.Value := "状态: 已开启 ✅ | 快捷键: " this.pluginHotkey
        }
        ToolTip(this.name ": 开", 10, 10)
        SetTimer(() => ToolTip(), -3000)

        if (this.autoClickModel = 2) {
            this.isAutoClickToggleModeEnabled := true
            SetTimer(() => this.AutoClickLoop(), 10)
        }
    }

    Close() {
        super.Close()
        if this.statusText {
            this.statusText.Value := "状态: 已关闭 ❌ | 快捷键: " this.pluginHotkey
        }
        ToolTip(this.name ": 关", 10, 10)
        SetTimer(() => ToolTip(), -3000)

        this.isAutoClickToggleModeEnabled := false
        SetTimer(() => this.AutoClickLoop(), 0)
    }

    AutoClickLoop() {
        if (!this.isActive) {
            SetTimer(() => this.AutoClickLoop(), 0)
            this.isAutoClickToggleModeEnabled := false
            return
        }
        Send "{LButton down}"
        Sleep(this.downDelay)
        Send "{LButton up}"
        Sleep(this.upDelay)
    }

    HandleHoldMode() {
        while GetKeyState("LButton", "P") {
            Send "{LButton down}"
            Sleep(this.downDelay)
            Send "{LButton up}"
            Sleep(this.upDelay)
        }
    }

    HandleToggleMode() {
        this.isAutoClickToggleModeEnabled := !this.isAutoClickToggleModeEnabled
        if (this.isAutoClickToggleModeEnabled) {
            SetTimer(() => this.AutoClickLoop(), 10)
        } else {
            SetTimer(() => this.AutoClickLoop(), 0)
        }
    }

    SaveSettings() {
        newHotkey := this.hotkeyCtrl.Value
        if (newHotkey = "") {
            MsgBox("快捷键不能为空！", "错误", 0x10)
            return
        }

        this.downDelay := this.downEdit.Value
        this.upDelay := this.upEdit.Value
        this.autoClickModel := this.modelEdit.Value

        SetPluginConfig("Settings", "DownDelay", this.downDelay)
        SetPluginConfig("Settings", "UpDelay", this.upDelay)
        SetPluginConfig("Settings", "AutoClickModel", this.autoClickModel)
        SavePluginHotkey("autoClick", newHotkey)

        ; 重新绑定快捷键
        this.pluginHotkey := RegisterPluginHotkey("autoClick", (*) => this.Toggle())
        if this.statusText {
            this.statusText.Value := "状态: " (this.isActive ? "已开启 ✅" : "已关闭 ❌") " | 快捷键: " this.pluginHotkey
        }

        MsgBox("设置已保存！", "提示", 0x40)
    }
}

global plugin := AutoClickPlugin()
plugin.Init()

#HotIf plugin.isActive and (WinActive("ahk_exe skullandbones.exe") or WinActive("Skull and Bones"))
~$LButton:: {
    global plugin
    if (plugin.isActive && plugin.autoClickModel = 1) {
        plugin.HandleHoldMode()
    } else if (plugin.isActive && plugin.autoClickModel = 2) {
        plugin.HandleToggleMode()
    }
}
#HotIf
