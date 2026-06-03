#Requires AutoHotkey v2.0

; ===========================================
; 图像识别点击函数库（纯 AHK v2 实现）
; 无需任何外部库，开箱即用
; ===========================================

; 全局调试开关
global FindImageDebug := false

; ===========================================
; 主函数：查找并点击图像
; ===========================================
FindImage(imageFile, searchRect := "", clickOffset := "", imageWidth := 0, imageHeight := 0, options := "") {
    ; ----- 参数初始化 -----
    defaultOptions := Map(
        "tolerance", 50,
        "useMultiTolerance", true,
        "useRegionSearch", true,
        "mouseSpeed", 50,
        "showTooltip", true,
        "tooltipDuration", 2000,
        "retryCount", 3,
        "retryDelay", 500,
        "minTolerance", 30,
        "maxTolerance", 200,
        "toleranceStep", 20
    )

    ; 合并选项
    if (options == "") {
        opts := defaultOptions
    } else {
        opts := defaultOptions.Clone()
        for key, value in options.OwnProps() {
            if opts.Has(key)
                opts[key] := value
        }
    }

    ; 设置搜索区域
    if (searchRect == "") {
        x1 := 0, y1 := 0
        x2 := A_ScreenWidth, y2 := A_ScreenHeight
    } else if (searchRect.Length >= 4) {
        x1 := searchRect[1], y1 := searchRect[2]
        x2 := searchRect[3], y2 := searchRect[4]
    } else {
        throw ValueError("searchRect 必须包含4个坐标值")
    }

    ; 确保坐标模式正确
    CoordMode("Pixel", "Screen")
    CoordMode("Mouse", "Screen")

    ; 检查文件是否存在
    if !FileExist(imageFile) {
        if opts["showTooltip"]
            ShowToolTip("✗ 图像文件不存在: " imageFile, opts["tooltipDuration"])
        return false
    }

    ; 获取图像尺寸（简化版）
    if (imageWidth <= 0 || imageHeight <= 0) {
        GetImageSizeSimple(imageFile, &imageWidth, &imageHeight)
    }

    ; 计算点击偏移
    if (clickOffset != "" && clickOffset.Length >= 2) {
        clickOffsetX := clickOffset[1]
        clickOffsetY := clickOffset[2]
    } else if (imageWidth > 0 && imageHeight > 0) {
        clickOffsetX := imageWidth // 2
        clickOffsetY := imageHeight // 2
    } else {
        clickOffsetX := 0
        clickOffsetY := 0
    }

    ; ----- 重试循环 -----
    loop opts["retryCount"] {
        result := FindImageInternal(imageFile, x1, y1, x2, y2, clickOffsetX, clickOffsetY, opts)
        if result {
            return true
        }
        if (A_Index < opts["retryCount"] && opts["retryDelay"] > 0) {
            Sleep(opts["retryDelay"])
        }
    }

    ; ----- 所有方法失败 -----
    if opts["showTooltip"]
        ShowToolTip("✗ 未找到目标图像", opts["tooltipDuration"])
    return false
}

; ===========================================
; 内部函数：执行实际搜索
; ===========================================
FindImageInternal(imageFile, x1, y1, x2, y2, clickOffsetX, clickOffsetY, opts) {
    foundX := 0, foundY := 0
    
    ; ----- 策略 1: 标准搜索（多级偏差）-----
    if opts["useMultiTolerance"] {
        ; 生成偏差值序列
        tolerances := []
        loop Ceil((opts["maxTolerance"] - opts["minTolerance"]) / opts["toleranceStep"]) + 1 {
            tol := opts["minTolerance"] + (A_Index - 1) * opts["toleranceStep"]
            tolerances.Push(tol)
        }
        ; 添加一些常用值
        tolerances.Push(80, 100, 120, 150, 180, 200, 220, 250)
        
        for tol in tolerances {
            if ImageSearch(&foundX, &foundY, x1, y1, x2, y2, "*" tol " " imageFile) {
                if (FindImageDebug)
                    ShowToolTip("标准搜索成功 (偏差:" tol ")", 1000)
                ClickAtPosition(foundX, foundY, clickOffsetX, clickOffsetY, opts)
                return true
            }
        }
    } else {
        if ImageSearch(&foundX, &foundY, x1, y1, x2, y2, "*" opts["tolerance"] " " imageFile) {
            ClickAtPosition(foundX, foundY, clickOffsetX, clickOffsetY, opts)
            return true
        }
    }

    ; ----- 策略 2: 区域网格搜索 -----
    if opts["useRegionSearch"] {
        ; 多级网格大小（从粗到细）
        gridConfigs := [[2, 40], [3, 30], [4, 20], [5, 15]]
        
        for config in gridConfigs {
            gridSize := config[1]
            overlap := config[2]
            
            regionWidth := (x2 - x1) // gridSize
            regionHeight := (y2 - y1) // gridSize
            
            if (regionWidth < 10 || regionHeight < 10)
                continue
            
            loop gridSize {
                row := A_Index - 1
                loop gridSize {
                    col := A_Index - 1
                    
                    startX := Max(x1, x1 + col * regionWidth - (col > 0 ? overlap : 0))
                    startY := Max(y1, y1 + row * regionHeight - (row > 0 ? overlap : 0))
                    endX := Min(x2, startX + regionWidth + overlap * 2)
                    endY := Min(y2, startY + regionHeight + overlap * 2)
                    
                    ; 使用较高偏差
                    for tol in [150, 180, 200, 220, 250] {
                        if ImageSearch(&foundX, &foundY, startX, startY, endX, endY, "*" tol " " imageFile) {
                            if (FindImageDebug)
                                ShowToolTip("区域搜索成功 (" gridSize "x" gridSize "网格, 偏差:" tol ")", 1000)
                            ClickAtPosition(foundX, foundY, clickOffsetX, clickOffsetY, opts)
                            return true
                        }
                    }
                }
            }
        }
    }

    ; ----- 策略 3: 全屏强力搜索（最后手段）-----
    toleranceList := [180, 200, 220, 250, 255]
    for tol in toleranceList {
        if ImageSearch(&foundX, &foundY, 0, 0, A_ScreenWidth, A_ScreenHeight, "*" tol " " imageFile) {
            if (FindImageDebug)
                ShowToolTip("全屏强力搜索成功 (偏差:" tol ")", 1000)
            ClickAtPosition(foundX, foundY, clickOffsetX, clickOffsetY, opts)
            return true
        }
    }

    return false
}

