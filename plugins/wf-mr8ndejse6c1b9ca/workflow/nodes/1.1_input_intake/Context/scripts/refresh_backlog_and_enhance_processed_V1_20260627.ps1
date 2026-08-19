param(
  [string]$ContextRoot = (Split-Path -Parent $PSScriptRoot),
  [string]$StartDate = "2026-05-01",
  [string]$EndDateInclusive = "2026-06-27"
)

$ErrorActionPreference = "Continue"
$DataRoot = Join-Path $ContextRoot "data"
Set-Location -LiteralPath $DataRoot

$start = [datetime]::Parse($StartDate + "T00:00:00Z")
$end = [datetime]::Parse($EndDateInclusive + "T00:00:00Z").AddDays(1)
$discoveredAt = (Get-Date -Format "yyyy-MM-dd")
$checkedAt = $discoveredAt

function Normalize-Text([string]$s) {
  if (-not $s) { return "" }
  $t = $s.ToLowerInvariant()
  $t = [regex]::Replace($t, "&amp;", "and")
  $t = [regex]::Replace($t, "[^\p{L}\p{Nd}]+", " ")
  $t = [regex]::Replace($t, "\s+", " ").Trim()
  return $t
}

function Get-Sha1([string]$s) {
  $sha = [System.Security.Cryptography.SHA1]::Create()
  $bytes = [Text.Encoding]::UTF8.GetBytes($s)
  return (($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString("x2") }) -join "")
}

function Get-Slug([string]$s) {
  $t = $s.ToLowerInvariant()
  $t = [regex]::Replace($t, "[^a-z0-9]+", "_").Trim("_")
  if (-not $t) { $t = "podcast" }
  return $t
}

function Get-ChildText($node, [string]$localName) {
  $n = $node.ChildNodes | Where-Object { $_.LocalName -eq $localName } | Select-Object -First 1
  if ($n) { return ([string]$n.InnerText).Trim() }
  return ""
}

function Get-ItemLink($item) {
  $linkNode = $item.ChildNodes | Where-Object { $_.LocalName -eq "link" } | Select-Object -First 1
  if ($linkNode) {
    if ($linkNode.Attributes -and $linkNode.Attributes["href"]) {
      return [pscustomobject]@{ Url = ([string]$linkNode.Attributes["href"].Value).Trim(); Kind = "link" }
    }
    if ($linkNode.InnerText) {
      return [pscustomobject]@{ Url = ([string]$linkNode.InnerText).Trim(); Kind = "link" }
    }
  }
  $enclosureNode = $item.ChildNodes | Where-Object { $_.LocalName -eq "enclosure" } | Select-Object -First 1
  if ($enclosureNode -and $enclosureNode.Attributes -and $enclosureNode.Attributes["url"]) {
    return [pscustomobject]@{ Url = ([string]$enclosureNode.Attributes["url"].Value).Trim(); Kind = "enclosure" }
  }
  return [pscustomobject]@{ Url = ""; Kind = "" }
}

function Get-YoutubeKey([string]$url) {
  if (-not $url) { return "" }
  $u = $url.ToLowerInvariant().TrimEnd("/")
  if ($u -match "youtube\.com/@([^/?#]+)") { return "@" + $matches[1] }
  if ($u -match "youtube\.com/(?:c|user)/([^/?#]+)") { return "@" + $matches[1] }
  if ($u -match "youtube\.com/channel/([^/?#]+)") { return "channel:" + $matches[1] }
  return $u
}

function Get-VideoId($row) {
  if ($row.platformId) { return [string]$row.platformId }
  if ($row.canonicalKey -match "^youtube:(.+)$") { return $matches[1] }
  if ($row.inputUrl -match "(?:v=|youtu\.be/)([A-Za-z0-9_-]{6,})") { return $matches[1] }
  return ""
}

$watch = @(Get-Content -Encoding UTF8 ".\podcast_watch_sources.jsonl" | ForEach-Object { $_ | ConvertFrom-Json })
$processed = @(Get-Content -Encoding UTF8 ".\processed_video_log.jsonl" | ForEach-Object { $_ | ConvertFrom-Json })

