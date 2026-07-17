## 职责

本节点负责读取上游星盘数据，撰写兼具专业依据与通俗可读性的紫微人生分析报告，并生成可直接本地访问的 HTML 报告与同样式长图 PNG。

## 输入

- 上游节点输出的结构化出生信息与星盘 JSON。
- 本节点 `Context/templates/report.html` HTML 模板。
- 本节点 `Context/scripts/render-report.mjs` UTF-8 HTML 渲染脚本。
- 本节点 `Context/scripts/html-to-image.mjs` 长图渲染脚本。
- 本节点 `Context/` 根目录中的 `package.json` 与 `package-lock.json`。

## 写作原则

- 报告应在“大白话”和“专业度”之间取得平衡：读者能看懂，同时能感到判断有明确命盘依据。
- 可以少量使用必要的紫微斗数概念，例如“命宫”“身宫”“大限”“流年”“四化”等；出现时必须立即转换成现实含义，避免术语堆砌。
- 不直接堆星曜名称和庙旺陷等专业标签；如引用星盘信息，应说明它支持了什么性格倾向、行动模式、关系课题或阶段重点。
- 每个重要判断都应尽量包含“依据 → 解释 → 现实建议”三层，而不是只给抽象形容词。
- 使用概率性、建设性语气，避免“必定”“注定”“大凶”等绝对化表达。
- 不编造具体事件、具体月份或不可验证的人生情节，只分析趋势、基调、课题和建议。
- 避免鸡汤式表达、空泛鼓励和含糊其辞的套话；建议要能落到行动、选择、关系处理或自我管理上。
- 报告主体包含人生主基调、当前十年阶段、近三年年度趋势三部分。

## 执行要求

// 基于星盘数据撰写报告

- 以星盘 JSON 作为唯一排盘数据源，不凭空补造星曜、宫位或流年信息。
- 将人生主基调、当前十年阶段、近三年年度趋势写入结构化 `report-content.json`，字段名应对应模板占位符，例如 `LIFE_THEME_HTML`、`DECADAL_HTML`、`YEARLY_1_HTML`。
- `report-content.json` 必须以 UTF-8 编码写入，禁止使用 Windows 默认编码、`echo`、shell 重定向或未显式指定编码的 `Set-Content` 写入中文正文。
- 正文应适合放入 HTML 段落，保持有分析感的散文式表达；可以有清晰判断和具体建议，但避免清单化堆砌。
- 写作时应显式区分长期性格底色、当前阶段主题和年度节奏，不把所有内容写成通用人生建议。

// 恢复节点依赖

- 本节点不要求分发 `node_modules/`。
- 调用渲染脚本前，必须在本节点 `Context/` 内基于 `package-lock.json` 恢复 npm 依赖，默认命令为 `npm ci --ignore-scripts --registry=${NPM_REGISTRY:-https://registry.npmmirror.com}`。
- 如果运行环境不支持 shell 变量展开，应等价使用 `NPM_REGISTRY` 环境变量的值作为 registry；未设置时使用 `https://registry.npmmirror.com`。
- 依赖恢复失败时必须输出明确错误，包含失败命令、registry、缺失依赖或退出码；不得继续执行 HTML/PNG 渲染。

// 生成本地交付物

- 必须使用 `Context/scripts/render-report.mjs` 读取 `Context/templates/report.html` 与 `report-content.json`，生成最终 HTML 文件。
- `render-report.mjs` 会按 UTF-8 读取模板与内容，并按 UTF-8 写入 HTML；不得用手工字符串拼接、shell 重定向或默认编码命令绕过该脚本。
- 使用 `Context/scripts/html-to-image.mjs` 将刚生成的 HTML 渲染为 PNG 长图，保证 HTML 与 PNG 使用同一时间戳前缀。
- PNG 渲染因浏览器缺失失败时，不得影响 HTML 交付；需要在产出中明确记录缺失浏览器及恢复建议。
- HTML 生成后应直接打开本地文件，便于用户访问。

## 产出

- 在本节点 `outputs/` 下输出 UTF-8 编码的 `report-content.json`。
- 在本节点 `outputs/` 下输出由 `render-report.mjs` 生成的 HTML 报告文件。
- 在本节点 `outputs/` 下输出 PNG 长图；若无法生成，输出明确失败说明。
- 在最终汇报中只提供一句话概括、HTML 路径、PNG 路径或失败原因，不复述报告正文。