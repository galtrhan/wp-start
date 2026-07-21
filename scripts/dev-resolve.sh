#!/usr/bin/env bash
# Resolve custom theme/plugin directories for linting and dev-php.sh.
#
# After sourcing, call:
#   collect_dev_targets "$repo_root"  — sets DEV_TARGETS[] (repo-relative paths)
#   dev_target_for_path "$repo_root" "$git_path" — prints matching target or fails

load_dev_env() {
    local root="${1:?}"
    if [[ -f "$root/.env" ]]; then
        set -a
        # shellcheck disable=SC1091
        source "$root/.env"
        set +a
    fi
}

has_dev_tooling() {
    local dir="${1%/}"
    [[ -f "$dir/composer.json" || -f "$dir/package.json" || -f "$dir/phpcs.xml" || -f "$dir/phpcs.xml.dist" ]]
}

is_custom_theme_dir() {
    local dir="${1%/}" name="$2"
    has_dev_tooling "$dir" || [[ -f "$dir/style.css" ]]
}

is_custom_plugin_dir() {
    local dir="${1%/}" name="$2"
    has_dev_tooling "$dir" || [[ -f "$dir/$name.php" ]]
}

is_default_theme() {
    case "$1" in
        twenty*) return 0 ;;
    esac
    return 1
}

is_default_plugin() {
    case "$1" in
        akismet|hello*) return 0 ;;
    esac
    return 1
}

collect_dev_targets() {
    local root="${1:?}"
    DEV_TARGETS=()
    load_dev_env "$root"

    if [[ -n "${THEME_NAME:-}" && -d "$root/wp-content/themes/$THEME_NAME" ]]; then
        DEV_TARGETS+=("wp-content/themes/$THEME_NAME")
    fi
    if [[ -n "${PLUGIN_NAME:-}" && -d "$root/wp-content/plugins/$PLUGIN_NAME" ]]; then
        DEV_TARGETS+=("wp-content/plugins/$PLUGIN_NAME")
    fi

    if ((${#DEV_TARGETS[@]})); then
        return 0
    fi

    local dir name
    shopt -s nullglob
    for dir in "$root/wp-content/themes"/*/; do
        [[ -d "$dir" ]] || continue
        name=$(basename "$dir")
        is_default_theme "$name" && continue
        if is_custom_theme_dir "$dir" "$name"; then
            DEV_TARGETS+=("wp-content/themes/$name")
        fi
    done
    for dir in "$root/wp-content/plugins"/*/; do
        [[ -d "$dir" ]] || continue
        name=$(basename "$dir")
        is_default_plugin "$name" && continue
        if is_custom_plugin_dir "$dir" "$name"; then
            DEV_TARGETS+=("wp-content/plugins/$name")
        fi
    done
    shopt -u nullglob

    ((${#DEV_TARGETS[@]}))
}

dev_target_for_path() {
    local root="${1:?}" path="${2:?}"
    collect_dev_targets "$root" || return 1

    local target
    for target in "${DEV_TARGETS[@]}"; do
        if [[ "$path" == "$target"/* || "$path" == "$target" ]]; then
            printf '%s\n' "$target"
            return 0
        fi
    done
    return 1
}

# Backward compatibility for theme-php.sh
resolve_theme_paths() {
    local root="${1:?}"
    THEME_REL=""
    THEME=""

    if ! collect_dev_targets "$root"; then
        return 1
    fi

    local target
    for target in "${DEV_TARGETS[@]}"; do
        if [[ "$target" == wp-content/themes/* ]]; then
            THEME_REL="$target"
            THEME="$root/$THEME_REL"
            return 0
        fi
    done

    return 1
}
