#!/usr/bin/env bash
set -euo pipefail

KIBANA_URL="${KIBANA_URL:-http://localhost:5601}"
DATA_VIEW_ID="microcrm-logs-dataview"
DASHBOARD_ID="microcrm-logs-dashboard"
TMP_DASHBOARD_FILE="/tmp/microcrm-dashboard.json"

kcurl() {
  curl -fsS "$@"
}

echo "Checking Kibana availability on ${KIBANA_URL}..."
kcurl "${KIBANA_URL}/api/status" >/dev/null

echo "Creating or updating data view..."
kcurl -X POST "${KIBANA_URL}/api/data_views/data_view" \
  -H 'kbn-xsrf: true' \
  -H 'Content-Type: application/json' \
  -d '{
    "data_view": {
      "id": "'"${DATA_VIEW_ID}"'",
      "name": "MicroCRM Logs",
      "title": "microcrm-logs-*",
      "timeFieldName": "@timestamp"
    },
    "override": true
  }' >/dev/null

create_search() {
  local id="$1"
  local title="$2"
  local query="$3"
  local columns="$4"
  local query_escaped="${query//\"/\\\"}"

  kcurl -X POST "${KIBANA_URL}/api/saved_objects/search/${id}?overwrite=true" \
    -H 'kbn-xsrf: true' \
    -H 'Content-Type: application/json' \
    -d '{
      "attributes": {
        "title": "'"${title}"'",
        "description": "",
        "columns": '"${columns}"',
        "sort": [["@timestamp", "desc"]],
        "kibanaSavedObjectMeta": {
          "searchSourceJSON": "{\"query\":{\"query\":\"'"${query_escaped}"'\",\"language\":\"kuery\"},\"filter\":[],\"indexRefName\":\"kibanaSavedObjectMeta.searchSourceJSON.index\"}"
        }
      },
      "references": [
        {
          "id": "'"${DATA_VIEW_ID}"'",
          "name": "kibanaSavedObjectMeta.searchSourceJSON.index",
          "type": "index-pattern"
        }
      ]
    }' >/dev/null
}

echo "Creating saved searches..."
create_search "microcrm-search-all" "All Logs" "" '["@timestamp", "app", "log_level", "source_type", "message"]'
create_search "microcrm-search-errors" "Recent Errors & Warnings" 'log_level : (ERROR or WARN)' '["@timestamp", "app", "log_level", "message"]'
create_search "microcrm-search-back" "Back Logs" 'source_type : springboot' '["@timestamp", "log_level", "logger", "log_message", "message"]'
create_search "microcrm-search-front" "Front Logs" 'source_type : caddy' '["@timestamp", "front.request.method", "front.request.uri", "front.status", "message"]'
create_search "microcrm-search-back-errors" "Back Errors" 'source_type : springboot and log_level : (ERROR or WARN)' '["@timestamp", "log_level", "logger", "log_message"]'
create_search "microcrm-search-front-errors" "Front HTTP Errors" 'source_type : caddy and front.status >= 400' '["@timestamp", "front.request.method", "front.request.uri", "front.status", "front.duration"]'

cat >"${TMP_DASHBOARD_FILE}" <<'JSON'
{
  "attributes": {
    "title": "MicroCRM - Local Observability",
    "description": "Rapport logs enrichi: vue globale, front/back, et erreurs prioritaires.",
    "hits": 0,
    "optionsJSON": "{\"useMargins\":true,\"syncColors\":false,\"syncCursor\":true,\"syncTooltips\":false,\"hidePanelTitles\":false}",
    "panelsJSON": "[{\"type\":\"search\",\"panelIndex\":\"1\",\"gridData\":{\"x\":0,\"y\":0,\"w\":24,\"h\":11,\"i\":\"1\"},\"embeddableConfig\":{},\"panelRefName\":\"panel_0\",\"title\":\"All Logs\"},{\"type\":\"search\",\"panelIndex\":\"2\",\"gridData\":{\"x\":24,\"y\":0,\"w\":24,\"h\":11,\"i\":\"2\"},\"embeddableConfig\":{},\"panelRefName\":\"panel_1\",\"title\":\"Recent Errors & Warnings\"},{\"type\":\"search\",\"panelIndex\":\"3\",\"gridData\":{\"x\":0,\"y\":11,\"w\":24,\"h\":11,\"i\":\"3\"},\"embeddableConfig\":{},\"panelRefName\":\"panel_2\",\"title\":\"Back Logs\"},{\"type\":\"search\",\"panelIndex\":\"4\",\"gridData\":{\"x\":24,\"y\":11,\"w\":24,\"h\":11,\"i\":\"4\"},\"embeddableConfig\":{},\"panelRefName\":\"panel_3\",\"title\":\"Front Logs\"},{\"type\":\"search\",\"panelIndex\":\"5\",\"gridData\":{\"x\":0,\"y\":22,\"w\":24,\"h\":10,\"i\":\"5\"},\"embeddableConfig\":{},\"panelRefName\":\"panel_4\",\"title\":\"Back Errors\"},{\"type\":\"search\",\"panelIndex\":\"6\",\"gridData\":{\"x\":24,\"y\":22,\"w\":24,\"h\":10,\"i\":\"6\"},\"embeddableConfig\":{},\"panelRefName\":\"panel_5\",\"title\":\"Front HTTP Errors\"}]",
    "kibanaSavedObjectMeta": {
      "searchSourceJSON": "{\"query\":{\"query\":\"\",\"language\":\"kuery\"},\"filter\":[]}"
    }
  },
  "references": [
    { "id": "microcrm-search-all", "name": "panel_0", "type": "search" },
    { "id": "microcrm-search-errors", "name": "panel_1", "type": "search" },
    { "id": "microcrm-search-back", "name": "panel_2", "type": "search" },
    { "id": "microcrm-search-front", "name": "panel_3", "type": "search" },
    { "id": "microcrm-search-back-errors", "name": "panel_4", "type": "search" },
    { "id": "microcrm-search-front-errors", "name": "panel_5", "type": "search" }
  ]
}
JSON

echo "Creating or updating dashboard..."
kcurl -X POST "${KIBANA_URL}/api/saved_objects/dashboard/${DASHBOARD_ID}?overwrite=true" \
  -H 'kbn-xsrf: true' \
  -H 'Content-Type: application/json' \
  --data-binary @"${TMP_DASHBOARD_FILE}" >/dev/null

rm -f "${TMP_DASHBOARD_FILE}"

echo "Dashboard ready: ${KIBANA_URL}/app/dashboards#/view/${DASHBOARD_ID}"
