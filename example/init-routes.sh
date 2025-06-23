#!/bin/bash

read -p "Nhập địa chỉ IP LAN của máy thật (VD: 192.168.1.100): " HOST_IP

if [[ ! $HOST_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "❌ Địa chỉ IP không hợp lệ!"
    exit 1
fi

ADMIN_API="http://localhost:9180/apisix/admin"
API_KEY="edd1c9f034335f136f87ad84b625c8f1"

# 🔑 Khóa bí mật dùng để ký JWT (phải trùng với phía microservice xác thực)
JWT_SECRET="8649b8d14cf53f327521e52012862e927ef74c63ff9baec5a85ff9afb4f0d724"

echo "🔧 Đang thiết lập các route cho APISIX với IP $HOST_IP..."

declare -A routes=(
    [1]="/login"
    [2]="/register"
    [3]="/logout"
    [4]="/verify-otp"
    [5]="/update-permision"
    [6]="/products"
    [7]="/top-5-orders"
    [8]="/order"
    [9]="/update-product"
    [10]="/add-product"
    [11]="/delete-product"
    [12]="/all-customers"
    [13]="/verify-otp-and-reset"
    [14]="/forgot-password"
)

declare -A ports=(
    [1]=5555
    [2]=5555
    [3]=5555
    [4]=5555
    [5]=5555
    [6]=6000
    [7]=6000
    [8]=6000
    [9]=6000
    [10]=6000
    [11]=6000
    [12]=7000
    [13]=5555
    [14]=5555
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
            },
            \"plugins\": {
                \"custom-signer\": {
                    \"key\": \"$JWT_SECRET\",
                    \"alg\": \"HS256\",
                    \"header_name\": \"X-Gateway-JWT\",
                    \"payload\": {
                        \"service\": \"apisix-gateway\",
                        \"route\": \"$uri\"
                    }
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
    echo "🎉 Tất cả các route đã được thiết lập thành công kèm JWT!"
else
    echo "⚠️ Một hoặc nhiều route gặp lỗi. Vui lòng kiểm tra lại!"
fi
