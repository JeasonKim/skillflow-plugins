#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const contextRoot = path.resolve(scriptDir, '..');
const dataRoot = path.join(contextRoot, 'data');
const schemaRoot = path.join(contextRoot, 'schemas');

function readJsonl(filePath) {
  const items = [];
  const errors = [];
  if (!fs.existsSync(filePath)) {
    return { items, errors: [`missing file: ${filePath}`] };
  }
  const text = fs.readFileSync(filePath, 'utf8');
  text.split(/\r?\n/).forEach((line, index) => {
    const trimmed = line.trim();
    if (!trimmed) return;
    try {
      items.push(JSON.parse(trimmed));
    } catch {
      errors.push(`parse error: ${filePath} line ${index + 1}`);
    }
  });
  return { items, errors };
}

function readSchema(fileName) {
  return JSON.parse(fs.readFileSync(path.join(schemaRoot, fileName), 'utf8'));
}

function validateAgainstSchema(name, items, schema) {
  const issues = [];
  const required = schema.required ?? [];
  const allowed = new Set(Object.keys(schema.properties ?? {}));
  for (const item of items) {
    const label = item.podcastName || item.taskCode || '(unknown row)';
    const props = Object.keys(item);
    for (const field of required) {
      if (!Object.hasOwn(item, field)) issues.push(`${name} missing field [${field}] on ${label}`);
    }
    for (const field of props) {
      if (!allowed.has(field)) issues.push(`${name} extra field [${field}] on ${label}`);
    }
    for (const [field, rule] of Object.entries(schema.properties ?? {})) {
      if (Object.hasOwn(item, field) && Array.isArray(rule.enum) && !rule.enum.includes(String(item[field]))) {
        issues.push(`${name} invalid enum [${field}=${item[field]}] on ${label}`);
      }
    }
  }
  return issues;
}

function findDuplicateCanonicalKeys(name, items) {
  const counts = new Map();
  for (const item of items) {
    if (!item.canonicalKey) continue;
    counts.set(item.canonicalKey, (counts.get(item.canonicalKey) ?? 0) + 1);
  }
  return [...counts.entries()]
    .filter(([, count]) => count > 1)
    .map(([key, count]) => `${name} duplicate canonicalKey [${key}] count=${count}`);
}

const processed = readJsonl(path.join(dataRoot, 'processed_video_log.jsonl'));
const backlog = readJsonl(path.join(dataRoot, 'podcast_episode_backlog.jsonl'));
const watch = readJsonl(path.join(dataRoot, 'podcast_watch_sources.jsonl'));

const processedSchema = readSchema('processed_video_log.schema_V1_20260627.json');
const backlogSchema = readSchema('podcast_episode_backlog.schema_V1_20260627.json');
const watchSchema = readSchema('podcast_watch_sources.schema_V1_20260627.json');

const issues = [
  ...processed.errors,
  ...backlog.errors,
  ...watch.errors,
  ...validateAgainstSchema('processed_video_log', processed.items, processedSchema),
  ...validateAgainstSchema('podcast_episode_backlog', backlog.items, backlogSchema),
  ...validateAgainstSchema('podcast_watch_sources', watch.items, watchSchema),
  ...findDuplicateCanonicalKeys('processed_video_log', processed.items),
  ...findDuplicateCanonicalKeys('podcast_episode_backlog', backlog.items),
];

for (const row of watch.items) {
  if (!row.officialSiteUrl) issues.push(`watch source missing officialSiteUrl: ${row.podcastName}`);
  if (!row.rssUrl) issues.push(`watch source missing rssUrl: ${row.podcastName}`);
  if (!row.youtubeChannelUrl && !row.youtubePlaylistUrl) {
    issues.push(`watch source missing YouTube: ${row.podcastName}`);
  }
}

const summary = {
  processedRows: processed.items.length,
  backlogRows: backlog.items.length,
  watchSourceRows: watch.items.length,
  issueCount: issues.length,
};

console.log(JSON.stringify(summary, null, 2));
if (issues.length > 0) {
  console.log('Issues:');
  for (const issue of issues) console.log(`- ${issue}`);
  process.exit(1);
}

console.log('Context state validation passed.');

