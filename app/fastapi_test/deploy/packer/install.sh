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
# Clone or copy monorepo to user-writable location
MONOREPO_PATH="$HOME/experiments"
rm -rf $MONOREPO_PATH
cp -r $SCRIPT_DIR/../../../../../experiments $MONOREPO_PATH

APP_PATH="$MONOREPO_PATH/app/$APP_NAME"
if [ ! -d "$APP_PATH" ]; then
  echo "❌ App path $APP_PATH not found"
  exit 1
fi

pip install -r "$APP_PATH/requirements.txt"
if [ $? -ne 0 ]; then
  echo "❌ Failed to install requirements for $APP_NAME"
  exit 1
fi

###################################################
##### END BOILERPLATE FOR ANY APP in MONOREPO #####
###################################################

# Get gunicorn path
GUNICORN_PATH="$(pyenv which gunicorn)"
if [ ! -x "$GUNICORN_PATH" ]; then
  echo "❌ gunicorn not installed in pyenv environment"
  exit 1
fi

# Write systemd unit file
SERVICE_FILE="/etc/systemd/system/$APP_NAME.service"
sudo tee $SERVICE_FILE > /dev/null <<EOF
[Unit]
Description=FastAPI Test App
After=network.target

[Service]
User=ubuntu
WorkingDirectory=$APP_PATH
ExecStart=$GUNICORN_PATH -w 4 -k uvicorn.workers.UvicornWorker src.main:app --bind 0.0.0.0:8000
Restart=always
Environment=PATH=$PYENV_ROOT/versions/$PYTHON_VERSION/bin:/usr/bin:/bin

[Install]
WantedBy=multi-user.target
EOF

# Enable service
sudo systemctl enable $APP_NAME