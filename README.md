# EnvSet Integration Automation Pipeline

> Enterprise DevOps Automation Project for Wolters Kluwer Global Architecture Environments (**STG** & **PROD**).

---

## 📌 Executive Summary

This repository contains the production-ready automation pipeline for **Environment Fileset (EnvSet / ConfigSet)** deployment lifecycle. It replaces manual execution with an automated, idempotent, resilient Linux Bash & GitHub Actions pipeline equipped with auto-recovery, sequential package transformation, duration metrics calculation, and MS Teams notification integration.

---

## 🖥 Server Matrix

| Environment | Server Name | IP Address | CDC Reporter URL | PCI2GA URL |
|---|---|---|---|---|
| **STG** | `wkgaeuslpci2ga01` | `10.73.144.124` | `http://10.73.144.124:8080/cdc/packages` | `http://10.73.144.124:8085` |
| **PROD** | `wkgaeuplpci2ga01` | `10.85.129.147` | `http://10.85.129.147:8080/cdc/packages` | `http://10.85.129.147:8085` |

---

## 🛠 Tech Stack

- **Scripting & Logic:** Linux Bash (`.sh`)
- **CI/CD Orchestration:** GitHub Actions (`workflow_dispatch`)
- **Configuration:** YAML (`config/environments.yaml`)
- **Target OS & Runner:** Linux (Self-hosted GitHub Runner)
- **Target User:** `cus01`
- **Notifications:** MS Teams Webhook Cards

---

## 🚀 How to Run

### Method 1: Interactive CLI Execution (Direct Shell Prompt)
Run the master interactive Bash script:

```bash
./scripts/run_pipeline.sh
```

**Interactive Prompts:**
```text
Select Target Environment:
  1) STG  (wkgaeuslpci2ga01 - 10.73.144.124)
  2) PROD (wkgaeuplpci2ga01 - 10.85.129.147)
Enter choice [1 or 2, default: 1]: 1

Enter ConfigSet / EnvSet Number (e.g., 1947): 1947

Enable Dry-Run Mode? (y/N): n
```

### Method 2: GitHub Actions Workflow UI
1. Go to **Actions** -> **EnvSet Deployment Automation Pipeline**.
2. Click **Run workflow**.
3. Select `environment` (**STG** or **PROD**), input `envset_number` (e.g. `1947`), and toggle `dry_run`.
4. Click **Run workflow**.

---

## 🧪 Automated Testing

Execute the test suite to validate all 14 Bash automation scripts in dry-run mode:

```bash
./tests/test_pipeline.sh
```

---

## 📊 Deployment Notification & Summary Output Mockup

### Microsoft Teams Summary Message Format

```text
Environment Fileset Processing

EnvSet: 1947
Environment: STG

Start Time: 10:15 IST
End Time: 13:42 IST

Total Duration:
3 Hours 27 Minutes

PCI2GA:
SUCCESS

Import:
SUCCESS

Overall:
SUCCESS
```

---

## 📖 Operational Documentation

- **[Solution Architecture & Sequence Diagrams](docs/ARCHITECTURE.md)**
- **[Operational Runbook & Troubleshooting Guide](docs/RUNBOOK.md)**
