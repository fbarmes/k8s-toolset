ARG UBUNTU_VERSION=20.04
FROM ubuntu:${UBUNTU_VERSION}



#-------------------------------------------------------------------------------
# Tools installation
#-------------------------------------------------------------------------------

RUN \
  #
  # update package repositories
  apt-get update &&\
  apt-get install -y curl unzip &&\
  #
  # aws cli (v2)
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
  # show versions
  echo "== aws cli version"  &&\
  aws --version &&\
  echo "== kubectl version"  &&\
  kubectl version --short --client &&\
  echo "== eksctl version"  &&\
  eksctl version &&\
  echo "== help version"  &&\
  helm version &&\
  true


#--
ENV AWS_ACCESS_KEY_ID ""
ENV AWS_SECRET_ACCESS_KEY ""
ENV AWS_DEFAULT_REGION "eu-west-1"
