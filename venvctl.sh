#!/bin/bash

# =============================================================
# venvctl config directory override
#
# By default, venvctl stores its internal state (venvs.db) under:
#   $HOME/.config/venvctl/
#
# To allow safe testing and sandboxing, this can be overridden by setting:
#   export VENVCTL_CONFIG_DIR=/path/to/custom/dir
#
# This makes testing fully isolated and avoids polluting the real system config.
# =============================================================
VENVCTL_CONFIG_DIR="${VENVCTL_CONFIG_DIR:-$HOME/.config/venvctl}"
VENVCTL_DB="$VENVCTL_CONFIG_DIR/venvs.db"



venvctl() {
    local cmd="$1"
    shift
    case "$cmd" in
        create)  venv::create "$@" ;;
        remove)  venv::remove "$@" ;;
        activate) venv::activate "$@" ;;
        deactivate) venv::deactivate "$@" ;;
        list) venv::list "$@" ;;
        status) venv::status "$@" ;;
        test) venv::test "$@" ;;
        help|--help|-h) venv::help ;;
        --version) venv::version ;;
        *) 
            echo "venvctl: Invalid command: '$cmd'" >&2
            echo "Use 'venvctl --help' for usage." >&2
            return 1
            ;;
    esac
}


venv::create() {
        local venv_name=${1:-venv}
        # if [ -d "$venv_name" ]; then
        if grep -q "^local,$venv_name," "$VENVCTL_DB" 2>/dev/null || [ -d "$env_name" ]; then
            echo "venvctl: venv '$venv_name' already exists. " >&2
            return 1
        fi

        local python_version
        python_version=$(python3 --version 2>&1)

        echo "Creating venv '$venv_name' using $python_version"
        echo "To select Python version, use \`pyenv local <version>\` before creating venv."
        read -r -p "Proceed? [y/N]: " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "venvctl: Aborted." >&2
            return 1
        fi

        python3 -m venv "$venv_name"
        if [ $? -eq 0 ]; then
            # write venv info to db
            local venv_path timestamp
            venv_path=$(realpath "./$venv_name")

            timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
            mkdir -p "$VENVCTL_CONFIG_DIR"
            touch "$VENVCTL_DB"
            echo "local,$venv_name,$venv_path,$python_version,$timestamp" >> "$VENVCTL_DB"
            echo "Successfully created venv '$venv_name'."
        else
            echo "venvctl: Failed to create venv '$env_name'. Check Python config." >&2
            return 1
        fi
}


venv::activate() {
    local venv_name=${1:-venv}

    # Check the venv db
    if [ ! -f "$VENVCTL_DB" ]; then
        echo "venvctl: Registry not found." >&2
        return 1
    fi

    # local activate_path="./${venv_name}/bin/activate"
    # if [ -f "$activate_path" ]; then
        # source "$activate_path"
    # else
    local entry
    entry=$(grep "^local,$venv_name," "$VENVCTL_DB" || true)

    if [ -z "$entry" ]; then
        echo "venvctl: venv '$venv_name' not found." >&2
        echo "Use \`venvctl list\` to view available venvs." >&2
        return 1
    fi

    # activate venv
    IFS=',' read -r scope name venv_path python_version timestamp <<< "$entry"
    local activate_path
    # venv_path=$(echo "$entry" | awk -F',' '{print $3}') # the 3rd item in the entry
    activate_path="$venv_path/bin/activate"

    if [ -f "$activate_path" ]; then
        source "$activate_path"
    else
        echo "venvctl: Activation file missing at $activate_path." >&2 # could be missing
        return 1
    fi
}

venv::deactivate() {
    deactivate
}


# venv::list() {
#     shopt -s nullglob
#     local found=0
#     echo "# venvs in current directory:"
#     echo "#"
#     for d in */pyvenv.cfg; do
#         found=1
#         local venv_dir="${d%/pyvenv.cfg}"
#         local venv_path="$(realpath "$venv_dir")"

