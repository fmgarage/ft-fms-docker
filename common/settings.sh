# Parse config
function get_setting() {
  grep -Ev '^\s*$|^\s*\#' "$2" | grep -E "\s*$1\s*=" | sed 's/.*=//; s/^ //g'
}

function check_empty() {
    if [[ -z "$1" ]]; then
    printf "error: variable empty" >&2
    exit 2
  fi
}

function check_many() {
  if [[ $(wc -l <<<"$1") -gt 1 ]]; then
    echo "multiple values found, 1 expected" >&2
    exit 1
  fi
}

function check_setting() {
  check_empty "$1"
  check_many "$1"
}
