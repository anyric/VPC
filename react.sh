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

installNodjs(){
  sudo apt-get install -y curl
  curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
  sudo apt-get install -y nodejs
  sudo apt-get install -y build-essential
  sudo npm install -g create-react-app
}

installNginx(){
    printf "*********************Installing Nginx******************************* \n"
    sudo apt-get install -y nginx nginx-extras 
}


cloneRepo(){
    printf "*******************Cloning git Repo******************* \n"
    git clone https://github.com/anyric/Yummy-Recipes-Reactjs.git
}

setupProjectDependancies(){
    printf "*******************Installing requirements.txt************* \n"
    cd Yummy-Recipes-Reactjs
    sudo npm install
}

configureNginx(){
    printf "******************Configuring Nginx*********************** \n"
    sudo systemctl start nginx
    sudo rm -rf /etc/nginx/sites-available/yummy /etc/nginx/sites-enabled/yummy
    sudo bash -c 'cat <<EOF> /etc/nginx/sites-available/yummy
server {
        listen 80;
        location / {
          proxy_pass http://127.0.0.1:3000;
          proxy_http_version 1.1;
          proxy_set_header Upgrade \$http_upgrade;
          proxy_set_header Connection "upgrade";
          proxy_set_header Host \$host;
          proxy_cache_bypass \$http_upgrade;
          proxy_redirect off;
        }
}
EOF'
    sudo rm -rf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
    sudo ln -s /etc/nginx/sites-available/yummy /etc/nginx/sites-enabled/
    sudo ufw allow 'Nginx Full'
    sudo systemctl restart nginx
}

setupYummy(){
    printf "***********************Setting yummy exec*************** \n"
    sudo bash -c 'cat <<EOF> /home/ubuntu/VPC/Yummy-Recipes-Reactjs/yummy.sh
#!/bin/bash

cd /home/ubuntu/VPC/Yummy-Recipes-Reactjs
npm start
EOF'

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
ExecStart=/bin/bash /home/ubuntu/VPC/Yummy-Recipes-Reactjs/yummy.sh

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
    installNodjs
    installNginx
    cloneRepo
    setupProjectDependancies
    setupHostIP
    configureNginx
    setupYummy
    configureSystemd
    startApp
}

run
