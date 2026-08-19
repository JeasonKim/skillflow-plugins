## 节点目标

在本次任务的主要交付完成后，把任务处理结果追加写入模板层 1.1 节点的长期处理日志，并维护关注播客的待处理名单。这个节点的目标是形成持续处理闭环：已经处理过的内容进入历史日志，发现但尚未处理的关注播客新单集进入 backlog，供用户以后手动决定是否创建 task。

本节点是归档和状态维护节点，不生成新的正文内容，不改写上游产物，不重新总结视频，也不自动创建 task。它只读取本次 task 的需求、上游节点输出清单、交付文件路径、1.1 Context 中的播客来源配置和历史状态文件，整理成结构化记录。

## 相关 Context 文件

本节点需要关注模板层 1.1 Context 中的以下文件：

- `data/processed_video_log.jsonl`：已处理历史日志，机器查重和追溯使用。
- `data/podcast_watch_sources.md`：播客更新检查来源配置，给人和 agent 阅读。
- `data/podcast_watch_sources.jsonl`：播客更新检查来源配置，给 agent 批量读取和匹配。
- `data/podcast_episode_backlog.jsonl`：待处理播客单集的结构化状态，供 agent 查重和追加。
- `data/podcast_episode_backlog.md`：待处理播客单集的人类可读看板。
- `docs/我关注的播客清单.md`：播客偏好、梯队和生态背景说明。
- `schemas/`：JSONL 字段规范。
- `scripts/validate_context_state.mjs`：跨平台状态校验脚本。

## 写入位置

长期状态只写入当前 workflow 的模板层 1.1 Context：

- 处理日志：`nodes/1.1_input_intake/Context/data/processed_video_log.jsonl`
- 播客待处理结构化状态：`nodes/1.1_input_intake/Context/data/podcast_episode_backlog.jsonl`
- 播客待处理人类可读看板：`nodes/1.1_input_intake/Context/data/podcast_episode_backlog.md`

如果这些文件不存在，应创建。JSONL 写入方式必须按 `canonicalKey` 安全追加或更新，不要简单无脑追加，也不要覆盖旧内容。Markdown 看板可以重写表格，但不得丢失已有有效待办和历史状态。

## JSONL 写入原则

写入 `processed_video_log.jsonl` 或 `podcast_episode_backlog.jsonl` 时，必须把 `canonicalKey` 当作主键：

- 如果 `canonicalKey` 不存在，才追加新记录。
- 如果 `canonicalKey` 已存在，应更新同一条记录的必要字段，例如 status、matchedProcessedTaskCode、updatedAt、输出路径、处理说明或 notes。
- 更新 backlog 时，不得覆盖或丢失人工维护过的 status、priority、reason、notes 等字段。若需要补充说明，应在原 notes 后追加简短说明，或只填补空字段。
- 对 backlog 中已经是 processed、skipped 或人工标注过 priority/reason 的记录，不要因为刷新来源而重置成 todo。
- 写入前后应尽量保持 JSONL 字段符合 `schemas/` 中的 schema。

## 处理日志字段

每条 `processed_video_log.jsonl` 建议包含：taskCode、taskName、workflowCode、inputUrl、normalizedUrl、canonicalKey、sourceType、platformId、title、podcastMatched、podcastName、status、markdownOutput、htmlOutput、pdfOutput、epubOutput、createdAt、finishedAt、updatedAt、notes。无法确认的字段使用空值、unknown、uncertain 或说明，不编造成确定信息。

## 播客 backlog 字段

每条 `podcast_episode_backlog.jsonl` 建议包含：podcastName、podcastTier、episodeTitle、episodeUrl、episodeId、canonicalKey、source、publishedAt、status、discoveredAt、lastCheckedAt、matchedProcessedTaskCode、priority、reason、sourceConfidence、notes。Markdown 看板应围绕同一信息维护人类可读表格，方便用户快速浏览待处理候选。

## 任务结束后的处理步骤

1. 读取 task requirement，提取原始输入、任务名和关键约束。
2. 读取上游主要节点 outputs 或交付清单，确认 Markdown、HTML、PDF、EPUB 的实际路径。
3. 尽量从 1.1、2.1 或 4.1 的说明中提取标题、来源类型、平台 ID、规范化 URL 和播客命中情况。
4. 按 `canonicalKey` 将本次任务记录安全写入 `data/processed_video_log.jsonl`：不存在则追加，已存在则更新必要字段。
5. 如果本次任务命中了关注播客，读取 `data/podcast_watch_sources.jsonl` 和 `data/podcast_watch_sources.md`，找到该播客或频道的更新检查来源。
6. 在可行范围内检查该播客或频道自上次处理以来的更新。优先使用官方 YouTube、Apple Podcasts、节目官网、RSS 或来源配置中指定的渠道。这里的重点是延续同一频道的处理线索，而不是漫无目的地搜索全网。
7. 将最近更新与 `data/processed_video_log.jsonl` 和 `data/podcast_episode_backlog.jsonl` 比对。已经处理过或已在 backlog 中的单集不要重复添加。
8. 对未处理、未入队的新单集，按 `canonicalKey` 安全写入 `data/podcast_episode_backlog.jsonl`，并同步更新 `data/podcast_episode_backlog.md` 看板；若条目已存在，只更新必要字段，不覆盖人工维护字段。
9. 写入 `processed_video_log.jsonl` 或 `podcast_episode_backlog.jsonl` 后，必须运行 `node nodes/1.1_input_intake/Context/scripts/validate_context_state.mjs`，或运行 PowerShell 版/等价 schema 校验。
10. 在本节点 outputs 中保存本次处理日志、backlog 更新记录、目标文件路径、写入时间、校验命令、校验结果和成功/失败说明。

## 边界

- 不修改 4.1、5.1、5.2、5.3 已交付文件。
- 不自动创建 task。backlog 只记录候选，是否创建新 task 必须由用户明确指挥。
- 不把日志或 backlog 只写入 task outputs；task outputs 只能保存本次归档说明，长期状态必须写入 1.1 Context。
- 不为补齐日志字段重新下载完整视频或重新生成逐字稿。
- 检查播客更新时只做轻量来源检查；遇到登录、反爬、来源不稳定或无法确认时，应标为 uncertain 或记录失败原因。
- 不把缺失字段编造成确定信息。
- 如果多个任务并发写入同一个日志或 backlog 文件，应尽量避免覆盖；必须以 `canonicalKey` 查重后写入，并在写入说明中记录时间和 taskCode。