#!/bin/bash

read -p "Nhập địa chỉ IP LAN của máy thật (VD: 192.168.1.100): " HOST_IP

if [[ ! $HOST_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "❌ Địa chỉ IP không hợp lệ!"
    exit 1
fi

ADMIN_API="http://localhost:9180/apisix/admin"
API_KEY="edd1c9f034335f136f87ad84b625c8f1"

echo "🔧 Đang thiết lập các route cho APISIX với IP $HOST_IP..."

# Định nghĩa các route và cổng tương ứng
declare -A routes=(
    [1]="/login"
    [2]="/register"
    [3]="/update-permision"
    [4]="/products"
    [5]="/top-5-orders"
    [6]="/order"
    [7]="/update-product"
    [8]="/add-product"
    [9]="/delete-product"
    [10]="/all-customers"
)

declare -A ports=(
    [1]=5000
    [2]=5000
    [3]=5000
    [4]=6000
    [5]=6000
    [6]=6000
    [7]=6000
    [8]=6000
    [9]=6000
    [10]=7000
)

all_ok=true

for id in "${!routes[@]}"; do
    uri="${routes[$id]}"
    port="${ports[$id]}"
    upstream="$HOST_IP:$port"
    
    echo "➡️  Thiết lập route $uri --> $upstream"

    response=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "$ADMIN_API/routes/$id" \
        -H "Content-Type: application/json" \
        -H "X-API-KEY: $API_KEY" \
        -d "{
            \"uri\": \"$uri\",
            \"upstream\": {
                \"type\": \"roundrobin\",
                \"scheme\": \"http\",
                \"nodes\": {
                    \"$upstream\": 1
                }
            }
        }")

    if [[ "$response" == "201" || "$response" == "200" ]]; then
        echo "✅ Route $uri thiết lập thành công!"
    else
        echo "❌ Lỗi khi thiết lập route $uri (Mã HTTP: $response)"
        all_ok=false
    fi
done

if $all_ok; then
    echo "🎉 Tất cả các route đã được thiết lập thành công!"
else
    echo "⚠️ Một hoặc nhiều route gặp lỗi. Vui lòng kiểm tra lại!"
fi
