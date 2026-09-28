"""Contact form relay for erasmus.works.

Takes the landing page form, checks Cloudflare Turnstile, and mails the message
to CONTACT_TO through SMTP2GO, so the address never appears in the page.
"""

import json
import os
import re
import smtplib
import ssl
import urllib.parse
import urllib.request
from email.message import EmailMessage
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

CONTACT_TO = os.environ["CONTACT_TO"]
CONTACT_FROM = os.environ["CONTACT_FROM"]
SMTP_HOST = os.environ["SMTP_HOST"]
SMTP_PORT = int(os.environ["SMTP_PORT"])
SMTP_USERNAME = os.environ["SMTP_USERNAME"]
SMTP_PASSWORD = os.environ["SMTP_PASSWORD"]
TURNSTILE_SECRET = os.environ["TURNSTILE_SECRET"]

MAX_BODY = 16 * 1024
# no whitespace or header punctuation, so it is safe to drop into Reply-To
EMAIL = re.compile(r"^[^@\s<>,;:\"]+@[^@\s<>,;:\"]+\.[^@\s<>,;:\"]+$")


def turnstile_ok(token, ip):
    data = urllib.parse.urlencode(
        {"secret": TURNSTILE_SECRET, "response": token, "remoteip": ip}
    ).encode()
    try:
        with urllib.request.urlopen(
            "https://challenges.cloudflare.com/turnstile/v0/siteverify", data, timeout=10
        ) as r:
            return json.load(r).get("success") is True
    except Exception as e:
        print(f"turnstile verify failed: {e}", flush=True)
        return False


def send(name, email, message, ip):
    msg = EmailMessage()
    msg["From"] = CONTACT_FROM
    msg["To"] = CONTACT_TO
    msg["Reply-To"] = email
    msg["Subject"] = f"erasmus.works contact: {name}"
    msg.set_content(f"From: {name} <{email}>\nIP: {ip}\n\n{message}\n")
    with smtplib.SMTP(SMTP_HOST, SMTP_PORT, timeout=15) as s:
        s.starttls(context=ssl.create_default_context())
        s.login(SMTP_USERNAME, SMTP_PASSWORD)
        s.send_message(msg)


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/healthz":
            self.reply(200, {"ok": True})
        else:
            self.reply(404, {"error": "not found"})

    def do_POST(self):
        if self.path != "/api/contact":
            return self.reply(404, {"error": "not found"})

        length = int(self.headers.get("Content-Length") or 0)
        if not 0 < length <= MAX_BODY:
            return self.reply(413, {"error": "Message too long."})
        body = self.rfile.read(length).decode("utf-8", "replace")
        form = {k: v[0].strip() for k, v in urllib.parse.parse_qs(body).items()}

        # Honeypot. The page keeps "website" off-screen (not display: none, which
        # some bots skip) so people never fill it, but form-filling bots do. Its
        # purpose stays out of the page's HTML and CSS so it isn't advertised.
        # Answer as if it worked so the bot has nothing to learn from.
        if form.get("website"):
            return self.reply(200, {"ok": True})

        name = " ".join(form.get("name", "").split())[:100]
        email = form.get("email", "")
        message = form.get("message", "")
        if not name or not message or len(email) > 254 or not EMAIL.match(email):
            return self.reply(400, {"error": "Please fill in your name, a valid email and a message."})
        if len(message) > 5000:
            return self.reply(400, {"error": "Message too long."})

        ip = self.headers.get("CF-Connecting-IP", "")
        if not turnstile_ok(form.get("cf-turnstile-response", ""), ip):
            return self.reply(403, {"error": "The spam check failed. Please try again."})

        try:
            send(name, email, message, ip)
        except Exception as e:
            print(f"smtp send failed: {e}", flush=True)
            return self.reply(502, {"error": "Sending failed. Please try again later."})
        self.reply(200, {"ok": True})

    def reply(self, status, payload):
        body = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt, *args):
        if self.path != "/healthz":
            super().log_message(fmt, *args)


if __name__ == "__main__":
    ThreadingHTTPServer(("", 8080), Handler).serve_forever()
