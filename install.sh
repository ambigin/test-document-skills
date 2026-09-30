#!/usr/bin/env bash
#
# test-document-skills skill installer for Linux, macOS and Git Bash.
#
#   ./install.sh               interactive picker
#   ./install.sh --help        all options
#   curl -fsSL https://raw.githubusercontent.com/ambigin/test-document-skills/main/install.sh | bash
#
# Works with bash 3.2 (the macOS default), so no associative arrays or mapfile.

set -euo pipefail

REPO="ambigin/test-document-skills"
REF="main"

AGENTS_ARG=""
SCOPE=""
PROJECT_DIR=""
SKILLS_ARG=""
ALL=0
LINK=0
UNINSTALL=0
LIST=0
DRY_RUN=0
YES=0
NO_TUI=0

OUT_TTY=0
if [ -t 1 ]; then OUT_TTY=1; fi
if [ $OUT_TTY -eq 1 ] && [ -z "${NO_COLOR:-}" ]; then
  BOLD=$'\033[1m' DIM=$'\033[2m' RED=$'\033[31m' GREEN=$'\033[32m'
  YELLOW=$'\033[33m' CYAN=$'\033[36m' RESET=$'\033[0m'
else
  BOLD="" DIM="" RED="" GREEN="" YELLOW="" CYAN="" RESET=""
fi

usage() {
  cat <<'EOF'
Install test-document-skills skills for Claude Code and/or GitHub Copilot.

Usage: install.sh [options]

Run without options for an interactive picker. Every option you pass skips its prompt.

  --agent LIST        claude, copilot, or claude,copilot
  --scope SCOPE       global (your user account) or project
  --project-dir PATH  Project root for --scope project (default: current directory)
  --skills LIST       Comma-separated skill names
  --all               Select every skill
  --link              Symlink skills instead of copying them (needs a local clone)
  --uninstall         Remove the selected skills instead of installing them
  --list              Show available skills and where they are installed, then exit
  --dry-run           Show what would happen without changing anything
  -y, --yes           Don't ask for confirmation
  --ref REF           Branch or tag to download when not run from a clone (default: main)
  --no-tui            Use numbered prompts instead of the arrow-key menu
  -h, --help          Show this help

Install locations:
  Claude Code     global: ~/.claude/skills     project: <project>/.claude/skills
  GitHub Copilot  global: ~/.copilot/skills    project: <project>/.github/skills

Examples:
  install.sh --agent claude --scope global --all -y
  install.sh --agent claude,copilot --scope project --skills test-case-generator,bug-report-generator
  curl -fsSL https://raw.githubusercontent.com/ambigin/test-document-skills/main/install.sh | bash -s -- --list
EOF
}

die() { printf '%serror:%s %s\n' "$RED" "$RESET" "$*" >&2; exit 1; }
warn() { printf '%s!%s %s\n' "$YELLOW" "$RESET" "$*"; }
info() { printf '%s%s%s\n' "$DIM" "$*" "$RESET"; }

need_value() { [ "$2" -ge 2 ] || die "$1 needs a value"; }

while [ $# -gt 0 ]; do
  case "$1" in
    --agent)       need_value "$1" $#; AGENTS_ARG=$2; shift ;;
    --scope)       need_value "$1" $#; SCOPE=$2; shift ;;
    --project-dir) need_value "$1" $#; PROJECT_DIR=$2; shift ;;
    --skills)      need_value "$1" $#; SKILLS_ARG=$2; shift ;;
    --ref)         need_value "$1" $#; REF=$2; shift ;;
    --all)         ALL=1 ;;
    --link)        LINK=1 ;;
    --uninstall)   UNINSTALL=1 ;;
    --list)        LIST=1 ;;
    --dry-run)     DRY_RUN=1 ;;
    -y|--yes)      YES=1 ;;
    --no-tui)      NO_TUI=1 ;;
    -h|--help)     usage; exit 0 ;;
    *)             die "unknown option '$1' (see --help)" ;;
  esac
  shift
done

case "$SCOPE" in
  ""|global|project) ;;
  *) die "--scope must be 'global' or 'project'" ;;
esac

