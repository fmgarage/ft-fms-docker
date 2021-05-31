# Parse config
function get_setting() {
  grep -Ev '^\s*$|^\s*\#' "$2" | grep -E "\s*$1\s*=" | sed 's/.*=//; s/^ //g'
}

function check_setting() {
  if [[ $(wc -l <<<"$1") -gt 1 ]]; then
    echo "multiple values found, 1 expected" >&2
    exit 1
  elif [[ -z "$1" ]]; then
    printf "error: variable empty" >&2
    exit 2
  fi
}

# Get settings from config
_pwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit 1
project_id=$(get_setting "ID" $_pwd/../.env)
printf "checking \$project_id...\n"
check_setting "$project_id"
