#!/bin/bash


#-------------------------------------------------------------------------------
# Set variables defaults
#-------------------------------------------------------------------------------
DOCKER_USER_NAME_DEFAULT=user
DOCKER_GROUP_NAME_DEFAULT=user

#-------------------------------------------------------------------------------
function echov() {
  if [[ ${DEBUG} == "true" ]] ; then
    echo "[DEBUG] ${@}"
  fi
}

#-------------------------------------------------------------------------------
function do_debug() {
  if [[ -z ${DOCKER_USER_ID} ]] ; then
    echov "DOCKER_USER_ID not defined"
  else
    echov "DOCKER_USER_ID defined as ${DOCKER_USER_ID}"
  fi

  if [[ -z ${DOCKER_GROUP_ID} ]] ; then
    echov "DOCKER_GROUP_ID not defined"
  else
    echov "DOCKER_GROUP_ID defined as ${DOCKER_GROUP_ID}"
  fi

  if [[ -z ${DOCKER_USER_NAME} ]] ; then
    echov "DOCKER_USER_NAME not defined"
  else
    echov "DOCKER_USER_NAME defined as ${DOCKER_USER_NAME}"
  fi

  if [[ -z ${DOCKER_GROUP_NAME} ]] ; then
    echov "DOCKER_GROUP_NAME not defined"
  else
    echov "DOCKER_GROUP_NAME defined as ${DOCKER_GROUP_NAME}"
  fi

}

#-------------------------------------------------------------------------------
function setup_user() {

  #-- Set variables defaults
  DOCKER_USER_NAME=${DOCKER_USER_NAME:-${DOCKER_USER_NAME_DEFAULT}}
  DOCKER_GROUP_NAME=${DOCKER_GROUP_NAME:-${DOCKER_GROUP_NAME_DEFAULT}}


  echov "Create user [${DOCKER_USER_NAME}], group [${DOCKER_GROUP_NAME}] with uid=[${DOCKER_USER_ID}], gid=[${DOCKER_GROUP_ID}]"

  #-- Create group
  groupadd --gid ${DOCKER_GROUP_ID} ${DOCKER_GROUP_NAME}

  #--  check if home already exists
  if [[ -d /home/${DOCKER_USER_NAME} ]] ; then
    cp -r /etc/skel/. /home/${DOCKER_USER_NAME}
  fi

  #--  Create user
  useradd \
    --shell /bin/bash \
    --uid $DOCKER_USER_ID \
    --gid $DOCKER_GROUP_ID \
    --non-unique \
    --comment ""  \
    --create-home \
    ${DOCKER_USER_NAME}

  #-- setup home
  export HOME=/home/${DOCKER_USER_NAME}

  #-- give rights to home
  chown ${DOCKER_USER_ID}:${DOCKER_GROUP_ID} ${HOME}

  #-- make user sudoer passwordless
  usermod -aG sudo ${DOCKER_USER_NAME}
  echo "${DOCKER_USER_NAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/sudoer_passwordless

}
#-------------------------------------------------------------------------------
function setup_shell() {
  echo "[INFO] setup shell"


  cat <<EOF >> ${HOME}/.bashrc
alias k=kubectl
alias kget="kubectl get -o wide"
complete -o default -F __start_kubectl k

function k-merge-configs() {
  old=" \$IFS"; IFS=':'; merged="\$*"; IFS=\$old
  echo \$merged

  if [[ -f \${HOME}/.kube/config ]] ; then
    cp \${HOME}/.kube/config \${HOME}/.kube/config.bak
  fi
  KUBECONFIG="\$merged" kubectl config view --flatten > \${HOME}/.kube/config
}


EOF

}



#-------------------------------------------------------------------------------
function main() {

  #-------------------------------------------------------------------------------
  # Debug
  #-------------------------------------------------------------------------------
  do_debug

  #-------------------------------------------------------------------------------
  # Check all parameters
  #-------------------------------------------------------------------------------
  if [[ ! -z ${DOCKER_USER_ID} ]] && [[ ! -z ${DOCKER_GROUP_ID}  ]] ; then
    # run CMD as gosu user
    echov "-> run as user"
    setup_user

    cd ${HOME}
    setup_shell

    exec /usr/local/bin/gosu ${DOCKER_USER_NAME} $@
  else
    # run CMD as root
    echov "-> run as root"

    cd ${HOME}
    setup_shell

    exec $@
  fi


}


#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
main $@
