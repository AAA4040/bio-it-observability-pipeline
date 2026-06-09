# 1. الاعتماد على نسخة بايثون المصغرة والمحمية
FROM python:3.11-slim

# 2. تثبيت الأدوات الأساسية للـ Bash والاتصال بالشبكة والـ Docker CLI
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    bash \
    && curl -fsSL https://get.docker.com | sh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 3. تحديد مجلد العمل داخل الحاوية
WORKDIR /app

# 4. نسخ ملف المتطلبات وتثبيت مكتبات بايثون (الذكاء الاصطناعي وقاعدة البيانات)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 5. إنشاء مجلدات السجلات (Logs) والسكربتات
RUN mkdir -p /app/logs /app/scripts

# 6. نسخ الأكواد والسكربتات إلى داخل الحاوية
COPY main.py .
COPY scripts/self_healing.sh ./scripts/

# 7. إعطاء صلاحيات التنفيذ لسكربت الـ Bash ليعمل كممرض منفذ
RUN chmod +x ./scripts/self_healing.sh

# 8. تشغيل المحلل الذكي (الطبيب) كـ Entrypoint أساسي للحاوية
CMD ["python", "main.py"]