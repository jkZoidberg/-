#SingleInstance Force
CoordMode "Mouse", "Screen"
CoordMode "Pixel", "Screen"
SetDefaultMouseSpeed 0

; ===== 可调参数 =====
Jitter := 0                     ; 点击抖动 ±像素
BetweenMin := 400                ; 步间最短随机等待(ms)
BetweenMax := 500                ; 步间最长随机等待(ms)
BetweenRoundsMin := 500         ; 每轮最短随机等待(ms)
BetweenRoundsMax := 2000         ; 每轮最长随机等待(ms)
TimeoutPerStep := 6000           ; 每步查找超时(ms)
PollInterval := 120              ; 查找轮询间隔(ms)
Similarity := 150                ; ImageSearch 相似度(0-255，越大越宽松)
DefaultOffsetX := 5             ; 找到图片左上角后点击的 X 偏移
DefaultOffsetY := 15             ; 找到图片左上角后点击的 Y 偏移

; ===== 第2/3步：只截“按钮文字”的小图（PNG），放脚本同目录 =====
Step2Imgs := ["step2.png"]   ; 例如：确认/下一步 的文字小图
Step3Imgs := ["step3.png"]   ; 例如：继续/删除 的文字小图

; ===== 热键 =====
toggle := false
F8:: {
    global toggle
    toggle := !toggle
    if toggle {
        ToolTip "循环已启动 (F8 停止)"
        SetTimer MainLoop, 100
    } else {
        SetTimer MainLoop, 0
        ToolTip
    }
}
Esc::ExitApp

MainLoop() {
    global Jitter, BetweenMin, BetweenMax, BetweenRoundsMin, BetweenRoundsMax
    global Step2Imgs, Step3Imgs

    ; Step 1（坐标左键）
    Click 241 + Random(-Jitter, Jitter), 371 + Random(-Jitter, Jitter)
    Sleep Random(BetweenMin, BetweenMax)

    ; Step 2（按文字小图识别→点击）
    ClickByTextImage(Step2Imgs)

    ; —— 固定等待 0.7 秒 ——
    Sleep 900

    ; Step 3（按文字小图识别→点击）
    ClickByTextImage(Step3Imgs)
    Sleep Random(BetweenMin, BetweenMax)

    ; Step 4（坐标左键）
    Click 1190 + Random(-Jitter, Jitter), 828 + Random(-Jitter, Jitter)
    Sleep Random(BetweenMin, BetweenMax)

    ; Step 5（坐标左键）
    Click 1694 + Random(-Jitter, Jitter), 190 + Random(-Jitter, Jitter)
    Sleep Random(BetweenMin, BetweenMax)

    ; 每轮随机休息
    Sleep Random(BetweenRoundsMin, BetweenRoundsMax)
}

; === 用“文字小图”找图并点击（不使用 *Trans）===
ClickByTextImage(imgs) {
    global TimeoutPerStep, PollInterval, Jitter, Similarity, DefaultOffsetX, DefaultOffsetY
    t0 := A_TickCount
    paramBase := "*" Similarity " "  ; 不拼接 *Trans（避免 bgColor 为空导致 Format 报错）

    while (A_TickCount - t0) <= TimeoutPerStep {
        for img in imgs {
            if pos := FindImageParam(paramBase, img) {
                ; 点击左上角 + 默认偏移 + 抖动
                cx := pos["x"] + DefaultOffsetX + Random(-Jitter, Jitter)
                cy := pos["y"] + DefaultOffsetY + Random(-Jitter, Jitter)
                Click cx, cy
                return true
            }
        }
        Sleep PollInterval
    }
    ToolTip "未找到：" (imgs.Length ? imgs[1] : "文字图")
    SetTimer () => ToolTip(), -1200
    return false
}

; === 全屏找图（返回 Map），不再使用 ImageGetSize，避免未定义函数告警 ===
FindImageParam(paramBase, imgPath) {
    if !FileExist(imgPath)
        return false
    if ImageSearch(&fx, &fy, 0, 0, A_ScreenWidth, A_ScreenHeight, paramBase imgPath) {
        ; 返回左上角坐标，w/h 用占位值即可（未用到）
        return Map("x", fx, "y", fy, "w", 0, "h", 0)
    }
    return false
}