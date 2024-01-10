# install nginx
apt install nginx -y
# install certbot
apt install certbot -y
# (Possibly do this)
apt install python3-certbot-nginx
# open port 80 for certbot
# IN NETWORK SECURITY GROUP
# run certbort for www api and arms-tracker.app
certbot certonly --nginx -d arms-tracker.app -d www.arms-tracker.app -d api.arms-tracker.app
# close port 80
# Copy config in /etc/nginx/sites-enabled/default
#start nginx