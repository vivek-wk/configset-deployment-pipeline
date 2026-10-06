# Wolters Kluwer Global Architecture - EnvSet Deployment Runbook

## Overview
This Runbook provides operational procedures for engineers managing the automated **EnvSet Deployment Automation** using Linux Bash scripts.

---

## 1. System Matrix

| Environment | Server Name | IP Address | CDC Reporter URL | PCI2GA URL |
|---|---|---|---|---|
| **STG** | `wkgaeuslpci2ga01` | `10.73.144.124` | `http://10.73.144.124:8080/cdc/packages` | `http://10.73.144.124:8085` |
| **PROD** | `wkgaeuplpci2ga01` | `10.85.129.147` | `http://10.85.129.147:8080/cdc/packages` | `http://10.85.129.147:8085` |

---

## 2. Execution Methods

### Option A: Interactive Bash CLI (Host / Server execution)
Run the automation directly from a terminal on the self-hosted Linux runner or target host:

```bash
cd /path/to/configset-deployment-pipeline
./scripts/run_all.sh
```

**Prompts:**
1. Target Environment (`1: STG` or `2: PROD`)
2. ConfigSet / EnvSet Number (e.g. `1947`)
3. Dry-Run Mode (`y/N`)
