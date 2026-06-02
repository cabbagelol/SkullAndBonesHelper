; Lib\Functions.ahk

; --- 自动左键 ---
global userConfigFile, appConfigFile, config
IniRead(userConfigFile, "Delays", "AutoClickModel", config["delays"]["autoClickModel"])

~$LButton:: {
    global isAutoClickEnabled, config

    if (isAutoClickEnabled && config["delays"]["autoClickModel"] = 1) {
        ; 模式1：按住触发
        HandleHoldMode()
    } else if (isAutoClickEnabled && config["delays"]["autoClickModel"] = 2) {
        ; 模式2：切换触发
        HandleToggleMode()
    }
}

; 模式1：按住触发
HandleHoldMode() {
    global isAutoClickEnabled, config

    local currentDownDelay := config["delays"]["down"]
    local currentUpDelay := config["delays"]["up"]

    while GetKeyState("LButton", "P") {
        Send "{LButton down}"
        Sleep(currentDownDelay)
        Send "{LButton up}"
        Sleep(currentUpDelay)
    }
}

; 模式2：切换触发
HandleToggleMode() {
    global isAutoClickToggleModeEnabled

    ; 切换状态
    isAutoClickToggleModeEnabled := !isAutoClickToggleModeEnabled

    if (isAutoClickToggleModeEnabled) {
        ; 启动自动点击
        SetTimer(AutoClick, 10) ; 立即开始，然后按配置间隔执行
    }
    if (!isAutoClickToggleModeEnabled || !isAutoClickEnabled) {
        ; 停止自动点击
        SetTimer(AutoClick, 0) ; 关闭定时器
    }
}

AutoClick() {
    global config, isAutoClickToggleModeEnabled

    if (!isAutoClickEnabled) {
        ; 关闭定时器
        SetTimer(AutoClick, 0)
        ; 切换状态
        isAutoClickToggleModeEnabled := !isAutoClickToggleModeEnabled
    }

    local currentDownDelay := config["delays"]["down"]
    local currentUpDelay := config["delays"]["up"]

    Send "{LButton down}"
    Sleep(currentDownDelay)
    Send "{LButton up}"
    Sleep(currentUpDelay)
}

if IniRead(appConfigFile, "App", "IsAutoClickAltStopEnabled", config["app"]["isAutoClickAltStopEnabled"]) {
    Alt:: {
        isAutoClickLSEnabled := true

        while (GetKeyState("Space", "P")) {
            Sleep 10
        }

        isAutoClickLSEnabled := false
    }
}

; --- 计时器功能 ---
; 开始计时
StartTimer(duration) {
    global timerRunning, timerEndTime, lv, config

    ; 在启动新计时器之前停止任何现有计时器
    if timerRunning {
        SetTimer(UpdateTimer, 0)
    }

    timerEndTime := A_TickCount + duration
    timerRunning := true
    SetTimer(UpdateTimer, 1000) ; 每秒更新

    if (row := GetRowIndexByFunctionName("计时器"))
        lv.Modify(row, "Check", "计时器", config["hotkeys"]["timer"], "运行中")
    ToolTip("计时器已启动。", 10, 30)
}

; 更新计时器显示
UpdateTimer() {
    global timerRunning, timerEndTime, lv, config

    remaining := timerEndTime - A_TickCount
    if (remaining <= 0) {
        timerRunning := false
        SetTimer(UpdateTimer, 0) ; 停止计时器
        SoundPlay("*64") ; 计时器结束时播放声音

        if (row := GetRowIndexByFunctionName("计时器"))
            lv.Modify(row, "-Check", "计时器", config["hotkeys"]["timer"], "关闭")
        ToolTip() ; 清除提示
        return
    }

    seconds := Floor(remaining / 1000)
    if (row := GetRowIndexByFunctionName("计时器"))
        lv.Modify(row, "Check", "计时器", config["hotkeys"]["timer"], seconds "秒") ; 更新 ListView 显示剩余秒数
    ToolTip("倒计时: " seconds "秒", 10, 30)
}

