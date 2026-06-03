; Lib\PluginManager.ahk
; 插件管理器模块 - 负责插件的扫描、加载、启停、导入和卸载

; --- 全局变量 ---
global pluginList := Map()          ; 存储所有插件信息 (插件文件夹名 => 信息Map)
global pluginProcesses := Map()     ; 存储运行中的插件进程PID (插件文件夹名 => PID)
global pluginDir := A_ScriptDir "\Public"  ; 插件根目录
global pluginManagerGui := 0        ; 插件管理GUI句柄
global pluginLv := 0                ; 插件列表控件

IsPluginRunning(pluginFolderName) {
    global pluginProcesses
    if pluginProcesses.Has(pluginFolderName) {
        pid := pluginProcesses[pluginFolderName]
        return ProcessExist(pid) != 0
    }
    return false
}

ShowPluginGui(pluginFolderName) {
    global pluginList
    if !pluginList.Has(pluginFolderName) {
        return
    }
    pluginTitle := pluginList[pluginFolderName]["name"] " v" pluginList[pluginFolderName]["version"]

    DetectHiddenWindows(true)
    if WinExist(pluginTitle) {
        PostMessage(0x8001, 0, 0, , pluginTitle)
    }
}

global pluginActiveStates := Map()

IsPluginActive(pluginFolderName) {
    if IsPluginRunning(pluginFolderName) {
        return GetUserConfig("PluginStatus", pluginFolderName, "0") = "1"
    }
    return false
}

MonitorPlugins() {
    global pluginProcesses, pluginList, pluginActiveStates
    changed := false

    ; 检查已停止的进程
    for folderName, pid in pluginProcesses.Clone() {
        if !ProcessExist(pid) {
            pluginProcesses.Delete(folderName)
            if pluginList.Has(folderName) {
                pluginList[folderName]["status"] := "已停止"
            }
            SetUserConfig("PluginStatus", folderName, "0")
            changed := true
        }
    }

    ; 检查激活状态是否改变
    for folderName, info in pluginList {
        currentActive := IsPluginActive(folderName)
        lastActive := pluginActiveStates.Has(folderName) ? pluginActiveStates[folderName] : false
        if (currentActive != lastActive) {
            pluginActiveStates[folderName] := currentActive
            changed := true
        }
    }

    if changed {
        ApplyHotkeys()
        UpdateFunctionList()
        RefreshPluginListView()
    }
}

; ============================================================
; 插件扫描与加载
; ============================================================

/*
 * 扫描 public/ 目录下所有插件，读取 packname.json 信息
 * 将有效插件记录到全局 pluginList 中
*/
LoadPlugins() {
    global pluginList, pluginDir

    ; 确保插件目录存在
    if !DirExist(pluginDir) {
        DirCreate(pluginDir)
    }

    ; 清空现有列表
    pluginList := Map()

    ; 遍历 public/ 下的所有子目录
    loop files pluginDir "\*", "D" {
        folderName := A_LoopFileName
        pluginPath := A_LoopFileFullPath

        ; 检查必要文件是否存在
        mainFile := pluginPath "\main.ahk"
        packFile := pluginPath "\packname.json"

        if !FileExist(mainFile) || !FileExist(packFile) {
            continue  ; 跳过不完整的插件
        }

        ; 读取插件信息
        info := ReadPluginInfo(packFile)
        if !info {
            continue  ; 跳过无法解析的插件
        }

        ; 记录插件文件夹路径
        info["folderPath"] := pluginPath
        info["folderName"] := folderName

        ; 检查该插件是否已在运行（通过PID判断）
        if pluginProcesses.Has(folderName) {
            pid := pluginProcesses[folderName]
            if ProcessExist(pid) {
                info["status"] := "运行中"
            } else {
                pluginProcesses.Delete(folderName)
                info["status"] := "已停止"
            }
        } else {
            info["status"] := "已停止"
        }

        pluginList[folderName] := info
    }
}

