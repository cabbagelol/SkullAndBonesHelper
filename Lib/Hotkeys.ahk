; Lib\Hotkeys.ahk

global registeredMainHotkeys := Map(
    "autoClick", "",
    "autoOpenBox", "",
    "timer", "",
    "antiKick", "",
    "pasteChat", "",
    "defense", ""
)

; 应用热键
ApplyHotkeys() {
    global config, registeredMainHotkeys

    ; 1. 关停所有之前由主程序物理注册的旧热键，防止传递与残留
    for name, key in registeredMainHotkeys {
        if (key != "") {
            try Hotkey(key, "Off")
            registeredMainHotkeys[name] := ""
        }
    }

    ; 2. 根据插件运行状态，绑定新热键或向运行中的插件发送更新通知
    
    ; 左键自动
    if (!IsPluginRunning("AutoClick")) {
        key := config["hotkeys"]["autoClick"]
        if (IsValidHotkey(key, ["LButton"])) {
            try {
                Hotkey(key, HotkeyTrigger_AutoClick, "On")
                registeredMainHotkeys["autoClick"] := key
            }
        }
    } else {
        NotifyPluginHotkeyUpdate("AutoClick")
    }

    ; 自动打开箱子
    if (!IsPluginRunning("AutoOpenBox")) {
        key := config["hotkeys"]["autoOpenBox"]
        if (IsValidHotkey(key)) {
            try {
                Hotkey(key, HotkeyTrigger_AutoOpenBox, "On")
                registeredMainHotkeys["autoOpenBox"] := key
            }
        }
    } else {
        NotifyPluginHotkeyUpdate("AutoOpenBox")
    }

    ; 计时器
    if (!IsPluginRunning("Timer")) {
        key := config["hotkeys"]["timer"]
        if (IsValidHotkey(key)) {
            try {
                Hotkey(key, HotkeyTrigger_Timer, "On")
                registeredMainHotkeys["timer"] := key
            }
        }
    } else {
        NotifyPluginHotkeyUpdate("Timer")
    }

    ; 防踢状态
    if (!IsPluginRunning("AntiKick")) {
        key := config["hotkeys"]["antiKick"]
        if (IsValidHotkey(key)) {
            try {
                Hotkey(key, HotkeyTrigger_AntiKick, "On")
                registeredMainHotkeys["antiKick"] := key
            }
        }
    } else {
        NotifyPluginHotkeyUpdate("AntiKick")
    }

    ; 粘贴聊天
    if (!IsPluginRunning("PasteChat")) {
        key := config["hotkeys"]["pasteChat"]
        if (IsValidHotkey(key)) {
            try {
                Hotkey(key, HotkeyTrigger_PasteChat, "On")
                registeredMainHotkeys["pasteChat"] := key
            }
        }
    } else {
        NotifyPluginHotkeyUpdate("PasteChat")
    }

    ; 间歇防御
    if (!IsPluginRunning("Defense")) {
        key := config["hotkeys"]["defense"]
        if (IsValidHotkey(key)) {
            try {
                Hotkey(key, HotkeyTrigger_Defense, "On")
                registeredMainHotkeys["defense"] := key
            }
        }
    } else {
        NotifyPluginHotkeyUpdate("Defense")
    }
}

; 检查热键是否有效
IsValidHotkey(hotkey, excludeList := []) {
    ; 检查是否在排除列表中
    for exclude in excludeList {
        if (hotkey = exclude) {
            return false
        }
    }

    ; 检查是否为空
    if (hotkey = "") {
        return false
    }

    return true
}

; 向指定运行中的插件发送快捷键热重载通知 (周期消息 0x8002)
NotifyPluginHotkeyUpdate(pluginFolderName) {
    global pluginList
    if !pluginList.Has(pluginFolderName) {
        return
    }
    pluginTitle := pluginList[pluginFolderName]["name"] " v" pluginList[pluginFolderName]["version"]
    
    DetectHiddenWindows(true)
    if WinExist(pluginTitle) {
        PostMessage(0x8002, 0, 0, , pluginTitle)
    }
}

; --- 快捷按键触发器 (当插件未运行，按下热键时，在后台启动并立即激活功能，不显示GUI) ---

HotkeyTrigger_AutoClick(*) {
    StartPlugin("AutoClick", "/active")
}

HotkeyTrigger_Timer(*) {
    StartPlugin("Timer", "/active")
}

HotkeyTrigger_AntiKick(*) {
    StartPlugin("AntiKick", "/active")
}

HotkeyTrigger_AutoOpenBox(*) {
    StartPlugin("AutoOpenBox", "/active")
}

HotkeyTrigger_PasteChat(*) {
    StartPlugin("PasteChat", "/active")
}

HotkeyTrigger_Defense(*) {
    StartPlugin("Defense", "/active")
}

; --- 界面操作切换器 (菜单栏点击或列表双击触发，显示或唤醒配置GUI) ---

ToggleAutoClick(*) {
    if IsPluginRunning("AutoClick") {
        ShowPluginGui("AutoClick")
    } else {
        StartPlugin("AutoClick", "/show")
    }
}

ToggleTimer(*) {
    if IsPluginRunning("Timer") {
        ShowPluginGui("Timer")
    } else {
        StartPlugin("Timer", "/show")
    }
}

ToggleAntiKick(*) {
    if IsPluginRunning("AntiKick") {
        ShowPluginGui("AntiKick")
    } else {
        StartPlugin("AntiKick", "/show")
    }
}

ToggleAutoOpenBox(*) {
    if IsPluginRunning("AutoOpenBox") {
        ShowPluginGui("AutoOpenBox")
    } else {
        StartPlugin("AutoOpenBox", "/show")
    }
}

TogglePasteChat(*) {
    if IsPluginRunning("PasteChat") {
        ShowPluginGui("PasteChat")
    } else {
        StartPlugin("PasteChat", "/show")
    }
}

ToggleDefense(*) {
    if IsPluginRunning("Defense") {
        ShowPluginGui("Defense")
    } else {
        StartPlugin("Defense", "/show")
    }
}
