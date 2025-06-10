; Lib\Resources.ahk

; 检查资源文件
CheckResources() {
    if !FileExist("UI_Main_Icon.ico") {
        MsgBox("图标文件 UI_Main_Icon.ico 不存在！", "资源缺失", 0x30)
    }
    if !FileExist("UI_MainMenu_Background.png") {
        MsgBox("背景图片 UI_MainMenu_Background.png 不存在！", "资源缺失", 0x30)
    }
}