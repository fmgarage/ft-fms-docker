_pwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $_pwd/settings.sh

paths=(
  "fms-admin-conf-${project_id}" "/Admin/conf/"
  "fms-data-backups-${project_id}" "/Data/Backups/"
  "fms-data-databases-${project_id}" "/Data/Databases/"
  "fms-data-preferences-${project_id}" "/Data/Preferences/"
  "fms-dbserver-extensions-${project_id}" "/Database Server/Extensions/"
  "fms-conf-${project_id}" "/conf/"
  "fms-http-dotconf-${project_id}" "/HTTPServer/.conf/"
  "fms-http-conf-${project_id}" "/HTTPServer/conf/"
  "fms-http-logs-${project_id}" "/HTTPServer/logs/"
  "fms-logs-${project_id}" "/Logs/"
  "fms-webpub-conf-${project_id}" "/Web Publishing/conf/"
)