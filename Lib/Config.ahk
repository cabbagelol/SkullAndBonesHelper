; Lib\Config.ahk
; 配置读取与保存模块 - 封装底层配置文件访问

; 加载配置
LoadConfig() {
    global config

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

    ; 使用公共配置助手加载配置
    config["hotkeys"]["autoClick"] := GetUserConfig("Hotkeys", "AutoClick", config["hotkeys"]["autoClick"])
    config["hotkeys"]["autoOpenBox"] := GetUserConfig("Hotkeys", "AutoOpenBox", config["hotkeys"]["autoOpenBox"])
    config["hotkeys"]["timer"] := GetUserConfig("Hotkeys", "Timer", config["hotkeys"]["timer"])
    config["hotkeys"]["antiKick"] := GetUserConfig("Hotkeys", "AntiKick", config["hotkeys"]["antiKick"])
    config["hotkeys"]["pasteChat"] := GetUserConfig("Hotkeys", "PasteChat", config["hotkeys"]["pasteChat"])
    config["hotkeys"]["defense"] := GetUserConfig("Hotkeys", "Defense", config["hotkeys"]["defense"])

    config["delays"]["down"] := GetUserConfig("Delays", "Down", config["delays"]["down"])
    config["delays"]["up"] := GetUserConfig("Delays", "Up", config["delays"]["up"])
    config["delays"]["autoClickModel"] := GetUserConfig("Delays", "AutoClickModel", config["delays"]["autoClickModel"])
    config["delays"]["defensePause"] := GetUserConfig("Delays", "DefensePause", config["delays"]["defensePause"])

    config["app"]["version"] := GetAppConfig("App", "Version", config["app"]["version"])
    config["app"]["isAutoClickAltStopEnabled"] := GetAppConfig("App", "IsAutoClickAltStopEnabled", config["app"]["isAutoClickAltStopEnabled"])
    config["app"]["isInitialCheckVersion"] := GetAppConfig("App", "IsInitialCheckVersion", config["app"]["isInitialCheckVersion"])
}

; 保存配置
SaveConfig() {
    global config

    ; 使用公共配置助手保存配置
    SetUserConfig("Hotkeys", "AutoClick", config["hotkeys"]["autoClick"])
    SetUserConfig("Hotkeys", "AutoOpenBox", config["hotkeys"]["autoOpenBox"])
    SetUserConfig("Hotkeys", "Timer", config["hotkeys"]["timer"])
    SetUserConfig("Hotkeys", "AntiKick", config["hotkeys"]["antiKick"])
    SetUserConfig("Hotkeys", "PasteChat", config["hotkeys"]["pasteChat"])
    SetUserConfig("Hotkeys", "Defense", config["hotkeys"]["defense"])

    SetUserConfig("Delays", "Down", config["delays"]["down"])
    SetUserConfig("Delays", "Up", config["delays"]["up"])
    SetUserConfig("Delays", "AutoClickModel", config["delays"]["autoClickModel"])
    SetUserConfig("Delays", "DefensePause", config["delays"]["defensePause"])

    SetAppConfig("App", "Version", config["app"]["version"])
    SetAppConfig("App", "IsAutoClickAltStopEnabled", config["app"]["isAutoClickAltStopEnabled"])
    SetAppConfig("App", "IsInitialCheckVersion", config["app"]["isInitialCheckVersion"])
}