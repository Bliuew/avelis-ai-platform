FROM python:3.13-slim AS unpack
WORKDIR /src
# Avezqi_Render_Deploy.zip holds the application; Avezqi_Part_2_Designs.zip adds the design images and PDFs.
COPY Avezqi_Render_Deploy.zip Avezqi_Part_2_Designs.zip /tmp/zips/
RUN python -m zipfile -e /tmp/zips/Avezqi_Render_Deploy.zip /tmp/deploy \
 && python -m zipfile -e /tmp/deploy/Avezqi_Phase_I_Updated_Platform.zip /src \
 && for z in /tmp/zips/Avezqi_Part_*.zip; do if [ -f "$z" ]; then python -m zipfile -e "$z" /src; fi; done \
 && test -f /src/server.py && test -f /src/requirements.txt && test -d /src/public

FROM python:3.13-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app
COPY --from=unpack /src/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt && useradd --create-home --uid 10001 avelis && mkdir -p /app/data && chown -R avelis:avelis /app
COPY --from=unpack --chown=avelis:avelis /src/server.py .
COPY --from=unpack --chown=avelis:avelis /src/public/ public/
USER avelis
EXPOSE 8000

CMD ["python", "-c", "import os, sys, time\nimport server\nemail = os.environ.pop('AVELIS_OWNER_EMAIL', '').strip()\ncode = os.environ.pop('AVELIS_OWNER_INVITE', '').strip()\nif email:\n    email = server.email(email)\n    server.configure_operator(email)\nif email and code:\n    if not 24 <= len(code) <= 200:\n        raise SystemExit('Generate a strong AVELIS_OWNER_INVITE in Render.')\n    with server.db() as c:\n        c.execute('BEGIN IMMEDIATE')\n        if not c.execute('SELECT 1 FROM users LIMIT 1').fetchone():\n            c.execute('INSERT OR IGNORE INTO invites VALUES(?,?,?,?,0)', (server.digest(code), None, email, int(time.time()) + 259200))\n            print('Founder invitation initialization checked.', flush=True)\nos.execv(sys.executable, [sys.executable, 'server.py'])\n"]
