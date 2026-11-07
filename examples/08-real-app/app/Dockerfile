# The API and the worker: one Python image, two commands. The API is the default command; the worker
# runs the same image with `python -m notes.worker`.
FROM python:3.14-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY notes ./notes

# The version shown by /api/health. CI passes sha-<commit>, or the release version on a tag.
ARG APP_VERSION=dev
ENV APP_VERSION=$APP_VERSION

USER 10001
EXPOSE 8000
CMD ["uvicorn", "notes.api:app", "--host", "0.0.0.0", "--port", "8000"]
