#!/bin/bash

apt update -y && apt upgrade -y                        #makes the OS up-to-date

git clone https://github.com/coooolk/datalogz-test.git #cloned git repo

apt install -y python3 python3-pip python3-venv        # installed venv

cd datalogz-test                                       #changed directory to git repo

python3 -m venv .venv                                  #created a venv
source .venv/bin/activate                              #activated the venv

pip install Flask                                      #installed flask

nohup python3 app.py > flask.log 2>&1 &                #running app.py in bg using nohup comamnd

echo "Flask app started in the background."