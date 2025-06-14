#!/bin/bash

set -e

PYTHON_VERSION="3.9.6"

# Install system dependencies
sudo apt update && sudo apt install -y \
  make build-essential libssl-dev zlib1g-dev \
  libbz2-dev libreadline-dev libsqlite3-dev curl \
  libncursesw5-dev xz-utils tk-dev libxml2-dev \
  libxmlsec1-dev libffi-dev liblzma-dev git

# Install pyenv for ubuntu user
curl https://pyenv.run | bash

# Set pyenv env
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# Install Python via pyenv
pyenv install -s $PYTHON_VERSION
pyenv global $PYTHON_VERSION

# ✅ Verify Python was installed
PYENV_PYTHON_PATH="$PYENV_ROOT/versions/$PYTHON_VERSION/bin/python"
if [ ! -x "$PYENV_PYTHON_PATH" ]; then
  echo "❌ Python $PYTHON_VERSION not installed at $PYENV_PYTHON_PATH"
  exit 1
fi

echo "✅ Python installed: $($PYENV_PYTHON_PATH --version)"

# Upgrade pip
pip install --upgrade pip setuptools
