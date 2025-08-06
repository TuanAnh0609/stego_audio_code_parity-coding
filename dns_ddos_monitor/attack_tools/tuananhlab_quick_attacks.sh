#!/bin/bash

# Quick DNS Attack Scripts cho tuananhlab.local
# Target DNS Server: 192.168.85.130

DNS_TARGET="192.168.85.130"
DNS_PORT="53"
DOMAIN="tuananhlab.local"

echo "🎯 TuanAnhLab DNS Attack Menu"
echo "Target: $DNS_TARGET:$DNS_PORT"
echo "Domain: $DOMAIN"
echo "=========================="
echo ""
echo "1. 🚀 DNS Flood Attack (dnsperf)"
echo "2. 💥 NXDOMAIN Flood (dnsperf)"
echo "3. 🌊 UDP Flood (hping3)"
echo "4. 📈 DNS Amplification"
echo "5. 🔍 Subdomain Enumeration"
echo "6. 🎭 Mixed Attack Scenario"
echo "7. 🧪 Custom Attack"
echo "8. 📊 Test Connectivity"
echo "0. ❌ Exit"
echo ""

read -p "Choose attack type (0-8): " choice

case $choice in
    1)
        echo "🚀 Starting DNS Flood Attack on $DOMAIN..."
        read -p "Duration (seconds) [60]: " duration
        duration=${duration:-60}
        read -p "QPS (queries per second) [1000]: " qps
        qps=${qps:-1000}
        
        python3 tuananhlab_attacks.py --attack flood --duration $duration --qps $qps
        ;;
    
    2)
        echo "💥 Starting NXDOMAIN Flood Attack on $DOMAIN..."
        read -p "Duration (seconds) [60]: " duration
        duration=${duration:-60}
        read -p "QPS (queries per second) [500]: " qps
        qps=${qps:-500}
        
        python3 tuananhlab_attacks.py --attack nxdomain --duration $duration --qps $qps
        ;;
    
    3)
        echo "🌊 Starting UDP Flood Attack..."
        read -p "Duration (seconds) [60]: " duration
        duration=${duration:-60}
        read -p "PPS (packets per second) [1000]: " pps
        pps=${pps:-1000}
        
        python3 tuananhlab_attacks.py --attack udp-flood --duration $duration --pps $pps
        ;;
    
    4)
        echo "📈 Starting DNS Amplification Attack on $DOMAIN..."
        read -p "Duration (seconds) [60]: " duration
        duration=${duration:-60}
        
        python3 tuananhlab_attacks.py --attack amplification --duration $duration
        ;;
    
    5)
        echo "🔍 Starting Subdomain Enumeration Attack on $DOMAIN..."
        read -p "Duration (seconds) [60]: " duration
        duration=${duration:-60}
        
        python3 tuananhlab_attacks.py --attack enumeration --duration $duration
        ;;
    
    6)
        echo "🎭 Starting Mixed Attack Scenario on $DOMAIN..."
        read -p "Total duration (seconds) [180]: " duration
        duration=${duration:-180}
        
        python3 tuananhlab_attacks.py --attack mixed --duration $duration
        ;;
    
    7)
        echo "🧪 Custom Attack Configuration..."
        echo "Available attacks: flood, nxdomain, udp-flood, amplification, enumeration"
        read -p "Attack type: " attack_type
        read -p "Duration (seconds): " duration
        read -p "QPS/PPS: " rate
        
        if [[ $attack_type == "udp-flood" ]]; then
            python3 tuananhlab_attacks.py --attack $attack_type --duration $duration --pps $rate
        else
            python3 tuananhlab_attacks.py --attack $attack_type --duration $duration --qps $rate
        fi
        ;;
    
    8)
        echo "📊 Testing DNS Connectivity to $DOMAIN..."
        echo ""
        
        # Test basic DNS resolution
        echo "Testing basic DNS queries..."
        echo "dig @$DNS_TARGET $DOMAIN +short"
        dig @$DNS_TARGET $DOMAIN +short
        echo ""
        
        echo "dig @$DNS_TARGET bind.$DOMAIN +short"
        dig @$DNS_TARGET bind.$DOMAIN +short
        echo ""
        
        echo "dig @$DNS_TARGET web.$DOMAIN +short"
        dig @$DNS_TARGET web.$DOMAIN +short
        echo ""
        
        echo "dig @$DNS_TARGET www.$DOMAIN +short"
        dig @$DNS_TARGET www.$DOMAIN +short
        echo ""
        
        echo "Testing different record types..."
        echo "dig @$DNS_TARGET $DOMAIN MX +short"
        dig @$DNS_TARGET $DOMAIN MX +short
        echo ""
        
        echo "dig @$DNS_TARGET $DOMAIN TXT +short"
        dig @$DNS_TARGET $DOMAIN TXT +short
        echo ""
        
        echo "dig @$DNS_TARGET $DOMAIN NS +short"
        dig @$DNS_TARGET $DOMAIN NS +short
        echo ""
        
        echo "Testing with nslookup..."
        nslookup www.$DOMAIN $DNS_TARGET
        echo ""
        
        echo "Testing UDP connectivity with hping3..."
        hping3 -2 -p $DNS_PORT -c 5 $DNS_TARGET
        echo ""
        
        echo "Testing dnsperf with small load..."
        echo "$DOMAIN A" > /tmp/tuananhlab_test_queries.txt
        echo "bind.$DOMAIN A" >> /tmp/tuananhlab_test_queries.txt
        echo "web.$DOMAIN A" >> /tmp/tuananhlab_test_queries.txt
        dnsperf -s $DNS_TARGET -p $DNS_PORT -d /tmp/tuananhlab_test_queries.txt -l 5 -c 1 -Q 10
        rm -f /tmp/tuananhlab_test_queries.txt
        echo ""
        
        echo "Testing web server connectivity..."
        curl -I http://192.168.85.135/ 2>/dev/null | head -1
        ;;
    
    0)
        echo "👋 Goodbye!"
        exit 0
        ;;
    
    *)
        echo "❌ Invalid choice. Please select 0-8."
        ;;
esac

echo ""
echo "✅ Attack completed!"
echo ""
echo "📈 Check results on:"
echo "- DNS Server console: Monitor alerts and statistics"
echo "- Web Dashboard: http://192.168.85.135:5000"
echo "- DNS Server logs: tail -f ~/dns_ddos_monitor/logs/alerts.json"
echo ""
echo "📝 Verify DNS resolution:"
echo "dig @$DNS_TARGET $DOMAIN"
echo "dig @$DNS_TARGET web.$DOMAIN"