#!/usr/bin/env node
/**
 * gen-chart.mjs
 *
 * 根据出生信息生成紫微斗数星盘数据 JSON，供 Claude 分析使用。
 *
 * 输入参数（全部通过 --key=value 形式）:
 *   --date=YYYY-M-D        阳历生日（必填）
 *   --time-index=0..12     紫微时辰序号（必填，需调用方完成真太阳时校正）
 *   --gender=男|女         性别（必填）
 *   --output=/path/x.json  输出 JSON 路径（必填）
 *   --name=张三            用户姓名（可选，写入 meta）
 *
 * 输出:
 *   一个 JSON 文件，结构见文件末尾示例。
 */

import { astro } from 'iztro';
import { writeFileSync, mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';

function parseArgs(argv) {
  const out = {};
  for (const raw of argv.slice(2)) {
    const m = raw.match(/^--([a-zA-Z-]+)=(.*)$/);
    if (m) out[m[1]] = m[2];
  }
  return out;
}

function fail(msg) {
  console.error(`[gen-chart] ERROR: ${msg}`);
  process.exit(1);
}

const args = parseArgs(process.argv);

const date = args.date;
const timeIndex = Number(args['time-index']);
const gender = args.gender;
const outputPath = args.output;
const name = args.name || '';

// —— 参数校验 ——
if (!date || !/^\d{4}-\d{1,2}-\d{1,2}$/.test(date)) {
  fail('Missing or invalid --date (expect YYYY-M-D)');
}
if (!Number.isInteger(timeIndex) || timeIndex < 0 || timeIndex > 12) {
  fail('Missing or invalid --time-index (expect integer 0..12)');
}
if (gender !== '男' && gender !== '女') {
  fail('Missing or invalid --gender (expect 男 or 女)');
}
if (!outputPath) {
  fail('Missing --output');
}

// —— 生成本命星盘 ——
const astrolabe = astro.bySolar(date, timeIndex, gender, true, 'zh-CN');

// —— 当前大限（以今天为锚点） ——
const today = new Date();
const todayStr = `${today.getFullYear()}-${today.getMonth() + 1}-${today.getDate()}`;
const currentHoroscope = astrolabe.horoscope(todayStr);

// —— 近 3 年流年（今年、明年、后年） ——
const currentYear = today.getFullYear();
const yearlyForecasts = [];
for (let i = 0; i < 3; i++) {
  const year = currentYear + i;
  // 用当年的 6 月 15 日作为 targetDate —— 流年干支只依赖年份，避开闰日和生日边界
  const targetDate = `${year}-6-15`;
  const scope = astrolabe.horoscope(targetDate);
  yearlyForecasts.push({
    year,
    nominalAge: scope.age?.nominalAge ?? null,
    yearly: scope.yearly,
    age: scope.age,
  });
}

// —— 裁剪 palace 数据：保留分析所需字段，丢掉函数和冗余 ——
function simplifyStar(s) {
  return {
    name: s.name,
    type: s.type,
    scope: s.scope,
    brightness: s.brightness ?? null,
    mutagen: s.mutagen ?? null,
  };
}

function simplifyPalace(p) {
  return {
    index: p.index,
    name: p.name,
    isBodyPalace: p.isBodyPalace,
    isOriginalPalace: p.isOriginalPalace,
    heavenlyStem: p.heavenlyStem,
    earthlyBranch: p.earthlyBranch,
    majorStars: (p.majorStars || []).map(simplifyStar),
    minorStars: (p.minorStars || []).map(simplifyStar),
    adjectiveStars: (p.adjectiveStars || []).map((s) => s.name),
    changsheng12: p.changsheng12,
    boshi12: p.boshi12,
    jiangqian12: p.jiangqian12,
    suiqian12: p.suiqian12,
    decadal: p.decadal,
    ages: p.ages,
  };
}

// —— 组装输出 ——
const outputData = {
  meta: {
    generatedAt: new Date().toISOString(),
    name,
    tool: 'iztro',
  },
  basicInfo: {
    solarDate: astrolabe.solarDate,
    lunarDate: astrolabe.lunarDate,
    chineseDate: astrolabe.chineseDate,
    time: astrolabe.time,
    timeRange: astrolabe.timeRange,
    sign: astrolabe.sign,
    zodiac: astrolabe.zodiac,
    earthlyBranchOfSoulPalace: astrolabe.earthlyBranchOfSoulPalace,
    earthlyBranchOfBodyPalace: astrolabe.earthlyBranchOfBodyPalace,
    soul: astrolabe.soul,
    body: astrolabe.body,
    fiveElementsClass: astrolabe.fiveElementsClass,
    gender,
  },
  palaces: astrolabe.palaces.map(simplifyPalace),
  currentDecadal: {
    asOfDate: todayStr,
    decadal: currentHoroscope.decadal,
    age: currentHoroscope.age,
    yearly: currentHoroscope.yearly,
  },
  yearlyForecasts,
};

// —— 确保输出目录存在并写入 ——
const absOutput = resolve(outputPath);
mkdirSync(dirname(absOutput), { recursive: true });
writeFileSync(absOutput, JSON.stringify(outputData, null, 2));

// —— 简要摘要打到 stdout，方便调用方看到关键信息 ——
const soulPalace = outputData.palaces.find((p) => p.name === '命宫');
const soulMajors = soulPalace?.majorStars?.map((s) => s.name).join('/') || '(无主星)';
const decadalPalaceIdx = currentHoroscope.decadal?.index;
const decadalPalaceName = decadalPalaceIdx != null ? outputData.palaces[decadalPalaceIdx]?.name : '(n/a)';
const yearlyLine = yearlyForecasts
  .map((y) => `${y.year}(${y.yearly?.heavenlyStem}${y.yearly?.earthlyBranch})`)
  .join(' ');

console.log(`[gen-chart] wrote ${absOutput}`);
console.log(`[gen-chart] 基本: ${astrolabe.solarDate} ${astrolabe.time} ${gender} | 命宫主星: ${soulMajors}`);
console.log(`[gen-chart] 命主/身主: ${astrolabe.soul}/${astrolabe.body} | 五行局: ${astrolabe.fiveElementsClass}`);
console.log(`[gen-chart] 当前大限落宫: ${decadalPalaceName} (${currentHoroscope.decadal?.heavenlyStem}${currentHoroscope.decadal?.earthlyBranch})`);
console.log(`[gen-chart] 流年: ${yearlyLine}`);
