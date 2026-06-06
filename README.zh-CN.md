# Mouse Desktop Switcher

一个基于 AutoHotkey v2 的 Windows 虚拟桌面鼠标手势工具。

本项目基于
[Mohdsuhailpgdi/MouseDesktopSwitcher](https://github.com/Mohdsuhailpgdi/MouseDesktopSwitcher)
修改扩展。原项目提供了 AutoHotkey v2 + `VirtualDesktopAccessor.dll` 快速切换
Windows 虚拟桌面的基础实现。

推荐主脚本：

```text
MouseDesktopMoveWindow_MiddleDrag.ahk
```

## 功能

- 按住鼠标中键左右拖动：切换到相邻虚拟桌面。
- 按住 `Shift` + 鼠标中键左右拖动：把当前窗口移动到相邻虚拟桌面。
- 仍保留旧版中键 + 滚轮切换脚本，适合偏好原始交互的用户。
- 可选跟随模式：移动窗口后自动切换到目标桌面，并重新聚焦该窗口。
- 轻量 HUD 提示：显示当前桌面或窗口移动结果，透明、短时显示，减少打扰。
- 紧急退出快捷键：`Ctrl + Alt + F12`。
- 主脚本不使用 `Send`、`SendInput`、`BlockInput`，降低鼠标或键盘状态卡住的风险。

## 环境要求

- Windows 10 或 Windows 11，并启用虚拟桌面。
- [AutoHotkey v2](https://www.autohotkey.com/download/)。
- `VirtualDesktopAccessor.dll` 与脚本放在同一目录。

`VirtualDesktopAccessor.dll` 需要匹配当前 Windows 版本。如果 Windows 更新后出现无法切换桌面或无法移动窗口的问题，请从
[Ciantic/VirtualDesktopAccessor](https://github.com/Ciantic/VirtualDesktopAccessor/releases)
下载兼容版本。

## 使用方法

1. 安装 AutoHotkey v2。
2. 确认 `MouseDesktopMoveWindow_MiddleDrag.ahk` 和 `VirtualDesktopAccessor.dll`
   位于同一文件夹。
3. 运行 `MouseDesktopMoveWindow_MiddleDrag.ahk`。
4. 使用手势：
   - 鼠标中键水平拖动：切换虚拟桌面。
   - `Shift` + 鼠标中键水平拖动：移动窗口到相邻虚拟桌面。
   - `Ctrl + Alt + F12`：立即退出脚本。

不要同时运行仓库里的多个脚本。它们会同时监听鼠标中键，可能产生冲突。

## 配置

配置项位于 `MouseDesktopMoveWindow_MiddleDrag.ahk` 顶部。

| 配置项 | 作用 |
| --- | --- |
| `targetWindowMode` | `"foreground"` 移动当前活动窗口；`"mouse"` 移动鼠标下方窗口。 |
| `dragThresholdPx` | 触发手势需要的水平拖动距离。 |
| `horizontalDominance` | 要求拖动方向明显偏水平，数值越高越不容易误触。 |
| `desktopSwitchCooldownMs` | 按住拖动时连续切换桌面的冷却时间。 |
| `followMovedWindow` | 移动窗口后是否跟随到目标桌面。 |
| `focusMovedWindowAfterFollow` | 跟随到目标桌面后是否重新聚焦被移动的窗口。 |
| `wrapDesktopSwitching` | 切换桌面时是否允许首尾循环。 |
| `wrapWindowMoving` | 移动窗口时是否允许首尾循环，默认关闭。 |
| `leftDragMovesToNext` | 控制左右拖动与上一个/下一个桌面的映射关系。 |
| `feedbackOpacity` | HUD 透明度。 |
| `feedbackMs` | HUD 显示时间。 |

## 开机自启动

如需登录 Windows 后自动运行：

1. 创建快捷方式，目标指向 AutoHotkey v2，例如：

   ```text
   C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe
   ```

2. 将快捷方式参数设置为脚本路径，例如：

   ```text
   "C:\Path\To\MouseDesktopSwitcher\MouseDesktopMoveWindow_MiddleDrag.ahk"
   ```

3. 把快捷方式放入 `shell:startup`。

测试阶段建议先不要启用自启动，确认日常使用稳定后再启用。

## 为什么切换更快

Windows 原生的 `Ctrl + Win + 左/右` 切换会经过 Explorer/Shell 的动画流程。
本项目通过 AutoHotkey v2 调用 `VirtualDesktopAccessor.dll`，直接访问虚拟桌面
相关 API，绕开原生动画路径，因此体感切换更快。

## 安全说明

- 可以用 `Ctrl + Alt + F12` 立即退出脚本。
- 如果输入设备状态异常，关闭运行该脚本的 AutoHotkey 进程，并禁用启动项。
- 主脚本只观察鼠标中键拖动距离，并在手势明确后调用虚拟桌面 API，不模拟键盘或鼠标输入。
- 部分管理员权限窗口、系统窗口、已固定窗口、最小化窗口、隐藏窗口或受保护窗口可能无法移动到其他桌面。

## 合规说明

- 本仓库基于
  [Mohdsuhailpgdi/MouseDesktopSwitcher](https://github.com/Mohdsuhailpgdi/MouseDesktopSwitcher)
  修改，原项目为 MIT License，原始版权声明已保留在 `LICENSE`。
- 使用说明参考了 Sophran 在少数派发布的文章
  [《Windows 也能丝滑切桌面：一个 DLL 干掉原生切换延迟》](https://sspai.com/post/106892)。
  本仓库只做来源引用和内容概括，不复制文章正文和代码块。
- 不要提交本地安装包，例如 `AutoHotkey_2.0.26_setup.exe`；用户应从 AutoHotkey 官方网站下载。
- 如果仓库包含 `VirtualDesktopAccessor.dll`，请保留 `THIRD_PARTY_NOTICES.md`。
- 保留 `LICENSE` 中的原始 MIT 版权声明。
- 不要提交个人启动快捷方式、本地测试日志、机器相关路径或包含隐私信息的截图。

## 文件说明

| 文件 | 作用 |
| --- | --- |
| `MouseDesktopMoveWindow_MiddleDrag.ahk` | 推荐主脚本。 |
| `VirtualDesktopAccessor.dll` | 第三方 DLL，用于访问 Windows 虚拟桌面 API。 |
| `MouseDesktopSwitch.ahk` | 旧版中键 + 滚轮切换脚本。 |
| `MouseDesktopSwitch_MiddleDrag.ahk` | 旧版中键拖动切换脚本。 |
| `THIRD_PARTY_NOTICES.md` | 第三方组件来源和许可说明。 |

## 许可证

本项目使用 MIT License，见 `LICENSE`。

随仓库提供的 `VirtualDesktopAccessor.dll` 来自
[Ciantic/VirtualDesktopAccessor](https://github.com/Ciantic/VirtualDesktopAccessor)，
同样使用 MIT License，见 `THIRD_PARTY_NOTICES.md`。

## 参考链接

- [Mohdsuhailpgdi/MouseDesktopSwitcher](https://github.com/Mohdsuhailpgdi/MouseDesktopSwitcher)
- [VirtualDesktopAccessor](https://github.com/Ciantic/VirtualDesktopAccessor)
- [少数派：Windows 也能丝滑切桌面](https://sspai.com/post/106892)
