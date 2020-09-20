#!/bin/bash


# arg1 (mandatory) : <uid:[gid]> => wanted user/group ids
# arg2 (mandatory) : name => wanted user name
# return : user_uid:group_gid:user_name:group_name
setup_service_user() {
  wanted_user="$1"
  default_name="$2"

  user_uid=
  group_gid=

  [ -n "$wanted_user" ] && echo "$wanted_user" | grep -q ':' && {
      group_gid="$(echo $wanted_user | cut -d: -f2)"
      user_uid="$(echo $wanted_user | cut -d: -f1)"
  } || user_uid=$wanted_user


  [[ $user_uid =~ ^[0-9]+$ ]] || return
  if [ -n "$group_gid" ]; then
     [[ $group_gid =~ ^[0-9]+$ ]] || return
  fi


  # default group name already in used
  if [ -z "$(getent group ${default_name} | cut -d: -f1)" ]; then
    default_group_name=${default_name}
  else
    # NOTE : we add user_uid instead of group_gid because group_gid can be empty
    default_group_name="${default_name}_${user_uid}"
  fi


  # we did sepify a group
  if [ -n "$group_gid" ]; then
    original_group_name=$(getent group $group_gid | cut -d: -f1)
    # the group do not exist
    if [ -z "$original_group_name" ]; then
      group_name=${default_group_name}
      # create a group with a given id and a default name
      type groupadd &>/dev/null && \
        groupadd -f -g $group_gid ${group_name} || \
        addgroup -g $group_gid ${group_name}
    else
      group_name=${original_group_name}
    fi
  fi


  # default user name already in used
  if [ -z "$(getent passwd ${default_name} | cut -d: -f1)" ]; then
    default_user_name=${default_name}
  else
    default_user_name="${default_name}_${user_uid}"
  fi

  original_user_name=$(getent passwd $user_uid | cut -d: -f1)

  # this user do not exist
  if [ -z "$original_user_name" ]; then
    user_name=${default_user_name}
     # we did not sepify a group
    if [ -z "$group_gid" ]; then
      # create a user with a given id and a default name, attached to a default created group
      type useradd &>/dev/null && \
        useradd -M -d /home/${user_name} -s /bin/bash -U -u $user_uid ${user_name} || \
        adduser -H -h /home/${user_name} -D -s /bin/bash -u $user_uid ${user_name}

        group_gid=$(getent passwd $user_uid | cut -d: -f4)
        group_name=$(getent group $group_gid | cut -d: -f1)
    else
      # create a user with a given id and a default name, attached to the wanted group
      type useradd &>/dev/null && \
        useradd -M -d /home/${user_name} -s /bin/bash -N -g $group_gid -u $user_uid ${user_name} || \
        adduser -H -h /home/${user_name} -D -s /bin/bash -G $group_name -u $user_uid ${user_name}
    fi
  else
    user_name=${original_user_name}
    group_gid=$(getent passwd $user_name | cut -d: -f4)
    group_name=$(getent group $group_gid | cut -d: -f1)
  fi


  mkdir -p /home/${user_name}
  chown -R ${user_uid}:${group_gid} /home/${user_name}

  echo ${user_uid}:${group_gid}:${user_name}:${group_name}
}



# when running default docker CMD
if [ "$1" = "supervisord" ]; then

  . activate ${CONDA_ENV}

  user_info="$(setup_service_user ${SERVICE_USER} ${SERVICE_NAME})"

  SERVICE_USER_UID="$(echo $user_info | cut -d: -f1)"
  SERVICE_GROUP_GID="$(echo $user_info | cut -d: -f2)"
  SERVICE_USER_NAME="$(echo $user_info | cut -d: -f3)"
  SERVICE_GROUP_NAME="$(echo $user_info | cut -d: -f4)"

  # export env var to make them available in supervisor context
  export PATH="${PATH}"
  # supervisor user
  export SERVICE_USER_NAME="${SERVICE_USER_NAME}"
  # service name
  export SERVICE_NAME="${SERVICE_NAME}"
  # export specific arg for service
  for a in ${SERVICE_EXPORT_ARG}; do
    export ${a}="${!a}"
  done

  # change service folder ownership
  chown -R ${SERVICE_USER_NAME}:${SERVICE_GROUP_NAME} ${SERVICE_INSTALL_DIR}

  # volume path
  # if not exist, create path using service user name
  for p in ${SERVICE_VOLUME_PATH}; do
    su "${SERVICE_USER_NAME}" -c "mkdir -p ${p}"
  done

  echo "** Run service as user: $SERVICE_USER_NAME ($SERVICE_USER_UID) group: $SERVICE_GROUP_NAME ($SERVICE_GROUP_GID) **"
fi

exec "$@"
