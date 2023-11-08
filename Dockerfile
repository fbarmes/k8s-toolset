ARG UBUNTU_VERSION=22.04
FROM ubuntu:${UBUNTU_VERSION}


#-------------------------------------------------------------------------------
# Tools installation
#-------------------------------------------------------------------------------

# Setup tz info
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Paris


ENV \
  KUBECTL_VERSION=v1.27.3 \
  EKSCTL_VERSION=v0.149.0 \
  HELM_VERSION=v3.13.1 \
  RKE_VERSION=v1.4.7

#-------------------------------------------------------------------------------
# System packages
#-------------------------------------------------------------------------------
RUN set -eux &&\
  #
  # Update package repositories
  apt-get update &&\
  #
  # Setup tzdata, basic tools
  apt-get install -y \
    vim \
    tzdata \
    curl \
    unzip \
    jq \
    gettext \
    bash-completion \
    moreutils \
    make \
    wget \
    iputils-ping \
    dnsutils \
    iproute2 &&\
  #
  mkdir /etc/bash_completion.d/ &&\
  #
  # clean apt
  apt-get -y clean &&\
  rm -rf /var/lib/apt/lists/* &&\
  #
  true


#-------------------------------------------------------------------------------
# AWS
#-------------------------------------------------------------------------------
RUN set -eux &&\
  #
  # install AWS cli (v2)
  cd /tmp &&\
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" &&\
  unzip awscliv2.zip &&\
  ./aws/install &&\
  rm -rf aws awscliv2.zip &&\
  #
  true

RUN set -eux &&\
  #
  # install eksctl
  curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/$EKSCTL_VERSION/eksctl_Linux_amd64.tar.gz" | tar xz -C /tmp &&\
  mv /tmp/eksctl /usr/local/bin &&\
  #
  # bash completion
  eksctl completion bash  >  /etc/bash_completion.d/eksctl_completion &&\
  #
  true

#-------------------------------------------------------------------------------
# kubectl and helm
#-------------------------------------------------------------------------------

RUN set -eux &&\
  #
  # install kubectl
  #
  echo $KUBECTL_VERSION &&\
  curl --location -o kubectl https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl &&\
  chmod 755 ./kubectl &&\
  mv kubectl /usr/local/bin &&\
  #
  # bash completion
  kubectl completion bash >  /etc/bash_completion.d/kubectl_completion &&\
  #
  true


RUN set -eux &&\
  #
  # install helm
  #
  wget https://get.helm.sh/helm-$HELM_VERSION-linux-amd64.tar.gz &&\
  tar -zxvf helm-$HELM_VERSION-linux-amd64.tar.gz &&\
  rm helm-$HELM_VERSION-linux-amd64.tar.gz &&\
  mv linux-amd64/helm /usr/local/bin/helm &&\
  #
  # bash completion
  helm completion bash    > /etc/bash_completion.d/helm_completion &&\
  #
  true


#-------------------------------------------------------------------------------
# rke
# https://github.com/rancher/rke/releases/download/v1.4.1/rke_linux-amd64
#-------------------------------------------------------------------------------
RUN set -eux &&\
  #
  # install rke
  #
  curl --location -o /usr/local/bin/rke https://github.com/rancher/rke/releases/download/$RKE_VERSION/rke_linux-amd64 &&\
  chmod 755 /usr/local/bin/rke &&\
  #
  true

#-------------------------------------------------------------------------------
# Terraform
#-------------------------------------------------------------------------------
ENV TERRAFORM_VERSION=1.6.3-1

RUN set -eux &&\
  apt-get update &&\
  apt-get install -y \
    gpg \
    lsb-release &&\
  #
  # terraform
  curl -s -o /tmp/hashicorp.gpg https://apt.releases.hashicorp.com/gpg  &&\
  gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg /tmp/hashicorp.gpg  &&\
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list &&\
  apt-get update &&\
  apt-get install -y \
    terraform=${TERRAFORM_VERSION} &&\
  #
  # clean apt
  apt-get -y clean &&\
  rm -rf /var/lib/apt/lists/* &&\
  #
  true

#-------------------------------------------------------------------------------
# Python, Ansible and requirements
#-------------------------------------------------------------------------------

COPY ansible-python-requirements.txt /tmp/ansible-python-requirements.txt

RUN set -eux &&\
  #
  # update apt
  apt-get update &&\ 
  #
  # python and pip
  apt-get install -y \
    python3 \
    python3-pip &&\
  #
  # upgrade pip
  pip install --upgrade pip &&\
  #
  # Ansible and python requirements
  pip install -r /tmp/ansible-python-requirements.txt &&\
  #
  # clean apt
  apt-get -y clean &&\
  rm -rf /var/lib/apt/lists/* &&\
  #
  true

#-------------------------------------------------------------------------------
# postinstal setup
#-------------------------------------------------------------------------------
RUN set -eux &&\
  #
  # add bash completion for the instaled tools
  echo "source /etc/profile.d/bash_completion.sh" >> ~/.bashrc &&\
  echo "source /etc/profile.d/bash_completion.sh" >> /etc/skel/.bashrc &&\
  #
  # show versions
  echo "== aws cli version"  &&\
  aws --version &&\
  echo "== kubectl version"  &&\
  kubectl version --output=yaml --client &&\
  echo "== eksctl version"  &&\
  eksctl version &&\
  echo "== help version"  &&\
  helm version &&\
  echo "== rke version" &&\
  rke --version &&\
  echo "== terraform version" &&\
  terraform -version &&\
  #
  true

#-------------------------------------------------------------------------------
# sudo
#-------------------------------------------------------------------------------
RUN set -eux &&\
  #
  # update apt
  apt-get update &&\ 
  #
  # python and pip
  apt-get install -y \
    sudo &&\
  # clean apt
  apt-get -y clean &&\
  rm -rf /var/lib/apt/lists/* &&\
  #
  true

#-------------------------------------------------------------------------------
# gosu
#-------------------------------------------------------------------------------
ENV GOSU_VERSION 1.11


RUN \
  set -x &&\
  curl --silent --show-error --location --output /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" &&\
  curl --silent --show-error --location --output /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" &&\
  chmod +x /usr/local/bin/gosu &&\
  true

#--
ENV \
  AWS_ACCESS_KEY_ID="" \
  AWS_SECRET_ACCESS_KEY="" \
  AWS_DEFAULT_REGION="eu-west-1" \
  DOCKER_USER_ID="" \
  DOCKER_GROUP_ID="" \
  DOCKER_USER_NAME="" \
  DOCKER_GROUP_NAME=""


#-------------------------------------------------------------------------------
# entrypoint
#-------------------------------------------------------------------------------
COPY ["docker-entrypoint.sh", "/usr/bin/"]
RUN chmod 755 /usr/bin/docker-entrypoint.sh
ENTRYPOINT ["/usr/bin/docker-entrypoint.sh"]
CMD ["/bin/bash"]
