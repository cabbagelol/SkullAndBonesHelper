; 自动开箱插件 - main.ahk
; 自动打开箱子功能，支持船仓/仓库模式，可自定义开箱次数
#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn All, Off

#Include ..\..\Lib\ConfigHelper.ahk

class AutoOpenBoxPlugin extends PluginLifecycle {
    boxOpenMode := 2
    boxOpenCount := 1
    customBoxCount := 1
    pluginHotkey := ""

    myGui := 0
    statusText := 0
    progressText := 0
    boxOpenModeDdl := 0
    boxOpenCountDdl := 0
    customBoxCountEdit := 0
    customBoxCountText := 0
    hotkeyCtrl := 0

    Init() {
        this.boxOpenMode := GetPluginConfig("Settings", "Mode", 2)
        this.boxOpenCount := GetPluginConfig("Settings", "CountIndex", 1)
        this.customBoxCount := GetPluginConfig("Settings", "CustomCount", 1)
        this.hotkeyName := "autoOpenBox"
        this.hotkeyCallback := (*) => this.Toggle()
        this.pluginHotkey := RegisterPluginHotkey(this.hotkeyName, this.hotkeyCallback)

        ; --- 创建 GUI ---
        this.myGui := Gui("+ToolWindow", this.name " v" this.version)
        this.myGui.OnEvent("Close", (*) => (this.myGui.Hide(), this.showGui := false, (!this.isActive ? ExitApp() : 0)))
        this.myGui.BackColor := "F2F2F2"

        this.myGui.SetFont("s11 bold")
        this.myGui.Add("Text", "x15 y10 w280", "📦 " this.name)
        this.myGui.SetFont("s9 norm")

        ; 状态显示
        this.statusText := this.myGui.Add("Text", "x15 y35 w280 c888888", "状态: " (this.isActive ? "运行中 ✅" : "已停止 ❌") " | 快捷键: " this
        .pluginHotkey)
        this.progressText := this.myGui.Add("Text", "x15 y55 w280 c888888", "进度: 无")

        this.myGui.Add("Text", "x15 y75 w280 0x10")  ; 分隔线

        ; 开箱模式
        this.myGui.Add("Text", "x15 y90", "开箱模式:")
        this.boxOpenModeDdl := this.myGui.Add("DropDownList", "x120 y88 w165 vBoxOpenModeChoice Choose" this.boxOpenMode,
            ["船仓", "仓库(推荐)"])

        ; 开箱次数
        this.myGui.Add("Text", "x15 y120", "开箱次数:")
        this.boxOpenCountDdl := this.myGui.Add("DropDownList", "x120 y118 w165 vBoxOpenCountChoice Choose" this.boxOpenCount,
            ["3次", "10次", "100次", "500次", "1000次", "自定义"])

        this.customBoxCountEdit := this.myGui.Add("Edit", "x120 y148 w120 vCustomBoxCount Number Limit5 " (this.boxOpenCount ==
            6 ? "" : "Hidden"), this.customBoxCount)
        this.customBoxCountText := this.myGui.Add("Text", "x245 y150 Hidden", "次")

        this.boxOpenCountDdl.OnEvent("Change", (*) => (
            this.customBoxCountEdit.Visible := (this.boxOpenCountDdl.Value == 6),
            this.customBoxCountText.Visible := (this.boxOpenCountDdl.Value == 6)
        ))

        ; 快捷键
        this.myGui.Add("Text", "x15 y180", "快捷键:")
        this.hotkeyCtrl := this.myGui.Add("Hotkey", "x120 y178 w70", this.pluginHotkey)

        this.myGui.Add("Text", "x15 y210 w280 0x10")  ; 分隔线

        ; 按钮区域
        this.myGui.Add("Button", "x15 y225 w80 h30", "开始开箱").OnEvent("Click", (*) => this.Run())
        this.myGui.Add("Button", "x105 y225 w80 h30", "停止").OnEvent("Click", (*) => this.Close())
        this.myGui.Add("Button", "x195 y225 w80 h30", "保存设置").OnEvent("Click", (*) => this.SaveSettings())

        if this.showGui {
            this.myGui.Show("w300 h270 Center")
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
        if this.isActive {
            MsgBox("自动开箱正在运行中！", "提示", 0x40)
            return
        }

        super.Run()

        selectedBoxCountIndex := this.boxOpenCountDdl.Value
        boxOpenTimes := 0

        switch selectedBoxCountIndex {
            case 1: boxOpenTimes := 3
            case 2: boxOpenTimes := 10
            case 3: boxOpenTimes := 100
            case 4: boxOpenTimes := 500
            case 5: boxOpenTimes := 1000
            case 6:
                customVal := this.customBoxCountEdit.Value
                if (!IsNumber(customVal) || customVal <= 0) {
                    MsgBox("自定义次数必须为正整数！", "错误", 0x10)
                    this.Close()
                    return
                }
                boxOpenTimes := customVal
        }

        if this.statusText {
            this.statusText.Value := "状态: 准备中 ⏳ | 快捷键: " this.pluginHotkey
        }

        ; 启动异步开箱任务 (避免卡死主GUI)
        SetTimer(() => this.PerformOpening(boxOpenTimes), -10)
    }

    PerformOpening(boxOpenTimes) {
        ; 3秒倒计时准备，让玩家有时间切回游戏
        loop 3 {
            if (!this.isActive) {
                return
            }
            countdown := 4 - A_Index
            if this.progressText {
                this.progressText.Value := "倒计时: " countdown " 秒后开始..."
            }
            Sleep(1000)
        }

        if this.statusText {
            this.statusText.Value := "状态: 运行中 ✅ | 快捷键: " this.pluginHotkey
        }

        mode := this.boxOpenModeDdl.Value

        loop boxOpenTimes {
            if (!this.isActive) {
                if this.progressText {
                    this.progressText.Value := "进度: 已停止 (" (A_Index - 1) "/" boxOpenTimes ")"
                }
                return
            }

            ; 仓库模式和船仓模式的模拟逻辑
            if (mode = 1) {
                ; 船仓模式: 按空格开箱，下移，循环
                Send "{Space down}"
                Sleep(80)
                Send "{Space up}"
                Sleep(800)
                Send "{S down}"
                Sleep(50)
                Send "{S up}"
                Sleep(200)
            } else {
                ; 仓库模式: 空格, Space(确认), ESC, S
                Send "{Space down}"
                Sleep(50)
                Send "{Space up}"
                Sleep(100)
                Send "{Space down}"
                Sleep(50)
                Send "{Space up}"
                Sleep(400)
                Send "{Esc down}"
                Sleep(50)
                Send "{Esc up}"
                Sleep(350)
                Send "{S down}"
                Sleep(50)
                Send "{S up}"
                Sleep(200)
            }

            if this.progressText {
                this.progressText.Value := "进度: " A_Index "/" boxOpenTimes
            }
            ToolTip("进度:" A_Index "/" boxOpenTimes, 10, 30)

            if (A_Index = boxOpenTimes && this.isActive) {
                this.Close()
                if this.statusText {
                    this.statusText.Value := "状态: 已完成 ✅ | 快捷键: " this.pluginHotkey
                }
                if this.progressText {
                    this.progressText.Value := "进度: 完成 " boxOpenTimes "/" boxOpenTimes
                }
                ToolTip("自动开箱完成!", 10, 30)
                SetTimer(() => ToolTip(), -3000)
            }
        }
    }

    Close() {
        super.Close()
        if this.statusText {
            this.statusText.Value := "状态: 已停止 ❌ | 快捷键: " this.pluginHotkey
        }
        if this.progressText {
            this.progressText.Value := "进度: 已停止"
        }
        ToolTip()
    }

    SaveSettings() {
        newHotkey := this.hotkeyCtrl.Value
        if (newHotkey = "") {
            MsgBox("快捷键不能为空！", "错误", 0x10)
            return
        }

        this.boxOpenMode := this.boxOpenModeDdl.Value
        this.boxOpenCount := this.boxOpenCountDdl.Value
        this.customBoxCount := this.customBoxCountEdit.Value

        SetPluginConfig("Settings", "Mode", this.boxOpenMode)
        SetPluginConfig("Settings", "CountIndex", this.boxOpenCount)
        SetPluginConfig("Settings", "CustomCount", this.customBoxCount)
        SavePluginHotkey("autoOpenBox", newHotkey)

        ; 重新绑定快捷键
        this.pluginHotkey := RegisterPluginHotkey("autoOpenBox", (*) => this.Toggle())
        if this.statusText {
            this.statusText.Value := "状态: " (this.isActive ? "运行中 ✅" : "已停止 ❌") " | 快捷键: " this.pluginHotkey
        }
        MsgBox("设置已保存！", "提示", 0x40)
    }
}

global plugin := AutoOpenBoxPlugin()
plugin.Init()