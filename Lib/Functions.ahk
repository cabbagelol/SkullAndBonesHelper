; Lib\Functions.ahk

; --- 计时器功能 ---
; 开始计时
StartTimer(duration) {
    global timerRunning, timerEndTime, lv, config

    ; Stop any existing timer before starting a new one
    if timerRunning {
        SetTimer(UpdateTimer, 0)
    }

    timerEndTime := A_TickCount + duration
    timerRunning := true
    SetTimer(UpdateTimer, 1000) ; Update every second

    lv.Modify(2, "Check", "计时器", config["hotkeys"]["timer"], "运行中")
    ToolTip("计时器已启动。", 10, 30)
}

; 更新计时器显示
UpdateTimer() {
    global timerRunning, timerEndTime, lv, config

    remaining := timerEndTime - A_TickCount
    if (remaining <= 0) {
        timerRunning := false
        SetTimer(UpdateTimer, 0) ; Stop the timer
        SoundPlay("*64") ; Play a sound when the timer finishes

        lv.Modify(2, "-Check", "计时器", config["hotkeys"]["timer"], "关闭")
        ToolTip() ; Clear the tooltip
        return
    }

    seconds := Floor(remaining / 1000)
    lv.Modify(2,"Check", "计时器", config["hotkeys"]["timer"],seconds "秒") ; Update the ListView with remaining seconds
    ToolTip("倒计时: " seconds "秒", 10, 30)
}

; 停止计时器
StopTimer() {
    global timerRunning, lv, config
    timerRunning := false
    SetTimer(UpdateTimer, 0) ; Stop the timer update

    lv.Modify(2, "-Check", "计时器", config["hotkeys"]["timer"], "关闭")

    ToolTip() ; Clear the tooltip
}

; --- 防踢功能 ---
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