#!/bin/bash
apt update -y && apt upgrade -y
git clone https://github.com/coooolk/datalogz-test.git
apt install -y python3 python3-pip
cd datalogz-test
python3 -m venv .venv
source .venv/bin/activate
pip install Flask
nohup python3 app.py > flask.log 2>&1 &
echo "Flask app started in the background."