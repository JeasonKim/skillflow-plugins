# 给 Agent 的说明：使用 1.1 Context

这个目录是 1.1 输入接收节点的长期参考区。它帮助判断用户关注范围、历史处理状态和播客待处理候选，但不能代替用户下任务，也不能代替真实网页核验。

## 先读什么

- 总览：`README.md`
- 播客范围：`docs/我关注的播客清单.md`
- 播客来源主数据：`data/podcast_watch_sources.jsonl`
- 人类可读来源表：`data/podcast_watch_sources.md`
- 已处理日志：`data/processed_video_log.jsonl`
- 待处理候选：`data/podcast_episode_backlog.jsonl` 和 `data/podcast_episode_backlog.md`
- 字段规范：`schemas/`
- 校验入口：`node scripts/validate_context_state.mjs`

## 创建任务前

用户问“我关注的播客”“a16z 播客”“有哪些没处理”“之前是否处理过”时，先查本目录再回答。若用户没有明确指定要创建哪条任务，先列候选让用户确认，不要自动创建 task。

用户给了精确链接时，可以直接围绕该链接创建任务；如果 `data/processed_video_log.jsonl` 命中疑似重复，只提醒用户，不要直接拒绝重跑。

## 节点执行时

1.1 输入接收节点应记录：

- 是否读取 1.1 Context。
- 命中的节目、机构、清单或 backlog 条目。
- 是否发现历史处理记录。
- 这些信息对后续转录、成稿和归档的影响。

归档节点应维护：

- `data/processed_video_log.jsonl`
- `data/podcast_episode_backlog.jsonl`
- `data/podcast_episode_backlog.md`

维护 JSONL 后必须运行或等价执行校验，并在节点 outputs 中记录校验结果。

## 边界

- 不自动创建 task。
- 不把播客清单当成视频或音频正文。
- 不把历史检索标记当成真实 URL。
- 不把空日志理解成没有历史，只能说明当前发布版状态尚未积累或已被重置。
- 不把空 backlog 理解成没有待处理内容，只能说明当前发布版尚未积累候选或已被重置。
- 不修改 Mission 或 Verification；模板契约变更必须由 workflow 层通过 update workflow 完成。