; 停止计时器
StopTimer() {
    global timerRunning, lv, config
    timerRunning := false
    SetTimer(UpdateTimer, 0) ; 停止计时器更新

    if (row := GetRowIndexByFunctionName("计时器"))
        lv.Modify(row, "-Check", "计时器", config["hotkeys"]["timer"], "关闭")

    ToolTip() ; 清除提示
}

; --- 防踢功能 ---
global boxOpenCountDdl ; 开箱次数下拉列表控件
global boxOpenModeDdl ; 开箱模式
global customBoxCountEdit ; 自定义次数输入框控件
global customBoxCountText ; 自定义次数文本标签控件

; 启动防踢
StartAntiKick(interval) {
    global isRandomKeyEnabled, randomKeyTimer, lv, config

    if isRandomKeyEnabled && randomKeyTimer {
        SetTimer(randomKeyTimer, 0)
    }

    isRandomKeyEnabled := true
    randomKeyTimer := SetTimer(SendRandomKey, interval)

    if (row := GetRowIndexByFunctionName("防踢状态"))
        lv.Modify(row, "Check", "防踢状态", config["hotkeys"]["antiKick"], "开启")
    ToolTip("防踢模式已启动", 10, 50)
}

; 发送随机按键
SendRandomKey() {
    global isRandomKeyEnabled

    if !isRandomKeyEnabled
        return

    randomKey := Random(1, 2) = 1 ? "%" : "+"
    SendEvent("{" randomKey " down}")
    Sleep(50)
    SendEvent("{" randomKey " up}")
    ToolTip("防踢按键: " randomKey, 10, 50)
    SetTimer(() => ToolTip(), -1000)
}

; --- 自动打开箱子
global myAutoOpenGui := ""
/*
 * 启动自动开箱功能的入口配置界面
 * 检查是否存在已有的配置窗口，如果没有则创建包含模式选择和次数自定义的 GUI 并显示。
*/
StartAutoOpenBox() {
    global boxOpenCountDdl, boxOpenModeDdl, customBoxCountEdit, customBoxCountText
    global myAutoOpenGui

    if IsObject(myAutoOpenGui) && myAutoOpenGui.Hwnd {
        myAutoOpenGui.Show()
        return
    }

    myAutoOpenGui := Gui()
    myAutoOpenGui.Title := "自动开箱设置"

    myAutoOpenGui.Add("Text", , "开箱模式:")
    boxOpenModeDdl := myAutoOpenGui.Add("DropDownList", "vBoxOpenModeChoice Choose2", ["船仓", "仓库(推荐)"])

    myAutoOpenGui.Add("Text", , "选择开箱次数:")
    boxOpenCountDdl := myAutoOpenGui.Add("DropDownList", "vBoxOpenCountChoice Choose1", ["3次", "10次", "100次", "500次",
        "1000次", "自定义"])

    customBoxCountEdit := myAutoOpenGui.Add("Edit", "vCustomBoxCount Number Limit5 w160 Hidden", 1)
    customBoxCountText := myAutoOpenGui.Add("Text", "x+6 Hidden", "次")

    boxOpenCountDdl.OnEvent("Change", (*) => (
        customBoxCountEdit.Visible := (boxOpenCountDdl.Value == 6),
        customBoxCountText.Visible := (boxOpenCountDdl.Value == 6)
    ))

    btnStartAutoOpen := myAutoOpenGui.Add("Button", "Default", "开始自动开箱")
    btnStartAutoOpen.OnEvent("Click", InitiateAutoOpening)

    myAutoOpenGui.Show()
}

