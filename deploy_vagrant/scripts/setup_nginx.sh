#!/bin/sh

# create nginx sites-available
# link sites-enabled
cp /vagrant/confs/nginx_bitisland /etc/nginx/sites-available/bitisland
ln -s /etc/nginx/sites-available/bitisland /etc/nginx/sites-enabled/bitisland

rm /etc/nginx/sites-enabled/default