#         if [ -n "$VIRTUAL_ENV" ] && [ "$(realpath "$VIRTUAL_ENV")" = "$venv_path" ]; then
#             printf "%-20s *   %s\n" "$venv_dir" "$venv_path"
#         else
#             printf "%-20s     %s\n" "$venv_dir" "$venv_path"
#         fi
#     done
#     # if [ $found -eq 0 ]; then
#     #     echo "venvctl: No venvs found in current directory."
#     # fi
#     shopt -u nullglob
# }

# rewrite venv::list() now that we have the db
venv::list() {
    if [ ! -f "$VENVCTL_DB" ]; then
        echo "venvctl: No virtualenv registry found." >&2
        return 1
    fi

    echo "# Registered venvs:"
    echo "#"
    local found=0

    while IFS=',' read -r scope venv_name venv_path python_version timestamp; do
        found=1
        local active_marker=""
        if [ -n "$VIRTUAL_ENV" ] && [ "$(realpath "$VIRTUAL_ENV")" = "$venv_path" ]; then
            active_marker="*"
        fi
        printf "%-20s %-3s %-50s (%s)\n" "$venv_name" "$active_marker" "$venv_path" "$python_version"
    done < "$VENVCTL_DB"

    # [ $found -eq 0 ] && echo "venvctl: Registry is empty."
}



venv::status() {
    if [ -n "$VIRTUAL_ENV" ]; then
        local python_version
        python_version=$(python3 -c 'import platform; print(platform.python_version())')
        echo "Active venv: $(basename "$VIRTUAL_ENV") (Python $python_version)"
        echo "Location: $VIRTUAL_ENV"
    else
        echo "No active venvs."
    fi
}

venv::test() {
    case "$1" in
        start)
            export VENVCTL_CONFIG_DIR="$(pwd)/.venvctl_test"
            VENVCTL_DB="$VENVCTL_CONFIG_DIR/venvs.db"
            # mkdir -p "$VENVCTL_CONFIG_DIR"
            # touch $VENVCTL_DB
            # echo "venvctl: Test mode started. VENVCTL_CONFIG_DIR=$VENVCTL_CONFIG_DIR"
            ;;
        stop)
            if [ -z "$VENVCTL_CONFIG_DIR" ]; then
                echo "venvctl: No test environment active." >&2
                return 1
            fi
            rm -rf "$VENVCTL_CONFIG_DIR"
            unset VENVCTL_CONFIG_DIR
            # echo "venvctl: Test mode cleaned up."
            ;;
        *)
            echo "venvctl: Usage: venvctl test {start|stop}" >&2
            return 1
            ;;
    esac
}

venv::remove() {
    local venv_name=${1:-venv}

    # Check if this venv is currently active
    if [ -n "$VIRTUAL_ENV" ] && [ "$(basename "$VIRTUAL_ENV")" = "$venv_name" ]; then
        echo "venvctl: Cannot remove venv '$venv_name' because it is currently active." >&2
        return 1
    fi

    if [ -d "$venv_name" ]; then
        echo "Removing venv '$venv_name'"
        read -r -p "Proceed? [y/N]: " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "venvctl: Aborted." >&2
            return 1
        fi
        rm -rf "$venv_name"
        echo "Successfully removed venv '$venv_name'"

        # remove the entry from the db if any
        if [ -f "$VENVCTL_DB" ]; then
            grep -v "^local,$venv_name," "$VENVCTL_DB" > "$VENVCTL_DB.tmp"
            mv "$VENVCTL_DB.tmp" "$VENVCTL_DB"
        fi
    else
        echo "venvctl: venv '$venv_name' does not exist." >&2
    fi
}


venv::version() {
    echo "venvctl v1.0.who-tf-cares -- Ay yai yai... stop inventing."
}


venv::help() {
    echo "Example Uuage:"
    echo "  venvctl create [env_name]         Create virtualenv (default: 'venv')"
    echo "  venvctl remove [env_name]         Remove virtualenv (default: 'venv')"
    echo "  venvctl activate [env_name]       Activate virtualenv (default: 'venv')"
    echo "  venvctl deactivate                Deactivate current virtualenv"
    echo "  venvctl status                    Show current virtualenv status"
    echo "  venvctl list                      List available virtualenvs in current directory"
    echo "  venvctl [version|-v|--version]    Show the version number"
    echo "  venvctl [help|-h|--help]          Show this help message"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  venvctl "$@"
fi
