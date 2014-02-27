#~/bin/sh
echo 'create upstart for nginx, mongo, and bitisland-server' 

# nginx Upstart
cp /vagrant/confs/nginx.conf /etc/init/nginx.conf

# app specific Upstart
cp /vagrant/confs/bitisland.conf /etc/init/bitisland.conf

# create monit rc
# Echo create upstart mongodb
cp /vagrant/confs/mongodb.conf /etc/init/mongodb.conf

# copy monit setup
cp -f /vagrant/confs/monitrc /etc/monit/monitrc
