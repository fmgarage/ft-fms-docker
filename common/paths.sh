_pwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_pwd"/get_instance_id.sh

paths=(
  "fms-admin-conf-${instance_id}" "/Admin/conf/"
  "fms-data-backups-${instance_id}" "/Data/Backups/"
  "fms-data-databases-${instance_id}" "/Data/Databases/"
  "fms-data-preferences-${instance_id}" "/Data/Preferences/"
  "fms-data-scripts-${instance_id}" "/Data/Scripts"
  "fms-dbserver-extensions-${instance_id}" "/Database Server/Extensions/"
  "fms-conf-${instance_id}" "/conf/"
  "fms-http-dotconf-${instance_id}" "/HTTPServer/.conf/"
  "fms-http-conf-${instance_id}" "/HTTPServer/conf/"
  "fms-http-htdocs-${instance_id}" "/HTTPServer/htdocs/"
  "fms-http-logs-${instance_id}" "/HTTPServer/logs/"
  "fms-logs-${instance_id}" "/Logs/"
  "fms-webpub-conf-${instance_id}" "/Web Publishing/conf/"
)
