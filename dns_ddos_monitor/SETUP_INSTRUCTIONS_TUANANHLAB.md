# 🎯 Hướng dẫn Setup DNS DDoS Monitor cho TuanAnhLab

## 📋 Môi trường hiện tại của bạn

Bạn đã có:
- **DNS Server**: 192.168.85.130 với BIND9 cấu hình `/data/named`
- **Web Server**: 192.168.85.135 với Apache
- **Kali**: 192.168.85.100 với `/etc/resolv.conf` trỏ đến DNS server
- **Domain**: `tuananhlab.local` đã hoạt động
- **Existing zone**: `cpv02.labipv6.vn1`

## 🚀 BƯỚC 1: Cập nhật DNS Server (192.168.85.130)

### 1.1 Clone project và setup:
```bash
# Clone từ GitHub
git clone https://github.com/TuanAnh0609/stego_audio_code_parity-coding
cd dns_ddos_monitor

# Chạy setup script cho môi trường thực
sudo chmod +x scripts/setup_tuananhlab_real.sh
sudo ./scripts/setup_tuananhlab_real.sh
```

### 1.2 Kết quả mong đợi:
- ✅ Zone file `/data/named/db.tuananhlab.local` được cập nhật với nhiều records
- ✅ Reverse zone `/data/named/db.85.168.192` được tạo
- ✅ BIND9 config cập nhật với rate limiting và logging
- ✅ Python monitoring environment được setup

### 1.3 Test DNS resolution:
```bash
./test_tuananhlab_dns.sh

# Manual test:
dig @localhost tuananhlab.local
dig @localhost www.tuananhlab.local  
dig @localhost api.tuananhlab.local
```

## 🎯 BƯỚC 2: Setup Attack Tools trên Kali (192.168.85.100)

### 2.1 Copy attack tools:
```bash
# Từ DNS server, copy sang Kali
scp -r attack_tools/ kali@192.168.85.100:~/dns_attacks/
```

### 2.2 Trên Kali, cài đặt tools:
```bash
cd ~/dns_attacks/
sudo chmod +x install_tools.sh
sudo ./install_tools.sh

# Cấp quyền execute
chmod +x tuananhlab_attacks.py
chmod +x tuananhlab_quick_attacks.sh
```

### 2.3 Test connectivity từ Kali:
```bash
# Test DNS resolution
dig @192.168.85.130 tuananhlab.local
dig @192.168.85.130 web.tuananhlab.local

# Test dnsperf
echo "tuananhlab.local A" > test.txt
dnsperf -s 192.168.85.130 -d test.txt -l 5 -Q 10

# Test hping3
hping3 -2 -p 53 -c 5 192.168.85.130
```

## 📊 BƯỚC 3: Khởi động Monitoring (DNS Server)

### 3.1 Start monitoring systems:
```bash
# Trên DNS server
cd ~/dns_ddos_monitor
./start_monitoring.sh

# Hoặc manual:
# Terminal 1: DNS Monitor
python3 src/dns_monitor.py

# Terminal 2: Auto Blocker  
sudo python3 src/auto_blocker.py

# Terminal 3: Log monitoring
tail -f logs/alerts.json
```

### 3.2 Start Web Dashboard (Web Server 192.168.85.135):
```bash
# Copy dashboard files
scp -r dashboard/ user@192.168.85.135:~/
scp -r logs/ user@192.168.85.135:~/dns_dashboard/

# Trên web server
cd ~/dashboard
python3 app.py
# Dashboard sẽ chạy trên http://192.168.85.135:5000
```

## 🎭 BƯỚC 4: Demo Attack Scenarios

### 4.1 Basic Attack Test (từ Kali):
```bash
# DNS Flood Attack
python3 tuananhlab_attacks.py --attack flood --duration 30 --qps 500

# NXDOMAIN Attack
python3 tuananhlab_attacks.py --attack nxdomain --duration 30 --qps 300

# UDP Flood
python3 tuananhlab_attacks.py --attack udp-flood --duration 30 --pps 800
```

