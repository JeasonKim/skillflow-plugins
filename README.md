<!-- 此文件由 SkillFlow 自动生成，请勿手动修改。 -->
# JeasonKim 的 Codex 插件市场

这是一个由 SkillFlow 自动生成并维护的 Codex 插件市场仓库。插件市场目录位于 [`.agents/plugins/marketplace.json`](./.agents/plugins/marketplace.json)，所有可安装的插件都位于 [`plugins/`](./plugins/)目录。

## 可用插件

| 插件 | 插件目录 | 安装命令 | 授权方式 |
| --- | --- | --- | --- |
| [`wf-mrk3toat216b141c`](./plugins/wf-mrk3toat216b141c) | `./plugins/wf-mrk3toat216b141c` | `codex plugin add wf-mrk3toat216b141c@jeasonkim-plugins` | 安装时完成授权 |

## 安装方法

把下面的文字发给 Codex，并将插件名替换为上表中需要安装的插件：

> 请从 https://github.com/JeasonKim/skillflow-plugins 安装 `wf-mrk3toat216b141c` Codex 插件。

Codex 会添加或更新这个插件市场，再安装指定插件。插件更新后，重新发送同样的请求即可刷新插件市场并安装最新版本。

## 给 Codex 的安装指引

当用户提供这个仓库地址并请求安装插件时，请将仓库根目录作为 Codex 插件市场，并按照以下步骤操作：

1. 从上方的“可用插件”中确认用户指定的插件。除非用户明确要求安装全部插件，否则不要批量安装。
2. 运行 `codex plugin marketplace list`，检查插件市场 `jeasonkim-plugins` 是否已经添加。
3. 如果尚未添加，运行：

   ```bash
   codex plugin marketplace add JeasonKim/skillflow-plugins --ref main
   ```

4. 如果已经添加，先运行以下命令刷新插件市场：

   ```bash
   codex plugin marketplace upgrade jeasonkim-plugins
   ```

5. 使用表格中的完整插件标识安装用户指定的插件，然后校验安装结果：

   ```bash
   codex plugin add <plugin-name>@jeasonkim-plugins
   codex plugin list
   ```

6. 安装完成后，告知用户新建一个 Codex 任务，以便加载新插件。

- GitHub 仓库：[`JeasonKim/skillflow-plugins`](https://github.com/JeasonKim/skillflow-plugins)
- 插件市场标识：`jeasonkim-plugins`
- 默认分支：`main`

## 仓库结构

```text
.agents/plugins/marketplace.json  # Codex 插件市场目录
plugins/<plugin-name>/            # 可安装的插件包
README.md                         # 自动生成的安装说明和插件索引
```

每次通过 SkillFlow 发布插件时，都会根据插件市场目录重新生成本文件。
