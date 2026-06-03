#!/bin/bash

# Configuration - المتغيرات الخاصة بالملفات والبيئة
LOG_FILE="${MONITOR_LOG_PATH:-/data/med_app.log}"
ALERT_FILE="${MONITOR_ALERT_PATH:-/data/critical_alerts.log}"
LAST_SEND_FILE="/dev/shm/last_telegram_send" # ملف مؤقت في الذاكرة السريعة لتتبع الوقت

# إعدادات قاعدة البيانات
DB_HOST="${DB_HOST:-db}"
DB_NAME="${DB_NAME:-bio_observability}"
DB_USER="${DB_USER:-azhar_admin}"
export PGPASSWORD="${DB_PASS:-secure_password123}"

# --- إعدادات Telegram الحالية الخاصة بك ---
TELEGRAM_TOKEN="${TELEGRAM_TOKEN:-YOUR_TELEGRAM_BOT_TOKEN_HERE}"
CHAT_ID="${CHAT_ID:-YOUR_TELEGRAM_CHAT_ID_HERE}"

# تحديد معدل الإرسال (مثلاً منع التكرار خلال 10 ثوانٍ)
RATE_LIMIT_SECONDS=10 
echo "0" > "$LAST_SEND_FILE" # تهيئة ملف الوقت بالقيمة صفر

echo "--- Bio-IT Advanced Monitor Started [PostgreSQL + Telegram Mode] ---"

# التأكد من وجود الملفات
touch "$ALERT_FILE"
[ ! -f "$LOG_FILE" ] && touch "$LOG_FILE" && echo "[INFO] Created log file."

last_lines=$(wc -l < "$LOG_FILE")

while true; do
    current_lines=$(wc -l < "$LOG_FILE")
    
    if [ "$current_lines" -gt "$last_lines" ]; then
        new_lines_count=$((current_lines - last_lines))
        
        tail -n "$new_lines_count" "$LOG_FILE" | while read -r LINE
        do
            # 1. التحليل الذكي (Advanced Parsing)
            PATIENT_ID=$(echo "$LINE" | grep -oP 'ID \d+' | awk '{print $2}' || echo "N/A")
            DEVICE=$(echo "$LINE" | cut -d':' -f1 | awk '{print $NF}' || echo "System")

            case "$LINE" in
                *CRITICAL*)
                    echo -e "\e[1;41m [CRITICAL] $LINE \e[0m"
                    
                    # 2. حقن البيانات في PostgreSQL (يعمل بنجاح دائماً)
                    psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c \
                    "INSERT INTO critical_alerts (patient_id, device_name, raw_message) 
                     VALUES ('$PATIENT_ID', '$DEVICE', '$LINE');"
                    
                    # 3. منطق الـ Rate Limiting المغلّف لحل مشكلة الـ Subshell
                    CURRENT_TIME=$(date +%s)
                    LAST_ALERT_TIME=$(cat "$LAST_SEND_FILE" 2>/dev/null || echo "0")
                    TIME_DIFF=$((CURRENT_TIME - LAST_ALERT_TIME))

                    if [ "$TIME_DIFF" -ge "$RATE_LIMIT_SECONDS" ]; then
                        # إرسال تنبيه Telegram بنفس الشكل المفضل لديك تماماً دون أي تغيير
                        curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
                            -d "chat_id=${CHAT_ID}" \
                            --data-urlencode "text=🚨 تنبيه طبي عاجل
👤 المريض: $PATIENT_ID
📟 الجهاز: $DEVICE
📝 السجل: $LINE" > /dev/null
                        
                        # تحديث ملف الوقت من داخل الـ Subshell بنجاح
                        echo "$CURRENT_TIME" > "$LAST_SEND_FILE"
                    else
                        echo "[RATE LIMIT] Telegram notification skipped to prevent spamming."
                    fi
                    
                    echo "$(date '+%Y-%m-%d %H:%M:%S') - ALERT | ID: $PATIENT_ID | Device: $DEVICE" >> "$ALERT_FILE"
                    ;;
                *ERROR*)
                    echo -e "\e[1;31m [ERROR] $LINE \e[0m"
                    ;;
                *)
                    echo -e "\e[1;32m [INFO] $LINE \e[0m"
                    ;;
            esac
        done
        last_lines=$current_lines
    fi
    sleep 1
done