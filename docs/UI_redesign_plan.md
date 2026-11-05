# UI 重新布局方案（讨论稿，2026-11-04）

状态：**2026-11-04 已按方式 A 实现**（`MMcodeOrcaV2/selfmade/applyLayout.m`，见 PROGRESS_LOG），**还没有在显微镜上测试**。
下面是讨论过程；与最终实现不同的地方以第 7 节为准。
编辑规则见 `CLAUDE.md`：先备份到 `_archive/`、两份代码同步、更新 PROGRESS_LOG、不能用 R2019a 之后才有的东西，
以及不要碰 640 nm Analog 模式的代码。

## 1. 需求

Fengyi："能不能根据我的工作流重新设计 UI。界面上留着的 feature 都是我常用的。现在这个 UI 太丑了，一堆按钮随便乱放。"

工作流（顺序）：
1. 调节每个通道的 galvo 和 detection（检测镜），确保图像质量良好
2. 用 Paint 定义 xy 平面的边界
3. 逐个 tile 定义 z 轴边界
4. 设置采集参数，开始成像

## 2. 现状（从 `matlab/document.xml` 的 `createComponents` 读出）

- `UIFigure` 大小为 943 x 1005。约 75 个控件，大部分直接放在 `UIFigure` 上，只有 4 个面板：
  `TakingimagesonMbyNtileswithzstacksPanel`、`ExcitationLensandDetectionLensPanel`、`PaintModePanel`、
  `imageparametersPanel`。
- 同一步骤用到的控件分散在各处，例如 Power/Exposure 在左下，颜色勾选框在右侧面板顶部；
  640 Analog 的 `Mode640nm` / `HDPRTable` / `SvAFG2` / `StopAnalog` 在左下角。
- 顺便发现：`SaveImAFG2Button`、`SaveImCamButton`、`TestTriggerButton` 已从界面删除，但它们的回调里
  仍引用这些组件（现在是死代码，不会触发）。新布局不涉及它们。

## 3. 布局方案

按操作顺序排列：从左到右、从上到下。

```
┌─ 顶栏（任何时候都会用到）─────────────────────────────────────────────────────────────────┐
│ Light Path[path1▾] 波长[640nm▾] 功率[ 5]mW 滤光片[676/37▾] (Shutter) │ [Enable Cam][Disable Cam]│
│ Exposure[100]ms  Contrast[  ]  ☐Show Grid  [Save Image]  AutoFocus[Tenengrad▾]                │
├─ ① 通道调节（每个颜色）──────┬─ ② 载物台 + Paint 定 XY ─────┬─ ③ 逐 tile 定 Z ──────────────┤
│ galvo X ───●─── [◀][▶] 0.01▾ │      Up/Down[100um▾]          │ move to tile [ 3 ▲▼]           │
│ galvo Y ───●─── [◀][▶] 0.01▾ │          ⏫                   │ Deep    start [-200] [save] k  │
│                              │     ⏪  ⍟  ⌾  ⏩               │ Surface end   [1000] [save] l  │
│ [Reset galvo][AFG_scan]      │          ⏬                   │ [save checkpoints ␣][skip tile]│
│ 激发镜 step[10um▾] [◀][▶]    │ L/R[100um▾]  In/Out[10um▾]    │ ┌ Tile States ──────────────┐ │
│ 检测镜 step[ 5um▾] [◀][▶]    │ X[    ] Y[    ] Z[    ]       │ │ All saved: No              │ │
│ ┌path 表┐ ┌motor 表┐        │ Min Z[   ] [Get Position]     │ │ ...                        │ │
│ └───────┘ └────────┘        │ ── Paint ──                   │ │ Saved Tiles List: 1(..)    │ │
│ ┌offset 表 488/561/640/730┐ │ (Paint) [Center] [Save paint] │ │                            │ │
│ │                          │ │      [Up]                     │ └────────────────────────────┘ │
│ └──────────────────────────┘ │ [Left]    [Right]  [Down]     │ [import tiles] [export tiles]  │
│ [save offset for this color] │ Vertical[2] Horizontal[3]     │                                │
│                              │ Check Points[3]               │                                │
│                              │ [create scan pattern] ● Status│                                │
├─ ④ 采集 ──────────────────────┴───────────────────────────────┴────────────────────────────────┤
│        ☑488   ☑561   ☑640   ☐730   │ z step[2]um  AF step[50]um  │ 640 mode[Analog▾]            │
│ Power  [ 5]   [ 5]   [ 8]   [  ]   │                             │ HDR 功率表 ┌──────────────┐  │
│ Exp    [100]  [100]  [100]  [  ]   │                             │            └──────────────┘  │
│                                    │                             │ [SvAFG2] [StopAnalog]        │
│ [Image saving directory] [D:\Data\...................] [Open Path]                             │
│ [Reset Imaging]                                         [ ▶ START IMAGE ALL TILES ]（大、绿色） │
└────────────────────────────────────────────────────────────────────────────────────────────────┘
```

