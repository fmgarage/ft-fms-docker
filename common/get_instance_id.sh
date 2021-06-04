# Get instance_id from .env
_pwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit 1
source "$_pwd"/settings.sh

instance_id=$(get_setting "ID" "$_pwd"/../.env)
check_setting "$instance_id"
