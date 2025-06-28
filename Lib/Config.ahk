; Lib\Config.ahk

; 加载配置
LoadConfig() {
    global configFile, config

    if FileExist(configFile) {
        try {
            config["hotkeys"]["autoClick"] := IniRead(configFile, "Hotkeys", "AutoClick", config["hotkeys"]["autoClick"])
            config["hotkeys"]["autoOpenBox"] := IniRead(configFile, "Hotkeys", "AutoOpenBox", config["hotkeys"]["autoOpenBox"])
            config["hotkeys"]["timer"] := IniRead(configFile, "Hotkeys", "Timer", config["hotkeys"]["timer"])
            config["hotkeys"]["antiKick"] := IniRead(configFile, "Hotkeys", "AntiKick", config["hotkeys"]["antiKick"])

            config["delays"]["down"] := IniRead(configFile, "Delays", "Down", config["delays"]["down"])
            config["delays"]["up"] := IniRead(configFile, "Delays", "Up", config["delays"]["up"])

            config["app"]["version"] := IniRead(configFile, "App", "Version", config["app"]["version"])
            config["app"]["isAutoClickAltStopEnabled"] := IniRead(configFile, "App", "IsAutoClickAltStopEnabled", config["app"]["isAutoClickAltStopEnabled"])
        } catch {
            FileDelete(configFile)
            MsgBox("配置文件加载失败或已损坏，已重置为默认设置。", "警告", 0x30)
        }
    }
}

; 保存配置
SaveConfig() {
    global configFile, config

    try {
        IniWrite(config["hotkeys"]["autoClick"], configFile, "Hotkeys", "AutoClick")
        IniWrite(config["hotkeys"]["autoOpenBox"], configFile, "Hotkeys", "AutoOpenBox")
        IniWrite(config["hotkeys"]["timer"], configFile, "Hotkeys", "Timer")
        IniWrite(config["hotkeys"]["antiKick"], configFile, "Hotkeys", "AntiKick")

        IniWrite(config["delays"]["down"], configFile, "Delays", "Down")
        IniWrite(config["delays"]["up"], configFile, "Delays", "Up")

        IniWrite(config["app"]["version"], configFile, "App", "Version")
        IniWrite(config["app"]["isAutoClickAltStopEnabled"], configFile, "App", "IsAutoClickAltStopEnabled")
    } catch as e {
        MsgBox("保存配置失败: " e.Message, "错误", 0x10)
    }
}