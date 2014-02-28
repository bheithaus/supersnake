#!/bin/sh

mkdir -p /home/vagrant/repos
cd /home/vagrant/repos && git clone https://github.com/bheithaus/supersnake.git 
cd supersnake
npm update && npm install
bower install --allow-root
