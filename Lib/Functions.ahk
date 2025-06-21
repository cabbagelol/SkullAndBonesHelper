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
global customBoxCountText     ; 自定义次数文本标签控件

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
; 启动自动开箱功能的入口
StartAutoOpenBox() {
    global boxOpenCountDdl

    myAutoOpenGui := Gui()
    myAutoOpenGui.Title := "自动开箱设置"
    myAutoOpenGui.Add("Text",, "选择开箱次数:")
    boxOpenCountDdl := myAutoOpenGui.Add("DropDownList", "vBoxOpenCountChoice Choose1", ["3次", "10次", "300次", "自定义"])

    ; 添加自定义次数输入框
    customBoxCountEdit := myAutoOpenGui.Add("Edit", "vCustomBoxCount Number Limit5 w160 Hidden", "1")
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
    global autoOpenBoxRunning, boxOpenCountDdl, lv ; 在函数内部声明要修改的全局变量

    ; 重置停止标志
    autoOpenBoxRunning := false

    ; 直接从下拉列表控件获取其当前的索引值
    selectedBoxCountIndex := boxOpenCountDdl.Value
    boxOpenTimes := 0

    ; 根据选择确定执行次数
    switch selectedBoxCountIndex {
        case 1: boxOpenTimes := 3    ; 第一项"3次"
        case 2: boxOpenTimes := 10   ; 第二项"10次"
        case 3: boxOpenTimes := 300   ; 第三项"300次"
        case 4: boxOpenTimes := Integer(customBoxCountEdit.Value) ; 第四项"自定义"，从 customBoxCountEdit 获取值
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

    lv.Modify(4, isAutoClickEnabled ? "Check" : "-Check", "自动打开箱子", config["hotkeys"]["autoOpenBox"], "开启")

    ; 执行模拟操作
    Loop boxOpenTimes {
        ; 在每次操作前检查停止标志
        if autoOpenBoxRunning {
            ToolTip
            MsgBox "自动开箱已停止!", "提示", 0x40
            break ; 跳出循环
        }

        ; 第一次空格
        Send "{Space}"
        Sleep 800  ; 800ms间隔

        ; 第二次空格
        Send "{Space}"
        Sleep 1100

        ; 按下ESC
        Send "{Esc}"
        Sleep 100  ; 100ms停顿

        ; 显示进度
        if Mod(A_Index, 10) = 0 || A_Index = boxOpenTimes
            ToolTip "开箱进度: " A_Index "/" boxOpenTimes

        ; 如果已经到达设定的次数，且没有被停止，就显示完成
        if (A_Index = boxOpenTimes && !autoOpenBoxRunning) {
            lv.Modify(4, isAutoClickEnabled ? "Check" : "-Check", "自动打开箱子", config["hotkeys"]["autoOpenBox"], "关闭")

            ToolTip
            MsgBox "自动开箱完成!", "完成", 0x40
        }
    }

    ToolTip ; 清除最后的 ToolTip
}