#!/bin/bash

apt update -y && apt upgrade -y                                                           #makes the OS up-to-date

wget https://raw.githubusercontent.com/coooolk/datalogz-test/refs/heads/master/app.py     #download app.py

apt install -y python3 python3-pip python3-venv                                           # installed venv

python3 -m venv .venv                                                                     #created a venv
source .venv/bin/activate                                                                 #activated the venv

pip install Flask                                                                         #installed flask

nohup python3 app.py > flask.log 2>&1 &                                                   #running app.py in bg using nohup comamnd

echo "Flask app started in the background."