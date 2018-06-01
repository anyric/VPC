#!/bin/bash

updateServer(){
    printf '***********************Updating OS********************** \n'
    sudo apt-get update
}

exportLang() {
    printf '***********************Exporting LANG******************* \n'
    export LANG="en_US.UTF-8"
    export LC_ALL="en_US.UTF-8"
    export LC_CTYPE="en_US.UTF-8"
}

installPython(){
    printf '**********************Installing Python 3.6 and dependancies***************** \n'
    sudo add-apt-repository ppa:deadsnakes/ppa
    sudo apt-get update
    sudo apt-get install -y python3.6 python3-pip nginx python3.6-gdbm
    sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.5 1
    sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.6 10
    sudo update-alternatives --config python3
    
    sudo apt install -y virtualenv
    virtualenv -p python3 venv
}

installNginxGunicorn(){
    printf "*********************Installing Nginx******************************* \n"
    sudo apt-get install -y nginx nginx-extras gunicorn
}


cloneRepo(){
    printf "*******************Cloning git Repo******************* \n"
    git clone https://github.com/anyric/Yummy-Recipes-Api.git
}

setupProjectDependancies(){
  printf "*******************Installing requirements.txt************* \n"
  source venv/bin/activate
  cd Yummy-Recipes-Api
  sudo pip3 install -r requirements.txt
  deactivate
}

setupHostIP(){
    printf "****************Configuring Host Ip Address***************** \n"

    sudo rm -rf app.py
    sudo bash -c 'cat <<EOF> ./app.py
from apps import app

if __name__ == "__main__":
    app.run(host="0.0.0.0", threaded=True)
EOF'
}

configureNginx(){
    printf "******************Configuring Nginx*********************** \n"
    sudo systemctl start nginx
    sudo rm -rf /etc/nginx/sites-available/yummy /etc/nginx/sites-enabled/yummy
    sudo bash -c 'cat <<EOF> /etc/nginx/sites-available/yummy
server {
        listen 80;
        location / {
            proxy_pass http://127.0.0.1:5000/;
            proxy_set_header Host \$host;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        }
}
EOF'
    sudo rm -rf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
    sudo ln -s /etc/nginx/sites-available/yummy /etc/nginx/sites-enabled/
    sudo ufw allow 'Nginx Full'
    sudo systemctl restart nginx
}

configureSSH(){
    printf "********************Configuring SSH****************** \n"
    sudo add-apt-repository ppa:certbot/certbot
    sudo apt-get update
    sudo apt-get install -y python-certbot-nginx
    sudo certbot --nginx 
}

setupYummy(){
    printf "***********************Setting yummy exec*************** \n"
    sudo bash -c 'cat <<EOF> /home/ubuntu/VPC/Yummy-Recipes-Api/yummy.sh
#!/bin/bash

cd /home/ubuntu/VPC
source venv/bin/activate
sudo pip install flask
cd Yummy-Recipes-Api
gunicorn --workers 4 --bind 0.0.0.0:5000 app:app

EOF'

    export DATABASE_URL="postgres://anyric:anyric1234@yummy.cztrtf3jyreo.us-east-2.rds.amazonaws.com:5432/yummy_api"
}
configureSystemd(){
    printf "***********************Configuring Systemd*************** \n"
    sudo rm -rf /etc/systemd/system/yummy.service
    sudo bash -c 'cat <<EOF> /etc/systemd/system/yummy.service
[Unit]
Description=Gunicorn instance to serve yummy recipe
After=network.target

[Service]
User=ubuntu
ExecStart=/bin/bash /home/ubuntu/VPC/Yummy-Recipes-Api/yummy.sh

[Install]
WantedBy=multi-user.target

EOF'
}

startApp(){
    printf "*******************Starting App*************************** \n"
    sudo chmod 755 /etc/systemd/system/yummy.service
    sudo systemctl daemon-reload
    sudo systemctl enable yummy
    sudo systemctl start yummy
    
}
run(){
    updateServer
    exportLang
    setupVirtualenv
    installPython
    installNginxGunicorn
    cloneRepo
    setupProjectDependancies
    setupHostIP
    configureNginx
    configureSSH
    setupYummy
    configureSystemd
    startApp
}

run
