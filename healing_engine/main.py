import os
import sys
import time
import subprocess
import requests
import psycopg2

# جلب متغيرات البيئة المؤمنة
DB_HOST = os.getenv("DB_HOST", "database")
DB_NAME = os.getenv("DB_NAME", "bio_observability_db")
DB_USER = os.getenv("DB_USER", "postgres_user")
DB_PASSWORD = os.getenv("DB_PASSWORD", "your_secure_password")
TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")
TELEGRAM_CHAT_ID = os.getenv("TELEGRAM_CHAT_ID")

LOG_FILE = "/app/logs/self_healing.log"

def log_local(level, message):
    timestamp = time.strftime('%Y-%m-%d %H:%M:%S')
    with open(LOG_FILE, "a") as f:
        f.write(f"[{timestamp}] [{level}] [AI-ENGINE] {message}\n")

def send_telegram_alert(message):
    if not TELEGRAM_BOT_TOKEN or not TELEGRAM_CHAT_ID:
        return
    url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage"
    payload = {"chat_id": TELEGRAM_CHAT_ID, "text": message, "parse_mode": "Markdown"}
    try:
        requests.post(url, json=payload, timeout=10)
    except Exception as e:
        log_local("ERROR", f"فشل الاتصال بـ تليجرام: {str(e)}")

def trigger_self_healing_script():
    log_local("ACTION" , "🤖 رصد نمط حرج! جاري إيقاظ ممرض الـ Bash...")
    try:
        result = subprocess.run(["/bin/bash", "./scripts/self_healing.sh"], capture_output=True, text=True)
        return result.returncode
    except Exception as e:
        log_local("CRITICAL", f"عاجز عن استدعاء السكربت: {str(e)}")
        return -1

# 🛠️ الدالة الجديدة: تهيئة وإنشاء الجدول تلقائياً لمنع خطأ Relation Does Not Exist
def initialize_database():
    print("🏗️ [DB-INIT] Checking database schema and tables...", flush=True)
    while True:
        try:
            conn = psycopg2.connect(host=DB_HOST, database=DB_NAME, user=DB_USER, password=DB_PASSWORD, connect_timeout=5)
            cursor = conn.cursor()
            
            # إنشاء الجدول بالأعمدة المهنية المطلوبة للمشروع إن لم يكن موجوداً
            create_table_query = """
                CREATE TABLE IF NOT EXISTS system_logs (
                    id SERIAL PRIMARY KEY,
                    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                    log_level VARCHAR(20) NOT NULL,
                    source_module VARCHAR(100),
                    message TEXT NOT NULL
                );
            """
            cursor.execute(create_table_query)
            conn.commit()
            
            cursor.close()
            conn.close()
            print("✅ [DB-INIT] Database schema is ready and verified.", flush=True)
            break
        except psycopg2.OperationalError:
            print("📡 [DB-INIT] Waiting for PostgreSQL container to accept connections...", flush=True)
            time.sleep(3)
        except Exception as e:
            print(f"❌ [DB-INIT-ERROR] Initialization failed: {str(e)}", flush=True)
            time.sleep(5)

def monitor_database_logs():
    print("📢 [STARTUP] Python AI Engine is initializing...", flush=True)
    log_local("INFO", "🎯 انطلق الطبيب المناوب. بدء مراقبة وفحص السجلات الإحصائية...")
    
    # استدعاء الفحص التلقائي للجدول قبل الدخول في الحلقة اللانهائية
    initialize_database()
    
    while True:
        print("🔍 [LOOP] Checking database logs status...", flush=True)
        conn = None
        try:
            conn = psycopg2.connect(host=DB_HOST, database=DB_NAME, user=DB_USER, password=DB_PASSWORD, connect_timeout=3)
            cursor = conn.cursor()
            
            query = """
                SELECT COUNT(*) FROM system_logs 
                WHERE log_level IN ('ERROR', 'CRITICAL') 
                AND timestamp >= NOW() - INTERVAL '1 minute';
            """
            cursor.execute(query)
            error_count = cursor.fetchone()[0]
            
            cursor.close()
            conn.close()

            # طباعة توضيحية لعدد الأخطاء الحالي في الـ Logs
            print(f"📊 [METRIC] Current critical errors in the last minute: {error_count}", flush=True)

            if error_count >= 5:
                print(f"⚠️ [ANOMALY] High error rate detected: {error_count} errors!", flush=True)
                log_local("WARN", f"🚨 مؤشر خطر: رصد {error_count} أخطاء حرجة متكررة!")
                
                # إطلاق الممرض والتقاط النتيجة
                exit_code = trigger_self_healing_script()
                
                # 🛠️ الممارسة الفضلى: قراءة آخر الأسطر من ملف الـ log لإرسالها للهاتف
                try:
                    with open(LOG_FILE, "r") as f:
                        lines = f.readlines()
                        # جلب آخر 3 أسطر كتبها سكربت الـ Bash أثناء عملية الإنقاذ
                        last_logs = "".join(lines[-3:]) 
                except Exception:
                    last_logs = "تعذر جلب تفاصيل السجل المحلي."

                # تحليل النتيجة الراجعة وبناء تقرير تليجرام غني بالتفاصيل (Rich Report)
                if exit_code == 0:
                    report = (
                        "✅ *Bio-IT Self-Healing Report*\n\n"
                        "📊 *Status:* Anomaly Resolved Successfully!\n"
                        f"🚨 *Trigger:* Detected {error_count} critical errors in 1 minute.\n"
                        "🐳 *Action:* Automated container inspection & system cache pruning executed.\n\n"
                        "📜 *Latest Execution Logs:*\n"
                        f"```text\n{last_logs}\n```\n"
                        "📈 *System Health:* Recovered & Stable."
                    )
                elif exit_code == 2:
                    report = (
                        "🚨 *CRITICAL SYSTEM ALERT*\n\n"
                        "❌ *Status:* Self-Healing Failed!\n"
                        "📉 *Action:* Forced restart executed but container is still unresponsive.\n"
                        f"⚠️ *Latest Logs:*\n```text\n{last_logs}\n```\n"
                        "👨‍💻 *Note:* Immediate developer manual intervention required!"
                    )
                else:
                    report = f"⚠️ *Notice:* Script executed but returned unknown code: {exit_code}"
                
                send_telegram_alert(report)
                time.sleep(120)
                
        except psycopg2.OperationalError as db_err:
            print(f"📡 [DATABASE OFFLINE] Connection failed: {db_err}", flush=True)
            log_local("CRITICAL", "📡 قاعدة البيانات لا تستجيب! إجراء تشافي اضطراري...")
            exit_code = trigger_self_healing_script()
            time.sleep(10)
            
        except Exception as e:
            print(f"❌ [UNEXPECTED ERROR] {str(e)}", flush=True)
            log_local("ERROR", f"خطأ غير متوقع: {str(e)}")
            time.sleep(10)
            
        time.sleep(5)

if __name__ == "__main__":
    print("🚀 [BOOT] Launching main execution thread...", flush=True)
    monitor_database_logs()