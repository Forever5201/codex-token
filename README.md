# Codex 模型切换器 (Codex Model Switcher)

> 给 **Codex 桌面版 / CLI** 一键切换默认模型和自定义 model provider 的本地小工具。
> 零依赖、纯 Python 标准库、单文件、跨平台。

Codex 桌面版没有给自定义 provider 提供模型选择器（见
[openai/codex#15138](https://github.com/openai/codex/issues/15138)），
但 App 会读取 `~/.codex/config.toml`。本工具开一个**本地网页**，点一下就安全地
改写这个文件来切换默认模型 / provider，**不会破坏**你已有的
`plugins` / `mcp_servers` / `projects` 等任何配置，每次写入前自动备份。

---

## ✨ 特性

- **零依赖**：只用 Python 标准库，`python3 switcher.py` 即可，无需 pip。
- **不破坏现有配置**：行级精准编辑，只动根级 `model` / `model_provider` 并新增/更新
  `[model_providers.<id>]` 块；连块内你手加的额外键、以及子表
  （`[model_providers.x.http_headers]` 等）都原样保留。
- **预设常用国产/第三方模型**：DeepSeek、Kimi(Moonshot)、智谱 GLM，可一键添加自定义 provider。
- **两种密钥模式**：内联到 config（桌面版 GUI 推荐）/ 环境变量（CLI 推荐）。
- **安全**：仅监听 `127.0.0.1` + 一次性随机 token + Host 校验；密钥不回传前端；
  含明文 key 的配置强制 `600` 权限。
- **稳**：原子写（写临时文件再 `os.replace`）+ 自动备份；正确处理 BOM / CRLF / 单引号 TOML 值。
- **跨平台**：macOS（`.command`）/ Windows（`.bat`）双击启动器。

---

## 🚀 安装与启动

需要本机已安装 **Python 3.7+**（Windows 在 [python.org](https://www.python.org) 下载时
记得勾选 “Add Python to PATH”）。

**macOS / Linux**

```bash
git clone https://github.com/Forever5201/codex-token.git
cd codex-token
python3 switcher.py          # 或双击 “启动切换器.command”
```

**Windows**

```bat
git clone https://github.com/Forever5201/codex-token.git
cd codex-token
py -3 switcher.py            :: 或双击 “启动切换器.bat”
```

启动后终端会打印一条带 token 的链接（并自动尝试打开浏览器）：

```
http://127.0.0.1:8765/?t=xxxxxxxx
```

> ⚠️ 必须用这条**带 `?t=...` 的链接**访问。直接开 `http://127.0.0.1:8765/` 会显示提示页，
> 这是安全设计。**每次重启切换器 token 都会变**，旧标签页会失效——重启后请用终端里的新链接。

---

## 🖱️ 使用

1. 卡片列出 OpenAI（内置）+ DeepSeek / Kimi / GLM 预设。
2. 点某个 provider 的「编辑」，填 `base_url` / `model` / API Key，保存。
3. 点「切到这个」即把它设为默认。
4. **回到 Codex 桌面版，开一个新会话**（或重启 App）才生效——
   已有会话的模型存在数据库里，不受 config 影响。

---

## ⚠️ 两个关键坑

### 1. 协议：`wire_api`

DeepSeek / Kimi / GLM 都是 **Chat Completions** 协议，而新版 Codex 只认
`wire_api = "responses"`（旧的 `chat` 已弃用）。**直连能否成功取决于你的 Codex 版本**：

- 直连可用 → 直接填官方 `base_url`。
- 直连报协议 / 格式错误 → 需要一层**翻译代理**把 Responses ↔ Chat 互转：
  [LiteLLM](https://github.com/BerriAI/litellm) / [OpenRouter](https://openrouter.ai/) / CLIProxyAPI。
  起好代理后，把该 provider 的 `base_url` 改成代理地址、`model` 用代理暴露的模型名即可，其它照旧。

### 2. 密钥：桌面版 GUI 读不到 shell 环境变量

- **macOS**：Finder/Dock 启动的 App 不继承 `.zshrc` 的 `export`。桌面版用「内联到 config」模式，
  或 `launchctl setenv KEY value` 后重启；CLI 用「环境变量」模式 `export KEY=value`。
- **Windows**：GUI App 读取用户级环境变量（设置后需重启 App）。桌面版用内联模式，
  或 `setx KEY value`；CLI 用 `set KEY=value`。

> 内联密钥是明文保存在 `~/.codex/config.toml`（mac/Linux 权限 600）。
> **切勿把 config.toml 上传、分享或提交到 git。**

---

## 📋 预设端点参考

| Provider | base_url（直连） | 示例 model | 环境变量 |
|---|---|---|---|
| DeepSeek | `https://api.deepseek.com/v1` | `deepseek-chat` / `deepseek-reasoner` | `DEEPSEEK_API_KEY` |
| Kimi (Moonshot) | `https://api.moonshot.cn/v1` | `kimi-k2-0905-preview` | `MOONSHOT_API_KEY` |
| 智谱 GLM | `https://open.bigmodel.cn/api/paas/v4` | `glm-4.6` | `ZHIPUAI_API_KEY` |

> GLM 若用 Coding Plan，端点是 `https://open.bigmodel.cn/api/coding/paas/v4`。
> 模型名以各家官方文档为准，可在编辑框里随时改。

---

## 🔧 工作原理

Codex 读取 `~/.codex/config.toml`。本工具：

- 用行级编辑只改写**根级** `model` / `model_provider`，并新增/更新 `[model_providers.<id>]` 块；
- 自己的预设存在 `~/.codex/.codex-switcher-presets.json`；
- 每次写入前备份为 `config.toml.bak.switcher-<时间戳>`，并采用原子写避免中途崩溃损坏配置。

可用环境变量定制：

| 变量 | 作用 |
|---|---|
| `CODEX_HOME` | Codex 目录（默认 `~/.codex`） |
| `SWITCHER_PORT` | 监听端口（默认 `8765`） |
| `SWITCHER_HOST` | 监听地址（默认 `127.0.0.1`） |
| `SWITCHER_NO_BROWSER` | 设置后不自动打开浏览器 |

---

## 🧱 已知限制

工具用行级编辑而非完整 TOML 解析器，以下罕见写法不支持（正常配置不受影响）：

- 跨进程文件锁：你和 Codex / 编辑器同时改 config 的极端情况无锁（有备份兜底）；
- 手写的畸形 TOML（重复表、根级跨多行数组且续行以 `[` 开头）不处理。

需要 100% 覆盖这些就得引入完整 TOML 库，会增加依赖且重排整个文件，故不采用。

---

## ♻️ 还原

每次写入都有备份。要还原，找到最近的
`~/.codex/config.toml.bak.switcher-*` 覆盖回 `config.toml` 即可。

---

## 📁 文件结构

```
switcher.py            主程序（本地 HTTP 服务 + 网页），三大系统通用
启动切换器.command      macOS 双击启动器
启动切换器.bat          Windows 双击启动器
README.md
```

---

## ⚖️ 免责声明

本工具仅在本机改写你自己的 Codex 配置文件，不上传任何数据。接入第三方模型的合规性、
费用与可用性由各模型服务商决定，与本工具无关。
