; Lib\Hotkeys.ahk
; 热键绑定管理模块 - 支持物理热键的动态绑定与热重载

global registeredMainHotkeys := Map()  ; 存储已注册的物理热键 ("folderName_hkName" => "hotkeyString")

; 动态应用热键
ApplyHotkeys() {
    global config, registeredMainHotkeys, pluginList

    ; 1. 关停所有之前由主程序物理注册的旧热键，防止残留与按键冲突
    for keyName, hotkeyStr in registeredMainHotkeys.Clone() {
        if (hotkeyStr != "") {
            try Hotkey(hotkeyStr, "Off")
        }
    }
    registeredMainHotkeys.Clear()

    ; 2. 动态遍历所有扫描到的插件，并根据运行状态绑定热键或发送通知
    for folderName, info in pluginList {
        if !info.Has("hotkeys") {
            continue
        }

        isProcessRunning := IsPluginRunning(folderName)

        for hk in info["hotkeys"] {
            hkName := hk["name"]
            defaultKey := hk["default"]

            ; 获取对应的配置段和键
            configKey := GetHotkeyConfigKey(folderName, hkName)
            userKey := GetUserConfig(configKey["section"], configKey["key"], defaultKey)

            if (userKey = "") {
                continue
            }

            if (!isProcessRunning) {
                ; 特殊排除规则：如果是左键自动插件（AutoClick）下的 autoClick 热键，且设定为 LButton，则不能被物理热键注册，避免直接拦截左键。
                excludeList := (folderName = "AutoClick" && hkName = "autoClick") ? ["LButton"] : []
                if (IsValidHotkey(userKey, excludeList)) {
                    try {
                        ; 使用闭包创建通用的激活函数并传参
                        targetFolder := folderName
                        triggerFunc := (*) => StartPlugin(targetFolder, "/active")
                        Hotkey(userKey, triggerFunc, "On")
                        registeredMainHotkeys[folderName "_" hkName] := userKey
                    }
                }
            } else {
                ; 插件正在运行，向其发送快捷键热重载的周期消息 (0x8002)
                NotifyPluginHotkeyUpdate(folderName)
            }
        }
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