/*
 * 解析 packname.json 文件，返回包含插件信息的 Map
 * 格式: { "name", "version", "author", "description", "updateDate", "updateUrls" }
 * 返回 0 表示解析失败
*/
ReadPluginInfo(jsonPath) {
    try {
        jsonText := FileRead(jsonPath, "UTF-8")

        ; 简易 JSON 解析器
        info := Map()

        ; 解析字符串字段
        for _, key in ["name", "version", "author", "description", "updateDate"] {
            if RegExMatch(jsonText, '"' key '"\s*:\s*"([^"]*)"', &m) {
                info[key] := m[1]
            } else {
                info[key] := ""
            }
        }

        ; 解析布尔控制字段 (默认均为 true)
        for _, key in ["visible", "uninstallable", "closable", "runnable"] {
            if RegExMatch(jsonText, '"' key '"\s*:\s*(true|false)', &m) {
                info[key] := (m[1] = "true")
            } else {
                info[key] := true
            }
        }

        ; 解析 updateUrls 数组
        info["updateUrls"] := []
        if RegExMatch(jsonText, '"updateUrls"\s*:\s*\[([^\]]*)\]', &m) {
            urlsStr := m[1]
            pos := 1
            while RegExMatch(urlsStr, '"([^"]*)"', &urlMatch, pos) {
                info["updateUrls"].Push(urlMatch[1])
                pos := urlMatch.Pos + urlMatch.Len
            }
        }

        ; 解析 hotkeys 数组
        info["hotkeys"] := ParsePluginHotkeys(jsonText)

        ; 验证必要字段
        if info["name"] = "" {
            return 0
        }

        return info
    } catch as e {
        return 0
    }
}

; ============================================================
; 插件启停控制
; ============================================================

/*
 * 启动指定插件（以独立 AHK 进程方式运行）
 * pluginFolderName: 插件在 public/ 下的文件夹名
*/
StartPlugin(pluginFolderName, params := "/show") {
    global pluginList, pluginProcesses, pluginDir

    if !pluginList.Has(pluginFolderName) {
        MsgBox("插件 " pluginFolderName " 不存在！", "错误", 0x10)
        return false
    }

    ; 检查是否已在运行
    if pluginProcesses.Has(pluginFolderName) {
        pid := pluginProcesses[pluginFolderName]
        if ProcessExist(pid) {
            if (params = "/show") {
                ShowPluginGui(pluginFolderName)
            }
            return true
        }
    }

    mainFile := pluginDir "\" pluginFolderName "\main.ahk"
    if !FileExist(mainFile) {
        MsgBox("插件入口文件 main.ahk 不存在！", "错误", 0x10)
        return false
    }

    try {
        ; 使用 Run 启动插件脚本为独立进程，并附带参数
        Run(A_AhkPath ' "' mainFile '" ' params, , , &pid)
        pluginProcesses[pluginFolderName] := pid
        pluginList[pluginFolderName]["status"] := "运行中"

        ApplyHotkeys()
        UpdateFunctionList()
        return true
    } catch as e {
        MsgBox("启动插件失败: " e.Message, "错误", 0x10)
        return false
    }
}

/*
 * 停止指定插件（终止其进程）
 * pluginFolderName: 插件在 public/ 下的文件夹名
*/
StopPlugin(pluginFolderName) {
    global pluginList, pluginProcesses

    if !pluginProcesses.Has(pluginFolderName) {
        return false
    }

    pid := pluginProcesses[pluginFolderName]

    try {
        if ProcessExist(pid) {
            ProcessClose(pid)
        }
    }

    pluginProcesses.Delete(pluginFolderName)

    if pluginList.Has(pluginFolderName) {
        pluginList[pluginFolderName]["status"] := "已停止"
    }

    ToolTip("插件已停止", 10, 50)
    SetTimer(() => ToolTip(), -2000)
    ApplyHotkeys()
    UpdateFunctionList()
    return true
}

; ============================================================
; 插件导入
; ============================================================

