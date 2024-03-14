#!/bin/bash
set -euo pipefail

user_id="${LOCAL_USER_ID:-9001}"
grp_id="${LOCAL_GRP_ID:-9001}"

if [ "$user_id" != "0" ]; then
  export USERNAME=user
  export HOME=/home/"$USERNAME"
  getent group "$grp_id" &>/dev/null || groupadd -g "$grp_id" "$USERNAME"
  id -u "$USERNAME" &>/dev/null || useradd --shell /bin/bash -u "$user_id" -g "$grp_id" -o -c "" -m "$USERNAME"
  current_uid="$(id -u $USERNAME)"
  current_gid="$(id -g $USERNAME)"
  if [ "$user_id" != "$current_uid" ] || [ "$grp_id" != "$current_gid" ]; then
    echo -e "WARNING: User with differing UID $current_uid/GID $current_gid already exists, most likely this container was started before with a different UID/GID. Re-create it to change UID/GID.\n"
  fi
else
  export USERNAME=root
  export HOME=/root
  current_uid="$user_id"
  current_gid="$grp_id"
  echo -e "WARNING: Starting container processes as root. This has some security implications and goes against docker best practice.\n"
fi

find "$WORKDIR" -writable -print0 | xargs -0 -I{} -P64 -n1 chown -f "${current_uid}":"${current_gid}" "{}"
find "$VIRTUAL_ENV" -writable -print0 | xargs -0 -I{} -P64 -n1 chown -f "${current_uid}":"${current_gid}" "{}"

echo "Username: $USERNAME, HOME: $HOME, UID: $current_uid, GID: $current_gid"

gosu_cmd=""
[ "${current_uid}" -ne 0 ] && gosu_cmd="/usr/local/bin/gosu $USERNAME"
exec $gosu_cmd "$@"