FROM python:3.11-slim


ARG FIRESTORE_EMULATOR_HOST
ENV FIRESTORE_EMULATOR_HOST=${FIRESTORE_EMULATOR_HOST}

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["python", "etl_prophet.py"]
