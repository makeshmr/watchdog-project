# NGINX Error Monitoring and Slack Alerting for Python Application


A lightweight, Docker-free monitoring setup for a Python-based backend application served via NGINX. This project captures NGINX error logs and notifies a Slack channel in real-time when backend errors occur.

---

## 📄 Description

This project demonstrates a simple monitoring and alerting system using shell scripts and Slack webhooks. It is designed for scenarios where you need quick visibility into backend issues without adding heavyweight monitoring tools.

---

## ⚙️ Components

- **`setup.sh`**  
  Automates the installation and configuration of NGINX, sets up the Python backend, and configures the necessary directories and permissions.

- **`monitoring.sh`**  
  A log-watching script that periodically scans NGINX’s `error.log` for new error entries and sends them to a configured Slack channel using a webhook URL.

- **Python Backend (`app.py`)**  
  A simple Flask/FastAPI app exposing endpoints like `/lib/act` or `/home/user/`, some of which deliberately raise errors to simulate production failures.

- **NGINX Configuration**  
  Acts as a reverse proxy forwarding requests to the backend app and logging access and error events.

- **Slack Webhook Integration**  
  Real-time notifications are sent to a Slack channel whenever a new error is detected.

---

## 🔁 Workflow

1. A user hits a frontend (or browser/curl) endpoint.
2. NGINX forwards the request to the Python backend.
3. If the backend fails, the error is logged in `/var/log/nginx/error.log`.
4. `monitoring.sh` detects the error.
5. An alert message is posted to a Slack channel.

---

## 🔧 Technologies Used

- 🐚 Shell scripting (`bash`)
- 🧭 NGINX (Reverse Proxy & Logging)
- 🐍 Python (`Flask` or `FastAPI`)
- 💬 Slack Webhook API
- 🐧 Ubuntu/Linux


## 🎥 Demo Video

Watch a 3-minute walkthrough of this project in action:

[![Watch the demo](https://img.youtube.com/vi/-xzWyFptNZg/0.jpg)](https://youtu.be/-xzWyFptNZg)

> 🔗 [Click here to watch the demo on YouTube](https://youtu.be/-xzWyFptNZg)