$ytMap = @{}
foreach ($p in $watch) {
  foreach ($url in @($p.youtubeChannelUrl, $p.youtubePlaylistUrl)) {
    $key = Get-YoutubeKey $url
    if ($key) {
      if (-not $ytMap.ContainsKey($key)) { $ytMap[$key] = @() }
      if ($p.podcastName -notin $ytMap[$key]) { $ytMap[$key] += $p.podcastName }
    }
  }
}

$manual = @{
  "@sequoiacapital" = @("Training Data", "Crucible Moments", "Long Strange Trip")
  "@ycombinator" = @("Y Combinator Startup Podcast", "Lightcone Podcast")
  "@a16z" = @("The a16z Show", "AI + a16z")
  "@greylockvc" = @("Greymatter", "Product-Led AI")
  "@joincolossus" = @("Business Breakdowns")
}
foreach ($k in $manual.Keys) { $ytMap[$k] = $manual[$k] }

$episodes = @()
$stats = @()
$rssErrors = @()

foreach ($p in $watch) {
  try {
    $resp = Invoke-WebRequest -Uri $p.rssUrl -TimeoutSec 25 -UseBasicParsing
    [xml]$xml = $resp.Content
    $items = @($xml.SelectNodes("//*[local-name()='item']"))
    if ($items.Count -eq 0) { $items = @($xml.SelectNodes("//*[local-name()='entry']")) }
    $countIn = 0
    foreach ($it in $items) {
      $dateText = Get-ChildText $it "pubDate"
      if (-not $dateText) { $dateText = Get-ChildText $it "published" }
      if (-not $dateText) { $dateText = Get-ChildText $it "updated" }
      if (-not $dateText) { continue }
      try {
        $dt = [datetime]::Parse($dateText, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AssumeUniversal -bor [Globalization.DateTimeStyles]::AdjustToUniversal)
      } catch {
        continue
      }
      if ($dt -ge $start -and $dt -lt $end) {
        $title = Get-ChildText $it "title"
        $linkInfo = Get-ItemLink $it
        $link = $linkInfo.Url
        $linkKind = $linkInfo.Kind
        $guid = Get-ChildText $it "guid"
        if ($guid) { $idSource = $guid } elseif ($link) { $idSource = $link } else { $idSource = "$($p.podcastName)|$title|$($dt.ToString('o'))" }
        $canonical = "podcast:" + (Get-Slug $p.podcastName) + ":" + (Get-Sha1 $idSource).Substring(0, 16)
        $episodes += [pscustomobject]@{
          podcastName = $p.podcastName
          podcastTier = $p.podcastTier
          episodeTitle = $title
          episodeUrl = $link
          episodeId = $idSource
          canonicalKey = $canonical
          source = "rss"
          publishedAt = $dt.ToString("yyyy-MM-dd")
          publishedAtIso = $dt.ToString("yyyy-MM-ddTHH:mm:ssZ")
          rssUrl = $p.rssUrl
          linkKind = $linkKind
          normalizedTitle = Normalize-Text $title
        }
        $countIn++
      }
    }
    $stats += [pscustomobject]@{ Podcast = $p.podcastName; Tier = $p.podcastTier; InRange = $countIn; TotalItems = $items.Count; Status = "ok"; Error = "" }
  } catch {
    $msg = $_.Exception.Message
    $rssErrors += [pscustomobject]@{ Podcast = $p.podcastName; Error = $msg }
    $stats += [pscustomobject]@{ Podcast = $p.podcastName; Tier = $p.podcastTier; InRange = 0; TotalItems = 0; Status = "error"; Error = $msg }
  }
}

$titleMap = @{}
foreach ($e in $episodes) {
  if ($e.normalizedTitle) {
    if (-not $titleMap.ContainsKey($e.normalizedTitle)) { $titleMap[$e.normalizedTitle] = @() }
    $titleMap[$e.normalizedTitle] += $e
  }
}