要点：
- 每个区块对应一个步骤，标题带编号，并用同一种浅色区分：顶栏灰、①绿、②蓝、③黄、④白。
- 4 行 Power_xxx / Exposure_xxx 和颜色勾选框合成一个 4 列的小网格，每列是同一个颜色。
- 640 Analog 的控件（Mode640nm、HDR 功率表、SvAFG2、StopAnalog）放在一起。**只挪位置，不碰代码**（CLAUDE.md 第 7 条）。
- 快捷键（k / l / 空格）写在对应按钮的文字里。也可以用 `Tooltip`，但要先查 MathWorks 文档，
  确认它在 R2019a 里已经有了（还没查）。
- 窗口目标大小约 960 x 900。显微镜电脑是普通 24 英寸显示器（一般是 1920 x 1080，去掉任务栏和标题栏后
  可用高度约 1000 px），所以控制窗口放在屏幕左半边、宽不超过 960，右半边留给 Live View / Paint。
  如果 Windows 显示缩放不是 100%，可用空间会变小，到时在显微镜上看一下。

### 3.1 galvo X / Y：保留滑块，加上左右键和步长下拉（2026-11-04 Fengyi 确定）

只在刻度轴上点击很难调准。Fengyi 的决定：**滑块保留**，旁边加 ◀ / ▶ 和步长下拉菜单，
操作方式和激发镜、检测镜一样（先选步长，再按方向键）。

```
galvo X  -0.4 ──────●────── 0.4   [◀] [▶]  step [0.01 ▾] V
galvo Y  -0.6 ──────●────── 0.6   [◀] [▶]  step [0.01 ▾] V
```

- ◀ / ▶ 每按一次，滑块值减 / 加一个步长，并马上输出到 galvo。滑块本身照常可以拖、可以点。
- 步长下拉选项：0.1 / 0.05 / 0.01 / 0.005 / 0.001 V，默认 0.01（待 Fengyi 确认）。X、Y 各有一个下拉，互不影响。
- 范围用滑块的 `Limits`（X 为 ±0.4 V，Y 为 ±0.6 V），超出时停在边界（滑块值不能超出 Limits，否则 MATLAB 报错）。
- 按钮回调只做两件事：算出新值写进 `galvo_XSlider.Value`，再调用原来的
  `galvo_XSliderValueChanged(app, [])`（Y 同理）。输出到 DAQ 的逻辑完全不变；
  其他代码（切换颜色载入 offset、Reset galvo、改 path 表、save offset）照常读写滑块，不需要额外同步。
- 每次按键后的精确数值可以在 `UITable_path` 的 Galvo_X / Galvo_Y 里看到（回调末尾会刷新这张表），
  所以 path 表要继续显示。
- 滑块高度不变，所以这一行不省空间；可以把滑块缩短一些（例如 316 → 220 px），给按钮和下拉腾出位置。
- 实现：方式 A 下在 `applyLayout.m` 里运行时新建 4 个按钮和 2 个下拉菜单；方式 B 下由 Fengyi 在 Design View 里加，
  回调由脚本写。

### 3.2 去掉 Galvo_Z（2026-11-04 Fengyi 提出）

界面上没有 galvo_Z 滑块，Galvo_Z 只出现在 `UITable_path` 和 `UITable_offset` 的一列里（offset 表里这列已经锁住不能编辑）。
- 这一列的数据**不能删**：所有 `outputSingleScan(... Galvo_Z ...)` 都要读它（DAQ 第 4 个通道），删了会报错。
- 只在界面上隐藏：把这列的 `ColumnWidth` 设成很小（例如 1 px），或把这一列移到最后再把表的宽度裁掉。
  R2019a 的 `uitable` 是否接受宽度 0，要先在 Mac 上测（用 R2026b 只能确认语法，最终要在显微镜上看）。
- 顺便发现：`save_checkpointButtonPushed` 里引用了不存在的 `galvo_ZSlider` / `galvo_Xview` 等，
  但它是 "Callback function"（没有绑定到任何控件），是旧代码，不会运行。

