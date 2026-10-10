# QA 证据说明

本目录保存可复核的构建、前台状态、设备截图和交互验证证据。

## 命名

- 构建记录：`YYYY-MM-DD-build.md`
- 交互记录：`YYYY-MM-DD-interaction.md`
- 审查记录：`YYYY-MM-DD-security-audit.md`
- 修复回归：`YYYY-MM-DD-remediation.md`
- 前台证明：`YYYY-MM-DD-foreground.txt`
- 截图：`screenshots/YYYY-MM-DD-<scene>.png`

## 记录要求

- 写明设备/模拟器、系统版本、构建变体、包名和 Ability。
- 交互记录包含操作前状态、用户动作、操作后状态与结论。
- 只记录必要日志，不保存签名口令、私钥、令牌或个人信息。
- 没有设备证据时使用 `blocked`，不能把构建通过写成真机通过。

