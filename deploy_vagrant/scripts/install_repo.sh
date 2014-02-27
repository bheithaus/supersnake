#!/bin/sh

mkdir -p /home/vagrant/repos
cd /home/vagrant/repos && git clone https://github.com/bheithaus/bitisland-frontend.git 
cd bitisland-frontend
npm update && npm install
bower install --allow-root
