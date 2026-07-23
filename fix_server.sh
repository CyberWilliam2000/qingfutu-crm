#!/bin/bash
# ==========================================
# 青蓝图客户追踪看板 · 服务器一键修复脚本
# 在腾讯云 VNC 控制台中执行
# ==========================================

set -e

echo "🔧 开始修复服务器..."

# 1. 创建 Nginx 可访问的目录
echo "📁 创建 /var/www/qingfutu..."
mkdir -p /var/www/qingfutu

# 2. 复制文件到新位置
echo "📋 复制文件..."
cp -f /home/ubuntu/qingfutu/客户追踪看板.html /var/www/qingfutu/index.html 2>/dev/null || echo "⚠️ 源 HTML 不存在，跳过"
cp -f /home/ubuntu/qingfutu/api_server.py /var/www/qingfutu/ 2>/dev/null || echo "⚠️ 源 api_server.py 不存在，跳过"
cp -f /home/ubuntu/qingfutu/客户追踪看板.xlsx /var/www/qingfutu/ 2>/dev/null || echo "⚠️ 源 Excel 不存在，跳过"

# 3. 修改 api_server.py 中的路径
sed -i 's|/home/ubuntu/qingfutu/客户追踪看板.xlsx|/var/www/qingfutu/客户追踪看板.xlsx|g' /var/www/qingfutu/api_server.py
sed -i 's|/home/ubuntu/qingfutu/客户追踪看板.html|/var/www/qingfutu/客户追踪看板.html|g' /var/www/qingfutu/api_server.py

# 4. 设置权限
echo "🔐 设置权限..."
chown -R www-data:www-data /var/www/qingfutu/
chmod 755 /var/www/qingfutu/
chmod 644 /var/www/qingfutu/*

# 5. 安装依赖
echo "📦 安装 Python 依赖..."
pip3 install flask flask-cors openpyxl gunicorn 2>/dev/null || python3 -m pip install flask flask-cors openpyxl gunicorn

# 6. 更新 Nginx 配置
echo "⚙️ 配置 Nginx..."
cat > /etc/nginx/sites-available/qingfutu <<'NGINX_EOF'
server {
    listen 80 default_server;
    server_name supersystem.beneblue.co 81.70.202.143 _;

    auth_basic "青蓝图 CRM";
    auth_basic_user_file /etc/nginx/.htpasswd;

    location = / {
        root /var/www/qingfutu;
        index index.html;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
NGINX_EOF

# 7. 确保 htpasswd 存在
if [ ! -f /etc/nginx/.htpasswd ]; then
    echo "🔑 创建 htpasswd..."
    apt-get install -y apache2-utils 2>/dev/null
    htpasswd -cb /etc/nginx/.htpasswd admin qingfutu2024
fi

# 8. 启用站点
ln -sf /etc/nginx/sites-available/qingfutu /etc/nginx/sites-enabled/qingfutu
rm -f /etc/nginx/sites-enabled/default

# 9. 更新 systemd 服务
echo "🔄 更新 systemd 服务..."
cat > /etc/systemd/system/qingfutu-crm.service <<'SYSTEMD_EOF'
[Unit]
Description=青蓝图客户追踪看板
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/var/www/qingfutu
ExecStart=/usr/local/bin/gunicorn -b 0.0.0.0:5000 -w 2 api_server:app
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SYSTEMD_EOF

# 10. 测试 Nginx
echo "🧪 测试 Nginx 配置..."
nginx -t

# 11. 重启服务
echo "🚀 重启服务..."
systemctl daemon-reload
systemctl enable qingfutu-crm
systemctl stop qingfutu-crm 2>/dev/null || true
systemctl start qingfutu-crm
systemctl restart nginx

# 12. 验证
echo ""
echo "========================================="
echo "  ✅ 修复完成！"
echo ""
echo "  📊 验证结果："
echo "========================================="
echo ""

echo "=== Nginx 状态 ==="
systemctl is-active nginx

echo ""
echo "=== Gunicorn 状态 ==="
systemctl is-active qingfutu-crm

echo ""
echo "=== 本地健康检查 ==="
sleep 1
curl -s http://127.0.0.1:5000/api/health 2>/dev/null || echo "⚠️ Gunicorn 可能还没启动"

echo ""
echo "=== www-data 读取测试 ==="
sudo -u www-data cat /var/www/qingfutu/index.html | head -1

echo ""
echo "=== Nginx 首页测试 ==="
curl -s -o /dev/null -w "HTTP Status: %{http_code}" http://127.0.0.1/ -H "Authorization: Basic $(echo -n 'admin:qingfutu2024' | base64)"

echo ""
echo "========================================="
echo "  🔗 访问地址：http://81.70.202.143"
echo "  👤 账号：admin"
echo "  🔑 密码：qingfutu2024"
echo "========================================="
