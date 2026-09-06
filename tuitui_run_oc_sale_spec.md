# 酷跑OC出售 施工说明书（给 Grok 完工用）
日期：2026-09-06
仓库：`D:\code\tuitui\tuitui_run`
引擎：Godot 4.7.2 Standard + GDScript 全静态类型
Notion 母页：https://app.notion.com/p/3d3bd116fd808180a3a3cfa327b9dda5

看完按第 2 节改仓库。完成定义 = 第 10 节勾选通过，不是“代码写了”。

---

## 0. 产品锁死

- 品类：横版无尽跑酷（对标天天酷跑经典模式，不拷贝 UI/IP）
- 商品：我方自研 3 个 OC 角色出售（不是用户交图定制）
- 平台：Android 先；PC 底盘已有
- 物理 60 tick，渲染锁 60 FPS
- 玩家钉屏幕左侧，世界左移
- 评分：`距离×0.04 + 币值×12 + 火圈×80`
- 币：金=5 银=3 铜=1；路径币充能，超级段 `fills_energy=false`
- 超级时空 15s；冲刺离地 150px

一期不做：进击 / 炫飞 / 多人 / 爱心门票 / 宠物坐骑精灵 / 抽卡 / 角色升级树 / 用户交 OC 图 / 三轨道

用户交图定制方案作废。

---

## 1. 已有 vs 本次必改

已有（不要重写）：

- loading → 首局填昵称 → home → levels/main → 结算
- 双键跳/滑、金币弧、火圈/挡板/钉刺、能量槽、超级段
- 本地榜 + `https://qrqto.club/tuitui-api/v1/scores`（安卓一期可先只本地）
- 首页左柜右舞台布局（自有色盘）

必改：

- 角色从硬编码拆成 `CharacterDef` 资源
- 安卓导出 + 左右热区
- 商店买角色 + 存档 owned/equipped
- 3 个 OC 同一套控制器，技能走配置
- chunk 池分教学/简/中/难

禁止：复制三份 Player 脚本；改动作表后不回归；一期混用 Spine+序列帧+Live2D；未售角色做成开跑依赖。

---

## 2. Grok 实现顺序（严格，不跳步）

1. 冻结本页常量，不改评分公式和 60 tick
2. 安卓 Debug APK：左 40% 滑、右 60% 跳，手指不挡角色
3. 拆 CharacterDef + Save.owned/equipped，先只装 oc_a
4. oc_a 成品质动作：idle/run/jump/fall/slide/dead
5. 商店买 oc_b（2400 金币），局内三连跳生效，杀进程仍在
6. oc_c 内购沙盒或 debug 开关，开局冲刺 2s
7. chunk：0–600m 教学池，之后混合，≥12 块
8. 签名包 + 隐私政策 + 崩溃日志

每步结束：对应第 10 节勾选全过。

编码约束：全静态类型；物理只写 `_physics_process`；`@onready + %UniqueName`；Call down / Signal up；禁止 Godot 3 API、禁止 C#、禁止 `if id == "oc_b"`。缺素材用色块占位，文件名按规范留好。输出必须带：完整 .gd + 节点树 + 编辑器手工步骤。

---

## 4. 目录、场景树、Autoload

旧路径保留。新文件：

```
data/characters/oc_a.tres
data/characters/oc_b.tres
data/characters/oc_c.tres
scripts/data/character_def.gd
scripts/autoload/catalog.gd
scripts/player/touch_zones.gd
scripts/shop/shop.gd
scenes/shop.tscn
scenes/chunks/teach_*.tscn
assets/characters/oc_a|oc_b|oc_c/
```

Autoload 只保留/补这 5 个：Save、Settings、Audio、Economy、Catalog。不要第七个。

```
Main
  WorldRoot            # 世界左移，玩家不跑 x
    Parallax2D_sky/mid/near
    Ground
    ChunkContainer
    PickupContainer
  Player               # x ≈ viewport*0.22
    AnimatedSprite2D
    ColRun / ColSlide
  TouchZones
    SlideZone 左 40%
    JumpZone 右 60%
  HUD / ResultLayer
```

