<!-- 此文件由 SkillFlow 自动生成，请勿手动修改。 -->
# JeasonKim 的 Skill Flow Agent 插件仓库

这是一个由 SkillFlow 自动生成并维护的 Agent 插件仓库。同一个 GitHub 仓库按平台维护独立的插件市场清单，插件主体统一放在 [`plugins/`](./plugins/) 目录中。

## 可用插件

| 插件 | 支持平台 |
| --- | --- |
| [`wf-mrk3toat216b141c`](./plugins/wf-mrk3toat216b141c) | Codex、Claude Code |

## Codex 安装方法

把下面的文字发给 Codex，并将插件名替换为上表中需要安装的插件：

> 请从 https://github.com/JeasonKim/skillflow-plugins 安装 `wf-mrk3toat216b141c` Codex 插件。

也可以直接运行：

```bash
codex plugin marketplace add JeasonKim/skillflow-plugins --ref main
codex plugin add wf-mrk3toat216b141c@jeasonkim-plugins
codex plugin list
```

首次安装后开启新对话；已有插件升级后，完整退出并重新启动 Codex Desktop，再开启新对话。

## Claude Code 安装方法

```bash
claude plugin marketplace add JeasonKim/skillflow-plugins@main
claude plugin install wf-mrk3toat216b141c@jeasonkim-plugins
claude plugin list
```

仓库更新后运行 `claude plugin marketplace update jeasonkim-plugins`，再更新对应插件。

## 仓库信息

- GitHub 仓库：[`JeasonKim/skillflow-plugins`](https://github.com/JeasonKim/skillflow-plugins)
- 默认分支：`main`

## 仓库结构

```text
.agents/plugins/marketplace.json   # Codex 插件市场目录
.claude-plugin/marketplace.json    # Claude Code 插件市场目录
plugins/<plugin-name>/             # 各平台共用的 Skill Flow 插件分包
README.md                          # 自动生成的安装说明和插件索引
```

每次通过 SkillFlow 发布任一 Agent 平台插件时，都会根据仓库内各平台的插件市场清单重新生成本文件。
