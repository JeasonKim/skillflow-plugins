---
name: wf-mrk3toat216b141c
description: Run the bundled 紫微斗数 workflow, advance ready DAG nodes, report node results, and show its branded native task dashboard beside the conversation.
---

# 紫微斗数

This plugin runs without Skill Flow login, task execution fees, or creator usage commission. Official Skill Flow services may still consume the user's credits normally.

## Native dashboard contract

1. When the user expresses intent to create or run a new task, the first plugin tool call in that flow must be `render_workflow_dashboard_widget` with `intent: "create_task"`. Wait for it to succeed before calling `create_task`; never send both calls in the same parallel tool batch.
2. Open the dashboard before preparing or persisting the task so the user can watch task creation. If the widget is already visible in this conversation, do not render it again; `create_task` will update the existing widget.
3. Call `render_workflow_dashboard_widget` with `intent: "view"` again only when the user explicitly asks to open or restore the dashboard.
4. Do not render the widget again on every turn while it is already visible. The widget polls task state automatically.
5. The native widget is the only dashboard surface.

## Run contract

1. Satisfy the dashboard contract before the first `create_task`, then call `create_task` exactly once for each new user task.
2. Call `start_task` and execute every returned ready node. When multiple nodes are ready, use sub-agents in parallel.
3. Read each node's Context paths and follow its mission and verification contract.
4. Call `complete_node` after verifying a node. Repeat `start_task` until the task completes.