## 4. 控件归属表（组件名 → 区块）

| 区块 | 组件 |
|---|---|
| 顶栏 | `LightPathDropDown`(+Label), `WavelengthLabel`, `Lightwavelight`, `LaserPowermWEditFieldLabel`, `LaserPower`, `FilterwheelDropDownLabel`, `Filterwheel`, `ShutterButton`, `EnableCam`, `DisableCam`, `Exposure_timeEditField`(+Label), `ImagecontrastLabel`, `Imagecontrast`, `ShowGridCheckBox`, `SaveImage`, `AutoFocusDropDown`(+Label) |
| ① 通道调节 | `galvo_XSlider`(+Label), `galvo_YSlider`(+Label), 新建的 galvo X/Y ◀▶ 按钮和步长下拉（3.1）, `Reset_galvo_XYButton`, `AFG_scanButton`, `ExcitationLensandDetectionLensPanel`（整个面板：`ExtStepsizeDropDown`, `ObjStepsizeDropDown`, `left/rightButtonExt`, `left/rightButtonObj`）, `UITable_path`, `UITable_motor`, `UITable_offset`, `saveoffsetfordifferentcolorButton`（现在在 M-by-N 面板里，要移出来） |
| 隐藏（`Visible = 'off'`） | `RollSlider`(+Label), `RollScanButton`（Fengyi 不用 Roll；只隐藏，回调不动，删除要在 Design View 里做） |
| ② 载物台 + Paint | `Button`(⏫), `Button_4`(⏬), `Button_3`(⏪), `Button_2`(⏩), `Button_5`(⍟), `Button_6`(⌾), `Updown_stepDropDown`, `Leftright_stepDropDown`, `Inout_stepDropDown`(+Labels), `StagepositionLabel`, `Stage_HardwareX/Y/Z_EditField`(+X/Y/Z Labels，注意 Y/Z 标签与字段是交叉命名的，移动时保持原来的配对), `MinZEditField`(+Label), `GetPositionButton`, `PaintModePanel`（整个面板）, `VerticaltileEditField`, `HorizontaltileEditField`, `CheckPointsEditField`(+Labels), `createscanpatterncenterButton`, `StatusLamp`(+Label), `GreensignalwillblockmotionexceptinzaxisLabel` |
| ③ 逐 tile 定 Z | `movetotileSpinner`(+Label), `DeepLabel_2`, `startofeachtileEditField`(+Label), `saveButton_3`, `SurfaceLabel`, `endofeachtileEditField`(+Label), `saveButton_4`, `savecheckpointsButton`, `skiptilesButton`, `TileStatesTextArea`(+Label), `importtilesButton`, `exporttilesButton` |
| ④ 采集 | `W488/561/640/730nmCheckBox`, `ChoosewhichcolortoimageLabel`, `Power_488/561/640/730EditField`(+Labels), `Exposure_488/561/640/730EditField`(+Labels), `zstack_distanceum`(+`z_step_sizeumLabel`), `AutoFocusStepSizeumEditField`(+Label), `Mode640nmDropDown`(+Label), `HDPRTable`, `ListofLaserPowerstogenerateHDRimageMin1Max20Label`, `SvAFG2Button`, `StopAnalogButton`, `ImagesavingdirectoryButton`, `pathEditField`, `OpenPathButton`, `ResetImagingButton`, `startimagealltilesButton` |

做完以后，四个旧面板中 `TakingimagesonMbyNtileswithzstacksPanel` 和 `imageparametersPanel` 会被清空，
可以隐藏或删除（删除要在 Design View 里由 Fengyi 做）。

## 5. 实现方式（已选 A：启动时自动排版）

| 方式 | 做法 | 优点 | 缺点 |
|---|---|---|---|
| **A（推荐）启动时自动排版** | 新建 `selfmade/applyLayout.m`，在 `startupFcn` 里加一行 `applyLayout(app)`。它在运行时创建这些面板，再把现有控件的 `Parent`/`Position` 改过去 | 可以用脚本完成，并在 Mac 上用假窗口测试（从 `createComponents` 搭）；`uipanel` 和改 `Parent` 在 R2019a 都能用；删掉那一行就恢复原样 | Design View 里看到的还是旧布局。以后新加的按钮要在 `applyLayout.m` 里分配位置，否则会留在旧位置 |
| B Fengyi 在 Design View 里手动改 | 按第 4 节的表和一份坐标清单拖动控件 | Design View 里看到的就是真实布局 | 约 75 个控件，手动工作量大 |
| C 用脚本直接改 `.mlapp` 里的组件 | 修改 `appModel.mat` 中序列化的界面对象和 `createComponents` | 效果和 B 一样 | 要在脚本里新增面板组件，违反 CLAUDE.md 第 3 条；风险最高，不建议 |

