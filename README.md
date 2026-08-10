<!-- 此文件由 Skill Flow 自动生成，请勿手动修改。 -->
# JeasonKim 的 Skill Flow Agent 插件仓库

这是一个跨平台 Agent 插件仓库。每个 Skill Flow 都会同时提供 Codex、Claude Code 与 WorkBuddy 入口，插件主体统一放在 [`plugins/`](./plugins/) 目录中。

仓库由 [Skill Flow](https://skillflow.penstairs.com) 自动生成和维护，发布内容仍归创作者所有。

## 可用插件

| 插件名称 | Code | 支持平台 |
| --- | --- | --- |
| 紫微斗数人生报告 | [`wf-mrk3toat216b141c`](./plugins/wf-mrk3toat216b141c) | Codex、Claude Code、WorkBuddy |

## Codex 安装方法

把下面的文字发给 Codex，并将插件名替换为上表中需要安装的插件：

> 请从 https://github.com/JeasonKim/skillflow-plugins 安装“紫微斗数人生报告”Codex 插件。

也可以直接运行：

```bash
codex plugin marketplace add JeasonKim/skillflow-plugins --ref main
codex plugin add wf-mrk3toat216b141c@jeasonkim-plugins
codex plugin list
```

首次安装后开启新对话；已有插件升级后，完整退出并重新启动 Codex Desktop，再开启新对话。

## Claude Code 安装方法

把下面的文字发给 Claude Code：

> 请从 https://github.com/JeasonKim/skillflow-plugins 安装“紫微斗数人生报告”Claude Code 插件。

```bash
claude plugin marketplace add JeasonKim/skillflow-plugins@main
claude plugin install wf-mrk3toat216b141c@jeasonkim-plugins
claude plugin list
```

仓库更新后运行 `claude plugin marketplace update jeasonkim-plugins`，再更新对应插件。

## WorkBuddy 安装方法

把下面的文字发给 WorkBuddy：

> 请从 https://github.com/JeasonKim/skillflow-plugins 安装“紫微斗数人生报告”WorkBuddy 专家。

安装 Agent 必须先读取根目录的 [`workbuddy-install.json`](./workbuddy-install.json)，并以其中的目标市场、分支和专家列表为准。

这些 WorkBuddy 产物是专家包。目标市场固定为 `my-experts`，不要把本仓库注册为普通的自定义 Marketplace；自定义 Marketplace 中的插件不会出现在专家中心。

将选中的 `plugins/<plugin-name>` 安装到 `$WORKBUDDY_CONFIG_DIR/plugins/marketplaces/my-experts/plugins`（未设置时默认 `~/.workbuddy/plugins/marketplaces/my-experts/plugins`），再按 WorkBuddy 内置 `expert-manager` 执行校验和注册。仓库分支使用 `main`。

连接专家依赖时，WorkBuddy 会把插件中的 MCP 声明写入 `custom-mcp`。必须原样保留自定位启动参数，不能替换为 `CODEBUDDY_PLUGIN_ROOT`；连接后检查 MCP 配置中没有未解析的 `PLUGIN_ROOT`，并确认工具列表包含 `render_workflow_dashboard_widget`。如果连接或工具校验失败，停止安装并报告。

安装成功后在【专家中心 → 我的专家】中查找：

| 专家 | 专家中心分类 | 技术名称 |
| --- | --- | --- |
| 紫微斗数人生报告 | 行业顾问 | `wf-mrk3toat216b141c` |

## 仓库信息

- GitHub 仓库：[`JeasonKim/skillflow-plugins`](https://github.com/JeasonKim/skillflow-plugins)
- 默认分支：`main`
- 开源协议：[MIT](./LICENSE)

## 仓库结构

```text
.skillflow/catalog.json            # 三个平台共用的插件目录事实源
.agents/plugins/marketplace.json   # Codex 插件市场目录
.claude-plugin/marketplace.json    # Claude Code 插件市场目录
.codebuddy-plugin/marketplace.json # WorkBuddy 插件市场目录
workbuddy-install.json             # WorkBuddy 专家安装目标与分支契约
plugins/<plugin-name>/             # 各平台共用的 Skill Flow 插件分包
LICENSE                            # MIT License
README.md                          # 自动生成的安装说明和插件索引
```

三个 marketplace 文件都由 [`.skillflow/catalog.json`](./.skillflow/catalog.json) 生成，请勿分别手工修改。
