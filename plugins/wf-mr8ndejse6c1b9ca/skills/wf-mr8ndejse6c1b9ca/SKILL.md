---
name: wf-mr8ndejse6c1b9ca
description: 运行内置的 一起共建声波档案 工作流，推进 DAG 中已就绪的节点，汇报节点结果，并持续展示专属任务看板。
---

# 一起共建声波档案

此插件无需登录 Skill Flow，不收取任务执行费，也不产生创作者运行分佣；调用 Skill Flow 官方服务时，仍可能按对应服务规则消耗用户积分。

## 看板契约

1. 用户表达创建或运行新任务的意图时，本轮流程的第一个插件工具调用必须是 `render_workflow_dashboard_widget`，参数为 `intent: "create_task"`。它成功返回后才能调用 `create_task`，二者不能放进同一个并行工具调用批次。
2. 渲染结果会自动选择最佳载体。`surface` 为 `mcp-app` 时由宿主渲染 MCP Apps 看板；为 `http` 时，立即把返回的 `dashboardUrl` 作为可点击的 HTTP 看板链接提供给用户。
3. 必须先打开看板，再准备或持久化任务，让用户能看到任务创建过程。本会话中看板已经可见时不要重复渲染，`create_task` 会更新现有看板。
4. 只有用户明确要求打开或恢复看板时，才再次以 `intent: "view"` 调用 `render_workflow_dashboard_widget`。
5. 不要在每轮对话重复渲染看板。MCP Apps 和 HTTP 两种载体都会自动轮询任务状态。

## 运行契约

1. 首次调用 `create_task` 前必须满足看板契约；每个新的用户任务只调用一次 `create_task`。
2. 调用 `start_task` 并执行所有返回的就绪节点；多个节点同时就绪时，使用子 Agent 并行执行。
3. 读取每个节点的 Context 路径，并遵循其中的任务目标和验收契约。
4. 验证节点结果后调用 `complete_node`，然后重复调用 `start_task`，直到任务完成。

## 作品发布契约

1. 不要要求用户先登录。安装、创建任务和执行节点都不以登录为前置条件。
2. 任务完成后，若 `workCollection.status` 为 `collecting`，必须把本次真实最终产出整理成一件完整 Work，并调用 `submit_task_work`。没有可在线查看或下载的产出时，提交 `not_publishable` 及真实原因。
3. Work 的 `fieldValues` 必须符合 `workCollection.showcase.dataModel`；本地资源路径使用 Task 工作区内的相对路径。
4. 已登录时 `submit_task_work` 会直接发布，不要再询问是否发布。未登录时任务仍然完成，草稿保留在看板，只在用户登录发布时续传。
5. 查看、重新发布、设为公开或不可见、删除作品分别使用看板或对应工具；`deleted` 只保留墓碑，但可用本地完整草稿重新发布。
