-- إنشاء الجدول مع أنواع بيانات دقيقة
CREATE TABLE IF NOT EXISTS critical_alerts (
    id SERIAL PRIMARY KEY,
    event_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    patient_id VARCHAR(50),
    device_name VARCHAR(100),
    severity VARCHAR(20) DEFAULT 'CRITICAL',
    raw_message TEXT
);

-- إضافة "فهرس" (Index) لضمان سرعة البحث عن المريض مستقبلاً
CREATE INDEX idx_patient_id ON critical_alerts(patient_id);