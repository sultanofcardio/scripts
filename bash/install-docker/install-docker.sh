#!/usr/bin/env bash

if [[ $(whoami) != "root" ]]; then
    echo "Must run as root"
    exit 1
fi

set -e

#######################################
# Check the docker GitHub repositories for the latest release of the specified tool
# Taken from this gist: https://gist.github.com/lukechilds/a83e1d7127b78fef38c2914c4ececc3c
# Arguments:
#   The docker item to check for: [docker-ce, compose]
# Returns:
#   The name of the latest release tag
#######################################
get_latest_release() {
  curl --silent "https://api.github.com/repos/docker/$1/releases/latest" |
    grep '"tag_name":' |
    sed -E 's/.*"([^"]+)".*/\1/'
}

#######################################
# Check the system for a particular tool, get the version if it exists and compare it to the version supplied
# Arguments:
#   The name of the tool to check for: [docker, docker-compose]
#   The version to compare it against
# Returns:
#   0 if the tool doesn't exist or the versions don't match, 1 otherwise
#######################################
needs_upgrading() {
  ! command_doesnt_exist "${1}" || return 0
  version=$(get_version "${1}")

  if [ -z "${version}" ] || [ "${version}" != "${2}" ]; then
    return 0
  else
    return 1
  fi
}

#######################################
# Call <command> --version and get the version string from the output
# Arguments:
#   The command to get the version for: [docker, docker-compose]
# Returns:
#   The version of the command, e.g. 1.0.0
#######################################
get_version() {
  "${1}" --version | grep -oP "[0-9]+\.[0-9]+\.[0-9]+"
}

#######################################
# Add the docker gpg key and apt repository, install dependencies
# (apt-transport-https ca-certificates curl gnupg-agent software-properties-common)
# and then install the following:
#   * docker
#   * docker-engine
#   * docker.io
#   * containerd
#   * runc
#######################################
install_docker() {
  echo "========================="
  echo "Installing docker"
  echo "========================="
  apt-get remove -y docker docker-engine docker.io containerd runc || true
  apt-get update || (echo "Error updating package index" && exit 1)
  DEBIAN_FRONTEND="noninteractive" apt-get install -y apt-transport-https ca-certificates gnupg-agent software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  apt-key fingerprint 0EBFCD88 | grep "9DC8 5822 9FC7 DD38 854A  E2D8 8D81 803C 0EBF CD88" || (echo "Unable to add gpg key" && exit 1)
  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" -y
  apt-get update || (echo "Error updating package index" && exit 1)
  DEBIAN_FRONTEND="noninteractive" apt-get install -y docker-ce docker-ce-cli containerd.io
}

#######################################
# Download the latest version of the docker-compose binary and add it to /usr/local/bin
#######################################
install_docker_compose() {
  echo "========================="
  echo "Installing docker-compose"
  echo "========================="
  curl -L "https://github.com/docker/compose/releases/download/${LATEST_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose

}

#######################################
# Check if a particular command exists on the system
# Arguments:
#   The name of the command to check for
# Returns:
#   0 if the command doesn't exist, 1 if it does
#######################################
command_doesnt_exist() {
  type "${1}" >/dev/null 2>&1 || return 0
  return 1
}

YES=false

OPTIND=1

while getopts "y?:" opt; do
    case "$opt" in
    y|\?)
        YES=true
        ;;
    esac
done

shift $((OPTIND-1))

if command_doesnt_exist curl; then
  if $YES; then
    apt-get update && DEBIAN_FRONTEND="noninteractive" apt-get install -y curl
  else
    read -p "Requires curl. Install? (y/n): " -r do_install
    if [ "${do_install}" == "y" ]; then
      apt-get update && DEBIAN_FRONTEND="noninteractive" apt-get install -y curl
    else
      exit 1
    fi
  fi
fi

LATEST_DOCKER_VERSION="$(get_latest_release docker-ce)"
LATEST_DOCKER_VERSION="${LATEST_DOCKER_VERSION:1}"
LATEST_COMPOSE_VERSION="$(get_latest_release compose)"


#######################################
# DOCKER
#######################################
if ! command_doesnt_exist docker; then
  DOCKER_VERSION=$(get_version docker)
  if needs_upgrading docker "${LATEST_DOCKER_VERSION}"; then
    echo "Docker version is ${DOCKER_VERSION}. Latest version is ${LATEST_DOCKER_VERSION}"
    if $YES; then
      echo "Upgrading docker"
      install_docker
    else
      read -p "Upgrade docker? (y/n): " -r upgrade_docker
      if [ "${upgrade_docker}" == "y" ]; then
        echo "Upgrading docker"
        install_docker
      fi
    fi
  else
    echo "Docker is already the latest version (${DOCKER_VERSION})"
  fi
else
    install_docker
fi

#######################################
# DOCKER-COMPOSE
#######################################
if ! command_doesnt_exist docker-compose; then
  DOCKER_COMPOSE_VERSION=$(get_version docker-compose)
  if needs_upgrading docker-compose "${LATEST_COMPOSE_VERSION}"; then
    echo "docker-compose version is ${DOCKER_COMPOSE_VERSION}. Latest version is ${LATEST_COMPOSE_VERSION}"
    if $YES; then
      echo "Upgrading docker-compose"
      install_docker_compose
    else
      read -p "Upgrade docker-compose? (y/n): " -r upgrade_docker_compose
      if [ "${upgrade_docker_compose}" == "y" ]; then
        echo "Upgrading docker-compose"
        install_docker_compose
      fi
    fi
  else
    echo "docker-compose is already the latest version (${DOCKER_COMPOSE_VERSION})"
  fi
else
    install_docker_compose
fi

echo "========================="
echo "Installation complete"
echo "========================="

