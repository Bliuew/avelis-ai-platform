FROM python:3.13-slim AS unpack
WORKDIR /src
COPY Avelis_AI_Private_Beta_Platform.zip /tmp/avelis.zip
RUN python -m zipfile -e /tmp/avelis.zip /src && test -f /src/server.py && test -f /src/requirements.txt && test -d /src/public

FROM python:3.13-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app
COPY --from=unpack /src/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt && useradd --create-home --uid 10001 avelis && mkdir -p /app/data && chown -R avelis:avelis /app
COPY --from=unpack --chown=avelis:avelis /src/server.py .
COPY --from=unpack --chown=avelis:avelis /src/public/ public/
USER avelis
EXPOSE 8000
CMD ["python", "server.py"]
