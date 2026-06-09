import os
import sys
import time
import subprocess
import requests
import psycopg2

# -----------------------------------------------------------------------------
# مشروع: Bio-IT Observability Pipeline - محرك التحليل والتشافي الذكي
# الممارسة الفضلى: حماية الاتصالات + فحص دقيق للـ Exit Codes + تقارير تفاعلية
# -----------------------------------------------------------------------------

# جلب متغيرات البيئة المؤمنة من ملف الكومبوز
DB_HOST = os.getenv("DB_HOST", "database")
DB_NAME = os.getenv("DB_NAME", "bio_observability_db")
DB_USER = os.getenv("DB_USER", "postgres_user")
DB_PASSWORD = os.getenv("DB_PASSWORD", "your_secure_password")
TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")
TELEGRAM_CHAT_ID = os.getenv("TELEGRAM_CHAT_ID")

LOG_FILE = "/app/logs/self_healing.log"

def log_local(level, message):
    """دالة لتوثيق التحليلات الذكية داخل ملف السجلات المحلي لتسهيل الـ Debugging"""
    timestamp = time.strftime('%Y-%m-%d %H:%M:%S')
    with open(LOG_FILE, "a") as f:
        f.write(f"[{timestamp}] [{level}] [AI-ENGINE] {message}\n")

def send_telegram_alert(message):
    """إرسال تنبيه فوري ومجاني لهاتف المستخدم عبر الـ Telegram API"""
    if not TELEGRAM_BOT_TOKEN or not TELEGRAM_CHAT_ID:
        log_local("WARN", "تنبيه Telegram غير مفعل لعدم توفر مفاتيح البيئة .env")
        return
    
    url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage"
    payload = {"chat_id": TELEGRAM_CHAT_ID, "text": message, "parse_mode": "Markdown"}
    try:
        response = requests.post(url, json=payload, timeout=10)
        if response.status_code == 200:
            log_local("INFO", "🚀 تم إرسال تقرير التشافي الذاتي إلى هاتف المطور عبر Telegram.")
        else:
            log_local("ERROR", f"فشل إرسال التنبيه، استجابة السيرفر: {response.status_code}")
    except Exception as e:
        log_local("ERROR", f"فشل الاتصال بـ شبكة Telegram: {str(e)}")

def trigger_self_healing_script():
    """استدعاء الممرض المنفذ (Bash Script) محلياً وقراءة النتيجة الهندسية منه"""
    log_local("ACTION" , "🤖 الذكاء الإحصائي رصد نمطاً حرجاً متكرراً! جاري إيقاظ ممرض الـ Bash...")
    try:
        # تشغيل السكربت وانتظار مخرجاته ورقم النهاية (Exit Code)
        result = subprocess.run(["/bin/bash", "./scripts/self_healing.sh"], capture_output=True, text=True)
        return result.returncode
    except Exception as e:
        log_local("CRITICAL", f"عاجز عن استدعاء ملف السكربت محلياً: {str(e)}")
        return -1

def monitor_database_logs():
    """فحص قاعدة البيانات بذكاء لرصد قفزات الأخطاء المتكررة في الدقيقة الأخيرة"""
    log_local("INFO", "🎯 انطلق الطبيب المناوب. بدء مراقبة وفحص السجلات الإحصائية...")
    
    while True:
        conn = None
        try:
            # محاولة اتصال آمنة ومحمية بقاعدة البيانات تمنع انهيار الحاوية بالكامل
            conn = psycopg2.connect(host=DB_HOST, database=DB_NAME, user=DB_USER, password=DB_PASSWORD, connect_timeout=5)
            cursor = conn.cursor()
            
            # استعلام ذكي: حساب عدد الأخطاء الحرجة المتكررة خلال الـ 60 ثانية الأخيرة فقط
            query = """
                SELECT COUNT(*) FROM system_logs 
                WHERE log_level IN ('ERROR', 'CRITICAL') 
                AND timestamp >= NOW() - INTERVAL '1 minute';
            """
            cursor.execute(query)
            error_count = cursor.fetchone()[0]
            
            cursor.close()
            conn.close()

            # المعيار الإحصائي المتفق عليه (تكرار الخطأ 5 مرات أو أكثر في دقيقة)
            if error_count >= 5:
                log_local("WARN", f"🚨 مؤشر خطر: رصد {error_count} أخطاء حرجة متكررة في دقيقة واحدة!")
                
                # إطلاق الممرض والتقاط النتيجة
                exit_code = trigger_self_healing_script()
                
                # تحليل النتيجة الراجعة وبناء تقرير تليجرام تفاعلي وصريح بناءً عليها
                if exit_code == 0:
                    report = (
                        "✅ *Bio-IT Self-Healing Report*\n\n"
                        "⚠️ *Status:* Anomaly Detected (High Error Rate).\n"
                        "🛠️ *Action Taken:* Container was successfully restarted, and dangling memory/caches were pruned.\n"
                        "📊 *System Health:* Recovered & Stable."
                    )
                elif exit_code == 2:
                    report = (
                        "🚨 *CRITICAL SYSTEM ALERT*\n\n"
                        "❌ *Status:* Self-Healing Failed!\n"
                        "📉 *Action Taken:* Tried to restart the container, but it fails to boot up properly.\n"
                        "👨‍💻 *Note:* Immediate developer manual intervention required! Check `self_healing.log`."
                    )
                else:
                    report = "⚠️ *Observability Pipeline Notice:* System anomalies triggered the script, but an internal execution error occurred."
                
                send_telegram_alert(report)
                
                # النوم لمدة دقيقتين بعد الإصلاح لإعطاء النظام فرصة للاستقرار وعدم تكرار الإجراء فوراً
                time.sleep(120)
                
        except psycopg2.OperationalError:
            # في حال كانت قاعدة البيانات نفسها منهارة، لا ينهار السكربت بل يتخذ إجراء تشافي اضطراري فوراً!
            log_local("CRITICAL", "📡 قاعدة البيانات لا تستجيب (Offline)! البدء في إجراءات التشافي الاضطراري...")
            exit_code = trigger_self_healing_script()
            if exit_code == 0:
                send_telegram_alert("⚠️ *Database Offline Alert:* PostgreSQL was unresponsive, but the pipeline successfully forced a restart. Verification in progress.")
            time.sleep(30)
            
        except Exception as e:
            log_local("ERROR", f"خطأ غير متوقع في محرك الفحص: {str(e)}")
            time.sleep(10)
            
        # فحص دوري خفيف كل 10 ثوانٍ (منخفض الاستهلاك تماماً للـ CPU)
        time.sleep(10)

if __name__ == "__main__":
    monitor_database_logs()