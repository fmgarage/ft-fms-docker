# Get project_id from .env
_pwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit 1
source "$_pwd"/settings.sh

project_id=$(get_setting "ID" "$_pwd"/../.env)
printf "checking \$project_id...\n"
check_setting "$project_id"
