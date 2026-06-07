# Mouse Desktop Switcher

AutoHotkey v2 utility for controlling Windows virtual desktops with mouse
gestures.

[中文说明](README.zh-CN.md)

This project is a modified derivative of
[Mohdsuhailpgdi/MouseDesktopSwitcher](https://github.com/Mohdsuhailpgdi/MouseDesktopSwitcher).
The original project provides the AutoHotkey v2 + `VirtualDesktopAccessor.dll`
foundation for fast Windows virtual desktop switching.

The main script is:

```text
MouseDesktopMoveWindow_MiddleDrag.ahk
```

## Features

- Hold the middle mouse button and drag left or right to switch virtual desktops.
- Hold `Shift` + middle mouse button and drag left or right to move the selected
  window to an adjacent virtual desktop.
- The legacy middle-button + wheel switching script is still included for users
  who prefer the original interaction.
- Optional follow mode: after moving a window, switch to the target desktop and
  refocus that window.
- Compact on-screen HUD for desktop/move feedback.
- Emergency exit hotkey: `Ctrl + Alt + F12`.
- Native middle-button input is allowed through. The script does not use
  `Send`, `SendInput`, or `BlockInput`, reducing the risk of stuck keyboard or
  mouse state.

## Requirements

- Windows 10 with virtual desktops enabled is the default supported target for
  the bundled `VirtualDesktopAccessor.dll`.
- Windows 11 may also work, but it is more sensitive to the Windows build and
  may require replacing `VirtualDesktopAccessor.dll` with a compatible release.
- [AutoHotkey v2](https://www.autohotkey.com/download/).
- `VirtualDesktopAccessor.dll` in the same directory as the script.

`VirtualDesktopAccessor.dll` must match your Windows build. If desktop switching
or window movement fails after a Windows update, especially on Windows 11,
download a compatible release from
[Ciantic/VirtualDesktopAccessor](https://github.com/Ciantic/VirtualDesktopAccessor/releases).

## Usage

1. Install AutoHotkey v2.
2. Keep `MouseDesktopMoveWindow_MiddleDrag.ahk` and
   `VirtualDesktopAccessor.dll` in the same folder.
3. Run `MouseDesktopMoveWindow_MiddleDrag.ahk`.
4. Use:
   - Middle-button horizontal drag: switch desktop.
   - `Shift` + middle-button horizontal drag: move window to adjacent desktop.
   - `Ctrl + Alt + F12`: exit the script.

Do not run multiple scripts from this repository at the same time. They may
compete for middle-button hooks.

## Configuration

Edit the tunables near the top of `MouseDesktopMoveWindow_MiddleDrag.ahk`.

| Setting | Purpose |
| --- | --- |
| `targetWindowMode` | `"foreground"` moves the active window; `"mouse"` moves the window under the cursor. |
| `dragThresholdPx` | Horizontal drag distance required before a gesture triggers. |
| `horizontalDominance` | Requires the gesture to be clearly horizontal. Higher values reduce accidental triggers. |
| `desktopSwitchCooldownMs` | Cooldown between repeated desktop switches while dragging. |
| `followMovedWindow` | Switch to the target desktop after moving a window. |
| `focusMovedWindowAfterFollow` | Refocus the moved window after following it. |
| `wrapDesktopSwitching` | Allow switching from last desktop to first, and first to last. |
| `wrapWindowMoving` | Allow moving windows across the first/last desktop boundary. Disabled by default. |
| `leftDragMovesToNext` | Controls normal desktop switching direction. Enabled by default to preserve the original switching feel. |
| `leftDragMovesWindowToPrevious` | Controls `Shift` + middle-drag window moving direction. Enabled by default so dragging left moves a window to the previous desktop. |
| `feedbackOpacity` | HUD opacity. |
| `feedbackMs` | HUD display time. |

## Auto Start

To start automatically when Windows signs in:

1. Create a shortcut whose target is AutoHotkey v2, for example:

   ```text
   C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe
   ```

2. Set the shortcut argument to the script path, for example:

   ```text
   "C:\Path\To\MouseDesktopSwitcher\MouseDesktopMoveWindow_MiddleDrag.ahk"
   ```

3. Put the shortcut in `shell:startup`.

During testing, keep auto start disabled until the script has been stable for
normal daily use.

## Why It Feels Fast

Windows' built-in `Ctrl + Win + Left/Right` desktop shortcut goes through the
Explorer/Shell animation path. This project uses AutoHotkey v2 with
`VirtualDesktopAccessor.dll` to call virtual desktop APIs directly, which avoids
that animation path and makes switching feel much faster.

## Safety Notes

- Use `Ctrl + Alt + F12` to exit the script immediately.
- If input behaves incorrectly, close any AutoHotkey process running this script
  and remove/disable the startup shortcut.
- The current implementation does not synthesize mouse or keyboard input. It
  observes middle-button drag distance and calls virtual-desktop APIs only after
  the gesture is clear.
- Some elevated, system, pinned, minimized, hidden, or protected windows cannot
  be moved between desktops.

## Compliance Notes

- This repository is based on
  [Mohdsuhailpgdi/MouseDesktopSwitcher](https://github.com/Mohdsuhailpgdi/MouseDesktopSwitcher),
  which is MIT licensed. The original copyright notice is retained in
  `LICENSE`.
- Usage documentation was also informed by Sophran's SSPAI article on smooth
  Windows desktop switching: <https://sspai.com/post/106892>.
  The article is linked as a reference only; its prose and code blocks are not
  copied into this repository.
- Do not commit local installers such as `AutoHotkey_2.0.26_setup.exe`; users
  should download AutoHotkey from the official website.
- Keep `THIRD_PARTY_NOTICES.md` when redistributing the repository, especially
  if `VirtualDesktopAccessor.dll` is included.
- Keep the original MIT copyright notice in `LICENSE`.
- Do not commit personal startup shortcuts, local test logs, or machine-specific
  paths.

## Files

| File | Role |
| --- | --- |
| `MouseDesktopMoveWindow_MiddleDrag.ahk` | Main recommended script. |
| `VirtualDesktopAccessor.dll` | Third-party DLL used to access Windows virtual desktop APIs. |
| `MouseDesktopSwitch.ahk` | Legacy middle-button + wheel script. |
| `MouseDesktopSwitch_MiddleDrag.ahk` | Legacy middle-drag desktop switch script. |
| `THIRD_PARTY_NOTICES.md` | Third-party attribution and license notes. |

## License

This project is released under the MIT License. See `LICENSE`.

The bundled `VirtualDesktopAccessor.dll` is from
[Ciantic/VirtualDesktopAccessor](https://github.com/Ciantic/VirtualDesktopAccessor)
and is also MIT licensed. See `THIRD_PARTY_NOTICES.md`.

## References

- [Mohdsuhailpgdi/MouseDesktopSwitcher](https://github.com/Mohdsuhailpgdi/MouseDesktopSwitcher)
- [VirtualDesktopAccessor](https://github.com/Ciantic/VirtualDesktopAccessor)
- [SSPAI article by Sophran on smooth Windows desktop switching](https://sspai.com/post/106892)
