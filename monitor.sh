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

# إعدادات Telegram الآمنة عبر متغيرات البيئة

TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-YOUR_TELEGRAM_BOT_TOKEN_HERE}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-YOUR_TELEGRAM_CHAT_ID_HERE}"

# تحديد معدل الإرسال (منع التكرار خلال 10 ثوانٍ)
RATE_LIMIT_SECONDS=10 
echo "0" > "$LAST_SEND_FILE" # تهيئة ملف الوقت بالقيمة صفر

echo "--- Bio-IT Advanced Monitor Started [PostgreSQL + Telegram Mode] ---"

# التأكد من وجود الملفات
touch "$ALERT_FILE"
[ ! -f "$LOG_FILE" ] && touch "$LOG_FILE" && echo "[INFO] Created log file."

# ----------------------------------------------------------------#
# الحل الأفضل لمشكلة تدوير السجلات واستلاك المعالج (Log Rotation & CPU) #
# ----------------------------------------------------------------#
# نستخدم tail -F لمراقبة تدفق البيانات لحظياً والتعافي التلقائي عند تصفير الملف
tail -F "$LOG_FILE" | while read -r LINE
do
    # إزالة رموز ويندوز المخفية للتنظيف الفوري وضمان سلامة النصوص
    LINE=$(echo "$LINE" | tr -d '\r')

    # تجنب معالجة الأسطر الفارغة
    [ -z "$LINE" ] && continue

    # التحليل الذكي واستخراج المتغيرات
    PATIENT_ID=$(echo "$LINE" | grep -oP 'ID \d+' | awk '{print $2}' || echo "N/A")
    DEVICE=$(echo "$LINE" | cut -d':' -f1 | awk '{print $NF}' || echo "System")

    case "$LINE" in
        *CRITICAL*)
            echo -e "\e[1;41m [CRITICAL] $LINE \e[0m"
            
            # ------------------------------------------------------------#
            # 1. سد ثغرة حقن البيانات (SQL Injection Protection)             #
            # ------------------------------------------------------------#
            # نقوم بالهروب (Escape) من علامات الاقتباس المفردة بتحويل ' إلى ''
            SAFE_LINE=$(echo "$LINE" | sed "s/'/''/g")
            SAFE_PATIENT_ID=$(echo "$PATIENT_ID" | sed "s/'/''/g")
            SAFE_DEVICE=$(echo "$DEVICE" | sed "s/'/''/g")

            # ------------------------------------------------------------#
            # 2. إدارة تتابع الأخطاء (Error Handling & Fault Tolerance)      #
            # ------------------------------------------------------------#
            # التحقق من نجاح عملية الإدخال في قاعدة البيانات قبل المضي قدماً
            if psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c \
               "INSERT INTO critical_alerts (patient_id, device_name, raw_message) 
                VALUES ('$SAFE_PATIENT_ID', '$SAFE_DEVICE', '$SAFE_LINE');" > /dev/null 2>&1; then
                
                echo "[DB SUCCESS] Alert logged into PostgreSQL database."
                DB_STATUS_MSG=""
            else
                echo -e "\e[1;33m [DB FAILURE] Failed to connect or insert into PostgreSQL! \e[0m"
                DB_STATUS_MSG="⚠️ (تنبيه: فشل الحفظ في قاعدة البيانات!)"
            fi
            
            # 3. منطق الـ Rate Limiting المغلّف
            CURRENT_TIME=$(date +%s)
            LAST_ALERT_TIME=$(cat "$LAST_SEND_FILE" 2>/dev/null || echo "0")
            TIME_DIFF=$((CURRENT_TIME - LAST_ALERT_TIME))

            if [ "$TIME_DIFF" -ge "$RATE_LIMIT_SECONDS" ]; then
                # دمج حالة قاعدة البيانات مع الرسالة لضمان الشفافية الكاملة للمهندس
                FULL_TEXT="🚨 تنبيه طبي عاجل
👤 المريض: $PATIENT_ID
📟 الجهاز: $DEVICE
📝 السجل: $LINE
$DB_STATUS_MSG"

                curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
                    -d "chat_id=${CHAT_ID}" \
                    --data-urlencode "text=$FULL_TEXT" > /dev/null
                
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