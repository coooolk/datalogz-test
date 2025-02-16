#!/bin/bash

apt update -y && apt upgrade -y #makes the OS up-to-date

git clone https://github.com/coooolk/datalogz-test.git #clone


apt install -y python3 python3-pip python3-venv
cd datalogz-test
python3 -m venv .venv
source .venv/bin/activate
pip install Flask
nohup python3 app.py > flask.log 2>&1 &
echo "Flask app started in the background."