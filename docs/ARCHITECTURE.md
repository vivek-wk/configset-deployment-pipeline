# Wolters Kluwer Global Architecture - EnvSet Integration Architecture Document

## Executive Summary
This document defines the Solution Architecture and DevOps Engineering Design for the automated **Environment Fileset (EnvSet) Integration Pipeline**. The pipeline automates the end-to-end deployment lifecycle for Wolters Kluwer Global Architecture EU environments (**STG** and **PROD**).

---

## 1. High-Level Architecture Diagram

```mermaid
flowchart TD
    A[User Trigger / GitHub Action UI] --> B[GitHub Action Runner]
    B --> C[Step 0: Server Mapping Resolver]
    C --> D[Step 1: Package & Directory Validation]
    D --> E[Step 2: Enable Maintenance Mode]
    E --> F[Step 3: Update PCI2GA config-wknl.xml]
    F --> G[Step 4: Restart PCI2GA Service]
    G --> H[Step 5: Copy CVC Package & Start Time Record]
    H --> I[Step 6: Monitor pciTransformer.log]
    I -- Auto-Recovery (Inactive 30m) --> IR[Clean picked-up & in-progress, Restart PCI2GA, Resubmit CVC]
    IR --> I
    I -- SUCCESS --> J[Step 7: Process ART & ATS Packages]
    J --> K[Step 8 & 9: Verify EnvFiles & Create Env<Number> Folder]
    K --> L[Step 10 & 11: Sequential GA Import & Status Validation]
    L --> M[Step 12: Calculate Duration Metrics]
    M --> N[Step 2 Cleanup: Disable Maintenance Mode]
    N --> O[Step 13: MS Teams Notification Summary]
```

---

## 2. Server Mapping & System Matrix

| Environment | Server Name | IP Address | CDC Reporter URL | PCI2GA URL | Config Path |
|---|---|---|---|---|---|
| **STG** | `wkgaeuslpci2ga01` | `10.73.144.124` | `http://10.73.144.124:8080/cdc/packages` | `http://10.73.144.124:8085` | `/ftp/WKNL-LTR/input/staging/config/Env{number}` |
| **PROD** | `wkgaeuplpci2ga01` | `10.85.129.147` | `http://10.85.129.147:8080/cdc/packages` | `http://10.85.129.147:8085` | `/ftp/WKNL-LTR/input/production/config/Env{number}` |

---

## 3. End-to-End Sequence Diagram

```mermaid
sequenceDiagram
    autonumber
    actor DevOps as Engineer/Pipeline User
    participant GHA as GitHub Actions Runner
    participant PCI as PCI2GA Server (cus01)
    participant GA as GA Import / IntApp

    DevOps->>GHA: Trigger Workflow / Interactive Script (EnvSet=1947, Env=STG)
    GHA->>PCI: Step 1: Validate Env1947 directory (CVC, ART, ATS)
    PCI-->>GHA: Validation Report (SUCCESS)
    GHA->>PCI: Step 2: Enable Maintenance Mode
    GHA->>PCI: Step 3: Backup config-wknl.xml & Update <environmentVersion>
    GHA->>PCI: Step 4: Run ./srv-stop.sh, kill lingering java, run ./srv-start.sh (user cus01)
    GHA->>PCI: Step 5: Copy CVC package & Record START TIME
    GHA->>PCI: Step 6: Tail pciTransformer.log until SUCCESS
    opt Auto Recovery Triggered
        GHA->>PCI: Clean picked-up & in-progress, restart PCI2GA, resubmit CVC
    end
    GHA->>PCI: Step 7: Copy and transform ART & ATS
    GHA->>PCI: Step 8 & 9: Verify EnvFiles and move to Env1947 folder
    loop Strictly Sequential Import (Part 1 & Part 2)
        GHA->>GA: Step 10 & 11: Import package and validate status
        GA-->>GHA: Status (PACK: SUCCESS, IPACK: SUCCESS)
    end
    GHA->>GHA: Step 12: Calculate Total Duration (Start -> End)
    GHA->>PCI: Step 2 Cleanup: Disable Maintenance Mode
    GHA->>DevOps: Step 13: Teams Webhook Notification Summary
```
