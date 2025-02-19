#!/bin/bash

apt update -y && apt upgrade -y                                                           #makes the OS up-to-date

wget https://raw.githubusercontent.com/coooolk/datalogz-test/refs/heads/master/app.py     #download app.py

apt install -y python3 python3-pip python3-venv                                           #install venv

python3 -m venv .venv                                                                     #create a venv
source .venv/bin/activate                                                                 #activat the venv

pip install Flask                                                                         #install flask

nohup python3 app.py > flask.log 2>&1 &                                                   #run app.py in bg using nohup comamnd

echo "Flask app started in the background."