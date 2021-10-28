ARG UBUNTU_VERSION=20.04
FROM ubuntu:${UBUNTU_VERSION}


#-------------------------------------------------------------------------------
# Tools installation
#-------------------------------------------------------------------------------

# Setup tz info
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Paris


RUN \
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
    make &&\
  #
  # AWS cli (v2)
  cd /tmp &&\
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" &&\
  unzip awscliv2.zip &&\
  ./aws/install &&\
  rm -rf aws awscliv2.zip &&\
  #
  # kubectl
  curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.21.2/2021-07-05/bin/linux/amd64/kubectl &&\
  chmod 755 ./kubectl &&\
  mv kubectl /usr/local/bin &&\
  #
  # eksctl
  curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp &&\
  mv /tmp/eksctl /usr/local/bin &&\
  #
  # helm
  apt-get install -y wget &&\
  wget https://get.helm.sh/helm-v3.7.0-linux-amd64.tar.gz &&\
  tar -zxvf helm-v3.7.0-linux-amd64.tar.gz &&\
  rm helm-v3.7.0-linux-amd64.tar.gz &&\
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
  kubectl version --short --client &&\
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
# gosu
#-------------------------------------------------------------------------------
ENV GOSU_VERSION 1.11


RUN \
  set -x &&\
  curl --silent --show-error --location --output /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" &&\
  curl --silent --show-error --location --output /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" &&\
  chmod +x /usr/local/bin/gosu &&\
  true
  # && export GNUPGHOME="$(mktemp -d)" \
  # && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
  # && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
  # && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
  # && chmod +x /usr/local/bin/gosu \
  # && gosu nobody true

#-------------------------------------------------------------------------------
# Tools installation
#-------------------------------------------------------------------------------
#--
#ENV LBC_VERSION "v2.2.0"


#--
ENV AWS_ACCESS_KEY_ID ""
ENV AWS_SECRET_ACCESS_KEY ""
ENV AWS_DEFAULT_REGION "eu-west-1"

ENV DOCKER_USER_ID=""
ENV DOCKER_GROUP_ID=""
ENV DOCKER_USER_NAME=""
ENV DOCKER_GROUP_NAME=""


#-------------------------------------------------------------------------------
# entrypoint
#-------------------------------------------------------------------------------
COPY ["docker-entrypoint.sh", "/usr/bin/"]
RUN chmod 755 /usr/bin/docker-entrypoint.sh
ENTRYPOINT ["/usr/bin/docker-entrypoint.sh"]
CMD ["/bin/bash"]
