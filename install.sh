#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_SKILLS_DIR="${SCRIPT_DIR}/skills"

if [[ ! -d "${SOURCE_SKILLS_DIR}" ]]; then
  echo "Error: Source skills directory '${SOURCE_SKILLS_DIR}' not found." >&2
  exit 1
fi

# Detect available skills
AVAILABLE_SKILLS=()
for skill_path in "${SOURCE_SKILLS_DIR}"/*; do
  if [[ -d "${skill_path}" ]]; then
    AVAILABLE_SKILLS+=("$(basename "${skill_path}")")
  fi
done

if [[ ${#AVAILABLE_SKILLS[@]} -eq 0 ]]; then
  echo "Error: No skills found in '${SOURCE_SKILLS_DIR}'." >&2
  exit 1
fi

# Styling helpers
if [[ -t 1 ]]; then
  BOLD="\033[1m"
  DIM="\033[2m"
  CYAN="\033[36m"
  GREEN="\033[32m"
  YELLOW="\033[33m"
  RED="\033[31m"
  RESET="\033[0m"
else
  BOLD=""
  DIM=""
  CYAN=""
  GREEN=""
  YELLOW=""
  RED=""
  RESET=""
fi

show_cursor() {
  printf "\033[?25h" 2>/dev/null || true
}

hide_cursor() {
  printf "\033[?25l" 2>/dev/null || true
}

cleanup() {
  show_cursor
}
trap cleanup EXIT INT TERM

# Read a single keypress, including escape sequences for arrow keys
read_key() {
  local key=""
  IFS= read -rsn1 key
  if [[ "${key}" == $'\x1b' ]]; then
    local rest=""
    IFS= read -rsn2 -t 0.1 rest 2>/dev/null || true
    key+="${rest}"
  fi
  case "${key}" in
    $'\x1b[A'|k|K) echo "UP" ;;
    $'\x1b[B'|j|J) echo "DOWN" ;;
    "")            echo "ENTER" ;;
    " ")           echo "SPACE" ;;
    q|Q)           echo "QUIT" ;;
    *)             echo "${key}" ;;
  esac
}

# Single-select menu using arrow / vim keys (sets SELECTED_MENU_IDX)
SELECTED_MENU_IDX=0
select_menu() {
  local prompt="$1"
  shift
  local -a options=("$@")
  local selected=0
  local total=${#options[@]}
  local lines_drawn=0

  hide_cursor

  while true; do
    # Clear previous render if any
    if [[ ${lines_drawn} -gt 0 ]]; then
      for (( i=0; i<lines_drawn; i++ )); do
        printf "\033[1A\033[2K"
      done
    fi

    # Render header and options
    echo -e "${BOLD}${prompt}${RESET}"
    echo -e "${DIM}Use ↑/↓ or j/k to navigate, [Enter] to select, [q] to cancel${RESET}"

    for (( i=0; i<total; i++ )); do
      if [[ $i -eq $selected ]]; then
        echo -e " ${CYAN}❯${RESET} ${BOLD}${options[$i]}${RESET}"
      else
        echo -e "   ${DIM}${options[$i]}${RESET}"
      fi
    done
    lines_drawn=$(( total + 2 ))

    local key
    key="$(read_key)"
    case "${key}" in
      UP)
        if [[ $selected -gt 0 ]]; then
          selected=$(( selected - 1 ))
        else
          selected=$(( total - 1 ))
        fi
        ;;
      DOWN)
        if [[ $selected -lt $(( total - 1 )) ]]; then
          selected=$(( selected + 1 ))
        else
          selected=0
        fi
        ;;
      ENTER)
        show_cursor
        SELECTED_MENU_IDX="${selected}"
        return 0
        ;;
      QUIT)
        show_cursor
        echo -e "\n${YELLOW}Installation cancelled.${RESET}" >&2
        exit 0
        ;;
    esac
  done
}

# Multi/single-select menu for skills (sets SELECTED_SKILLS array)
SELECTED_SKILLS=()
select_skills_menu() {
  local prompt="Select skill(s) to install:"
  local -a skills=("${AVAILABLE_SKILLS[@]}")
  local -a options=("All skills (default)" "${skills[@]}")
  local -a checked=()
  local total=${#options[@]}
  local selected=0
  local lines_drawn=0

  for (( i=0; i<total; i++ )); do
    checked+=(0)
  done
  # Default: "All skills" checked
  checked[0]=1

  hide_cursor

  while true; do
    if [[ ${lines_drawn} -gt 0 ]]; then
      for (( i=0; i<lines_drawn; i++ )); do
        printf "\033[1A\033[2K"
      done
    fi

    echo -e "${BOLD}${prompt}${RESET}"
    echo -e "${DIM}Use ↑/↓ or j/k to navigate, [Space] to toggle, [Enter] to confirm, [q] to cancel${RESET}"

    for (( i=0; i<total; i++ )); do
      local mark=" "
      if [[ ${checked[$i]} -eq 1 ]]; then
        mark="✓"
      fi

      local prefix="   "
      if [[ $i -eq $selected ]]; then
        prefix=" ${CYAN}❯${RESET} "
      fi

      if [[ ${checked[$i]} -eq 1 ]]; then
        echo -e "${prefix}${GREEN}[${mark}]${RESET} ${BOLD}${options[$i]}${RESET}"
      else
        echo -e "${prefix}[${mark}] ${options[$i]}"
      fi
    done
    lines_drawn=$(( total + 2 ))

    local key
    key="$(read_key)"
    case "${key}" in
      UP)
        if [[ $selected -gt 0 ]]; then
          selected=$(( selected - 1 ))
        else
          selected=$(( total - 1 ))
        fi
        ;;
      DOWN)
        if [[ $selected -lt $(( total - 1 )) ]]; then
          selected=$(( selected + 1 ))
        else
          selected=0
        fi
        ;;
      SPACE)
        if [[ $selected -eq 0 ]]; then
          # Toggled "All skills"
          if [[ ${checked[0]} -eq 1 ]]; then
            checked[0]=0
          else
            checked[0]=1
            for (( i=1; i<total; i++ )); do
              checked[$i]=0
            done
          fi
        else
          # Toggled individual skill
          checked[0]=0
          if [[ ${checked[$selected]} -eq 1 ]]; then
            checked[$selected]=0
          else
            checked[$selected]=1
          fi
        fi
        ;;
      ENTER)
        # If user hits Enter on an option while nothing is checked, treat the current option as checked
        local any_checked=0
        for (( i=0; i<total; i++ )); do
          if [[ ${checked[$i]} -eq 1 ]]; then
            any_checked=1
            break
          fi
        done

        if [[ $any_checked -eq 0 ]]; then
          checked[$selected]=1
        fi

        show_cursor
        SELECTED_SKILLS=()
        if [[ ${checked[0]} -eq 1 ]]; then
          SELECTED_SKILLS=("${AVAILABLE_SKILLS[@]}")
        else
          for (( i=1; i<total; i++ )); do
            if [[ ${checked[$i]} -eq 1 ]]; then
              SELECTED_SKILLS+=("${options[$i]}")
            fi
          done
        fi
        return 0
        ;;
      QUIT)
        show_cursor
        echo -e "\n${YELLOW}Installation cancelled.${RESET}" >&2
        exit 0
        ;;
    esac
  done
}

# -----------------------------------------------------------------------------
# Main Execution
# -----------------------------------------------------------------------------

TARGET_DIR=""
SKILLS_TO_INSTALL=()

# Non-interactive mode via arguments
if [[ $# -ge 1 && -n "${1:-}" ]]; then
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: $0 [destination-directory] [skill1 skill2 ...]"
    echo ""
    echo "Available skills:"
    for skill in "${AVAILABLE_SKILLS[@]}"; do
      echo "  - ${skill}"
    done
    exit 0
  fi

  TARGET_DIR="${1/#\~/$HOME}"
  shift

  if [[ $# -ge 1 ]]; then
    SKILLS_TO_INSTALL=("$@")
  else
    SKILLS_TO_INSTALL=("${AVAILABLE_SKILLS[@]}")
  fi
else
  # Interactive mode
  if [[ ! -t 0 ]]; then
    echo "Error: Interactive installation requires a terminal (TTY)." >&2
    echo "Usage: $0 <destination-directory> [skill1 skill2 ...]" >&2
    exit 1
  fi

  echo -e "${BOLD}=== Agent Skills Installer ===${RESET}\n"

  COMMON_DIRS=(
    "Antigravity (~/.gemini/skills)"
    "Claude Code (~/.claude/skills)"
    "OpenAI Codex (~/.codex/skills)"
    "GitHub Copilot (~/.config/github-copilot/skills)"
    "Cursor (~/.cursor/skills)"
    "Custom directory..."
  )

  select_menu "Select installation destination directory:" "${COMMON_DIRS[@]}"

  case "${SELECTED_MENU_IDX}" in
    0) TARGET_DIR="$HOME/.gemini/skills" ;;
    1) TARGET_DIR="$HOME/.claude/skills" ;;
    2) TARGET_DIR="$HOME/.codex/skills" ;;
    3) TARGET_DIR="$HOME/.config/github-copilot/skills" ;;
    4) TARGET_DIR="$HOME/.cursor/skills" ;;
    5)
      echo ""
      while true; do
        read -r -e -p "Enter destination directory path: " custom_input
        if [[ -n "${custom_input// /}" ]]; then
          TARGET_DIR="${custom_input/#\~/$HOME}"
          break
        fi
        echo -e "${RED}Path cannot be empty. Please try again.${RESET}"
      done
      ;;
  esac

  echo -e "\nSelected directory: ${CYAN}${TARGET_DIR}${RESET}\n"

  # Skill selection
  select_skills_menu
  SKILLS_TO_INSTALL=("${SELECTED_SKILLS[@]}")
  echo ""
fi

# Validate target directory
mkdir -p "${TARGET_DIR}"

echo -e "${BOLD}Installing skills to '${TARGET_DIR}'...${RESET}"

for skill_name in "${SKILLS_TO_INSTALL[@]}"; do
  skill_src="${SOURCE_SKILLS_DIR}/${skill_name}"
  if [[ -d "${skill_src}" ]]; then
    echo -e "  ${GREEN}✓${RESET} Copying ${BOLD}${skill_name}${RESET}..."
    cp -r "${skill_src}" "${TARGET_DIR}/"
  else
    echo -e "  ${RED}✗${RESET} Warning: Skill '${skill_name}' not found in '${SOURCE_SKILLS_DIR}'." >&2
  fi
done

echo -e "\n${GREEN}${BOLD}Successfully installed ${#SKILLS_TO_INSTALL[@]} skill(s) to '${TARGET_DIR}'.${RESET}"