/*
 * 弹出文件夹选择对话框，验证插件结构后复制到 public/ 目录
*/
ImportPlugin() {
    global pluginDir

    ; 弹出文件夹选择对话框
    selectedFolder := DirSelect("*" A_ScriptDir, 3, "选择插件文件夹 (需包含 main.ahk 和 packname.json)")

    if selectedFolder = "" {
        return  ; 用户取消选择
    }

    ; 验证插件结构
    if !FileExist(selectedFolder "\main.ahk") {
        MsgBox("所选文件夹中缺少 main.ahk 入口文件！", "导入失败", 0x10)
        return
    }

    if !FileExist(selectedFolder "\packname.json") {
        MsgBox("所选文件夹中缺少 packname.json 配置文件！", "导入失败", 0x10)
        return
    }

    ; 读取插件信息进行验证
    info := ReadPluginInfo(selectedFolder "\packname.json")
    if !info {
        MsgBox("packname.json 格式无效或缺少必要字段（name）！", "导入失败", 0x10)
        return
    }

    ; 获取文件夹名作为插件目录名
    SplitPath(selectedFolder, &folderName)

    targetDir := pluginDir "\" folderName

    ; 检查是否已存在同名插件
    if DirExist(targetDir) {
        result := MsgBox("插件目录 " folderName " 已存在，是否覆盖？", "确认覆盖", "YesNo 48")
        if result != "Yes" {
            return
        }
        ; 先停止运行中的同名插件
        if pluginProcesses.Has(folderName) {
            StopPlugin(folderName)
        }
        try DirDelete(targetDir, true)
    }

    ; 复制插件文件夹到 public/ 目录
    try {
        DirCopy(selectedFolder, targetDir)

        ; 刷新插件列表
        LoadPlugins()
        UpdateFunctionList()

        MsgBox("插件「" info["name"] "」(v" info["version"] ") 导入成功！", "导入完成", 0x40)

        ; 如果插件管理窗口已打开，刷新列表
        RefreshPluginListView()
    } catch as e {
        MsgBox("导入插件失败: " e.Message, "错误", 0x10)
    }
}

; ============================================================
; 插件卸载
; ============================================================

/*
 * 停止并删除指定插件
 * pluginFolderName: 插件在 public/ 下的文件夹名
*/
UninstallPlugin(pluginFolderName) {
    global pluginList, pluginProcesses, pluginDir

    if !pluginList.Has(pluginFolderName) {
        return
    }

    pluginName := pluginList[pluginFolderName]["name"]
    result := MsgBox("确定要卸载插件「" pluginName "」吗？`n`n此操作将删除插件的所有文件，无法恢复！", "确认卸载", "YesNo 48")

    if result != "Yes" {
        return
    }

    ; 先停止插件
    StopPlugin(pluginFolderName)

    ; 运行卸载生命周期，让插件清理配置
    targetDir := pluginDir "\" pluginFolderName
    mainFile := targetDir "\main.ahk"
    if FileExist(mainFile) {
        try {
            RunWait(A_AhkPath ' "' mainFile '" /uninstall')
        }
    }

    ; 删除插件目录
    try {
        DirDelete(targetDir, true)
        pluginList.Delete(pluginFolderName)

        MsgBox("插件「" pluginName "」已卸载。", "卸载完成", 0x40)

        ; 刷新列表
        RefreshPluginListView()
        UpdateFunctionList()
    } catch as e {
        MsgBox("卸载插件失败: " e.Message, "错误", 0x10)
    }
}

; ============================================================
; 插件管理 GUI
; ============================================================

/*
 * 显示插件管理窗口
 * 包含插件列表（ListView）和操作按钮
*/
ShowPluginManager(*) {
    global MainGui, pluginManagerGui, pluginLv, pluginList

    ; 如果窗口已存在，直接显示
    if IsObject(pluginManagerGui) && pluginManagerGui.Hwnd {
        try {
            pluginManagerGui.Show()
            RefreshPluginListView()
            return
        }
    }

    ; 先刷新插件列表数据
    LoadPlugins()

    pluginManagerGui := Gui("+Resize +MinSize400x300 +Owner" MainGui.Hwnd, "插件管理")
    pluginManagerGui.OnEvent("Close", (*) => (pluginManagerGui.Destroy(), pluginManagerGui := 0))

    pluginManagerGui.BackColor := "F2F2F2"

    ; 标题区域
    pluginManagerGui.SetFont("s11 bold")
    pluginManagerGui.Add("Text", "x15 y10 w400", "已安装的插件")
    pluginManagerGui.SetFont("s9 norm")
    pluginManagerGui.Add("Text", "x15 y30 w500 c888888", "插件存放在 public/ 目录下，每个插件需包含 main.ahk 和 packname.json")

    ; 插件列表 ListView
    pluginLv := pluginManagerGui.Add("ListView", "x15 y55 w460 h250 -Multi AltSubmit Grid", ["名称", "版本", "作者", "状态",
        "更新日期"])
    pluginLv.ModifyCol(1, 130)
    pluginLv.ModifyCol(2, 60)
    pluginLv.ModifyCol(3, 80)
    pluginLv.ModifyCol(4, 80)
    pluginLv.ModifyCol(5, 100)

    ; 填充插件列表
    RefreshPluginListView()

    ; 操作按钮区域
    pluginManagerGui.Add("Button", "x15 y315 w80", "启动").OnEvent("Click", (*) => PluginAction_Start())
    pluginManagerGui.Add("Button", "x105 y315 w80", "停止").OnEvent("Click", (*) => PluginAction_Stop())
    pluginManagerGui.Add("Button", "x195 y315 w80", "卸载").OnEvent("Click", (*) => PluginAction_Uninstall())
    pluginManagerGui.Add("Button", "x285 y315 w80", "详情").OnEvent("Click", (*) => PluginAction_Details())
    pluginManagerGui.Add("Button", "x395 y315 w80", "刷新").OnEvent("Click", (*) => (LoadPlugins(), RefreshPluginListView()))

    pluginManagerGui.Show("w490 h355")
}

