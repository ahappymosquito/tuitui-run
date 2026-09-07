# Tuitui Run

Godot 4.7.2 Standard / GDScript。Chrome 小恐龙手感 + 天天酷跑经典模式一期。

玩家钉在屏幕左侧，世界左移。物理 **60 tick**，渲染锁 **60 FPS**。

## 操作

- 一段跳：空格、上、W、点击
- 下滑：下、S（挡板必须钻）
- 暂停：Esc
- 星门从圆环中心穿过加分，擦边死亡
- 跟着金币弧线跳，那条弧就是预判的舒适路线

## 流程

第一次启动取昵称，生成游戏 ID → 首页商店/角色/设置/排行 → 开跑。

冲刺：飞起 + 冲击波 + 吸金币。  
超级时空：能量满后进入约 18 秒休息关，金币/银币/铜币排成心形星形等；奖励币**不会再充能量**。

结算：总分从 0 跳到 `距离×0.04 + 币值×12 + 星门×80`。破纪录会庆祝。可重玩或回首页。

## 排行榜 API

线上：`https://qrqto.club/tuitui-api`（源码 `server/`，部署在 ts3@qrqto）。

## 发布包

`builds/TuituiRun.exe`（单文件 embed pck）。图标用项目根目录 `icon.png` / `icon.ico`。

编辑器：`C:\Tools\Godot\4.7.2\godot-4.7.2.exe` 打开 `tuitui_run/`。