$oembedOk = 0
$oembedFail = 0
foreach ($r in $processed) {
  foreach ($field in @("inputUrl", "normalizedUrl")) {
    if ($r.$field) { $r.$field = ([string]$r.$field).Trim().Trim([char]96) }
  }
  if ($r.notes -match "\?\?\?") {
    $r.notes = "历史回填记录；字段来自 task requirement、metadata 和 outputs；缺失项保留空值或 unknown。"
  }
  if ($r.sourceType -in @("BAAI live", "Bilibili", "webpage video")) {
    $r.podcastMatched = "no"
    $r.podcastName = ""
    if ($r.notes -notmatch "二次增强") { $r.notes = $r.notes.TrimEnd("。") + "；二次增强：非播客来源。" }
    continue
  }
  if ($r.sourceType -ne "YouTube") {
    $r.podcastMatched = "unknown"
    if ($r.notes -notmatch "二次增强") { $r.notes = $r.notes.TrimEnd("。") + "；二次增强：来源类型不明，未做播客匹配。" }
    continue
  }

  $id = Get-VideoId $r
  if ($id) {
    $r.platformId = $id
    $r.canonicalKey = "youtube:" + $id
    $r.normalizedUrl = "https://www.youtube.com/watch?v=" + $id
    if (-not $r.inputUrl) { $r.inputUrl = $r.normalizedUrl }
  }

  $matchedPodcast = ""
  $matchBasis = ""
  $author = ""
  $authorUrl = ""
  if ($id) {
    try {
      $encoded = [uri]::EscapeDataString("https://www.youtube.com/watch?v=" + $id)
      $o = Invoke-RestMethod -Uri ("https://www.youtube.com/oembed?url=" + $encoded + "&format=json") -TimeoutSec 15
      $oembedOk++
      if ($o.title -and ($r.title -eq "任务目标" -or -not $r.title)) { $r.title = [string]$o.title }
      $author = [string]$o.author_name
      $authorUrl = [string]$o.author_url
      $tn = Normalize-Text $r.title
      if ($tn -and $titleMap.ContainsKey($tn)) {
        $pods = @($titleMap[$tn] | Select-Object -ExpandProperty podcastName -Unique)
        if ($pods.Count -eq 1) {
          $matchedPodcast = $pods[0]
          $matchBasis = "RSS 标题精确匹配"
        }
      }
      if (-not $matchedPodcast) {
        $key = Get-YoutubeKey $authorUrl
        if ($key -and $ytMap.ContainsKey($key)) {
          $candidates = @($ytMap[$key] | Select-Object -Unique)
          if ($candidates.Count -eq 1) {
            $matchedPodcast = $candidates[0]
            $matchBasis = "YouTube 作者频道唯一匹配"
          } elseif ($r.taskCode -like "yc_podcast_*" -and "Y Combinator Startup Podcast" -in $candidates) {
            $matchedPodcast = "Y Combinator Startup Podcast"
            $matchBasis = "taskCode 与 YC 播客匹配"
          }
        }
      }
      if ($matchedPodcast) {
        $r.podcastMatched = "yes"
        $r.podcastName = $matchedPodcast
      } else {
        $key = Get-YoutubeKey $authorUrl
        if ($key -and $ytMap.ContainsKey($key)) {
          $r.podcastMatched = "unknown"
          $matchBasis = "YouTube 作者频道对应多档播客，未能唯一归属"
        } else {
          $r.podcastMatched = "no"
          $matchBasis = "YouTube 作者频道不在关注来源表"
        }
      }
      $noteAdd = "二次增强：YouTube oEmbed 标题/作者已检查"
      if ($author) { $noteAdd += "，作者=$author" }
      if ($matchBasis) { $noteAdd += "，匹配依据=$matchBasis" }
      if ($r.notes -notmatch [regex]::Escape($noteAdd)) { $r.notes = $r.notes.TrimEnd("。") + "；" + $noteAdd + "。" }
    } catch {
      $oembedFail++
      $r.podcastMatched = "unknown"
      if ($r.notes -notmatch "oEmbed 获取失败") { $r.notes = $r.notes.TrimEnd("。") + "；二次增强：YouTube oEmbed 获取失败，保留 unknown。" }
    }
  }
}

$processedTitleMap = @{}
$processedUrlMap = @{}
foreach ($r in $processed) {
  foreach ($u in @($r.inputUrl, $r.normalizedUrl)) {
    if ($u) { $processedUrlMap[$u.ToLowerInvariant()] = $r }
  }
  $nt = Normalize-Text $r.title
  if ($nt -and $r.title -ne "任务目标") {
    if (-not $processedTitleMap.ContainsKey($nt)) { $processedTitleMap[$nt] = @() }
    $processedTitleMap[$nt] += $r
  }
}