- player.gd 只读 CharacterDef，必须有 `apply_character(def)`
- touch_zones.gd 把触摸写成 InputMap action `jump` / `slide`
- 动作名锁：idle run jump fall slide dead
- 组名：coin / obstacle / pickup
- 项目设置：1920×1080 横屏，stretch=canvas_items，aspect=expand，Physics Ticks=60，Android Renderer=Mobile，`Engine.max_fps=60`

---

## 5. CharacterDef 与三个 OC

```gdscript
class_name CharacterDef
extends Resource

@export var id: StringName
@export var display_name: String
@export var skill_blurb: String
@export var unlocked_default: bool = false
@export var currency: StringName = &"coin" # coin | iap
@export var price: int = 0
@export var iap_sku: String = ""
@export var max_jumps: int = 2
@export var can_glide: bool = false
@export var glide_gravity_scale: float = 0.35
@export var start_sprint_sec: float = 0.0
@export var hitbox_run: Vector2 = Vector2(42, 86)
@export var hitbox_slide: Vector2 = Vector2(56, 46)
@export var sprite_frames: SpriteFrames
@export var shop_portrait: Texture2D
```

Catalog 启动加载 `res://data/characters/*.tres`。

| 字段 | oc_a | oc_b | oc_c |
|---|---|---|---|
| skill_blurb | 二段跳 | 三连跳 | 开局冲刺 + 二段跳 |
| unlocked_default | true | false | false |
| currency | coin | coin | iap |
| price | 0 | 2400 | 0 |
| iap_sku | | | sku_oc_c |
| max_jumps | 2 | 3 | 2 |
| can_glide | false | false | false |
| start_sprint_sec | 0 | 0 | 2.0 |

OC-B 若改滑翔：max_jumps=2 且 can_glide=true。三连跳与滑翔二选一，不能同时给 B。一期按表走三连跳。
开局 800 币。B=2400 表示 3–8 局能买到；一局平均入账 <400 只改 price，禁止一局买齐。
`apply_character` 只换 sprite_frames、命中盒、max_jumps、can_glide、start_sprint_sec。
三皮脚底对齐误差 < 4px。一期 AnimatedSprite2D，不上 Spine。B/C 没图就复制 A 改色，必须独立 .tres。

---

## 6. 状态机与输入

```gdscript
enum State { RUN, JUMP, FALL, SLIDE, GLIDE, SPRINT, SUPER, DEAD }
var jumps_used: int = 0
```

不要拆 JUMP1/JUMP2。起跳速度、重力用仓库现值。

InputMap：jump=Space／右热区点按；slide=Down 或 S／左热区按住；pause=Esc／右上键。
Android：左 40%=slide，右 60%=jump，角色约 x=22%，热区高约底部 28%。多点可同时按。仅 mobile 显示热区。键盘保留。
jump 用 just_pressed；slide / 滑翔用 pressed。SLIDE 中不能跳，松手立刻起身。

转换：

- RUN + jump + 着地 → JUMP，jumps_used=1
- JUMP 顶点或 vy>0 → FALL
- JUMP/FALL + just_pressed + jumps_used < def.max_jumps → 再跳
- JUMP/FALL + def.can_glide + held + jumps_used==max_jumps → GLIDE（gravity*=glide_gravity_scale）
- RUN + slide held + 着地 → SLIDE，切 ColSlide
- 致命碰撞 / 掉坑 → DEAD，3 秒内可重开
- 能量满 → SUPER 15s，fills_energy=false
- start_sprint_sec>0 开局 → SPRINT（离地 150px、吸币、短暂无敌）
- 着地 jumps_used=0

矮障只滑可过；高障/挡板要跳；坑要跳过；火圈穿心加分、擦边死。命中盒贴身形，金币 Area 比视觉大 20–30%。

默认物理（库里有数用库里的，没有才用）：speed 520→780 cap 820，jump -620，gravity 1850，cut 0.45，slide 0.55s。

---

## 7. Chunk

块宽固定（建议 2048px），起止地面齐平，oc_a 必须能过。同类连出 ≤2。死局组合（两坑间距 < 二段跳距）丢掉重抽。总块 ≥12。

教学池 0–600m（前 200m 必有平地+单障）：

