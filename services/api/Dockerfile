# Seeded misconfiguration: stale base image with known CVEs. Pinned (never :latest) so the
# fix is a single deterministic line change (poc/fix/fixers.py: BaseImageFixer).
FROM python:3.9-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .

CMD ["python", "app.py"]