$backlog = @()
foreach ($e in ($episodes | Sort-Object podcastName, publishedAtIso, episodeTitle)) {
  $matched = ""
  if ($e.episodeUrl -and $processedUrlMap.ContainsKey($e.episodeUrl.ToLowerInvariant())) {
    $matched = $processedUrlMap[$e.episodeUrl.ToLowerInvariant()].taskCode
  }
  if (-not $matched -and $e.normalizedTitle -and $processedTitleMap.ContainsKey($e.normalizedTitle)) {
    $candidates = @($processedTitleMap[$e.normalizedTitle])
    $same = @($candidates | Where-Object { $_.podcastName -eq $e.podcastName })
    if ($same.Count -gt 0) { $matched = $same[0].taskCode }
    elseif ($candidates.Count -eq 1 -and ($candidates[0].podcastMatched -eq "unknown" -or -not $candidates[0].podcastName)) { $matched = $candidates[0].taskCode }
  }

  if ($matched) { $status = "processed" } else { $status = "todo" }
  if ($e.podcastTier -eq "Top10") { $priority = "high" } elseif ($e.podcastTier -eq "Tier2") { $priority = "medium" } else { $priority = "low" }
  if ($e.episodeUrl -and $e.episodeTitle -and $e.publishedAt -and $e.linkKind -eq "link") { $confidence = "high" } else { $confidence = "medium" }
  if ($matched) { $reason = "$StartDate 至 $EndDateInclusive RSS 更新；已在 processed_video_log 中按标题或 URL 命中。" } else { $reason = "$StartDate 至 $EndDateInclusive RSS 更新；未在 processed_video_log 中命中，作为待处理候选。" }

  $backlog += [pscustomobject]@{
    podcastName = $e.podcastName
    podcastTier = $e.podcastTier
    episodeTitle = $e.episodeTitle
    episodeUrl = $e.episodeUrl
    episodeId = $e.episodeId
    canonicalKey = $e.canonicalKey
    source = "rss"
    publishedAt = $e.publishedAt
    status = $status
    discoveredAt = $discoveredAt
    lastCheckedAt = $checkedAt
    matchedProcessedTaskCode = $matched
    priority = $priority
    reason = $reason
    sourceConfidence = $confidence
    notes = if ($e.linkKind -eq "enclosure") { "RSS: $($e.rssUrl)；episodeUrl 来自 RSS enclosure 音频地址。" } else { "RSS: $($e.rssUrl)" }
  }
}

$backlog = @($backlog | Group-Object canonicalKey | ForEach-Object { $_.Group | Select-Object -First 1 })

$processedLines = $processed | ForEach-Object { ($_ | ConvertTo-Json -Compress).Replace("\u0026", "&").Replace("\u0027", "'") }
[System.IO.File]::WriteAllLines((Resolve-Path ".\processed_video_log.jsonl"), $processedLines, [System.Text.UTF8Encoding]::new($false))

$backlogLines = $backlog | Sort-Object podcastName, publishedAt, episodeTitle | ForEach-Object { ($_ | ConvertTo-Json -Compress).Replace("\u0026", "&").Replace("\u0027", "'") }
[System.IO.File]::WriteAllLines((Resolve-Path ".\podcast_episode_backlog.jsonl"), $backlogLines, [System.Text.UTF8Encoding]::new($false))