- teach_flat
- teach_low_slide
- teach_high_jump
- teach_gap_double
- teach_coin_arc
- teach_fire_ring

之后混合：360–600 +easy；600–1200 +mid；1200+ hard。mix ≥8，含挡板+钉刺、钉刺+挡板、双坑、金币支线。

超级段：能量 100 切 super_reward，15s，清障碍，币 fills_energy=false。路径币 8 枚=1 能量。每 400–600m 有一次满槽机会。
600m 按现有距离单位换算，不改手感。

---

## 8. 存档与商店

`user://save.json`：

```json
{
  "v": 1,
  "player_id": "",
  "nickname": "",
  "coins": 800,
  "owned": ["oc_a"],
  "equipped": "oc_a",
  "best_score": 0,
  "best_distance": 0,
  "iap_owned": []
}
```

API：`is_owned` / `buy_with_coins` / `equip` / `grant_iap` / `add_coins`。
买成功先写盘再刷 UI。未拥有不能 equip。死亡不换人。清数据后 iap 可恢复购买，金币购不恢复。
结算只加 coins。Home → 角色 → 买 B → 穿 → 开跑三连跳生效 → 死 → Home 舞台仍是 B。
OC-C：闸 5 前 debug_unlock / grant_iap；再接 Play 沙盒 sku_oc_c。沙盒不通不挡主循环。
禁止抽卡、碎片、角色升级、局中换人。

---

## 9. 安卓导出

- 模板与编辑器同为 4.7.2 Standard
- 横屏 16:9 锁定，隐藏状态栏
- Gradle，arm64 必选
- 一期不读相册；接内购才加 BILLING
- 首包只强依赖 oc_a；b/c 可进包但不要 preload 成开跑依赖
- Debug APK 真机验；发布用 AAB
- Engine.max_fps=60；VRAM ETC2/ASTC
- 中低端 30fps+；Settings 放隐私政策；写 crash.log
- 国内商用版号另走

---

## 10. 验收勾选（没勾完=没完工）

闸1 安卓灰盒

- [ ] 真机能装能开
- [ ] 左滑右跳生效，键盘仍可调
- [ ] 手不挡角色
- [ ] 矮障必滑、高障必跳、坑必跳，三者不能互替
- [ ] 重开 < 3 秒
- [ ] 60 tick，评分公式不变
- [ ] 3 机 × 10 局不崩

闸2 OC-A

- [ ] idle/run/jump/fall/slide/dead 齐
- [ ] 脚底误差 < 4px
- [ ] 队外 5 人无教程能玩 2 分钟，3 人愿再开
- [ ] 中低端 30+ 帧
- [ ] 主路安全 / 支线多币
- [ ] 400–600m 能满一次能量

闸3 能卖

- [ ] 新号只能用 oc_a
- [ ] 2400 买成 oc_b 并写档
- [ ] B 三连跳、A 仍二段跳
- [ ] 杀进程 B 还在
- [ ] 队外能说出差异
- [ ] 代码无 `if id ==`

闸4 攒金买人全路径

- [ ] 安装 → 新号 → A 跑死 → 攒到 2400 → 买 B → 用 B 再跑 → 重进仍是 B
- [ ] 一局买不齐 B
- [ ] chunk ≥ 12；前 600m 教学池
- [ ] 超级段币不充能

闸5 软上线

- [ ] 签名包
- [ ] C 沙盒或开关发货 + 恢复购买
- [ ] 隐私政策入口
- [ ] 外部 20 人能独立买 B
- [ ] 崩溃 < 2%

---

## 11. 贴给下一个 Grok 的 Prompt

```
读 Notion「酷跑OC出售 施工说明书」全页，以及本地 tuitui_run_oc_sale_spec.md。
Godot 4.7.2 + GDScript 静态类型。只改 D:\code\tuitui\tuitui_run。
按第 2 节顺序做当前一步，不跳步。
不改评分公式、60 tick、超级 15s、冲刺 150px。
角色只用 CharacterDef，禁止 if id==。
先盘点现有文件再改。
输出完整 .gd + 节点树 + 编辑器手工步骤。
做完用第 10 节对应闸门自查。
```
