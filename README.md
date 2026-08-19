<!-- 此文件由 Skill Flow 自动生成，请勿手动修改。 -->
# JeasonKim 的 Skill Flow Agent 插件仓库

这是一个跨平台 Agent 插件仓库。每个 Skill Flow 都会同时提供 Codex、Claude Code 与 WorkBuddy 入口，插件主体统一放在 [`plugins/`](./plugins/) 目录中。

仓库由 [Skill Flow](https://skillflow.penstairs.com) 自动生成和维护，发布内容仍归创作者所有。

## 可用插件

| 插件名称 | Code | 支持平台 |
| --- | --- | --- |
| 一起共建声波档案 | [`wf-mr8ndejse6c1b9ca`](./plugins/wf-mr8ndejse6c1b9ca) | Codex、Claude Code、WorkBuddy |
| 紫微斗数人生报告 | [`wf-mrk3toat216b141c`](./plugins/wf-mrk3toat216b141c) | Codex、Claude Code、WorkBuddy |

## 发给 Agent 的安装提示

复制下面整段发给当前 Agent；需要安装其他插件时只替换插件名称：

```text
请从 https://github.com/JeasonKim/skillflow-plugins 安装“一起共建声波档案”。先在 README 的“可用插件”中按名称找到 Code，以下 <code> 使用该值；只执行当前平台对应步骤。

Codex：
codex plugin marketplace add JeasonKim/skillflow-plugins --ref main
codex plugin add <code>@jeasonkim-plugins
codex plugin list

Claude Code：
claude plugin marketplace add JeasonKim/skillflow-plugins@main
claude plugin install <code>@jeasonkim-plugins
claude plugin list

WorkBuddy：
1. 读取 workbuddy-install.json；把 plugins/<code> 安装到 my-experts，并用内置 expert-manager 校验、注册。不要把本仓库注册为普通的自定义 Marketplace。
2. 将 .codebuddy-plugin/plugin.json 的 mcpServers 原样合并到 mcp.json，必须保留 runtime.type=node，且不能含未解析的 PLUGIN_ROOT。
3. 设置 settings.json 的 enabledPlugins["<code>@my-experts"]=true；信任配置由 WorkBuddy UI 写入，不要预写。
4. 完整重启 WorkBuddy，并开启新会话。若仍无工具，停止并检查 render_workflow_dashboard_widget、create_task、start_task、complete_node、submit_task_work、get_task_status。
```

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