/*
 * 自动开箱的具体任务执行方法
 * 解析用户在 GUI 中设置的开箱次数，给出3秒倒计时准备，
 * 然后通过循环执行特定的模拟键盘输入（Space, S, ESC）完成连续开箱动作。
 * 在循环过程或结束时同步更新主界面状态与气泡提示。
*/
InitiateAutoOpening(*) {
    global autoOpenBoxRunning, boxOpenCountDdl, lv, customBoxCountEdit, myAutoOpenGui

    autoOpenBoxRunning := true

    selectedBoxCountIndex := boxOpenCountDdl.Value
    boxOpenTimes := 0

    switch selectedBoxCountIndex {
        case 1: boxOpenTimes := 3
        case 2: boxOpenTimes := 10
        case 3: boxOpenTimes := 100
        case 4: boxOpenTimes := 500
        case 5: boxOpenTimes := 1000
        case 6:
            try {
                boxOpenTimes := Integer(customBoxCountEdit.Value)
            } catch {
                return
            }
    }

    if boxOpenTimes <= 0 {
        MsgBox "请输入有效的开箱次数!", "错误", 0x10
        SetTimer(() => ToolTip(), -3000)
        return
    }

    ToolTip "3秒后开始自动开箱，请切换到目标窗口...", 0, 0
    Sleep 1000
    ToolTip "2秒后开始自动开箱，请切换到目标窗口...", 0, 0
    Sleep 1000
    ToolTip "1秒后开始自动开箱，请切换到目标窗口...", 0, 0
    Sleep 1000
    ToolTip

    if (row := GetRowIndexByFunctionName("自动打开箱子"))
        lv.Modify(row, "Check", "自动打开箱子", config["hotkeys"]["autoOpenBox"], "开启")

    loop boxOpenTimes {
        if (!autoOpenBoxRunning) {
            if (row := GetRowIndexByFunctionName("自动打开箱子"))
                lv.Modify(row, "-Check", "自动打开箱子", config["hotkeys"]["autoOpenBox"], "关闭")
            SetTimer(() => ToolTip(), -1000)
            break
        }

        SetKeyDelay(50, 50)

        SendEvent("{Space}")
        Sleep(550)

        if boxOpenModeDdl.Value == 2 {
            SendEvent("{S}")
            Sleep(50)
        }

        SendEvent("{Space}")
        Sleep(550)

        SendEvent("{Esc}")
        Sleep(1000)

        if (row := GetRowIndexByFunctionName("自动打开箱子"))
            lv.Modify(row, "-Check", "自动打开箱子", config["hotkeys"]["autoOpenBox"], A_Index "/" boxOpenTimes)
        ToolTip("进度:" A_Index "/" boxOpenTimes, 10, 30)

        if (A_Index = boxOpenTimes && autoOpenBoxRunning) {
            if (row := GetRowIndexByFunctionName("自动打开箱子"))
                lv.Modify(row, "-Check", "自动打开箱子", config["hotkeys"]["autoOpenBox"], "关闭")
            ToolTip("自动开箱完成!", 10, 30)
            SetTimer(() => ToolTip(), -3000)
        }
    }

    autoOpenBoxRunning := false
}

; --- 间歇防御功能 ---
RunDefense() {
    global isDefenseEnabled, config
    if (!isDefenseEnabled) {
        SetTimer(RunDefense, 0)
        return
    }

    SetKeyDelay(50, 50)

    Send "{Space down}"

    pauseTime := config["delays"]["defensePause"] * 1000

    ; 分段 Sleep (100ms 一次)，以便能瞬间响应用户的“关闭”操作，防止界面无响应或游戏操作粘连
    loopCount := Floor(pauseTime / 100)
    loop loopCount {
        if (!isDefenseEnabled) {
            Send "{Space up}"
            return
        }
        Sleep(100)
    }

    Send "{Space up}"

    ; 组合间隔 0.5s
    loop 5 {
        if (!isDefenseEnabled)
            return
        Sleep(100)
    }
}

; --- 粘贴聊天功能 ---
#HotIf isPasteChatEnabled and (WinActive("ahk_exe skullandbones.exe") or WinActive("Skull and Bones"))
~^c:: {
    Sleep(100) ; 等待系统复制完成
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
    SetKeyDelay(50, 50) ; 设置按键延迟，适应游戏接收
    SendEvent("{Text}" clipText)
}
#HotIf