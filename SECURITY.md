# Security Policy

## Supported Version

Only the latest version of `MouseDesktopMoveWindow_MiddleDrag.ahk` in this
repository is supported.

## Reporting

Please report bugs or security concerns through GitHub Issues.

Avoid posting sensitive local details such as full user names, private file
paths, screenshots containing personal data, or workplace-specific system
information.

## Input Safety

This project installs mouse hooks through AutoHotkey and calls Windows virtual
desktop APIs. It is intended for local desktop use only.

The main script does not use `Send`, `SendInput`, or `BlockInput`. If input
behaves incorrectly, exit the script with `Ctrl + Alt + F12` or stop the
AutoHotkey process from Task Manager.
