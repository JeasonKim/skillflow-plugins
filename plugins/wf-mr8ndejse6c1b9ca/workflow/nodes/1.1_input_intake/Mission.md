确认本次任务的在线视频输入、目标交付形态和关键约束。输入可以是 YouTube 链接、任意网页 URL、平台视频页、文章页中的嵌入视频、播放器页面、视频直链、音频直链，或用户提供的本地/云端素材路径。本节点只负责整理需求与可用输入，识别并记录页面中可能存在的视频来源线索，不下载素材、不翻译正文、不产出最终文章。

## Context 使用

执行时应读取本节点 `Context/` 中的长期参考资料。发布版 Context 按目录组织：

- `Context/docs/`：播客范围、研究报告和背景资料。
- `Context/data/`：播客来源、已处理日志和待处理 backlog 的结构化数据与看板。
- `Context/schemas/`：JSONL 字段规范。
- `Context/scripts/`：状态校验和辅助维护脚本。

若存在 `Context/data/processed_video_log.jsonl` 或同类处理日志，应检查本次输入的原始 URL、规范化 URL、平台 ID、活动 ID、BV 号、YouTube ID、标题或节目名是否已在历史记录中出现过。若可能已处理过，应在需求整理中标明历史 taskCode、任务名、处理时间、主要输出路径和是否建议重复执行；除非用户明确要求重跑，不要把明显重复输入当成全新任务。

处理播客、硅谷科技内容、AI/VC/创业播客，或用户提到“关注的播客”“a16z 播客”时，应读取 `Context/docs/我关注的播客清单.md`、`Context/data/podcast_watch_sources.jsonl`、`Context/data/podcast_watch_sources.md`、`Context/data/podcast_episode_backlog.md` 和 `Context/data/podcast_episode_backlog.jsonl`。这些文件用于理解关注范围、判断节目类型和优先级、识别待处理候选、避免重复处理。它们只提供背景、候选和状态，不代表自动创建 task；是否创建新 task 仍由用户明确指挥。

涉及播客、关注播客、backlog 或更新来源时，机器处理优先读取 `Context/data/podcast_watch_sources.jsonl`，因为它是结构化来源配置；需要人类核验、查看备注或理解来源背景时，再看 `Context/data/podcast_watch_sources.md`。不要只读 Markdown 表格就跳过 JSONL，也不要把 Markdown 当作机器主数据。

## 输出要求

输出应包含需求整理、输入形态判断、可用输入清单、页面视频线索、约束记录、历史日志检查结果、播客 Context 命中情况和待确认事项。