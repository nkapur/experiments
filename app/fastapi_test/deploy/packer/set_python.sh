#!/bin/bash

set -e

PYTHON_VERSION="3.9.6"

# Install system dependencies required for pyenv, Python builds, and Git
apt update && apt install -y \
  make build-essential libssl-dev zlib1g-dev \
  libbz2-dev libreadline-dev libsqlite3-dev curl \
  libncursesw5-dev xz-utils tk-dev libxml2-dev \
  libxmlsec1-dev libffi-dev liblzma-dev

# Install pyenv
curl https://pyenv.run | bash

# Set pyenv environment for this script
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# Install specific Python version
pyenv install -s $PYTHON_VERSION
pyenv global $PYTHON_VERSION

# Verify Python version
python --version

# Upgrade pip for that version
pip install --upgrade pip setuptools