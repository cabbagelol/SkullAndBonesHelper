; Lib\ConfigHelper.ahk
; 共享配置和快捷键管理助手 - 支持主程序与各独立插件使用

global activePluginHotkeys := Map()

; 获取配置文件根目录路径
GetRootConfigPath(fileName) {
    if FileExist(A_ScriptDir "\" fileName) {
        return A_ScriptDir "\" fileName
    }
    if FileExist(A_ScriptDir "\..\..\" fileName) {
        return A_ScriptDir "\..\..\" fileName
    }
    if FileExist(A_ScriptDir "\Main.ahk") {
        return A_ScriptDir "\" fileName
    }
    return A_ScriptDir "\..\..\" fileName
}

GetAppConfigPath() {
    return GetRootConfigPath("app.config.ini")
}

GetUserConfigPath() {
    return GetRootConfigPath("user.config.ini")
}

; 读取 app.config.ini 配置
GetAppConfig(section, key, defaultValue := "") {
    path := GetAppConfigPath()
    try {
        return IniRead(path, section, key, defaultValue)
    } catch {
        return defaultValue
    }
}

; 写入 app.config.ini 配置
SetAppConfig(section, key, value) {
    path := GetAppConfigPath()
    try {
        IniWrite(value, path, section, key)
        return true
    } catch {
        return false
    }
}

; 读取 user.config.ini 配置
GetUserConfig(section, key, defaultValue := "") {
    path := GetUserConfigPath()
    try {
        return IniRead(path, section, key, defaultValue)
    } catch {
        return defaultValue
    }
}

; 写入 user.config.ini 配置
SetUserConfig(section, key, value) {
    path := GetUserConfigPath()
    try {
        IniWrite(value, path, section, key)
        return true
    } catch {
        return false
    }
}

; 获取插件配置键值映射 (内置插件映射到 [Delays] 段)
GetPluginConfigKey(folderName, section, key) {
    static mapping := Map(
        "AutoClick_Settings_DownDelay", Map("section", "Delays", "key", "Down"),
        "AutoClick_Settings_UpDelay", Map("section", "Delays", "key", "Up"),
        "AutoClick_Settings_AutoClickModel", Map("section", "Delays", "key", "AutoClickModel"),
        "Defense_Settings_DefensePause", Map("section", "Delays", "key", "DefensePause")
    )
    mapKey := folderName "_" section "_" key
    if mapping.Has(mapKey) {
        return mapping[mapKey]
    }
    return Map("section", "Plugin_" folderName "_" section, "key", key)
}

; 获取插件快捷键映射 (内置插件映射到 [Hotkeys] 段)
GetHotkeyConfigKey(folderName, name) {
    keyName := folderName "_" name
    static mapping := Map(
        "AutoClick_autoClick", "AutoClick",
        "AutoOpenBox_autoOpenBox", "AutoOpenBox",
        "Timer_timer", "Timer",
        "AntiKick_antiKick", "AntiKick",
        "PasteChat_pasteChat", "PasteChat",
        "Defense_defense", "Defense"
    )
    if mapping.Has(keyName) {
        return Map("section", "Hotkeys", "key", mapping[keyName])
    }
    return Map("section", "PluginHotkeys", "key", keyName)
}

; 读取插件专属配置 (优先使用映射段，否则迁移至 user.config.ini 存储)
GetPluginConfig(section, key, defaultValue := "") {
    SplitPath(A_ScriptDir, &folderName)
    configKey := GetPluginConfigKey(folderName, section, key)
    return GetUserConfig(configKey["section"], configKey["key"], defaultValue)
}

; 写入插件专属配置
SetPluginConfig(section, key, value) {
    SplitPath(A_ScriptDir, &folderName)
    configKey := GetPluginConfigKey(folderName, section, key)
    return SetUserConfig(configKey["section"], configKey["key"], value)
}

; 注册插件快捷键
RegisterPluginHotkey(name, callback) {
    global activePluginHotkeys
    packPath := A_ScriptDir "\packname.json"

    if !FileExist(packPath) {
        MsgBox("错误: 缺少 packname.json，无法注册快捷键！", "错误", 0x10)
        return false
    }

    ; 读取并解析 json (支持单行/多行，限制最多读取/注册2个快捷键)
    jsonText := FileRead(packPath, "UTF-8")
    hotkeys := []
    
    if RegExMatch(jsonText, '"hotkeys"\s*:\s*\[([^\]]*)\]', &m) {
        hotkeysStr := m[1]
        pos := 1
        while RegExMatch(hotkeysStr, '\{([^\}]+)\}', &objMatch, pos) {
            if (hotkeys.Length >= 2) {
                break
            }
            objStr := objMatch[1]
            hkName := ""
            defaultKey := ""
            if RegExMatch(objStr, '"name"\s*:\s*"([^"]*)"', &nameMatch) {
                hkName := nameMatch[1]
            }
            if RegExMatch(objStr, '"default"\s*:\s*"([^"]*)"', &defaultMatch) {
                defaultKey := defaultMatch[1]
            }
            if (hkName != "") {
                hotkeys.Push(Map("name", hkName, "default", defaultKey))
            }
            pos := objMatch.Pos + objMatch.Len
        }
    }

    ; 查找匹配 of 快捷键名字
    found := false
    defaultKey := ""
    for hk in hotkeys {
        if hk["name"] == name {
            found := true
            defaultKey := hk["default"]
            break
        }
    }

    if !found {
        MsgBox("错误: 快捷键【" name "】未在 packname.json 中配置，限制最多注册前2个配置 of 快捷键！", "错误", 0x10)
        return false
    }

    ; 如果已经存在该热键，先停用旧的
    if activePluginHotkeys.Has(name) {
        try Hotkey(activePluginHotkeys[name], "Off")
    }

    ; 从 user.config.ini 读取用户设置的快捷键
    SplitPath(A_ScriptDir, &folderName)
    configKey := GetHotkeyConfigKey(folderName, name)
    key := GetUserConfig(configKey["section"], configKey["key"], defaultKey)

    if (key == "") {
        return false
    }

    ; 绑定热键
    try {
        Hotkey(key, callback, "On")
        activePluginHotkeys[name] := key
        return key
    } catch as e {
        MsgBox("绑定快捷键【" key "】失败: " e.Message, "错误", 0x10)
        return false
    }
}

