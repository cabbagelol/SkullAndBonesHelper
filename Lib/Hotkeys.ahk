; Lib\Hotkeys.ahk

; 应用热键
ApplyHotkeys() {
    global config

    try Hotkey(config["hotkeys"]["autoClick"], "Off")
    try Hotkey(config["hotkeys"]["autoOpenBox"], "Off")
    try Hotkey(config["hotkeys"]["timer"], "Off")
    try Hotkey(config["hotkeys"]["antiKick"], "Off")

    ; The '$' prefix makes the hotkey function even when the script's own window is active.
    try Hotkey("$" config["hotkeys"]["autoClick"], ToggleAutoClick, "On")
    try Hotkey("$" config["hotkeys"]["autoOpenBox"], ToggleAutoOpenBox, "On")
    try Hotkey("$" config["hotkeys"]["timer"], ToggleTimer, "On")
    try Hotkey("$" config["hotkeys"]["antiKick"], ToggleAntiKick, "On")
}

; --- 功能开关与执行 (由快捷键触发的逻辑) ---

; 切换左键自动
ToggleAutoClick(*) {
    global isAutoClickEnabled, lv, config
    isAutoClickEnabled := !isAutoClickEnabled

    lv.Modify(1, isAutoClickEnabled ? "Check" : "-Check", "左键自动", config["hotkeys"]["autoClick"], isAutoClickEnabled ? "开启" : "关闭")

    ToolTip("左键自动: " (isAutoClickEnabled ? "开" : "关"), 10, 10)
    SetTimer(() => ToolTip(), -3000)
}

; 切换计时器 (由快捷键触发)
ToggleTimer(*) {
    global timerRunning
    if timerRunning {
        StopTimer() ; Call the function from Lib\Functions.ahk
    } else {
        StartTimer(60 * 1000) ; Call the function from Lib\Functions.ahk
    }
}

; 切换防踢
ToggleAntiKick(*) {
    global isRandomKeyEnabled, randomKeyTimer, lv, config
    isRandomKeyEnabled := !isRandomKeyEnabled

    if isRandomKeyEnabled {
        StartAntiKick(60 * 1000) ; Call the function from Lib\Functions.ahk
    } else {
        if randomKeyTimer {
            SetTimer(randomKeyTimer, 0)
            randomKeyTimer := 0
        }
        lv.Modify(3, "-Check", "防踢状态", config["hotkeys"]["antiKick"], "关闭")
        ToolTip("防踢模式已关闭", 10, 50)
        SetTimer(() => ToolTip(), -1000)
    }
}

; 自动打开箱子
ToggleAutoOpenBox(*) {
    global isAutoOpenBoxEnabled, autoOpenBoxRunning, config
    isAutoOpenBoxEnabled := !isAutoOpenBoxEnabled

    if autoOpenBoxRunning {
        autoOpenBoxRunning := false
    } else {
        StartAutoOpenBox()
        autoOpenBoxRunning := true
    }
}