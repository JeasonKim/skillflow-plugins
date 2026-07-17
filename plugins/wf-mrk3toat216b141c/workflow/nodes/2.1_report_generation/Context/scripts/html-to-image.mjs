#!/usr/bin/env node
/**
 * html-to-image.mjs
 * ————————————————
 * 把一份独立的 HTML 文件渲染成一张长图 PNG（full-page screenshot），
 * 用于分享到微信 / 朋友圈 / 小红书等不需要分页的场景。
 *
 * 实现方式：puppeteer-core 驱动系统已安装的 Chrome / Chromium。
 *   - puppeteer-core 不下载 Chromium，体积小
 *   - 系统 Chrome 负责真正的渲染 + 字体加载
 *   - page.screenshot({ fullPage: true }) 自动处理页面高度、滚动拼接
 *
 * 用法：
 *   node html-to-image.mjs --input=/abs/report.html --output=/abs/report.png \
 *     [--width=720] [--scale=2]
 *
 * 退出码：
 *   0  成功
 *   1  参数错误
 *   2  找不到 Chromium 系浏览器
 *   3  渲染 / 截图失败
 */

import puppeteer from 'puppeteer-core';
import { existsSync, statSync } from 'node:fs';
import { resolve } from 'node:path';
import process from 'node:process';

// ——— 参数解析 ———
function parseArgs(argv) {
  const args = {};
  for (const raw of argv.slice(2)) {
    const m = raw.match(/^--([^=]+)=(.*)$/);
    if (m) args[m[1]] = m[2];
  }
  return args;
}

const args = parseArgs(process.argv);
const input = args.input;
const output = args.output;
const width = Number.parseInt(args.width || '720', 10);
const scale = Number.parseFloat(args.scale || '2');

if (!input || !output) {
  console.error(
    'Usage: node html-to-image.mjs --input=/abs/report.html --output=/abs/report.png [--width=720] [--scale=2]'
  );
  process.exit(1);
}

const inputAbs = resolve(input);
const outputAbs = resolve(output);

if (!existsSync(inputAbs)) {
  console.error(`[html-to-image] 输入文件不存在: ${inputAbs}`);
  process.exit(1);
}

// ——— Chromium 探测 ———
const CANDIDATES = [
  // macOS
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  '/Applications/Google Chrome Canary.app/Contents/MacOS/Google Chrome Canary',
  '/Applications/Chromium.app/Contents/MacOS/Chromium',
  '/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge',
  '/Applications/Brave Browser.app/Contents/MacOS/Brave Browser',
  '/Applications/Arc.app/Contents/MacOS/Arc',
  // Linux
  '/usr/bin/google-chrome',
  '/usr/bin/google-chrome-stable',
  '/usr/bin/chromium',
  '/usr/bin/chromium-browser',
  '/usr/bin/microsoft-edge',
  '/usr/bin/brave-browser',
  '/snap/bin/chromium',
];

function detectBrowser() {
  for (const p of CANDIDATES) {
    try {
      if (existsSync(p) && statSync(p).isFile()) return p;
    } catch {}
  }
  return null;
}

const executablePath = detectBrowser();
if (!executablePath) {
  console.error('[html-to-image] 未找到 Chromium 系浏览器 (Chrome / Edge / Brave / Chromium)。');
  console.error('            请安装 Google Chrome: https://www.google.com/chrome/');
  process.exit(2);
}

// ——— 渲染 + 截图 ———
let browser;
try {
  browser = await puppeteer.launch({
    executablePath,
    headless: true,
    args: [
      '--no-sandbox',
      '--disable-gpu',
      '--hide-scrollbars',
      '--disable-dev-shm-usage',
      '--font-render-hinting=none',
    ],
  });

  const page = await browser.newPage();
  await page.setViewport({
    width,
    height: 1000,
    deviceScaleFactor: scale,
  });

  await page.goto('file://' + inputAbs, {
    waitUntil: 'domcontentloaded',
    timeout: 30000,
  });

  // 等 Google Fonts 加载完，确保页面高度和字宽都稳定
  await page.evaluate(() => document.fonts && document.fonts.ready);

  // 再给一点渲染稳定时间（阴影 / 渐变 / reflow）
  await new Promise((r) => setTimeout(r, 400));

  await page.screenshot({
    path: outputAbs,
    type: 'png',
    fullPage: true,
    omitBackground: false,
  });

  console.log(outputAbs);
} catch (err) {
  console.error('[html-to-image] 渲染 / 截图失败:', err?.message || err);
  process.exit(3);
} finally {
  if (browser) {
    try {
      await browser.close();
    } catch {}
  }
}
