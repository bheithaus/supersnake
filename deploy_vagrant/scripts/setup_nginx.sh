#!/bin/sh

# create nginx sites-available
# link sites-enabled
cp /vagrant/confs/nginx_supersnake /etc/nginx/sites-available/supersnake
ln -s /etc/nginx/sites-available/supersnake /etc/nginx/sites-enabled/supersnake

rm /etc/nginx/sites-enabled/default

