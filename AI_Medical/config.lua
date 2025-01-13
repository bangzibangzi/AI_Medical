Config = {}

-- 自定义配置选项
Config.ProgressTime = 15000          -- 复活进度条时间（以毫秒为单位）
Config.ReviveCost = 5000             -- 复活费用
Config.JobCheck = 'ambulance'       -- ESX医护职业名称
Config.NotifyType = 'esx'           -- 通知方式（改为 'esx'）
Config.UseBank = true               -- 是否优先从银行扣除费用，true 为优先使用银行
Config.MaxEMSCount = 2              -- 超过这个数量的医护在线时将禁用AI医护

-- 3D文字显示配置
Config.Show3DText = true            -- 是否显示3D文字
Config.TextDistance = 15.0          -- 3D文字显示距离
Config.TextScale = 0.35             -- 3D文字大小
Config.TextColor = {r = 255, g = 0, b = 0}  -- 3D文字颜色（红色）
Config.NotifyNearbyPlayers = true   -- 是否通知附近玩家
Config.NotifyDistance = 20.0        -- 通知范围（米）