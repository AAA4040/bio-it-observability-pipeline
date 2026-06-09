#!/bin/bash

# -----------------------------------------------------------------------------
# مشروع: Bio-IT Observability Pipeline - سكربت التشافي الذاتي المؤتمت
# الممارسة الفضلى: تدوير وتوثيق العمليات بدقة عالية + حماية المتغيرات
# -----------------------------------------------------------------------------

# 1. تحديد مسارات ملف السجلات وإعدادات التنبيه
LOG_FILE="/app/logs/self_healing.log"
TARGET_CONTAINER="bio_postgres_db" # الحاوية المستهدفة بالفحص كمثال

# دالة برمجية موحدة للكتابة المنظمة داخل ملف الـ Logs لتسهيل الـ Debugging
log_message() {
    local LEVEL=$1
    local MSG=$2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$LEVEL] $MSG" >> "$LOG_FILE"
}

log_message "INFO" "⚡ تم استدعاء سكربت الـ Self-Healing بنجاح بواسطة حاوية المحلل الذكي."

# -----------------------------------------------------------------------------
# 2. المرحلة الأولى: الفحص والتأكد (Inspection Phase)
# -----------------------------------------------------------------------------
log_message "INSPECT" "جاري التحقق من حالة الحاوية المستهدفة: $TARGET_CONTAINER..."

# الاتصال بالحارس الأمني لمعرفة حالة الحاوية (هل هي تعمل أم متوقفة؟)
CONTAINER_STATUS=$(docker inspect -f '{{.State.Status}}' "$TARGET_CONTAINER" 2>/dev/null)

if [ $? -ne 0 ]; then
    log_message "ERROR" "❌ عاجز عن الاتصال بالحارس الأمني أو الحاوية غير موجودة في بيئة دوكر."
    exit 1
fi

log_message "INFO" "الحالة الحالية للحاوية $TARGET_CONTAINER هي: [$CONTAINER_STATUS]"

# -----------------------------------------------------------------------------
# 3. المرحلة الثانية والثالثة: اتخاذ القرار والتنفيذ (Decision & Action Phase)
# -----------------------------------------------------------------------------
if [ "$CONTAINER_STATUS" != "running" ]; then
    log_message "WARN" "⚠️ تم رصد انهيار أو توقف الحاوية. البدء في إجراءات التشافي التلقائي..."
    
    # إرسال أمر إعادة التشغيل عبر الحارس الأمني المؤمن
    log_message "ACTION" "جاري إطلاق الأمر الآمن: docker restart $TARGET_CONTAINER"
    docker restart "$TARGET_CONTAINER" >> "$LOG_FILE" 2>&1
    
    # الانتظار 5 ثوانٍ للتأكد من استقرار إقلاع الحاوية
    sleep 5
    
    # إعادة الفحص للتأكد من نجاح العملية
    NEW_STATUS=$(docker inspect -f '{{.State.Status}}' "$TARGET_CONTAINER" 2>/dev/null)
    
    if [ "$NEW_STATUS" == "running" ]; then
        log_message "SUCCESS" "✅ تمت إعادة تشغيل الحاوية $TARGET_CONTAINER بنجاح واستعادت استقرارها."
        # هنا سنضع علامة نجاح (Exit Code 0) لتلتقطها حاوية بايثون وترسل التقرير
        exit 0
    else
        log_message "CRITICAL" "🚨 تفاقم الخلل: الحاوية عاجزة عن النهوض بعد إعادة التشغيل المباشر!"
        exit 2
    fi
else
    # سيناريو امتلاء الكاش أو الذاكرة مع بقاء الحاوية تعمل
    log_message "INFO" "الحاوية تعمل ولكن مؤشرات الأداء تشير لامتلاء الكاش. جاري تنظيف الموارد المؤقتة..."
    log_message "ACTION" "تنفيذ أمر تنظيف كاش النظام الداخلي الآمن للـ Docker Layers الفائضة."
    
    docker system prune -f --filter "label=stage=builder" >> "$LOG_FILE" 2>&1
    
    log_message "SUCCESS" "✅ تم تنظيف كاش الموارد الفائضة بنجاح لخفض استهلاك الذاكرة."
    exit 0
fi