/*
 * 刷新插件列表 ListView 的显示内容
*/
RefreshPluginListView() {
    global pluginLv, pluginList, pluginProcesses

    if !IsObject(pluginLv) || !pluginLv {
        return
    }

    try {
        pluginLv.Delete()

        ; 同步进程状态
        for folderName, info in pluginList {
            if pluginProcesses.Has(folderName) {
                pid := pluginProcesses[folderName]
                if ProcessExist(pid) {
                    info["status"] := "运行中"
                } else {
                    pluginProcesses.Delete(folderName)
                    info["status"] := "已停止"
                }
            }
        }

        for folderName, info in pluginList {
            pluginLv.Add(
                info["status"] = "运行中" ? "Check" : "",
                info["name"],
                info["version"],
                info["author"],
                info["status"],
                info["updateDate"]
            )
        }
    }
}

/*
 * 获取当前选中的插件文件夹名
*/
GetSelectedPluginFolder() {
    global pluginLv, pluginList

    row := pluginLv.GetNext()
    if !row {
        MsgBox("请先选择一个插件！", "提示", 0x40)
        return ""
    }

    selectedName := pluginLv.GetText(row, 1)

    ; 通过名称查找对应的文件夹名
    for folderName, info in pluginList {
        if info["name"] = selectedName {
            return folderName
        }
    }

    return ""
}

; --- 操作按钮回调 ---

; 启动选中的插件
PluginAction_Start() {
    global pluginList
    folder := GetSelectedPluginFolder()
    if folder != "" {
        if (pluginList.Has(folder) && pluginList[folder].Has("runnable") && !pluginList[folder]["runnable"]) {
            MsgBox("错误: 该插件已被配置为不可启动！", "权限限制", 0x10)
            return
        }
        StartPlugin(folder)
        RefreshPluginListView()
    }
}

; 停止选中的插件
PluginAction_Stop() {
    global pluginList
    folder := GetSelectedPluginFolder()
    if folder != "" {
        if (pluginList.Has(folder) && pluginList[folder].Has("closable") && !pluginList[folder]["closable"]) {
            MsgBox("错误: 该插件已被配置为不可关闭！", "权限限制", 0x10)
            return
        }
        StopPlugin(folder)
        RefreshPluginListView()
    }
}

; 卸载选中的插件
PluginAction_Uninstall() {
    global pluginList
    folder := GetSelectedPluginFolder()
    if folder != "" {
        if (pluginList.Has(folder) && pluginList[folder].Has("uninstallable") && !pluginList[folder]["uninstallable"]) {
            MsgBox("错误: 该插件已被配置为不可卸载！", "权限限制", 0x10)
            return
        }
        UninstallPlugin(folder)
    }
}

; 显示选中插件的详细信息
PluginAction_Details() {
    global pluginList, pluginDir

    folder := GetSelectedPluginFolder()
    if folder = "" {
        return
    }

    info := pluginList[folder]

    ; 构建更新地址列表文本
    urlsText := ""
    if info["updateUrls"].Length > 0 {
        for i, url in info["updateUrls"] {
            urlsText .= "  " i ". " url "`n"
        }
    } else {
        urlsText := "  (无)"
    }

    detailText := ""
    detailText .= "插件名称: " info["name"] "`n"
    detailText .= "版本: " info["version"] "`n"
    detailText .= "作者: " info["author"] "`n"
    detailText .= "描述: " info["description"] "`n"
    detailText .= "更新日期: " info["updateDate"] "`n"
    detailText .= "当前状态: " info["status"] "`n"
    detailText .= "所在目录: " info["folderPath"] "`n"
    detailText .= "`n更新地址:`n" urlsText

    MsgBox(detailText, "插件详情 - " info["name"], 0x40)
}
