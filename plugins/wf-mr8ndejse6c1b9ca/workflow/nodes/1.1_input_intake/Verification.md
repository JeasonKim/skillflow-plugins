1. [需求整理] 包含用户提供的原始 URL 或文件路径、目标语言、期望交付格式和是否需要保留时间戳或讲话人信息。
2. [输入形态识别] 标明输入属于 YouTube 链接、其他平台视频页、普通网页中的嵌入视频、播放器页面、视频/音频直链、本地文件或其他来源；若暂时无法判断，记录待下游探测。
3. [页面视频线索] 对普通网页输入，记录页面标题、域名、可能的视频区域、嵌入平台、iframe/player/video 标签线索、分享链接或用户补充说明；若用户只给了网页 URL，也应允许下游继续探测页面内视频。
4. [输入清单] 列出所有可用输入来源，包含用户提供的文件路径、链接、网页、参考资料或历史产出。
5. [约束记录] 明确字幕优先、网页/平台视频兼容、可用平台转写能力优先、不可用再降级到任务环境可用 ASR/TTS、中文 Markdown 输出等关键处理约束。
6. [待确认事项] 对缺失但会影响执行的条件列出具体问题；若无待确认事项，写明无。
7. [历史日志检查] 若 `Context/data/processed_video_log.jsonl` 或同类日志存在，记录是否检查过历史任务；若命中疑似重复输入，列出历史 taskCode、任务名、处理时间、主要输出路径和本次是否继续执行的依据。
8. [播客 Context 检查] 若任务涉及播客、关注播客、a16z、硅谷科技播客、AI/VC/创业播客、backlog、更新来源或待处理候选，记录是否读取 `Context/docs/我关注的播客清单.md`、`Context/data/podcast_watch_sources.jsonl`、`Context/data/podcast_watch_sources.md`、`Context/data/podcast_episode_backlog.md` 和 `Context/data/podcast_episode_backlog.jsonl`，并说明命中的节目、梯队、来源配置或待处理条目。
9. [来源读取优先级] 涉及播客来源配置时，记录机器处理是否优先读取 `Context/data/podcast_watch_sources.jsonl`；若只读取 `Context/data/podcast_watch_sources.md`，必须说明原因。
10. [不自动创建任务] 若发现 backlog 中存在其它待处理候选，只能在 1.1 输出中提示，不得自动创建新 task。