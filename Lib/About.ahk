; Lib\About.ahk

; 关于对话框
ShowAbout(*) {
    global MainGui, AboutGui, configFile, config ; Ensure AboutGui is global

    AboutGui := Gui("+ToolWindow +Border +Owner" MainGui.Hwnd, "关于")
    AboutGui.OnEvent("Close", (*) => AboutGui.Destroy()) ; Make sure it destroys itself
    AboutGui.MarginX := 20
    AboutGui.MarginY := 20

    try {
        AboutGui.Add("Picture", "w32 h32", "UI_Main_Icon.ico")
    } catch {
        AboutGui.Add("Picture", "w32 h32 Icon1", A_AhkPath)
    }

    AboutGui.SetFont("s12 bold")
    AboutGui.Add("Text", "xp+40 yp", "Skull and Bones 小助手")
    AboutGui.SetFont("s10 norm")
    AboutGui.Add("Text", "xp y+2", "版本 " IniRead(configFile, "App", "version", config["app"]["version"]))

    AboutGui.Add("Text", "x20 y+10 w300 0x10")

    AboutGui.SetFont("s9")
    AboutGui.Add("Text", "x20 y+10", "这是一个用AutoHotkey编写的")
    AboutGui.Add("Text", "x20 y+5", "脚本，通过模拟输入端实现功能。")
    AboutGui.Add("Text", "x20 y+5", "By cabbagelol")

    AboutGui.Show("AutoSize Center")
}