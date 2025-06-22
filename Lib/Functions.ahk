; Lib\Functions.ahk

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

    lv.Modify(2, "Check", "计时器", config["hotkeys"]["timer"], "运行中")
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

        lv.Modify(2, "-Check", "计时器", config["hotkeys"]["timer"], "关闭")
        ToolTip() ; 清除提示
        return
    }

    seconds := Floor(remaining / 1000)
    lv.Modify(2,"Check", "计时器", config["hotkeys"]["timer"],seconds "秒") ; 更新 ListView 显示剩余秒数
    ToolTip("倒计时: " seconds "秒", 10, 30)
}

; 停止计时器
StopTimer() {
    global timerRunning, lv, config
    timerRunning := false
    SetTimer(UpdateTimer, 0) ; 停止计时器更新

    lv.Modify(2, "-Check", "计时器", config["hotkeys"]["timer"], "关闭")

    ToolTip() ; 清除提示
}

; --- 防踢功能 ---
global boxOpenCountDdl        ; 开箱次数下拉列表控件
global customBoxCountEdit     ; 自定义次数输入框控件
global customBoxCountText    ; 自定义次数文本标签控件

; 启动防踢
StartAntiKick(interval) {
    global isRandomKeyEnabled, randomKeyTimer, lv, config

    if isRandomKeyEnabled && randomKeyTimer {
        SetTimer(randomKeyTimer, 0)
    }

    isRandomKeyEnabled := true
    randomKeyTimer := SetTimer(SendRandomKey, interval)

    lv.Modify(3, "Check", "防踢状态", config["hotkeys"]["antiKick"], "开启")
    ToolTip("防踢模式已启动。", 10, 50)
}

; 发送随机按键
SendRandomKey() {
    global isRandomKeyEnabled

    if !isRandomKeyEnabled
        return

    randomKey := Random(1, 2) = 1 ? "a" : "d"
    SendEvent("{" randomKey " down}")
    Sleep(50)
    SendEvent("{" randomKey " up}")
    ToolTip("防踢按键: " randomKey, 10, 50)
    SetTimer(() => ToolTip(), -1000)
}

; --- 自动打开箱子
global myAutoOpenGui := ""
; 启动自动开箱功能的入口
StartAutoOpenBox() {
    global boxOpenCountDdl, customBoxCountEdit, customBoxCountText
    global myAutoOpenGui

    ; 检查是否已经有一个 GUI 实例存在并且没有被销毁
    if IsObject(myAutoOpenGui) && myAutoOpenGui.Hwnd {
        myAutoOpenGui.Show() ; 如果已存在，直接显示并激活它
        return
    }

    myAutoOpenGui := Gui()
    myAutoOpenGui.Title := "自动开箱设置"
    myAutoOpenGui.Add("Text",, "选择开箱次数:")
    boxOpenCountDdl := myAutoOpenGui.Add("DropDownList", "vBoxOpenCountChoice Choose1", ["3次", "10次", "100次", "500次" ,"1000次", "自定义"])

    ; 添加自定义次数输入框
    customBoxCountEdit := myAutoOpenGui.Add("Edit", "vCustomBoxCount Number Limit5 w160 Hidden", 1)
    customBoxCountText := myAutoOpenGui.Add("Text", "x+5 Hidden", "次")

    ; 当下拉框选择"自定义"时显示编辑框
    boxOpenCountDdl.OnEvent("Change", (*) => (
        customBoxCountEdit.Visible := (boxOpenCountDdl.Value == 4),
        customBoxCountText.Visible := (boxOpenCountDdl.Value == 4)
    ))

    btnStartAutoOpen := myAutoOpenGui.Add("Button", "Default", "开始自动开箱")
    btnStartAutoOpen.OnEvent("Click", InitiateAutoOpening)

    myAutoOpenGui.Show()
}

; 实际执行自动开箱操作的函数
InitiateAutoOpening(*) {
    global autoOpenBoxRunning, boxOpenCountDdl, lv, customBoxCountEdit, myAutoOpenGui

    ; 重置停止标志（这可能应该设置为 true 以指示它正在运行）
    ; 你当前将 autoOpenBoxRunning 设置为 false，这将立即中断循环。
    ; 它应该在自动打开过程开始时设置为 true。
    autoOpenBoxRunning := true

    ; 直接从下拉列表控件获取其当前的索引值
    selectedBoxCountIndex := boxOpenCountDdl.Value
    boxOpenTimes := 0

    ; 根据选择确定执行次数
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
            Return
        }
    }

    if boxOpenTimes <= 0 {
        MsgBox "请输入有效的开箱次数!", "错误", 0x10
        return
    }

    ; 延迟3秒让用户准备
    ToolTip "3秒后开始自动开箱，请切换到目标窗口...", 0, 0
    Sleep 1000
    ToolTip "2秒后开始自动开箱，请切换到目标窗口...", 0, 0
    Sleep 1000
    ToolTip "1秒后开始自动开箱，请切换到目标窗口...", 0, 0
    Sleep 1000
    ToolTip

    ; 更新 lv 中的状态（假设 lv 是你的 ListView 控件）
    ; 确保 config 和 isAutoClickEnabled 也是全局可访问的或已传递。
    ; 这行可能需要根据你管理 isAutoClickEnabled 和 config 的方式进行调整。
    lv.Modify(4, "Check", "自动打开箱子", config["hotkeys"]["autoOpenBox"], "开启")

    ; 执行模拟操作
    Loop boxOpenTimes {
        ; 在每次操作前检查停止标志（此检查应针对 *停止* 信号）
        ; 你当前的逻辑是在 autoOpenBoxRunning 为 true 时中断，这意味着它正在运行。
        ; 你需要一个单独的停止标志，或者反转这个逻辑。
        ; 例如，引入一个 `stopAutoOpen := false` 全局变量。
        ; 让我们假设 autoOpenBoxRunning 应该为 *false* 才能停止。
        if (!autoOpenBoxRunning) { ; 如果 autoOpenBoxRunning 变为 false（外部停止）
            lv.Modify(4, "-Check", "自动打开箱子", config["hotkeys"]["autoOpenBox"], "关闭")
            break ; 跳出循环
        }

        ; 第一次空格
        SetKeyDelay(50, 50)
        SendEvent("{Space}") ; 或者 SendPlay("{Space}")
        Sleep(1100)

        ; 第二次空格
        SendEvent("{Space}") ; 或者 SendPlay("{Space}")
        Sleep(1100)

        ; 按下ESC
        SendEvent("{Esc}") ; 或者 SendPlay("{Esc}")
        Sleep(500)

        ; 显示进度
        lv.Modify(4, "-Check", "自动打开箱子", config["hotkeys"]["autoOpenBox"], A_Index "/" boxOpenTimes)
        ToolTip("进度:" A_Index "/" boxOpenTimes, 10, 30)

        ; 如果已经达到设定的次数，且没有被停止，就显示完成
        if (A_Index = boxOpenTimes && autoOpenBoxRunning) { ; 检查是否仍在运行
            lv.Modify(4, "-Check", "自动打开箱子", config["hotkeys"]["autoOpenBox"], "关闭")
            ToolTip("自动开箱完成!", 10, 30)
            SetTimer(() => ToolTip(), -3000)
        }
    }

    autoOpenBoxRunning := false ; 确保循环完成后重置
}