AGENTS=""
if [ -n "$AGENTS_ARG" ]; then
  for a in $(printf '%s' "$AGENTS_ARG" | tr ',' ' '); do
    case "$a" in
      claude|copilot) AGENTS="$AGENTS $a" ;;
      all|both) AGENTS=" claude copilot" ;;
      *) die "unknown agent '$a' (use claude and/or copilot)" ;;
    esac
  done
  AGENTS=${AGENTS# }
fi

# ---------------------------------------------------------------------------
# Terminal handling

HAVE_TTY=0
if { : </dev/tty; } 2>/dev/null; then HAVE_TTY=1; fi
USE_TUI=0
if [ $HAVE_TTY -eq 1 ] && [ $NO_TUI -eq 0 ] && [ $OUT_TTY -eq 1 ] && [ "${TERM:-dumb}" != dumb ]; then
  USE_TUI=1
fi

TMP_DIR=""
cleanup() {
  if [ $USE_TUI -eq 1 ]; then printf '\033[?25h'; fi
  if [ -n "$TMP_DIR" ]; then rm -rf "$TMP_DIR"; fi
}
trap cleanup EXIT
trap 'exit 130' INT TERM

# Reads one line into REPLY_LINE. Under `curl | bash`, stdin is the script
# itself, so read from the terminal whenever there is one.
read_input() {
  if [ $HAVE_TTY -eq 1 ]; then
    IFS= read -r REPLY_LINE </dev/tty || die "no input"
  else
    IFS= read -r REPLY_LINE || die "no input available; pass the choices as options (see --help) and add --yes"
  fi
}

confirm() {
  if [ $YES -eq 1 ]; then return 0; fi
  printf '%s [Y/n] ' "$1"
  read_input
  case "$REPLY_LINE" in
    ""|y|Y|yes|Yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

# Truncates $1 to $2 characters, but only when writing to a terminal.
fit() {
  if [ $OUT_TTY -eq 0 ] || [ "$2" -ge ${#1} ]; then
    printf '%s' "$1"
  elif [ "$2" -ge 10 ]; then
    printf '%s…' "${1:0:$(($2 - 1))}"
  fi
}

term_cols() {
  local cols
  cols=$( (stty size </dev/tty) 2>/dev/null | awk '{print $2}') || cols=""
  if [ -z "$cols" ] || [ "$cols" -lt 20 ] 2>/dev/null; then cols=${COLUMNS:-80}; fi
  printf '%s' "$cols"
}

# Menus read MENU_LABELS, MENU_DESCS and MENU_TAGS (parallel arrays) and
# MENU_PRESELECT (space-separated indices). They set MENU_RESULT to the
# space-separated indices the user picked.
select_menu() {
  if [ $USE_TUI -eq 1 ]; then tui_menu "$@"; else numbered_menu "$@"; fi
}

tui_menu() {
  local title=$1 multi=$2
  local n=${#MENU_LABELS[@]} cur=0 i key rest msg="" hint cols labelw=0 count
  local pointer box label desc tag tagcolor room
  local -a sel
  cols=$(term_cols)
  for ((i = 0; i < n; i++)); do
    sel[i]=0
    if [ ${#MENU_LABELS[i]} -gt $labelw ]; then labelw=${#MENU_LABELS[i]}; fi
  done
  for i in $MENU_PRESELECT; do sel[i]=1; done
  if [ "$multi" -eq 0 ] && [ -n "$MENU_PRESELECT" ]; then cur=${MENU_PRESELECT%% *}; fi

  if [ "$multi" -eq 1 ]; then
    hint="↑/↓ move · space toggle · a all · n none · enter confirm · q quit"
  else
    hint="↑/↓ move · enter select · q quit"
  fi
  printf '\n%s%s%s\n%s%s%s\n' "$BOLD" "$title" "$RESET" "$DIM" "$hint" "$RESET"
  printf '\033[?25l'

  local drawn=0
  while :; do
    if [ $drawn -eq 1 ]; then printf '\033[%dA' $((n + 1)); fi
    drawn=1
    for ((i = 0; i < n; i++)); do
      pointer=" " label=${MENU_LABELS[i]}
      if [ $i -eq $cur ]; then pointer="${CYAN}❯${RESET}" label="${CYAN}${label}${RESET}"; fi
      box=""
      if [ "$multi" -eq 1 ]; then
        if [ "${sel[i]}" -eq 1 ]; then box="${GREEN}[x]${RESET} "; else box="[ ] "; fi
      fi
      tag=${MENU_TAGS[i]} desc=${MENU_DESCS[i]}
      case "$tag" in
        installed) tagcolor=$GREEN ;;
        *) tagcolor=$YELLOW ;;
      esac
      room=$((cols - 7 - labelw - 2 - 1))
      if [ -n "$tag" ]; then room=$((room - ${#tag} - 4)); fi
      if [ $room -lt 10 ]; then
        desc=""
      elif [ ${#desc} -gt $room ]; then
        desc="${desc:0:$((room - 1))}…"
      fi
      printf '\r\033[2K %s %s%s%*s  %s%s%s' "$pointer" "$box" "$label" $((labelw - ${#MENU_LABELS[i]})) "" "$DIM" "$desc" "$RESET"
      if [ -n "$tag" ]; then printf '  %s[%s]%s' "$tagcolor" "$tag" "$RESET"; fi
      printf '\n'
    done
    printf '\r\033[2K%s%s%s\n' "$YELLOW" "$msg" "$RESET"
    msg=""

    IFS= read -rsn1 key </dev/tty || key=q
    case "$key" in
      $'\033')
        rest=""
        IFS= read -rsn2 -t 1 rest </dev/tty || true
        case "$rest" in
          '[A'|'OA') cur=$(((cur + n - 1) % n)) ;;
          '[B'|'OB') cur=$(((cur + 1) % n)) ;;
          '') printf '\nCancelled.\n'; exit 1 ;;
        esac
        ;;
      k) cur=$(((cur + n - 1) % n)) ;;
      j) cur=$(((cur + 1) % n)) ;;
      ' ')
        if [ "$multi" -eq 1 ]; then sel[cur]=$((1 - sel[cur])); fi
        ;;
      a|A)
        if [ "$multi" -eq 1 ]; then for ((i = 0; i < n; i++)); do sel[i]=1; done; fi
        ;;
      n|N)
        if [ "$multi" -eq 1 ]; then for ((i = 0; i < n; i++)); do sel[i]=0; done; fi
        ;;
      q|Q) printf '\nCancelled.\n'; exit 1 ;;
      "")
        if [ "$multi" -eq 0 ]; then MENU_RESULT=$cur; break; fi
        MENU_RESULT="" count=0
        for ((i = 0; i < n; i++)); do
          if [ "${sel[i]}" -eq 1 ]; then MENU_RESULT="$MENU_RESULT $i"; count=$((count + 1)); fi
        done
        MENU_RESULT=${MENU_RESULT# }
        if [ $count -gt 0 ]; then break; fi
        msg="Select at least one item with space (or press a for all)."
        ;;
    esac
  done
  printf '\033[?25h'
}

numbered_menu() {
  local title=$1 multi=$2
  local n=${#MENU_LABELS[@]} i tok ok answer tag labelw=0 cols
  cols=$(term_cols)
  for ((i = 0; i < n; i++)); do
    if [ ${#MENU_LABELS[i]} -gt $labelw ]; then labelw=${#MENU_LABELS[i]}; fi
  done
  printf '\n%s%s%s\n' "$BOLD" "$title" "$RESET"
  for ((i = 0; i < n; i++)); do
    tag=""
    if [ -n "${MENU_TAGS[i]}" ]; then tag=" [${MENU_TAGS[i]}]"; fi
    printf '  %2d) %-*s  %s%s%s%s\n' $((i + 1)) "$labelw" "${MENU_LABELS[i]}" "$DIM" \
      "$(fit "${MENU_DESCS[i]}" $((cols - labelw - ${#tag} - 9)))" "$RESET" "$tag"
  done
  while :; do
    if [ "$multi" -eq 1 ]; then
      printf 'Enter numbers separated by commas, or "all": '
    else
      printf 'Enter a number: '
    fi
    read_input
    answer=$(printf '%s' "$REPLY_LINE" | tr ',' ' ')
    if [ -z "${answer// /}" ] && [ -n "$MENU_PRESELECT" ]; then
      MENU_RESULT=$MENU_PRESELECT
      return
    fi
    MENU_RESULT="" ok=1
    if [ "$multi" -eq 1 ] && [ "$(printf '%s' "$answer" | tr -d ' ')" = "all" ]; then
      for ((i = 0; i < n; i++)); do MENU_RESULT="$MENU_RESULT $i"; done
    else
      for tok in $answer; do
        case "$tok" in
          *[!0-9]*) ok=0 ;;
          *)
            if [ "$tok" -ge 1 ] && [ "$tok" -le "$n" ]; then
              case " $MENU_RESULT " in
                *" $((tok - 1)) "*) ;;
                *) MENU_RESULT="$MENU_RESULT $((tok - 1))" ;;
              esac
            else
              ok=0
            fi
            ;;
        esac
      done
    fi
    MENU_RESULT=${MENU_RESULT# }
    if [ "$multi" -eq 0 ] && [ "$MENU_RESULT" != "${MENU_RESULT%% *}" ]; then ok=0; fi
    if [ $ok -eq 1 ] && [ -n "$MENU_RESULT" ]; then return; fi
    printf '%sInvalid choice, try again.%s\n' "$YELLOW" "$RESET"
  done
}

# ---------------------------------------------------------------------------
# Skills source

# Downloads a .tar.gz from $1 (with bearer token $2, if set) into TMP_DIR.
fetch_archive() {
  local auth=()
  if command -v curl >/dev/null 2>&1; then
    if [ -n "$2" ]; then auth=(-H "Authorization: Bearer $2"); fi
    (curl -fsSL ${auth[@]+"${auth[@]}"} "$1" | tar -xz -C "$TMP_DIR") 2>/dev/null
  elif command -v wget >/dev/null 2>&1; then
    if [ -n "$2" ]; then auth=(--header "Authorization: Bearer $2"); fi
    (wget -qO- ${auth[@]+"${auth[@]}"} "$1" | tar -xz -C "$TMP_DIR") 2>/dev/null
  else
    die "curl or wget is needed to download the skills"
  fi
}

SCRIPT_DIR=""
script_path=${BASH_SOURCE[0]:-}
if [ -n "$script_path" ] && [ -f "$script_path" ]; then
  SCRIPT_DIR=$(cd "$(dirname "$script_path")" && pwd)
fi

if [ -n "$SCRIPT_DIR" ] && [ -d "$SCRIPT_DIR/skills" ]; then
  SKILLS_ROOT="$SCRIPT_DIR/skills"
  SOURCE_LABEL="local clone ($SCRIPT_DIR)"
else
  [ $LINK -eq 0 ] || die "--link needs a local clone of the repo; run ./install.sh from inside it"
  TMP_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t leapfrog-skills)
  hint="If the repo is private, sign in with 'gh auth login' or set GITHUB_TOKEN, or clone the repo and run ./install.sh from it."
  info "Downloading $REPO@$REF ..."
  if ! fetch_archive "https://codeload.github.com/$REPO/tar.gz/$REF" ""; then
    # Private repos need credentials: use a token from the environment or the GitHub CLI.
    token=${GITHUB_TOKEN:-${GH_TOKEN:-}}
    if [ -z "$token" ] && command -v gh >/dev/null 2>&1; then token=$(gh auth token 2>/dev/null) || token=""; fi
    [ -n "$token" ] || die "couldn't download $REPO@$REF. $hint"
    info "Retrying with your GitHub credentials ..."
    rm -rf "${TMP_DIR:?}"/*
    fetch_archive "https://api.github.com/repos/$REPO/tarball/$REF" "$token" || die "couldn't download $REPO@$REF. $hint"
  fi
  SKILLS_ROOT=$(find "$TMP_DIR" -mindepth 2 -maxdepth 2 -type d -name skills | head -n 1)
  [ -n "$SKILLS_ROOT" ] || die "the downloaded archive has no skills/ folder"
  SOURCE_LABEL="GitHub $REPO@$REF"
fi

if [ $LINK -eq 1 ] && [ $UNINSTALL -eq 0 ]; then
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) die "--link doesn't create real links in Git Bash; use install.ps1 -Link instead" ;;
  esac
fi

# Prints the first sentence of the SKILL.md frontmatter description, joining
# the lines of a folded (>) block.
skill_summary() {
  awk '
    { sub(/\r$/, "") }
    NR == 1 { if ($0 != "---") exit; next }
    $0 == "---" { exit }
    /^description:/ {
      d = $0; sub(/^description:[ \t]*/, "", d)
      if (d ~ /^[>|][-+]?$/) d = ""
      grab = 1; next
    }
    grab && /^[ \t]/ { l = $0; sub(/^[ \t]+/, "", l); d = (d == "" ? l : d " " l); next }
    { grab = 0 }
    END {
      gsub(/^["\047]|["\047]$/, "", d)
      i = index(d, ". "); if (i > 0) d = substr(d, 1, i)
      print d
    }
  ' "$1"
}

