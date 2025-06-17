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
        help|--help|-h) venv::help ;;
        --version) venv::version ;;
        *) 
            echo "venvctl: ERROR: Invalid command: '$cmd'" >&2
            echo "Use 'venvctl help' for usage." >&2
            return 1
            ;;
    esac
}


venv::create() {
        local venv_name=${2:-venv}
        if [ -d "$venv_name" ]; then
            echo "venvctl: venv '$venv_name' already exists. " >&2
            return 1
        fi

        local python_version
        python_version=$(python3 --version 2>&1)

        echo "Creating venv '$venv_name' using $python_version"
        echo "Tips: To select Python version, use \`pyenv local <version>\` before creating venv."
        read -r -p "Proceed? [y/N]: " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "venvctl: Aborted." >&2
            return 1
        fi

        python3 -m venv "$venv_name"
        if [ $? -eq 0 ]; then
            echo "Successfully created venv '$venv_name'."
        else
            echo "venvctl: Failed to create venv '$env_name'. Check Python config." >&2
            return 1
        fi
}


venv::activate() {
    local venv_name=${2:-venv}
    local activate_path="./${venv_name}/bin/activate"
    if [ -f "$activate_path" ]; then
        source "$activate_path"
    else
        echo "venvctl: venv '$venv_name' not found at $activate_path"
        echo "Use \`venvctl list\` to list all available venvs." >&2
        return 1
    fi
}

venv::deactivate() {
    deactivate
}


venv::list() {
    shopt -s nullglob
    local found=0
    echo "# venvs in current directory:"
    echo "#"
    for d in */pyvenv.cfg; do
        found=1
        local venv_dir="${d%/pyvenv.cfg}"
        local venv_path="$(realpath "$venv_dir")"

        if [ -n "$VIRTUAL_ENV" ] && [ "$(realpath "$VIRTUAL_ENV")" = "$venv_path" ]; then
            printf "%-20s *   %s\n" "$venv_dir" "$venv_path"
        else
            printf "%-20s     %s\n" "$venv_dir" "$venv_path"
        fi
    done
    # if [ $found -eq 0 ]; then
    #     echo "venvctl: No venvs found in current directory."
    # fi
    shopt -u nullglob
}


venv::status() {
    if [ -n "$VIRTUAL_ENV" ]; then
        local python_version
        python_version=$(python3 -c 'import platform; print(platform.python_version())')
        echo "Active venv: $(basename "$VIRTUAL_ENV") ($python_version)"
        echo "Location: $VIRTUAL_ENV"
    else
        echo "No active venvs."
    fi
}


venv::remove() {
    local venv_name=${2:-venv}
    if [ -d "$venv_name" ]; then
        echo "Removing venv '$venv_name'"
        read -r -p "Proceed? [y/N]: " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "venvctl: Aborted." >&2
            return 1
        fi
        rm -rf "$venv_name"
        echo "Successfully removed venv '$venv_name'"
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

