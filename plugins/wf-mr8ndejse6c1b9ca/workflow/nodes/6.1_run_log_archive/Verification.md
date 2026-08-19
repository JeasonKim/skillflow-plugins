1. [处理日志文件存在] 模板层 `nodes/1.1_input_intake/Context/data/processed_video_log.jsonl` 存在；若此前不存在，本节点已创建。
2. [处理日志安全写入] 本次任务已按 `canonicalKey` 写入 `processed_video_log.jsonl`；若 key 不存在则追加，若 key 已存在则更新同一条记录的必要字段，没有制造重复 canonicalKey。
3. [处理日志字段完整] 处理日志记录包含 workflowCode、taskCode、taskName、inputUrl、normalizedUrl、canonicalKey、sourceType、platformId、title、podcastMatched、podcastName、status、markdownOutput、htmlOutput、pdfOutput、epubOutput、createdAt、finishedAt、updatedAt、notes。
4. [不含临时索引字段] 处理日志中不包含“是否使用某个临时外部索引”“是否使用某个活动专用索引”或同类非长期查重字段。
5. [输出路径可追溯] 已尽量记录 4.1 Markdown、5.1 HTML、5.2 PDF、5.3 EPUB 的实际文件路径；缺失时说明原因。
6. [播客来源配置检查] 若本次任务命中关注播客，检查并记录是否读取 `data/podcast_watch_sources.jsonl`、`data/podcast_watch_sources.md` 和 `docs/我关注的播客清单.md`。
7. [backlog 文件存在] `data/podcast_episode_backlog.jsonl` 和 `data/podcast_episode_backlog.md` 存在；若此前不存在，本节点已创建。
8. [backlog 查重] 新增待处理单集前，已对比 `data/processed_video_log.jsonl` 和 `data/podcast_episode_backlog.jsonl`，避免重复加入已处理或已入队单集。
9. [同频道更新检查] 若本次任务能对应到某档播客、频道或节目来源，已检查该来源自上次处理后的新增内容；若未检查，说明原因。
10. [backlog 安全写入] 若发现未处理的新单集，已按 `canonicalKey` 安全写入 `data/podcast_episode_backlog.jsonl` 并同步更新 `data/podcast_episode_backlog.md`；若同 key 已存在，只更新必要字段。
11. [人工字段保护] 更新 backlog 已有记录时，没有覆盖或丢失人工维护过的 status、priority、reason、notes；如需补充说明，应追加到 notes 或只填补空字段。
12. [写后校验] 写入 `processed_video_log.jsonl` 或 `podcast_episode_backlog.jsonl` 后，已运行 `node nodes/1.1_input_intake/Context/scripts/validate_context_state.mjs`、PowerShell 版或等价 schema 校验，并记录校验结果。
13. [不自动创建任务] 本节点没有创建新 task，只维护日志和待处理候选。
14. [不臆造] 无法确认的 URL、标题、平台 ID、播客命中情况、发布日期或输出路径使用空值、unknown、uncertain 或说明，不编造确定信息。
15. [本次归档说明] 本节点 outputs 中保存本次处理日志、backlog 更新记录、目标文件路径、写入时间、校验命令、校验结果和写入成功/失败说明。
16. [未来可读] 日志和 backlog 足以让 1.1 在未来任务中判断疑似重复输入、定位历史 task、看到待处理播客候选，并提示用户手动决定是否创建新任务。