方式 A 的注意事项：
- 控件的回调和属性都不变，只改 `Parent` 和 `Position`，所以不影响功能（包括 640 Analog）。
- `UIFigureKeyPress` 快捷键挂在 figure 上，焦点在面板内的控件上时也能触发，需要在显微镜上确认。
- 代码里有通过 `BackgroundColor` 给 `Lightwavelight` / `WavelengthLabel` / `Filterwheel` 上色的地方
  （按波长变色），面板配色不能盖掉这些效果。

## 6. 待 Fengyi 回答

已回答（2026-11-04）：
- 屏幕：普通 24 英寸显示器（见第 3 节）。
- 不需要调 Galvo_Z，可以去掉（见 3.2）。
- galvo X/Y 保留滑块，另加 ◀▶ 和步长下拉菜单（见 3.1），默认步长 0.01 V。
- 实现方式：**A，启动时自动排版**。
- Roll 用不到：`RollSlider`(+Label)、`RollScanButton` 隐藏。

还没回答：
1. Live View / Paint 窗口的初始位置（见 6.1）。
2. 布局有没有要调整的地方，比如某个控件放错了步骤，或者顶栏里有不常用的东西
   （`SaveImage`、`MinZ`、`Check Points` 应该放在哪里）？

### 6.1 Live View 和 Paint 窗口

现状（从代码读出）：两个都是**独立的窗口**（`figure`），不在控制界面里面。
- Live View：`EnableCamButtonPushed` 里 `app.f = figure; app.f.Position = [100 100 800 800]`，
  也就是每次从屏幕左下角弹出，正好压在控制窗口上。
- Paint：`PaintButtonValueChanged` 里 `app.paint = figure; app.paint.Position = [100 100 1024 1024]`，
  高 1024 px，比 1080 屏幕的可用高度还大，标题栏可能跑到屏幕外。
- Paint 拼图大小不受窗口限制：每次移动后把新图拼进一张大画布，裁到已拍区域再 `imshow`，
  `imshow` 会自动缩放到窗口里。样本越大，显示得越小；需要看细节时用窗口工具栏的放大镜。

建议：**仍然是独立窗口，只改弹出时的初始位置**，放在屏幕右半边（例如 `[965 50 940 940]`），
不再和控制窗口重叠。弹出后照样可以拖动、拉大、最大化，样本大时可以把 Paint 窗口拉大或最大化。
不建议把它们嵌进控制界面：嵌进去以后窗口大小就被界面限制了，而且 App Designer 的 `uiaxes`
刷新实时图像比普通 `figure` 慢。
- 实现：只改两行 `Position`（上面两个回调里），不涉及 640 Analog 代码。
- 可选：记住上次的位置，下次在同一位置弹出（关窗口时把 `Position` 存到 app 属性里）。

## 7. 最终实现（2026-11-04）

- 窗口 960 x 960，放在屏幕左半边（`[1 41 960 960]`）。顶栏高 75；①②③ 三列各约 313 宽、630 高；④ 在底部，高 235。
- Fengyi 决定：
  - 屏幕：24 英寸，控制窗口占半个屏幕，边看相机边调。
  - galvo X/Y：保留滑块，加 ◀▶ 和步长下拉（默认 0.01 V）。
  - Roll：隐藏。
  - Galvo_Z：表格里这一列隐藏，数据仍在用。
  - Live View / Paint：还是独立窗口，弹出位置改到右半边 `[965 45 945 945]`，可以照常拖动、缩放。
  - Tile States：放大（约 300 x 395），等宽字体；每个 tile 一项，两项一行，没存的显示 `---`；
    第 3 行是已存数和没存的 tile 号；更多的往下滚动。
- `.mlapp` 里改了：`startupFcn` 加一行 `applyLayout(app)`；新增公开方法 `galvoStep`；`updateTileStatus` 的显示格式；
  `EnableCamButtonPushed` / `PaintButtonValueChanged` 中窗口位置各一行。
- 在本机 R2026a 用 `createComponents` 搭了假窗口截图检查过排版；R2019a 和显微镜上的显示效果（字体、Windows 缩放）没测。
