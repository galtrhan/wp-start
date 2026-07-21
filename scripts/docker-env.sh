#!/usr/bin/env bash
# Point the Docker CLI at a working daemon (rootful or rootless).
# Source from project scripts, or run with --print to emit DOCKER_HOST for eval.
# Respects an existing DOCKER_HOST (e.g. from fish shell config).

docker_host_ready() {
    local host="${1:-}"
    if [[ -z "$host" ]]; then
        docker info >/dev/null 2>&1
        return
    fi
    docker -H "$host" info >/dev/null 2>&1
}

configure_docker_host() {
    if [[ -n "${DOCKER_HOST:-}" ]]; then
        return 0
    fi

    if docker_host_ready; then
        return 0
    fi

    local runtime_sock
    if [[ -n "${XDG_RUNTIME_DIR:-}" ]]; then
        runtime_sock="${XDG_RUNTIME_DIR}/docker.sock"
    else
        runtime_sock="/run/user/$(id -u)/docker.sock"
    fi

    local candidates=()
    if [[ -S "$runtime_sock" ]]; then
        candidates+=("unix://${runtime_sock}")
    fi

    local home_sock="${HOME}/.docker/run/docker.sock"
    if [[ -S "$home_sock" ]]; then
        candidates+=("unix://${home_sock}")
    fi

    local host
    for host in "${candidates[@]}"; do
        if docker_host_ready "$host"; then
            export DOCKER_HOST="$host"
            return 0
        fi
    done

    return 1
}

if [[ "${1:-}" == "--print" ]]; then
    configure_docker_host || true
    if [[ -n "${DOCKER_HOST:-}" ]]; then
        printf '%s\n' "$DOCKER_HOST"
    fi
    exit 0
fi

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    configure_docker_host || true
fi
