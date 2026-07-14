# HealthLife DevEco GLM-5.1 Bridge

该桥接只用于本地开发与演示。HarmonyOS 应用本身不能执行 Windows PowerShell/Node 命令，因此由开发机运行桥接，再通过 HDC 把设备回环端口转发到开发机。

## 启动

确保已执行 `deveco auth login`，并连接 DevEco Studio 模拟器或真机，然后在项目根目录运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\deveco-bridge\start-bridge.ps1
```

启动脚本会执行等价于下面的端口映射：

```powershell
hdc rport tcp:8787 tcp:8787
```

应用通过 `http://127.0.0.1:8787/chat` 访问桥接。桥接内部另行启动只监听 `127.0.0.1` 且启用随机 Basic Auth 的 `deveco serve`，不会把 DevEco 的 Provider、文件或命令接口暴露给应用。

## 安全边界

- 使用独立 `healthlife` Agent，所有工具权限均为 `deny`。
- DevEco 服务与桥接都只监听本机回环地址。
- 单次输入最多 4000 字符，请求体最多 32 KiB。
- 对话 30 分钟无活动后从 DevEco 会话存储中删除；停止桥接时也会清理本次运行创建的会话。
- GLM-5.1 实际仍通过 DevEco 在线服务推理，并不是端侧离线模型。

该方案依赖开发机、DevEco 登录状态和免费模型通道，不适合作为应用上架后的生产后端。
