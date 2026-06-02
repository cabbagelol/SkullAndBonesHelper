; Lib\About.ahk

; 关于对话框
ShowAbout(*) {
    global MainGui, AboutGui, appConfigFile, config ; Ensure AboutGui is global

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
    localVersion := IniRead(appConfigFile, "App", "version", config["app"]["version"])
    AboutGui.Add("Text", "xp y+2", "版本 " localVersion)

    AboutGui.Add("Text", "x20 y+10 w300 0x10")

    AboutGui.SetFont("s9")
    AboutGui.Add("Text", "x20 y+10", "这是一个用AutoHotkey编写的")
    AboutGui.Add("Text", "x20 y+5", "脚本，通过模拟输入端实现功能。")
    AboutGui.Add("Text", "x20 y+5", "By cabbagelol")

    ; 添加检查更新按钮
    AboutGui.Add("Button", "x20 y+20 w80 h30 Default", "检查更新").OnEvent("Click", (*) => CheckForUpdate(true))
    chk := AboutGui.Add("Checkbox", "x+15 yp+5 Checked" (config["app"]["isInitialCheckVersion"] ? "1" : "0"), "启动时自动检查更新")
    chk.OnEvent("Click", (chkCtrl, *) => (
        config["app"]["isInitialCheckVersion"] := chkCtrl.Value = 1,
        SaveConfig()
    ))

    AboutGui.Show("AutoSize Center")
}

; 检查更新 (异步，不阻塞主线程)
CheckForUpdate(isTip) {
    global appConfigFile, config
    
    ; 使用静态变量，保持异步请求对象在函数执行完后依然存活
    static whr := ""
    
    try {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        ; 第三个参数为 true 表示异步请求
        whr.Open("GET", "https://raw.githubusercontent.com/cabbagelol/SkullAndBonesHelper/refs/heads/version/version.txt", true)
        whr.Send()
        
        ; 开启定时器轮询状态，不卡顿主线程
        SetTimer(CheckResponse, 100)
    } catch as e {
        if isTip {
            MsgBox("检查更新时出错: " e.Message, "错误", "16")
        }
    }
    
    CheckResponse() {
        try {
            ; 检查请求是否完成 (WaitForResponse(0) 返回 true 表示已完成)
            if (!whr.WaitForResponse(0)) {
                return
            }
            ; 关闭定时器
            SetTimer(CheckResponse, 0)
            
            if (whr.Status == 200) {
                remoteVersion := Trim(whr.ResponseText)
                localVersion := IniRead(appConfigFile, "App", "version", config["app"]["version"])
                if (CompareVersions(remoteVersion, localVersion) > 0) {
                    result := MsgBox("发现新版本 " remoteVersion " (当前版本 " localVersion ")`n`n是否要前往GitHub下载更新?", "更新可用", "YesNo 64")
                    if (result == "Yes") {
                        Run("https://github.com/cabbagelol/SkullAndBonesHelper")
                    }
                } else {
                    if isTip {
                        MsgBox("当前已是最新版本。", "检查更新", "64")
                    }
                }
            } else {
                if isTip {
                    MsgBox("无法下载版本信息文件，HTTP状态码: " whr.Status, "错误", "16")
                }
            }
        } catch as e {
            SetTimer(CheckResponse, 0)
            if isTip {
                MsgBox("检查更新时出错: " e.Message, "错误", "16")
            }
        }
    }
}

; 比较版本号函数 (格式如 1.2.3)
CompareVersions(v1, v2) {
    ; 移除可能的非数字字符
    v1 := RegExReplace(v1, "[^\d.]")
    v2 := RegExReplace(v2, "[^\d.]")

    a := StrSplit(v1, ".")
    b := StrSplit(v2, ".")

    loop Max(a.Length, b.Length) {
        ; 将每部分转换为整数
        num1 := a.Has(A_Index) ? Integer(a[A_Index]) : 0
        num2 := b.Has(A_Index) ? Integer(b[A_Index]) : 0

        if (num1 > num2)
            return 1
        if (num1 < num2)
            return -1
    }
    return 0
}