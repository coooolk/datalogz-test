#!/bin/bash
apt update -y && apt upgrade -y
git clone https://github.com/coooolk/datalogz-test.git
apt install -y python3 python3-pip
pip3 install Flask
cd datalogz-test
nohup python3 app.py &
echo "Flask app started in the background."