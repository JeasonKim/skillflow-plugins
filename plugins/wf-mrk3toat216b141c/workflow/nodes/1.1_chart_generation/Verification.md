## 验收项

- `outputs/` 中存在结构化出生信息文件，包含原始出生信息、归一化后的阳历日期、校正前时间、出生地、经度、真太阳时偏移、校正后时间、最终 `timeIndex`。
- 依赖恢复日志或执行记录中包含实际使用的 npm registry；默认情况下为 `https://registry.npmmirror.com`，设置 `NPM_REGISTRY` 时为对应覆盖值。
- `outputs/` 中存在星盘 JSON 文件，且包含 `basicInfo`、`palaces`、`currentDecadal`、`yearlyForecasts` 四类数据。
- 星盘 JSON 的 `palaces` 数量为 12，`yearlyForecasts` 数量为 3。
- 若发生依赖恢复或排盘脚本失败，产出或日志中明确记录失败命令与失败原因，且没有生成伪造的星盘 JSON。