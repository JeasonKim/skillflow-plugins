param(
  [string]$ContextRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"

function Read-Jsonl {
  param([string]$Path)
  $items = @()
  $errors = @()
  if (-not (Test-Path -LiteralPath $Path)) {
    return [pscustomobject]@{ Items = $items; Errors = @("missing file: $Path") }
  }
  $lineNo = 0
  foreach ($line in Get-Content -Encoding UTF8 -LiteralPath $Path) {
    $lineNo++
    if (-not $line.Trim()) { continue }
    try {
      $items += ($line | ConvertFrom-Json)
    } catch {
      $errors += "parse error: $Path line $lineNo"
    }
  }
  [pscustomobject]@{ Items = $items; Errors = $errors }
}

function Test-AgainstSchema {
  param(
    [string]$Name,
    [object[]]$Items,
    [string]$SchemaPath
  )
  $issues = @()
  $schema = Get-Content -Raw -Encoding UTF8 -LiteralPath $SchemaPath | ConvertFrom-Json
  $required = @($schema.required)
  foreach ($item in $Items) {
    $label = $item.podcastName
    if (-not $label) { $label = $item.taskCode }
    if (-not $label) { $label = "(unknown row)" }

    $props = @($item.PSObject.Properties.Name)
    foreach ($field in $required) {
      if ($field -notin $props) {
        $issues += "$Name missing field [$field] on $label"
      }
    }
    foreach ($field in $props) {
      if ($field -notin $required) {
        $issues += "$Name extra field [$field] on $label"
      }
    }

    foreach ($prop in $schema.properties.PSObject.Properties) {
      $fieldName = $prop.Name
      if (($prop.Value.PSObject.Properties.Name -contains "enum") -and $fieldName -in $props) {
        $enum = @($prop.Value.enum)
        $value = [string]$item.$fieldName
        if ($value -notin $enum) {
          $issues += "$Name invalid enum [$fieldName=$value] on $label"
        }
      }
    }
  }
  $issues
}

function Find-DuplicateCanonicalKey {
  param(
    [string]$Name,
    [object[]]$Items
  )
  $dupes = @()
  $Items |
    Where-Object { $_.canonicalKey } |
    Group-Object canonicalKey |
    Where-Object { $_.Count -gt 1 } |
    ForEach-Object { $dupes += "$Name duplicate canonicalKey [$($_.Name)] count=$($_.Count)" }
  $dupes
}

$dataRoot = Join-Path $ContextRoot "data"
$schemaRoot = Join-Path $ContextRoot "schemas"

$processedPath = Join-Path $dataRoot "processed_video_log.jsonl"
$backlogPath = Join-Path $dataRoot "podcast_episode_backlog.jsonl"
$watchPath = Join-Path $dataRoot "podcast_watch_sources.jsonl"
$processedSchema = Join-Path $schemaRoot "processed_video_log.schema_V1_20260627.json"
$backlogSchema = Join-Path $schemaRoot "podcast_episode_backlog.schema_V1_20260627.json"
$watchSchema = Join-Path $schemaRoot "podcast_watch_sources.schema_V1_20260627.json"

$processed = Read-Jsonl $processedPath
$backlog = Read-Jsonl $backlogPath
$watch = Read-Jsonl $watchPath

$issues = @()
$issues += $processed.Errors
$issues += $backlog.Errors
$issues += $watch.Errors
$issues += Test-AgainstSchema "processed_video_log" $processed.Items $processedSchema
$issues += Test-AgainstSchema "podcast_episode_backlog" $backlog.Items $backlogSchema
$issues += Test-AgainstSchema "podcast_watch_sources" $watch.Items $watchSchema
$issues += Find-DuplicateCanonicalKey "processed_video_log" $processed.Items
$issues += Find-DuplicateCanonicalKey "podcast_episode_backlog" $backlog.Items

foreach ($row in $watch.Items) {
  if (-not $row.officialSiteUrl) { $issues += "watch source missing officialSiteUrl: $($row.podcastName)" }
  if (-not $row.rssUrl) { $issues += "watch source missing rssUrl: $($row.podcastName)" }
  if (-not ($row.youtubeChannelUrl -or $row.youtubePlaylistUrl)) { $issues += "watch source missing YouTube: $($row.podcastName)" }
}

$summary = [pscustomobject]@{
  ProcessedRows = $processed.Items.Count
  BacklogRows = $backlog.Items.Count
  WatchSourceRows = $watch.Items.Count
  IssueCount = $issues.Count
}

$summary | Format-List
if ($issues.Count -gt 0) {
  "Issues:"
  $issues | ForEach-Object { "- $_" }
  exit 1
}

"Context state validation passed."
