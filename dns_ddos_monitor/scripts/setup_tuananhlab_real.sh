#!/bin/bash

# Setup script cho DNS DDoS Monitor với cấu hình thực tế của TuanAnhLab
# Phù hợp với cấu trúc BIND9 sử dụng /data/named và /data/logdns

echo "🎯 TuanAnhLab DNS DDoS Monitor Setup"
echo "===================================="
echo "Cấu hình cho BIND9 với directory /data/named"
echo ""

# Kiểm tra quyền root
if [[ $EUID -ne 0 ]]; then
   echo "❌ Script này cần chạy với quyền root (sudo)" 
   exit 1
fi

# Tạo thư mục cần thiết
echo "📁 Creating necessary directories..."
mkdir -p /data/named
mkdir -p /data/logdns
mkdir -p /var/run-named
mkdir -p ~/dns_ddos_monitor/logs

# Cấp quyền cho bind user
chown -R bind:bind /data/named
chown -R bind:bind /data/logdns
chown -R bind:bind /var/run-named
chmod 755 /data/named /data/logdns

echo "✅ Directories created and permissions set"

# Backup cấu hình hiện tại
echo "📦 Backing up current configuration..."
cp /etc/bind/named.conf /etc/bind/named.conf.backup.$(date +%Y%m%d) 2>/dev/null || true

# Copy zone files to /data/named
echo "📝 Installing zone files..."
cp config/db.tuananhlab.local /data/named/
cp config/db.85.168.192 /data/named/
cp config/db.nonexistent.tuananhlab.local /data/named/

# Cấp quyền cho zone files
chown bind:bind /data/named/db.*
chmod 644 /data/named/db.*

# Copy named.conf mới
echo "🔧 Installing new named.conf..."
cp config/named.conf.tuananhlab /etc/bind/named.conf

# Kiểm tra cấu hình BIND9
echo "✅ Checking BIND9 configuration..."
named-checkconf
if [ $? -ne 0 ]; then
    echo "❌ BIND9 configuration error!"
    echo "Restoring backup..."
    cp /etc/bind/named.conf.backup.$(date +%Y%m%d) /etc/bind/named.conf 2>/dev/null || true
    exit 1
fi

# Kiểm tra zone files
echo "✅ Checking zone files..."
named-checkzone tuananhlab.local /data/named/db.tuananhlab.local
if [ $? -ne 0 ]; then
    echo "❌ Zone file error for tuananhlab.local!"
    exit 1
fi

named-checkzone 85.168.192.in-addr.arpa /data/named/db.85.168.192
if [ $? -ne 0 ]; then
    echo "❌ Zone file error for reverse zone!"
    exit 1
fi

# Copy monitor configuration
echo "🔧 Installing monitor configuration..."
cp config/monitor_config_tuananhlab.json config/monitor_config.json
cp config/blocker_config.json config/blocker_config.json

# Cài đặt Python dependencies nếu chưa có
echo "🐍 Installing Python dependencies..."
pip3 install -r requirements.txt 2>/dev/null || {
    echo "⚠️  Some Python packages may need to be installed manually"
}

# Restart BIND9
echo "🔄 Restarting BIND9 service..."
systemctl restart bind9

# Kiểm tra service status
if systemctl is-active --quiet bind9; then
    echo "✅ BIND9 service is running"
else
    echo "❌ BIND9 service failed to start"
    echo "Checking logs..."
    journalctl -u bind9 --no-pager -n 20
    exit 1
fi

# Test DNS resolution
echo "🧪 Testing DNS resolution..."
sleep 3

echo "Testing tuananhlab.local:"
dig @localhost tuananhlab.local +short

echo "Testing bind.tuananhlab.local:"
dig @localhost bind.tuananhlab.local +short

echo "Testing web.tuananhlab.local:"
dig @localhost web.tuananhlab.local +short

echo "Testing reverse DNS:"
dig @localhost -x 192.168.85.130 +short

# Tạo test script
echo "📝 Creating test scripts..."
cat > test_tuananhlab_dns.sh << 'EOF'
#!/bin/bash

# Test DNS resolution cho tuananhlab.local
DNS_SERVER="192.168.85.130"
DOMAIN="tuananhlab.local"

echo "🧪 Testing DNS resolution for $DOMAIN"
echo "======================================"

echo "1. Basic A records:"
dig @$DNS_SERVER $DOMAIN +short
dig @$DNS_SERVER bind.$DOMAIN +short
dig @$DNS_SERVER web.$DOMAIN +short
dig @$DNS_SERVER www.$DOMAIN +short

echo ""
echo "2. Different record types:"
dig @$DNS_SERVER $DOMAIN MX +short
dig @$DNS_SERVER $DOMAIN TXT +short
dig @$DNS_SERVER $DOMAIN NS +short

echo ""
echo "3. Reverse DNS:"
dig @$DNS_SERVER -x 192.168.85.130 +short
dig @$DNS_SERVER -x 192.168.85.135 +short

echo ""
echo "4. Test NXDOMAIN:"
dig @$DNS_SERVER nonexistent.$DOMAIN +short

echo ""
echo "✅ DNS test completed!"
EOF

chmod +x test_tuananhlab_dns.sh

# Tạo startup script
cat > start_monitoring.sh << 'EOF'
#!/bin/bash

echo "🎯 Starting TuanAnhLab DNS DDoS Monitor"
echo "======================================"

# Kiểm tra log files tồn tại
if [ ! -f /data/logdns/log_query ]; then
    echo "⚠️  Query log file not found. Creating..."
    touch /data/logdns/log_query
    chown bind:bind /data/logdns/log_query
fi

# Start monitoring trong tmux sessions
echo "Starting DNS Monitor..."
tmux new-session -d -s dns_monitor 'python3 src/dns_monitor.py'

echo "Starting Auto Blocker..."
tmux new-session -d -s auto_blocker 'sudo python3 src/auto_blocker.py'

echo ""
echo "✅ Monitoring started!"
echo ""
echo "📊 View sessions:"
echo "tmux attach -t dns_monitor    # DNS Monitor console"
echo "tmux attach -t auto_blocker   # Auto Blocker console"
echo ""
echo "📈 Monitor logs:"
echo "tail -f logs/alerts.json"
echo "tail -f /data/logdns/log_query"
echo ""
echo "🌐 Web Dashboard: http://192.168.85.135:5000"
EOF

chmod +x start_monitoring.sh

echo ""
echo "✅ TuanAnhLab DNS DDoS Monitor setup completed!"
echo ""
echo "📋 Summary:"
echo "- BIND9 configured with /data/named directory"
echo "- Logging configured to /data/logdns/"
echo "- Zone files installed for tuananhlab.local"
echo "- Rate limiting enabled (50 RPS)"
echo "- Query logging enabled"
echo ""
echo "🎯 Next steps:"
echo "1. Test DNS: ./test_tuananhlab_dns.sh"
echo "2. Start monitoring: ./start_monitoring.sh"
echo "3. Run attacks from Kali:"
echo "   python3 tuananhlab_attacks.py --attack flood --duration 60"
echo ""
echo "📁 Important paths:"
echo "- Zone files: /data/named/"
echo "- DNS logs: /data/logdns/"
echo "- Monitor logs: ~/dns_ddos_monitor/logs/"
echo "- Config: ~/dns_ddos_monitor/config/"
echo ""
echo "🌐 Domain ready: tuananhlab.local"
echo "📡 DNS Server: 192.168.85.130"
echo "🌍 Web Server: 192.168.85.135"