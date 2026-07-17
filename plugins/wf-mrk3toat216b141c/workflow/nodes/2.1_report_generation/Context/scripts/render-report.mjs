#!/usr/bin/env node
/**
 * render-report.mjs
 *
 * Render the report HTML from a UTF-8 template and a JSON placeholder map.
 * This script exists to avoid Windows shell encoding issues when generated
 * Chinese content is written into the final HTML file.
 *
 * Usage:
 *   node render-report.mjs \
 *     --template=/path/report.html \
 *     --content=/path/report-content.json \
 *     --output=/path/report.html
 *
 * The content JSON can be either:
 *   { "META_NAME": "...", "LIFE_THEME_HTML": "..." }
 * or:
 *   { "placeholders": { "META_NAME": "...", "LIFE_THEME_HTML": "..." } }
 */

import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';

function parseArgs(argv) {
  const args = {};
  for (const raw of argv.slice(2)) {
    const match = raw.match(/^--([^=]+)=(.*)$/);
    if (match) args[match[1]] = match[2];
  }
  return args;
}

function fail(message) {
  console.error(`[render-report] ERROR: ${message}`);
  process.exit(1);
}

function normalizePlaceholderMap(rawContent) {
  const source = rawContent.placeholders && typeof rawContent.placeholders === 'object'
    ? rawContent.placeholders
    : rawContent;

  const placeholders = {};
  for (const [key, value] of Object.entries(source)) {
    if (!/^[A-Z0-9_]+$/.test(key)) continue;
    if (value == null) {
      placeholders[key] = '';
    } else if (typeof value === 'string') {
      placeholders[key] = value;
    } else {
      placeholders[key] = String(value);
    }
  }
  return placeholders;
}

const args = parseArgs(process.argv);
const templatePath = args.template;
const contentPath = args.content;
const outputPath = args.output;

if (!templatePath || !contentPath || !outputPath) {
  fail('Missing required args. Expected --template=/path/report.html --content=/path/report-content.json --output=/path/report.html');
}

let template;
let rawContent;
try {
  template = readFileSync(resolve(templatePath), 'utf8');
} catch (error) {
  fail(`Failed to read template as UTF-8: ${error.message}`);
}

try {
  rawContent = JSON.parse(readFileSync(resolve(contentPath), 'utf8'));
} catch (error) {
  fail(`Failed to read content JSON as UTF-8: ${error.message}`);
}

const placeholders = normalizePlaceholderMap(rawContent);

let html = template.replace(/<!DOCTYPE html>\s*<!--[\s\S]*?-->/, '<!DOCTYPE html>');
for (const [key, value] of Object.entries(placeholders)) {
  html = html.replaceAll(`{{${key}}}`, value);
}

const unresolved = [...html.matchAll(/{{([A-Z0-9_]+)}}/g)].map((match) => match[1]);
if (unresolved.length > 0) {
  fail(`Unresolved placeholders: ${[...new Set(unresolved)].join(', ')}`);
}

const outputAbs = resolve(outputPath);
mkdirSync(dirname(outputAbs), { recursive: true });
writeFileSync(outputAbs, html, 'utf8');
console.log(`[render-report] wrote ${outputAbs}`);