SKILL_IDS=()
SKILL_DESCS=()
for dir in "$SKILLS_ROOT"/*/; do
  dir=${dir%/}
  [ -f "$dir/SKILL.md" ] || continue
  SKILL_IDS+=("$(basename "$dir")")
  SKILL_DESCS+=("$(skill_summary "$dir/SKILL.md")")
done
[ ${#SKILL_IDS[@]} -gt 0 ] || die "no skills found in $SKILLS_ROOT"

is_skill() {
  local s
  for s in "${SKILL_IDS[@]}"; do
    if [ "$s" = "$1" ]; then return 0; fi
  done
  return 1
}

SELECTED=""
if [ -n "$SKILLS_ARG" ]; then
  for s in $(printf '%s' "$SKILLS_ARG" | tr ',' ' '); do
    is_skill "$s" || die "unknown skill '$s' (run with --list to see them)"
    SELECTED="$SELECTED $s"
  done
  SELECTED=${SELECTED# }
fi

# ---------------------------------------------------------------------------
# Install targets and status

agent_label() {
  case "$1" in
    claude) printf 'Claude Code' ;;
    copilot) printf 'GitHub Copilot' ;;
  esac
}

target_root() {
  case "$1:$2" in
    claude:global) printf '%s' "$HOME/.claude/skills" ;;
    claude:project) printf '%s' "$PROJECT_DIR/.claude/skills" ;;
    copilot:global) printf '%s' "$HOME/.copilot/skills" ;;
    copilot:project) printf '%s' "$PROJECT_DIR/.github/skills" ;;
  esac
}

# Prints none, linked, installed (same files) or outdated (files differ).
skill_status() {
  local src="$SKILLS_ROOT/$1" dest=$2
  if [ -L "$dest" ]; then
    echo linked
  elif [ ! -d "$dest" ]; then
    echo none
  elif ! command -v diff >/dev/null 2>&1 || diff -rq "$src" "$dest" >/dev/null 2>&1; then
    echo installed
  else
    echo outdated
  fi
}

# Combined status across the chosen agents, for the picker.
status_tag() {
  local a st total=0 have=0 outdated=0
  for a in $AGENTS; do
    total=$((total + 1))
    st=$(skill_status "$1" "$(target_root "$a" "$SCOPE")/$1")
    case "$st" in
      none) ;;
      outdated) have=$((have + 1)); outdated=1 ;;
      *) have=$((have + 1)) ;;
    esac
  done
  if [ $outdated -eq 1 ]; then
    printf 'update available'
  elif [ $have -eq 0 ]; then
    printf ''
  elif [ $have -lt $total ]; then
    printf 'partly installed'
  else
    printf 'installed'
  fi
}

resolve_project_dir() {
  local dir=$1
  case "$dir" in
    "~") dir=$HOME ;;
    "~/"*) dir="$HOME/${dir#\~/}" ;;
  esac
  (cd "$dir" 2>/dev/null && pwd)
}

if [ -n "$PROJECT_DIR" ]; then
  PROJECT_DIR=$(resolve_project_dir "$PROJECT_DIR") || die "project directory not found: $PROJECT_DIR"
fi

# ---------------------------------------------------------------------------
# --list

if [ $LIST -eq 1 ]; then
  [ -n "$PROJECT_DIR" ] || PROJECT_DIR=$(pwd)
  list_agents=${AGENTS:-claude copilot}
  list_scopes=${SCOPE:-global project}
  labelw=0 cols=$(term_cols)
  for s in "${SKILL_IDS[@]}"; do
    if [ ${#s} -gt $labelw ]; then labelw=${#s}; fi
  done
  printf '%sSkills from %s%s\n\n' "$BOLD" "$SOURCE_LABEL" "$RESET"
  for i in "${!SKILL_IDS[@]}"; do
    s=${SKILL_IDS[i]}
    printf '  %s%-*s%s  %s\n' "$CYAN" "$labelw" "$s" "$RESET" "$(fit "${SKILL_DESCS[i]}" $((cols - labelw - 5)))"
    where=""
    for sc in $list_scopes; do
      for a in $list_agents; do
        st=$(skill_status "$s" "$(target_root "$a" "$sc")/$s")
        case "$st" in
          none) ;;
          outdated) where="$where  ${YELLOW}$a/$sc (update available)${RESET}" ;;
          *) where="$where  ${GREEN}$a/$sc ($st)${RESET}" ;;
        esac
      done
    done
    if [ -n "$where" ]; then printf '  %*s %s\n' "$labelw" "" "$where"; fi
  done
  printf '\n%sProject status is for %s%s\n' "$DIM" "$PROJECT_DIR" "$RESET"
  exit 0
fi

# ---------------------------------------------------------------------------
# Interactive choices

printf '%stest-document-skills skill installer%s\n' "$BOLD" "$RESET"
info "Source: $SOURCE_LABEL"
if [ $UNINSTALL -eq 1 ]; then warn "Uninstall mode: selected skills will be removed."; fi

if [ -z "$AGENTS" ]; then
  MENU_LABELS=("Claude Code" "GitHub Copilot")
  MENU_DESCS=("~/.claude/skills or <project>/.claude/skills" "~/.copilot/skills or <project>/.github/skills")
  MENU_TAGS=("" "")
  MENU_PRESELECT="0"
  select_menu "Which assistants should get the skills?" 1
  for i in $MENU_RESULT; do
    case $i in
      0) AGENTS="$AGENTS claude" ;;
      1) AGENTS="$AGENTS copilot" ;;
    esac
  done
  AGENTS=${AGENTS# }
fi

ask_project_dir=0
if [ -z "$SCOPE" ]; then
  MENU_LABELS=("Global" "Project")
  MENU_DESCS=("Your user account: available in every project" "One project only: commit it to share with your team")
  MENU_TAGS=("" "")
  MENU_PRESELECT="0"
  select_menu "Where should they go?" 0
  if [ "$MENU_RESULT" = 0 ]; then SCOPE=global; else SCOPE=project; ask_project_dir=1; fi
fi

if [ "$SCOPE" = project ] && [ -z "$PROJECT_DIR" ]; then
  if [ $ask_project_dir -eq 1 ]; then
    while :; do
      printf '\nProject directory [%s]: ' "$(pwd)"
      read_input
      if [ -z "$REPLY_LINE" ]; then REPLY_LINE=$(pwd); fi
      if PROJECT_DIR=$(resolve_project_dir "$REPLY_LINE"); then break; fi
      warn "Directory not found: $REPLY_LINE"
    done
  else
    PROJECT_DIR=$(pwd)
  fi
fi
if [ "$SCOPE" = project ] && [ ! -e "$PROJECT_DIR/.git" ]; then
  warn "$PROJECT_DIR is not the root of a git repository."
fi

if [ $ALL -eq 1 ]; then
  SELECTED="${SKILL_IDS[*]}"
elif [ -z "$SELECTED" ]; then
  MENU_LABELS=() MENU_DESCS=() MENU_TAGS=()
  for i in "${!SKILL_IDS[@]}"; do
    tag=$(status_tag "${SKILL_IDS[i]}")
    # When uninstalling, only offer skills that are actually there.
    if [ $UNINSTALL -eq 1 ] && [ -z "$tag" ]; then continue; fi
    MENU_LABELS+=("${SKILL_IDS[i]}")
    MENU_DESCS+=("${SKILL_DESCS[i]}")
    MENU_TAGS+=("$tag")
  done
  if [ ${#MENU_LABELS[@]} -eq 0 ]; then
    printf '\nNo skills are installed there, so there is nothing to remove.\n'
    exit 0
  fi
  MENU_PRESELECT=""
  if [ $UNINSTALL -eq 1 ]; then
    select_menu "Which skills should be removed?" 1
  else
    select_menu "Which skills do you want to install?" 1
  fi
  for i in $MENU_RESULT; do SELECTED="$SELECTED ${MENU_LABELS[i]}"; done
  SELECTED=${SELECTED# }
fi

# ---------------------------------------------------------------------------
# Plan, confirm, apply

PLAN=""
printf '\n%sPlan%s\n' "$BOLD" "$RESET"
for s in $SELECTED; do
  for a in $AGENTS; do
    dest="$(target_root "$a" "$SCOPE")/$s"
    st=$(skill_status "$s" "$dest")
    if [ $UNINSTALL -eq 1 ]; then
      if [ "$st" = none ]; then
        printf '  %s- %-28s not installed for %s, skipping%s\n' "$DIM" "$s" "$(agent_label "$a")" "$RESET"
        continue
      fi
      action="remove"
    else
      case "$st" in
        none) action="install" ;;
        outdated) action="update" ;;
        *) action="reinstall" ;;
      esac
    fi
    PLAN="$PLAN $s|$a"
    printf '  %-9s %-32s → %s\n' "$action" "$s" "$dest"
  done
done
PLAN=${PLAN# }

if [ -z "$PLAN" ]; then
  printf '\nNothing to do.\n'
  exit 0
fi
if [ $DRY_RUN -eq 1 ]; then
  printf '\n%sDry run: nothing was changed.%s\n' "$DIM" "$RESET"
  exit 0
fi
printf '\n'
if ! confirm "Proceed?"; then
  printf 'Cancelled.\n'
  exit 1
fi

remove_path() {
  if [ -L "$1" ]; then rm -f "$1"; elif [ -e "$1" ]; then rm -rf "$1"; fi
}

install_one() {
  local src="$SKILLS_ROOT/$1" dest=$2
  mkdir -p "$(dirname "$dest")" && remove_path "$dest" &&
    if [ $LINK -eq 1 ]; then ln -s "$src" "$dest"; else cp -R "$src" "$dest"; fi
}

printf '\n'
ok=0 failed=0
for item in $PLAN; do
  s=${item%%|*} a=${item#*|}
  dest="$(target_root "$a" "$SCOPE")/$s"
  if [ $UNINSTALL -eq 1 ]; then
    if remove_path "$dest"; then result=0; else result=1; fi
  else
    if install_one "$s" "$dest"; then result=0; else result=1; fi
  fi
  if [ $result -eq 0 ]; then
    ok=$((ok + 1))
    printf '  %s✔%s %s %s(%s)%s\n' "$GREEN" "$RESET" "$s" "$DIM" "$(agent_label "$a")" "$RESET"
  else
    failed=$((failed + 1))
    printf '  %s✖%s %s %s(%s)%s\n' "$RED" "$RESET" "$s" "$DIM" "$(agent_label "$a")" "$RESET"
  fi
done

if [ $UNINSTALL -eq 1 ]; then
  printf '\nRemoved %d, failed %d.\n' "$ok" "$failed"
  [ $failed -eq 0 ] || exit 1
  exit 0
fi
printf '\nInstalled %d, failed %d.\n' "$ok" "$failed"

# ---------------------------------------------------------------------------
# Dependencies and next steps

find_python() {
  local py
  for py in python3 python py; do
    if command -v "$py" >/dev/null 2>&1 &&
      "$py" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 8) else 1)' >/dev/null 2>&1; then
      printf '%s' "$py"
      return 0
    fi
  done
  return 1
}

needs_openpyxl=0
for s in $SELECTED; do
  if grep -rqs --include='*.py' openpyxl "$SKILLS_ROOT/$s"; then needs_openpyxl=1; fi
done

if [ $needs_openpyxl -eq 1 ]; then
  if ! PY=$(find_python); then
    printf '\n'
    warn "Python 3.8+ wasn't found. These skills need it (with openpyxl) to create .xlsx files."
  elif ! "$PY" -c 'import openpyxl' >/dev/null 2>&1; then
    printf '\n'
    warn "The Python package openpyxl is missing. These skills use it to create .xlsx files."
    if [ $YES -eq 0 ] && confirm "Install it now with '$PY -m pip install --user openpyxl'?"; then
      if ! "$PY" -m pip install --user openpyxl; then
        warn "pip failed. Install openpyxl yourself (pip, pipx or your package manager)."
      fi
    else
      info "  To install it later: $PY -m pip install openpyxl"
    fi
  fi
fi

first_skill=${SELECTED%% *}
printf '\n%sNext steps%s\n' "$BOLD" "$RESET"
for a in $AGENTS; do
  case "$a" in
    claude)
      printf '  • Claude Code: start a new session, then type /%s or just describe your task.\n' "$first_skill" ;;
    copilot)
      printf '  • GitHub Copilot: reload VS Code and use Copilot Chat in agent mode. If the skills\n'
      printf '    do not show up, turn on the chat.useAgentSkills setting.\n' ;;
  esac
done
if [ "$SCOPE" = project ]; then
  printf '  • Commit the skills folder in %s so your team gets them too.\n' "$PROJECT_DIR"
fi
if [ $failed -gt 0 ]; then exit 1; fi
