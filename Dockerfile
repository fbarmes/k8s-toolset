ARG UBUNTU_VERSION=22.04
FROM ubuntu:${UBUNTU_VERSION}


#-------------------------------------------------------------------------------
# Tools installation
#-------------------------------------------------------------------------------

# Setup tz info
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Paris


ENV \
  KUBECTL_VERSION=v1.25.3 \
  EKSCTL_VERSION=v0.117.0 \
  HELM_VERSION=v3.10.1


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
    wget &&\
  #
  # AWS cli (v2)
  cd /tmp &&\
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" &&\
  unzip awscliv2.zip &&\
  ./aws/install &&\
  rm -rf aws awscliv2.zip &&\
  #
  # kubectl
  echo $KUBECTL_VERSION &&\
  curl --location -o kubectl https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl &&\
  chmod 755 ./kubectl &&\
  mv kubectl /usr/local/bin &&\
  #
  # eksctl
  curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/$EKSCTL_VERSION/eksctl_Linux_amd64.tar.gz" | tar xz -C /tmp &&\
  mv /tmp/eksctl /usr/local/bin &&\
  #
  # helm
  wget https://get.helm.sh/helm-$HELM_VERSION-linux-amd64.tar.gz &&\
  tar -zxvf helm-$HELM_VERSION-linux-amd64.tar.gz &&\
  rm helm-$HELM_VERSION-linux-amd64.tar.gz &&\
  mv linux-amd64/helm /usr/local/bin/helm &&\
  #
  # clean apt
  apt-get -y clean &&\
  rm -rf /var/lib/apt/lists/* &&\
  #
  # add bash completion for the instaled tools
  mkdir /etc/bash_completion.d/ &&\
  kubectl completion bash >  /etc/bash_completion.d/kubectl_completion &&\
  eksctl completion bash  >  /etc/bash_completion.d/eksctl_completion &&\
  helm completion bash    > /etc/bash_completion.d/helm_completion &&\
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
  #
  # cleanup apt
  apt-get -y clean &&\
  rm -rf /var/lib/apt/lists/* &&\
  #
  true


#-------------------------------------------------------------------------------
# more tools
#-------------------------------------------------------------------------------
RUN set -eux &&\
  #
  # Update package repositories
  apt-get update &&\
  #
  # install tools
  apt-get install -y \
    iputils-ping \
    curl \
    dnsutils \
    iproute2 &&\
  #
  # cleanup apt
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

#-------------------------------------------------------------------------------
# Tools installation
#-------------------------------------------------------------------------------

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
