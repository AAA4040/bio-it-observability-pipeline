-- 1. إنشاء جدول السجلات العام والموحد للمنظومة
CREATE TABLE IF NOT EXISTS system_logs (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    log_level VARCHAR(20) NOT NULL DEFAULT 'INFO',
    source_module VARCHAR(100), -- اسم الحاوية أو الجهاز (مثل Bio-Sequencer أو لابتوب المريض)
    patient_id VARCHAR(50),     -- معرف المريض (اختياري، يملأ فقط لو كان السجل يخص مريض)
    message TEXT NOT NULL
);

-- 2. الممارسة الفضلى: إضافة فهارس لضمان سرعة البحث بالوقت ونوع الخطأ مستقبلاً
CREATE INDEX IF NOT EXISTS idx_logs_timestamp ON system_logs(timestamp);
CREATE INDEX IF NOT EXISTS idx_logs_level ON system_logs(log_level);
CREATE INDEX IF NOT EXISTS idx_logs_patient ON system_logs(patient_id);