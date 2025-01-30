#!/bin/bash
set -e

if [ -f /.username ]; then
  export USERNAME=$(cat /.username)
fi

## load common functions
source /usr/local/bin/functions.sh

mappingUnprivUidGid $USERNAME $PUID $PGID

createShellAlias

switchToolsVersion

## switch unprivileged user
if [[ -n "${SU}" && "${SU}" != 0 ]]; then
  sudo -u $USERNAME -H -E --preserve-env=ENV "$@"
else
  exec "$@"
fi

## fix UNIX permissions (FIX_PERMISSION_PATH)
if [[ -n $FIX_PERMISSION_PATH && -e $FIX_PERMISSION_PATH ]]; then
  fixPermissionPath "$FIX_PERMISSION_PATH"
fi
