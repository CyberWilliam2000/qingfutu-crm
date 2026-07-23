#!/bin/bash
# 修复 Nginx 配置

sudo tee /etc/nginx/sites-available/qingfutu > /dev/null <<'EOF'
server {
    listen 80;
    server_name supersystem.beneblue.co;

    auth_basic "青蓝图客户追踪看板";
    auth_basic_user_file /etc/nginx/.htpasswd-qingfutu;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/qingfutu /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl status nginx
