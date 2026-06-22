# Codex 模型切换器

给 **Codex 桌面版 / CLI** 切换默认模型和自定义 model provider 的本地小工具。
零依赖（纯 Python 标准库），一个网页点一下就改写 `~/.codex/config.toml`。

## 为什么需要它

Codex 桌面版没有给自定义 provider 提供模型选择器（见
[issue #15138](https://github.com/openai/codex/issues/15138)），
但 App 会读取 `~/.codex/config.toml`。本工具就是用安全的**行级编辑**去改这个文件——
只动根级的 `model` / `model_provider`，并按需追加 `[model_providers.<id>]` 块，
**不会破坏**你已有的 plugins / mcp_servers / projects 等配置，且每次写入前自动备份
（`config.toml.bak.switcher-<时间戳>`）。

## 启动

**macOS / Linux**
- 双击 `启动切换器.command`，或终端运行：

```bash
cd codex-model-switcher
python3 switcher.py
```

**Windows**
- 双击 `启动切换器.bat`，或在 PowerShell / CMD 运行：

```bat
cd codex-model-switcher
py -3 switcher.py
```

> 需要已安装 Python 3.7+（Windows 在 <https://python.org> 下载时记得勾选
> “Add Python to PATH”）。脚本本身零依赖、纯标准库，三大系统通用。
> `.command` 仅 macOS 可用，`.bat` 仅 Windows 可用。

然后浏览器打开 <http://127.0.0.1:8765>（脚本会自动尝试打开）。

## 用法

1. 卡片列出 OpenAI（内置）+ DeepSeek / Kimi / 智谱 GLM 预设。
2. 点某个 provider 的「编辑」，填 `base_url` / `model` / API Key，保存。
3. 点「切到这个」即把它设为默认。
4. **回到 Codex 桌面版，开一个新会话**（或重启 App）才生效——
   已有会话的模型存在数据库里，不受 config 影响。

## ⚠️ 两个关键坑

### 1. 协议：`wire_api`

DeepSeek / Kimi / GLM 都是 **Chat Completions** 协议，而新版 Codex 只认
`wire_api = "responses"`（旧的 `chat` 已弃用）。**直连能否成功取决于你的 Codex 版本**：

- 直连可用 → 直接填官方 `base_url` 即可。
- 直连报协议/格式错误 → 需要一层**翻译代理**，把 Responses ↔ Chat 互转：
  - [LiteLLM](https://github.com/BerriAI/litellm)（本地起一个代理，`base_url` 指向它）
  - [OpenRouter](https://openrouter.ai/)（云端聚合）
  - CLIProxyAPI（社区方案，专门转国产模型）

  起好代理后，在切换器里把该 provider 的 `base_url` 改成代理地址、`model` 用代理暴露的模型名即可，**其它照旧**。

### 2. 密钥：桌面版 GUI 读不到 shell 环境变量

**macOS**：从 Finder/Dock 启动的 App **不继承** `.zshrc` 里的 `export`。所以：

- **桌面版 App** → 用「内联到 config」模式（密钥写进 `experimental_bearer_token`，明文），
  或运行 `launchctl setenv DEEPSEEK_API_KEY 你的key` 后重启 App。
- **CLI** → 用「环境变量」模式，`export DEEPSEEK_API_KEY=你的key` 即可。

**Windows**：GUI App 会读取用户级环境变量（设置后需重启 App 才生效）。

- **桌面版 App** → 用「内联到 config」模式，或在 CMD 跑
  `setx DEEPSEEK_API_KEY 你的key`（或在“系统属性 → 环境变量”里添加），然后重启 App。
- **CLI** → 当前会话 `set DEEPSEEK_API_KEY=你的key`，或用上面的 `setx` 永久生效。

> 内联密钥是明文保存在 `~/.codex/config.toml`（macOS/Linux 文件权限 600）。
> **切勿把 config.toml 上传、分享或提交到 git。**

## 预设端点参考

| Provider | base_url（直连） | 示例 model | 环境变量 |
|---|---|---|---|
| DeepSeek | `https://api.deepseek.com/v1` | `deepseek-chat` / `deepseek-reasoner` | `DEEPSEEK_API_KEY` |
| Kimi (Moonshot) | `https://api.moonshot.cn/v1` | `kimi-k2-0905-preview` | `MOONSHOT_API_KEY` |
| 智谱 GLM | `https://open.bigmodel.cn/api/paas/v4` | `glm-4.6` | `ZHIPUAI_API_KEY` |

> GLM 若用 Coding Plan，端点是 `https://open.bigmodel.cn/api/coding/paas/v4`。
> 模型名以各家官方文档为准，可在编辑框里随时改。

## 文件说明

- `switcher.py` —— 全部逻辑（本地 HTTP 服务 + 网页），三大系统通用
- `启动切换器.command` —— macOS 双击启动器
- `启动切换器.bat` —— Windows 双击启动器
- 切换器自己的预设存在 `~/.codex/.codex-switcher-presets.json`

## 还原

每次写入都有备份。要还原，找到最近的
`~/.codex/config.toml.bak.switcher-*`，覆盖回 `config.toml` 即可。
