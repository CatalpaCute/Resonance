# Official Cloud Release Variable

GitHub Actions 发版构建现在要求注入官方折纸云地址，否则 workflow 会在打包前直接失败。

## 配置位置

在仓库里打开：

`Settings -> Secrets and variables -> Actions -> Variables`

新增一个 repository variable：

- `OFFICIAL_CLOUD_BASE_URL`

## 值怎么填

填官方折纸云 Worker 的 HTTPS 基址，例如：

```txt
https://your-worker.example.com
```

不要带尾部斜杠也可以，带了也不会影响客户端使用。

## 工作流如何使用

release workflow 会把它注入到 Flutter 构建命令里：

```txt
--dart-define=OFFICIAL_CLOUD_BASE_URL=...
```

当前已经覆盖：

- Android Release APK
- Linux Release
- Windows Release

## 为什么放 Variables

这个值通常只是公开的服务地址，不是 token、密钥或密码，所以优先放 `Variables`，不必放 `Secrets`。

如果以后官方云需要鉴权 token，再单独加 `Secrets` 即可。
