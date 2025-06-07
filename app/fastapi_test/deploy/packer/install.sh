#!/bin/bash

set -e

###################################################
##### BOILERPLATE FOR ANY APP in MONOREPO #########
###################################################

APP_NAME="fastapi_test"
SCRIPT_PATH=$0
SCRIPT_DIR=$(dirname "$0")

# Install Python Environment using pyenv
source $SCRIPT_DIR/set_python.sh
PYTHON_VERSION=$(python --version | awk '{print $2}')

# Clone the FastAPI test repository
MONOREPO_PATH="/opt/experiments"
rm -rf $MONOREPO_PATH
# git clone https://github.com/nkapur/experiments.git $MONOREPO_PATH
### TEST ONLY ###
cp -r $SCRIPT_DIR/../../../../../experiments $MONOREPO_PATH


APP_PATH="$MONOREPO_PATH/app/$APP_NAME"
if [ -d "$APP_PATH" ]; then
  echo "FastAPI test application found at $APP_PATH"
else
  echo "FastAPI test application not found at $APP_PATH"
  exit 1
fi

pip install -r $APP_PATH/requirements.txt

###################################################
##### END BOILERPLATE FOR ANY APP in MONOREPO #####
###################################################


# For FastAPI Apps, create systemd service to run FastAPI using gunicorn from pyenv-installed Python
cat <<EOF > /etc/systemd/system/$APP_NAME.service
[Unit]
Description=FastAPI Test App
After=network.target

[Service]
User=root
WorkingDirectory=$APP_PATH
ExecStart=/root/.pyenv/versions/$PYTHON_VERSION/bin/gunicorn -w 4 -k uvicorn.workers.UvicornWorker main:src --bind 0.0.0.0:80
Restart=always
Environment=PATH=/root/.pyenv/versions/$PYTHON_VERSION/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

[Install]
WantedBy=multi-user.target
EOF

# Enable service on boot
systemctl enable $APP_NAME