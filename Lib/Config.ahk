; Lib\Config.ahk

; 加载配置
LoadConfig() {
    global userConfigFile, appConfigFile, config

    oldConfigFile := A_ScriptDir "\config.ini"

    ; 自动迁移旧版本 config.ini 配置文件
    if FileExist(oldConfigFile) {
        try {
            config["hotkeys"]["autoClick"] := IniRead(oldConfigFile, "Hotkeys", "AutoClick", config["hotkeys"]["autoClick"])
            config["hotkeys"]["autoOpenBox"] := IniRead(oldConfigFile, "Hotkeys", "AutoOpenBox", config["hotkeys"]["autoOpenBox"])
            config["hotkeys"]["timer"] := IniRead(oldConfigFile, "Hotkeys", "Timer", config["hotkeys"]["timer"])
            config["hotkeys"]["antiKick"] := IniRead(oldConfigFile, "Hotkeys", "AntiKick", config["hotkeys"]["antiKick"])
            config["hotkeys"]["pasteChat"] := IniRead(oldConfigFile, "Hotkeys", "PasteChat", config["hotkeys"]["pasteChat"])
            config["hotkeys"]["defense"] := IniRead(oldConfigFile, "Hotkeys", "Defense", config["hotkeys"]["defense"])

            config["delays"]["down"] := IniRead(oldConfigFile, "Delays", "Down", config["delays"]["down"])
            config["delays"]["up"] := IniRead(oldConfigFile, "Delays", "Up", config["delays"]["up"])
            config["delays"]["autoClickModel"] := IniRead(oldConfigFile, "Delays", "AutoClickModel", config["delays"]["autoClickModel"])
            config["delays"]["defensePause"] := IniRead(oldConfigFile, "Delays", "DefensePause", config["delays"]["defensePause"])

            config["app"]["version"] := IniRead(oldConfigFile, "App", "Version", config["app"]["version"])
            config["app"]["isAutoClickAltStopEnabled"] := IniRead(oldConfigFile, "App", "IsAutoClickAltStopEnabled", config["app"]["isAutoClickAltStopEnabled"])
            config["app"]["isInitialCheckVersion"] := IniRead(oldConfigFile, "App", "IsInitialCheckVersion", config["app"]["isInitialCheckVersion"])

            ; 写入新配置文件
            SaveConfig()

            ; 删除旧配置文件
            FileDelete(oldConfigFile)
        } catch {
            try FileDelete(oldConfigFile)
        }
        return
    }

    if FileExist(userConfigFile) {
        try {
            config["hotkeys"]["autoClick"] := IniRead(userConfigFile, "Hotkeys", "AutoClick", config["hotkeys"]["autoClick"])
            config["hotkeys"]["autoOpenBox"] := IniRead(userConfigFile, "Hotkeys", "AutoOpenBox", config["hotkeys"]["autoOpenBox"])
            config["hotkeys"]["timer"] := IniRead(userConfigFile, "Hotkeys", "Timer", config["hotkeys"]["timer"])
            config["hotkeys"]["antiKick"] := IniRead(userConfigFile, "Hotkeys", "AntiKick", config["hotkeys"]["antiKick"])
            config["hotkeys"]["pasteChat"] := IniRead(userConfigFile, "Hotkeys", "PasteChat", config["hotkeys"]["pasteChat"])
            config["hotkeys"]["defense"] := IniRead(userConfigFile, "Hotkeys", "Defense", config["hotkeys"]["defense"])

            config["delays"]["down"] := IniRead(userConfigFile, "Delays", "Down", config["delays"]["down"])
            config["delays"]["up"] := IniRead(userConfigFile, "Delays", "Up", config["delays"]["up"])
            config["delays"]["autoClickModel"] := IniRead(userConfigFile, "Delays", "AutoClickModel", config["delays"]["autoClickModel"])
            config["delays"]["defensePause"] := IniRead(userConfigFile, "Delays", "DefensePause", config["delays"]["defensePause"])
        } catch {
            try FileDelete(userConfigFile)
            MsgBox("用户配置文件加载失败或已损坏，已重置为默认设置。", "警告", 0x30)
        }
    }

    if FileExist(appConfigFile) {
        try {
            config["app"]["version"] := IniRead(appConfigFile, "App", "Version", config["app"]["version"])
            config["app"]["isAutoClickAltStopEnabled"] := IniRead(appConfigFile, "App", "IsAutoClickAltStopEnabled", config["app"]["isAutoClickAltStopEnabled"])
            config["app"]["isInitialCheckVersion"] := IniRead(appConfigFile, "App", "IsInitialCheckVersion", config["app"]["isInitialCheckVersion"])
        } catch {
            try FileDelete(appConfigFile)
            MsgBox("程序配置文件加载失败或已损坏，已重置为默认设置。", "警告", 0x30)
        }
    }
}

; 保存配置
SaveConfig() {
    global userConfigFile, appConfigFile, config

    try {
        IniWrite(config["hotkeys"]["autoClick"], userConfigFile, "Hotkeys", "AutoClick")
        IniWrite(config["hotkeys"]["autoOpenBox"], userConfigFile, "Hotkeys", "AutoOpenBox")
        IniWrite(config["hotkeys"]["timer"], userConfigFile, "Hotkeys", "Timer")
        IniWrite(config["hotkeys"]["antiKick"], userConfigFile, "Hotkeys", "AntiKick")
        IniWrite(config["hotkeys"]["pasteChat"], userConfigFile, "Hotkeys", "PasteChat")
        IniWrite(config["hotkeys"]["defense"], userConfigFile, "Hotkeys", "Defense")

        IniWrite(config["delays"]["down"], userConfigFile, "Delays", "Down")
        IniWrite(config["delays"]["up"], userConfigFile, "Delays", "Up")
        IniWrite(config["delays"]["autoClickModel"], userConfigFile, "Delays", "AutoClickModel")
        IniWrite(config["delays"]["defensePause"], userConfigFile, "Delays", "DefensePause")

        IniWrite(config["app"]["version"], appConfigFile, "App", "Version")
        IniWrite(config["app"]["isAutoClickAltStopEnabled"], appConfigFile, "App", "IsAutoClickAltStopEnabled")
        IniWrite(config["app"]["isInitialCheckVersion"], appConfigFile, "App", "IsInitialCheckVersion")
    } catch as e {
        MsgBox("保存配置失败: " e.Message, "错误", 0x10)
    }
}