; ===========================================
; 获取图像尺寸（使用 WIA，Windows 自带）
; ===========================================
GetImageSizeSimple(imageFile, &width, &height) {
    width := 0
    height := 0
    
    try {
        ; 使用 WIA 获取图像尺寸
        wia := ComObject("WIA.ImageFile")
        wia.LoadFile(imageFile)
        width := wia.Width
        height := wia.Height
        
        if (FindImageDebug) {
            ShowToolTip("图像尺寸: " width "x" height, 1000)
        }
        return true
    } catch {
        ; 如果失败，返回默认值
        if (FindImageDebug) {
            ShowToolTip("无法获取图像尺寸，使用默认偏移", 1000)
        }
        return false
    }
}

; ===========================================
; 辅助函数：执行点击和提示
; ===========================================
ClickAtPosition(foundX, foundY, offsetX, offsetY, opts, extraMsg := "") {
    clickX := foundX + offsetX
    clickY := foundY + offsetY

    ; 移动鼠标
    if (opts["mouseSpeed"] >= 0) {
        MouseMove(clickX, clickY, opts["mouseSpeed"])
    } else {
        MouseMove(clickX, clickY, 0)
    }
    Sleep(50)

    ; 可选：执行点击（如果需要自动点击，取消下面注释）
    ; Click

    ; 显示提示
    if opts["showTooltip"] {
        tooltipText := "✓ 找到目标`n坐标: " clickX ", " clickY
        if (extraMsg != "")
            tooltipText .= "`n" extraMsg

        ShowToolTip(tooltipText, opts["tooltipDuration"])
    }
}

; ===========================================
; 辅助函数：显示临时 ToolTip
; ===========================================
ShowToolTip(text, durationMs) {
    ToolTip(text)
    SetTimer(RemoveToolTip, -durationMs)

    RemoveToolTip() {
        ToolTip()
    }
}

; ===========================================
; 辅助函数：切换调试模式
; ===========================================
ToggleFindImageDebug() {
    global FindImageDebug
    FindImageDebug := !FindImageDebug
    ToolTip "图像识别调试模式: " (FindImageDebug ? "开启" : "关闭")
    SetTimer () => ToolTip(), -2000
}

; ===========================================
; 辅助函数：测试图像识别
; ===========================================
TestFindImage(imageFile, tolerance := 150) {
    if !FileExist(imageFile) {
        MsgBox "文件不存在: " imageFile
        return false
    }
    
    options := {
        tolerance: tolerance,
        useMultiTolerance: true,
        useRegionSearch: true,
        showTooltip: true,
        retryCount: 3,
        minTolerance: 50,
        maxTolerance: 250,
        toleranceStep: 30
    }
    
    result := FindImage(imageFile, "", "", 0, 0, options)
    
    if result {
        ToolTip "✓ 测试成功！找到图片"
    } else {
        ToolTip "✗ 测试失败！未找到图片"
    }
    SetTimer () => ToolTip(), -3000
    
    return result
}

; ===========================================
; 简易版函数
; ===========================================
SimpleFindClick(imagePath, options := "") {
    return FindImage(imagePath, "", "", 0, 0, options)
}