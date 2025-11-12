# 模式切换指南（Claude Code Permissions Modes）

本模板默认：
```jsonc
{
  "permissions": {
    "defaultMode": "bypassPermissions"
  }
}
```

## 1) 切到更安全的 Accept-Edits 模式并**禁用绕过**
把用户级设置改成：
```jsonc
{
  "permissions": {
    "defaultMode": "acceptEdits",
    "disableBypassPermissionsMode": "disable"
  }
}
```
（无脚本）直接编辑 `~/.claude/settings.json`。

## 2) 恢复为绕过模式
删除上面的禁用键并设定默认模式：
```jsonc
{
  "permissions": {
    "defaultMode": "bypassPermissions"
  }
}
```
（无脚本）直接编辑 `~/.claude/settings.json`。

## 3) 自定义模式值
如果你有其他模式值（例如企业镜像预设的模式字符串），请直接编辑 `~/.claude/settings.json` 的：
```jsonc
{ "permissions": { "defaultMode": "<mode-string>" } }
```

> 注意：如果你的电脑/容器存在 **企业托管的 managed-settings.json** 禁用了绕过模式，那么用户级/项目级设置不会生效。需要改由管理员下发的那份策略后再切换。