### 4.2 Interactive Menu:
```bash
./tuananhlab_quick_attacks.sh
# Chọn attack type và parameters
```

### 4.3 Demo Scenario cho Báo cáo:
```bash
# 15-minute structured demo
python3 tuananhlab_attacks.py --attack mixed --duration 180
```

## 📈 BƯỚC 5: Verification và Results

### 5.1 Trên DNS Server Console:
- ✅ Màn hình hiển thị real-time alerts
- ✅ Top attacking IP: 192.168.85.100
- ✅ Attack types: Flood, NXDOMAIN, Amplification
- ✅ Statistics: QPS, domains, clients

### 5.2 Auto IP Blocking:
```bash
# Kiểm tra IP bị chặn
sudo iptables -L INPUT -n | grep 192.168.85.100

# Từ Kali - DNS queries sẽ timeout
dig @192.168.85.130 tuananhlab.local
```

### 5.3 Web Dashboard Results:
- 🌐 http://192.168.85.135:5000
- ✅ Interactive charts với attack timeline
- ✅ Top attackers visualization
- ✅ Real-time statistics

### 5.4 Log Files cho Báo cáo:
```bash
# Structured alerts
cat logs/alerts.json | jq . | tail -20

# Raw DNS queries
tail -f /data/logdns/log_query

# IP blocking history
cat logs/block_actions.json | jq .
```

## 🔧 BƯỚC 6: Troubleshooting

### 6.1 DNS Server Issues:
```bash
# Check BIND9 status
sudo systemctl status bind9

# Check configuration
sudo named-checkconf
sudo named-checkzone tuananhlab.local /data/named/db.tuananhlab.local

# Check logs
sudo tail -f /data/logdns/named.log
```

### 6.2 Attack Tools Issues:
```bash
# Verify tools installed
which dnsperf
which hping3

# Check connectivity
ping 192.168.85.130
telnet 192.168.85.130 53
```

### 6.3 Monitoring Issues:
```bash
# Check Python dependencies
pip3 install -r requirements.txt

# Check log file permissions
ls -la /data/logdns/
sudo chown bind:bind /data/logdns/log_query
```

## 📊 Expected Demo Results

### Phase 1: Baseline (Normal traffic)
```
DNS Monitor Console:
- Green status indicators
- Low QPS (< 10)
- No alerts
```

### Phase 2: Light Attack
```
DNS Monitor Console:
- Yellow alerts appearing
- QPS increasing (100-500)
- Client 192.168.85.100 in top list
```

### Phase 3: Heavy Attack
```
DNS Monitor Console:  
- Red critical alerts
- QPS > 1000
- Multiple attack types detected
- Auto blocker activating
```

### Phase 4: IP Blocked
```
From Kali:
- DNS queries timeout
- Connection refused
- iptables rules visible on DNS server
```

## 📁 Files cho Báo cáo

### Screenshots cần chụp:
1. DNS Monitor console với alerts
2. Web dashboard charts
3. iptables output với blocked IPs
4. Attack tools running trên Kali
5. Log files với structured data

### Data files:
- `logs/alerts.json` - Attack detection data
- `logs/stats.json` - Performance metrics
- `/data/logdns/log_query` - Raw DNS logs
- `logs/block_actions.json` - IP blocking history

## 🎯 Summary Commands

### Quick Start (DNS Server):
```bash
git clone <repo-url>
cd dns_ddos_monitor
sudo ./scripts/setup_tuananhlab_real.sh
./start_monitoring.sh
```

### Quick Attack (Kali):
```bash
python3 tuananhlab_attacks.py --attack mixed --duration 120
```

### Quick Verify:
```bash
sudo iptables -L INPUT -n | grep DNS-DDoS-Block
cat logs/alerts.json | jq . | tail -10
```

---

**🎓 Hệ thống đã sẵn sàng cho demo và báo cáo!**

**Domain**: tuananhlab.local | **Network**: 192.168.85.0/24  
**⚠️ Chỉ sử dụng cho mục đích học tập và nghiên cứu**