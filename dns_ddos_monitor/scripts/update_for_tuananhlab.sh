#!/bin/bash

# Script cập nhật hệ thống DNS DDoS Monitor cho domain tuananhlab.local
echo "🔄 Updating DNS DDoS Monitor for tuananhlab.local domain"

# Kiểm tra quyền root  
if [[ $EUID -ne 0 ]]; then
   echo "Script này cần chạy với quyền root (sudo)" 
   exit 1
fi

# Copy updated zone file
echo "📝 Updating zone file with additional records..."
cp config/db.tuananhlab.local /etc/bind/zones/tuananhlab.local

# Ensure proper ownership and permissions
chown bind:bind /etc/bind/zones/tuananhlab.local
chmod 644 /etc/bind/zones/tuananhlab.local

# Check configuration
echo "✅ Checking BIND9 configuration..."
named-checkzone tuananhlab.local /etc/bind/zones/tuananhlab.local

# Restart BIND9
echo "🔄 Restarting BIND9 service..."
systemctl restart bind9

echo "✅ Update completed successfully!"