$todoCount = @($backlog | Where-Object { $_.status -eq "todo" }).Count
$processedCount = @($backlog | Where-Object { $_.status -eq "processed" }).Count
$md = @()
$md += "# 播客待处理名单"
$md += ""
$md += '本文件是给人读的播客待处理看板。机器查重和状态更新优先使用 `podcast_episode_backlog.jsonl`，但每次 6.1 更新 backlog 时，也应尽量同步维护本文件，方便用户快速浏览。'
$md += ""
$md += "本文件只记录候选和已覆盖更新，不自动创建 task。用户明确要求创建任务时，才基于这里的条目创建新 task。"
$md += ""
$md += "## 本次覆盖范围"
$md += ""
$md += "- 检查范围：$StartDate 至 $EndDateInclusive。"
$md += "- 覆盖播客：$($watch.Count) 档。"
$md += "- RSS 读取失败：$($rssErrors.Count) 档。"
$md += "- 范围内更新：$($backlog.Count) 条。"
$md += "- 待处理：$todoCount 条。"
$md += "- 已匹配历史处理：$processedCount 条。"
$md += '- 来源：`podcast_watch_sources.jsonl` 中的 RSS feed。'
$md += ""
$md += "## 使用规则"
$md += ""
$md += '- `todo`：尚未处理，适合未来创建 task。'
$md += '- `processed`：已经处理，需写明历史 taskCode。'
$md += '- `skipped`：用户或 agent 判断暂不处理。'
$md += '- `uncertain`：来源、标题、链接或是否已处理仍不确定，需要人工确认。'
$md += ""
$md += "## 播客覆盖汇总"
$md += ""
$md += "| 播客 | 梯队 | 5/1-6/27 更新 | todo | processed | RSS 状态 |"
$md += "|---|---|---:|---:|---:|---|"
foreach ($s in ($stats | Sort-Object Tier, Podcast)) {
  $rowsFor = @($backlog | Where-Object { $_.podcastName -eq $s.Podcast })
  $td = @($rowsFor | Where-Object { $_.status -eq "todo" }).Count
  $pr = @($rowsFor | Where-Object { $_.status -eq "processed" }).Count
  $md += ("| {0} | {1} | {2} | {3} | {4} | {5} |" -f $s.Podcast, $s.Tier, $s.InRange, $td, $pr, $s.Status)
}
$md += ""
$md += "## 待处理总览"
$md += ""
$md += "| 状态 | 播客 | 梯队 | 发布时间 | 标题 | 链接 | 发现时间 | 备注 |"
$md += "|---|---|---|---|---|---|---|---|"
foreach ($b in ($backlog | Sort-Object status, podcastTier, podcastName, publishedAt, episodeTitle)) {
  $title = ($b.episodeTitle -replace "\|", "/")
  if ($b.episodeUrl) { $link = "[链接]($($b.episodeUrl))" } else { $link = "" }
  if ($b.status -eq "processed") { $note = "已匹配 $($b.matchedProcessedTaskCode)" } else { $note = $b.reason }
  $note = $note -replace "\|", "/"
  $md += ("| {0} | {1} | {2} | {3} | {4} | {5} | {6} | {7} |" -f $b.status, $b.podcastName, $b.podcastTier, $b.publishedAt, $title, $link, $b.discoveredAt, $note)
}
$md += ""
$md += "## 维护说明"
$md += ""
$md += "- 6.1 执行日志归档节点在任务结束后，可以检查当前播客是否有新单集，并把未处理的新单集追加到这里。"
$md += '- 如果同一单集已经在 `processed_video_log.jsonl` 中出现，不应重复加入 `todo`。'
$md += '- 如果同一单集已经在 `podcast_episode_backlog.jsonl` 中出现，不应重复加入。'
$md += '- 如果缺少稳定链接或无法确认是否同一集，应标为 `uncertain`。'
$md += '- 不要把本文件当作最新官方节目列表；最新性仍需到 `podcast_watch_sources.md` 里的官方来源核验。'
[System.IO.File]::WriteAllLines((Resolve-Path ".\podcast_episode_backlog.md"), $md, [System.Text.UTF8Encoding]::new($false))

[pscustomobject]@{
  RssPodcasts = $watch.Count
  RssErrors = $rssErrors.Count
  EpisodesInRange = $episodes.Count
  BacklogRows = $backlog.Count
  Todo = $todoCount
  Processed = $processedCount
  OembedOk = $oembedOk
  OembedFail = $oembedFail
  ProcessedPodcastYes = @($processed | Where-Object { $_.podcastMatched -eq "yes" }).Count
  ProcessedPodcastNo = @($processed | Where-Object { $_.podcastMatched -eq "no" }).Count
  ProcessedPodcastUnknown = @($processed | Where-Object { $_.podcastMatched -eq "unknown" }).Count
} | Format-List
