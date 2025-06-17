#!/bin/bash

# This file contains instructions for local development on a new Mac with
# the goal to simplify future developer or laptop onboarding.

### Base Dev Setup ###

 xcode-select --install
 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"


### Python Setup ###

PYTHON_VERSION="3.9.6"
brew install pyenv

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# Install specific Python version
pyenv install -s $PYTHON_VERSION
pyenv global $PYTHON_VERSION
python --version
pip install --upgrade pip setuptools
pip install virtualenv

# Create a virtual environment for the current project
if [ ! -d ".venv" ]; then
  virtualenv .venv
  echo "Virtual environment created at .venv"
else
  echo "Virtual environment already exists at .venv"
fi
pip install -r requirements.txt


### Cloud CLI Setup ###

brew tap hashicorp/tap
brew install hashicorp/tap/packer
brew install hashicorp/tap/terraform

brew install awscli
brew tap databricks/tap
brew install databricks


### Kube Setup ###
brew install kubectl
brew install minikube

# Install Kube convert for version management
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/arm64/kubectl-convert"\n
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/arm64/kubectl-convert.sha256"\n
 echo "$(cat kubectl-convert.sha256)  kubectl-convert" | shasum -a 256 --check\n

### .zshrc Setup ###
echo <<EOF > ~/.zshrc
autoload -Uz compinit
compinit

eval "$(/opt/homebrew/bin/brew shellenv)"

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"

alias va="source .venv/bin/activate"
alias vd="deactivate"

export PATH="$HOME/bin:$PATH"
source <(kubectl completion zsh)
EOF
source ~/.zshrc


### Install Additional Tools ###
echo "Base, Python, Cloud CLI and .zshrc setup complete. Please configure your clients with providers like Git, AWS, Databricks etc."

echo "OPTIONAL: To test Github workflows locally, 
    1. download and setup Docker Desktop for Mac per instructions here - https://docs.docker.com/desktop/setup/install/mac-install/.
    2. Run `curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash`
    3. Run `act -l` to list available workflows and `act <workflow_name>` to run a specific workflow."
