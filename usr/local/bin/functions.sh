#!/usr/bin/env bash

shopt -s nullglob

###
# Check if current user is root
##
function rootCheck() {
  # Root check
  if [ "$(/usr/bin/whoami)" != "root" ]; then
    echo "[ERROR] $* must be run as root"
    exit 1
  fi
}

###
# Create /docker.stdout and /docker.stderr
##
function createDockerStdoutStderr() {
  # link stdout from docker
  if [[ -n $LOG_STDOUT ]]; then
    echo "Log stdout redirected to $LOG_STDOUT"
  else
    LOG_STDOUT="/proc/$$/fd/1"
  fi

  if [[ -n $LOG_STDERR ]]; then
    echo "Log stderr redirected to $LOG_STDERR"
  else
    LOG_STDERR="/proc/$$/fd/2"
  fi

  ln -f -s "$LOG_STDOUT" /docker.stdout
  ln -f -s "$LOG_STDERR" /docker.stderr
}

###
# Include script directory text inside a file
#
# $1 -> path
##
function includeScriptDir() {
  if [[ -d $1 ]]; then
    for FILE in "$1"/*.sh; do
      echo "-> Executing ${FILE}"
      # run custom scripts, only once
      . "$FILE"
    done
  fi
}

###
# List environment variables (based on prefix)
##
function envListVars() {
  if [[ $# -eq 1 ]]; then
    env | grep "^${1}" | cut -d= -f1
  else
    env | cut -d= -f1
  fi
}

###
# Get environment variable (even with dots in name)
##
function envGetValue() {
  awk "BEGIN {print ENVIRON[\"$1\"]}"
}

###
# Mapping unprivileged user UID and GID
#
# Parameters: unpriv_username, new_unpriv_uid, new_unpriv_gid
##
function mappingUnprivUidGid() {
  ORIG_UID=$(id -u $1)
  ORIG_GID=$(id -g $1)
  if [[ -n $2 && $ORIG_UID != $2 ]]; then
    usermod -o -u $2 $1 &>/dev/null
    find /etc -user $ORIG_UID -exec chown -h $2 {} \;
    find /var/run -user $ORIG_UID -exec chown -h $2 {} \;
  fi
  if [[ -n $3 && $ORIG_GID != $3 ]]; then
    groupmod -o -g $3 $1 &>/dev/null
    find /etc -group $ORIG_GID -exec chgrp -h $3 {} \;
    find /var/run -group $ORIG_GID -exec chgrp -h $3 {} \;
    usermod -g $3 $1 &>/dev/null
  fi
}

###
# Create shell command alias (shell.alias.*)
##
function createShellAlias() {
  for ENV_VAR in $(envListVars "shell\.alias\."); do
    env_key=${ENV_VAR#shell.alias.}
    env_val=$(envGetValue "$ENV_VAR")
    echo "alias ${env_key}='${env_val}'" >> /etc/bash.bashrc
    echo "alias ${env_key}='${env_val}'" >> /etc/profile.d/02-custom-shell-alias.sh
  done
}

###
# Switch version for CLI tools (tools.cli.*)
##
function switchToolsVersion() {
  for ENV_VAR in $(envListVars "tools\.cli\."); do
    env_key=${ENV_VAR#tools.cli.}
    env_val=$(envGetValue "$ENV_VAR")
    FILE_PATH=/usr/local/bin/${env_key}.${env_val}
    if [ -f $FILE_PATH ]; then
      rm -f /usr/local/bin/${env_key}
      ln -s $FILE_PATH /usr/local/bin/${env_key}
    else
      echo "WARNING: CLI tools ${env_key} with version ${env_val} doesn't exist";
    fi
  done
}

###
# Fix UNIX permissions (FIX_PERMISSION_PATH)
# https://github.com/uselagoon/lagoon-images/blob/83560c217278edfc73cbd9de859ee511d889cb8c/images/commons/fix-permissions
##
function fixPermissionPath() {
  # Fix permissions on the given directory to allow group read/write of
  # regular files and execute of directories.
  find -L "$1" -exec chgrp 0 {} +
  find -L "$1" -exec chmod g+rwX {} +
}

###
# Get filenames from array, without extension
##
function getFilenamesWithoutExtension() {
  local ARR=("$@")
  for I in "${!ARR[@]}"; do
    local FILENAME=$(basename -- ${ARR[$I]})
    ARR[$I]="${FILENAME%.*}"
  done
  echo ${ARR[*]}
}
