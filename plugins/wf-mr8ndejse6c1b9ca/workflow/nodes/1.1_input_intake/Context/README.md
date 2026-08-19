# 1.1 Context：长视频输入与播客状态库

这个目录是「长视频转可阅读文本」workflow 的 1.1 输入接收节点长期参考区。它不是某一次 task 的临时输入，而是用于识别关注播客、记录处理历史、维护待处理候选和固定结构化数据字段。

发布版保留播客来源清单和通用字段规范，默认清空执行历史与 backlog 进展。新用户安装后可以直接基于已有播客来源启动检查，不需要重新准备关注清单；后续任务会逐步写入自己的处理日志和待处理候选。

## 目录结构

- `data/`
  - `podcast_watch_sources.jsonl`：播客更新来源的机器可读主数据。
  - `podcast_watch_sources.md`：播客更新来源的人类可读看板。
  - `processed_video_log.jsonl`：已处理视频日志，发布版初始为空。
  - `podcast_episode_backlog.jsonl`：待处理播客候选，发布版初始为空。
  - `podcast_episode_backlog.md`：待处理播客候选的人类可读看板，发布版仅保留表头。
- `docs/`
  - `我关注的播客清单.md`：播客范围、分层和背景资料。
  - `硅谷最火科技播客研究报告.docx`：播客研究报告交付版，可作为来源补充参考。
- `schemas/`
  - 三个 JSONL 文件的字段规范和说明。
- `scripts/`
  - `validate_context_state.mjs`：跨平台校验脚本，推荐 macOS/Linux/Windows 使用。
  - `validate_context_state_V1_20260627.ps1`：PowerShell 校验脚本，适合 Windows 或已安装 `pwsh` 的 macOS/Linux。
  - `refresh_backlog_and_enhance_processed_V1_20260627.ps1`：历史批量刷新脚本，保留作参考；日常维护优先做增量安全写入。

## 使用规则

当任务涉及播客、a16z、硅谷科技、AI、VC、创业或产品增长时，1.1 节点应读取本目录：

1. 判断内容是否命中关注播客范围。
2. 用 `data/processed_video_log.jsonl` 检查是否疑似重复处理。
3. 用 `data/podcast_episode_backlog.jsonl` 或 `data/podcast_episode_backlog.md` 检查是否来自待处理候选。
4. 把命中的节目背景、重复检查和待处理来源写入 1.1 输出，供后续节点使用。

任务结束后，归档节点负责维护长期状态：

1. 按 `canonicalKey` 将本次任务写入 `data/processed_video_log.jsonl`。
2. 如果任务来自 backlog，将对应候选安全更新为已处理。
3. 如果能对应到某档播客或频道，可轻量检查该来源新增内容，并把未处理候选写入 backlog。
4. 写入后运行 `node scripts/validate_context_state.mjs` 或等价校验。

## 边界

- 不自动创建 task。backlog 只保存候选，是否创建任务必须由用户明确指挥。
- 不把播客清单或研究报告当成逐字稿来源。
- 不伪造链接、标题、发布时间、嘉宾、节目状态或历史处理记录。
- 空的 `processed_video_log.jsonl` 只表示发布版尚未积累历史，不表示现实中从未处理过相关内容。
- 空的 backlog 只表示发布版尚未积累待处理候选，不表示关注播客没有新内容。