; 保存快捷键配置到 user.config.ini
SavePluginHotkey(name, newKey) {
    SplitPath(A_ScriptDir, &folderName)
    configKey := GetHotkeyConfigKey(folderName, name)
    return SetUserConfig(configKey["section"], configKey["key"], newKey)
}

; 判断游戏窗口是否激活且功能开启
IsGameActive(enabledState := true) {
    return enabledState and (WinActive("ahk_exe skullandbones.exe") or WinActive("Skull and Bones"))
}

ReadPacknameInfo(jsonPath) {
    if !FileExist(jsonPath) {
        return 0
    }
    try {
        jsonText := FileRead(jsonPath, "UTF-8")
        info := Map("name", "", "version", "")
        if RegExMatch(jsonText, '"name"\s*:\s*"([^"]*)"', &m) {
            info["name"] := m[1]
        }
        if RegExMatch(jsonText, '"version"\s*:\s*"([^"]*)"', &m) {
            info["version"] := m[1]
        }
        if (info["name"] = "" || info["version"] = "") {
            return 0
        }
        return info
    } catch {
        return 0
    }
}

; 插件生命周期基础类
class PluginLifecycle {
    name := ""
    version := ""
    isActive := false
    showGui := false
    hotkeyName := ""
    hotkeyCallback := 0

    __New() {
        packPath := A_ScriptDir "\packname.json"
        info := ReadPacknameInfo(packPath)
        if (!info) {
            MsgBox("错误: 无法加载插件！缺少或无效的 packname.json 配置文件。", "错误", 0x10)
            ExitApp()
        }
        this.name := info["name"]
        this.version := info["version"]

        ; 注册周期通知消息
        OnMessage(0x8001, (wp, lp, msg, hwnd) => this.Configure())
        OnMessage(0x8002, (wp, lp, msg, hwnd) => this.HotkeyUpdate())

        ; 解析命令行参数
        for arg in A_Args {
            if (arg = "/show") {
                this.showGui := true
            } else if (arg = "/active") {
                this.isActive := true
            } else if (arg = "/update") {
                this.Update()
                ExitApp()
            } else if (arg = "/uninstall") {
                this.Uninstall()
                ExitApp()
            }
        }
    }

    ; 1. 初始化生命周期
    Init() {
        ; 由子类覆盖重写，做配置读取、GUI初始化、快捷键绑定等
    }

    ; 2. 运行生命周期
    Run() {
        this.isActive := true
        SplitPath(A_ScriptDir, &folderName)
        SetUserConfig("PluginStatus", folderName, "1")
    }

    ; 3. 关闭生命周期
    Close() {
        this.isActive := false
        SplitPath(A_ScriptDir, &folderName)
        SetUserConfig("PluginStatus", folderName, "0")
        if (!this.showGui) {
            ExitApp()
        }
    }

    ; 切换开启/关闭状态
    Toggle() {
        if this.isActive {
            this.Close()
        } else {
            this.Run()
        }
    }

    ; 双击配置周期通知
    Configure() {
        this.showGui := true
        if this.myGui {
            this.myGui.Show("Center")
        }
    }

    ; 快捷键更新周期通知
    HotkeyUpdate() {
        global activePluginHotkeys
        if (this.hotkeyName = "" || !this.hotkeyCallback) {
            return
        }
        
        ; 移除旧快捷键触发
        if activePluginHotkeys.Has(this.hotkeyName) {
            oldKey := activePluginHotkeys[this.hotkeyName]
            try Hotkey(oldKey, "Off")
        }
        
        ; 注册新快捷键
        newKey := RegisterPluginHotkey(this.hotkeyName, this.hotkeyCallback)
        if (newKey) {
            this.pluginHotkey := newKey
            ; 采用正则防御替换，不破坏原状态字符格式
            if this.statusText {
                currentVal := this.statusText.Value
                if RegExMatch(currentVal, "i)快捷键:\s*(.*)", &m) {
                    this.statusText.Value := StrReplace(currentVal, "快捷键: " m[1], "快捷键: " newKey)
                }
            }
            if this.hotkeyCtrl {
                this.hotkeyCtrl.Value := newKey
            }
        }
    }

    ; 4. 更新生命周期
    Update() {
        ; 可由子类覆盖重写，用于版本升级更新
    }

    ; 5. 卸载生命周期
    Uninstall() {
        ; 可由子类覆盖重写，用于清理注册配置
    }
}
