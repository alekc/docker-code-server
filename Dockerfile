FROM ghcr.io/linuxserver/baseimage-ubuntu:jammy

# set version label
ARG BUILD_DATE
ARG VERSION
ARG CODE_RELEASE
LABEL maintainer="alekc"

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"
ENV HOME="/config"

RUN \
  echo "**** install runtime dependencies ****" && \
  apt-get update && \
  apt-get install -y \
    git \
    jq \
    libatomic1 \
    nano \
    net-tools \
    netcat \
    build-essential \
    zsh \
    htop \
    wget \
    python3  \
    python3-pip \
    python3-venv \
    nodejs \
    npm \
    unzip \
    vim \
    sudo && \
  echo "**** install code-server ****" && \
  if [ -z ${CODE_RELEASE+x} ]; then \
    CODE_RELEASE=$(curl -sX GET https://api.github.com/repos/coder/code-server/releases/latest \
      | awk '/tag_name/{print $4;exit}' FS='[""]' | sed 's|^v||'); \
  fi && \
  mkdir -p /app/code-server && \
  curl -o \
    /tmp/code-server.tar.gz -L \
    "https://github.com/coder/code-server/releases/download/v${CODE_RELEASE}/code-server-${CODE_RELEASE}-linux-amd64.tar.gz" && \
  tar xf /tmp/code-server.tar.gz -C \
    /app/code-server --strip-components=1 && \
  echo "**** adding mods ****" && \
   echo "### Kubectl ###" && \
  cd /tmp && \
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
  install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
  echo "### AWS cli ###" && \
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
  unzip awscliv2.zip && \
  ./aws/install && \
  echo "### Helm ###" && \
  curl https://get.helm.sh/helm-v3.11.2-linux-amd64.tar.gz -o helm.tar.gz && \
  tar xzvf helm.tar.gz && \
  install -o root -g root -m 0755 linux-amd64/helm /usr/local/bin/helm && \
  echo "### checkov ###" && \
  pip3 install pre-commit checkov && \
  echo "### terraform-docs ###" && \
  curl -sSLo ./terraform-docs.tar.gz https://terraform-docs.io/dl/v0.16.0/terraform-docs-v0.16.0-$(uname)-amd64.tar.gz && \
  tar -xzf terraform-docs.tar.gz && \
  install -o root -g root -m 0755 terraform-docs /usr/local/bin/terraform-docs && \
  echo "### Tfsec ###" && \
  curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash && \
  echo "### Tflint ###" && \
  curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash && \
  echo "### OhMyZash ###" && \
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended && \
  echo "### Helm Docs ###" && \
  wget https://github.com/norwoodj/helm-docs/releases/download/v1.11.0/helm-docs_1.11.0_Linux_x86_64.deb && \
  dpkg -i helm-docs_1.11.0_Linux_x86_64.deb && \
  echo "### Terraform ###" && \
  wget https://releases.hashicorp.com/terraform/1.4.0/terraform_1.4.0_linux_amd64.zip && \
  unzip terraform_1.4.0_linux_amd64.zip && \ 
  install -o root -g root -m 0755 terraform /usr/local/bin/terraform && \
  echo "### Terraform-ls ###" && \
  wget https://releases.hashicorp.com/terraform-ls/0.30.3/terraform-ls_0.30.3_linux_amd64.zip && \
  unzip terraform-ls_0.30.3_linux_amd64.zip && \
  install -o root -g root -m 0755 terraform-ls /usr/local/bin/terraform-ls && \
  echo "### Npm ###" && \
  npm install -g npx prettier && \
  echo "### miniconda ###" && \
  wget https://repo.anaconda.com/miniconda/Miniconda3-py310_23.1.0-1-Linux-x86_64.sh && \
  bash Miniconda3-py310_23.1.0-1-Linux-x86_64.sh && \
  echo "**** clean up ****" && \
  apt-get clean && \
  rm -rf \
    /config/* \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*

# add local files
COPY /root /

# ports and volumes
EXPOSE 8443
