# Bio-IT Observability Pipeline: Medical Log Monitor

## Overview
This project is a real-time observability system designed to monitor medical device logs within a containerized environment. It automates the detection of critical health events, categorizes them by severity using color-coded alerts, and archives critical failures for further medical analysis.

## Key Features
- **Real-time Monitoring**: Uses an event-driven approach to process log streams instantly.
- **Dockerized Architecture**: Completely isolated and portable using Docker and Docker Compose.
- **Color-Coded Alerting**: High-visibility alerts for different severity levels:
  - 🟢 **INFO**: Normal system operations.
  - 🟡 **WARNING**: Potential issues (e.g., low oxygen, temperature fluctuations).
  - 🔴 **CRITICAL**: Immediate action required (e.g., system failure, low backup power).
- **Persistent Storage**: Automatically logs all `CRITICAL` events into a dedicated file for auditing.

## Tech Stack
- **Docker & Docker Compose**: Container orchestration and environment isolation.
- **Alpine Linux**: Lightweight base image for optimal resource usage.
- **Bash Scripting**: Logic for pattern matching and log processing.
- **Git**: Version control and development lifecycle management.

## Project Structure
```text
.
├── Dockerfile              # Instructions to build the monitor image
├── docker-compose.yml      # Orchestration file for automated deployment
├── monitor.sh              # The core logic (Bash script)
├── med_app.log             # Input log file (monitored by the system)
└── critical_alerts.log     # Output log file (auto-generated for critical events)
