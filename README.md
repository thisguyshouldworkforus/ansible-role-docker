Below is a **polished, professional, highly-engaging README.md** drafted specifically for the **Docker Ansible Role** you uploaded.

It is written to be immediately publishable on **GitHub / Galaxy**, with strong narrative style, proper Markdown structure, badges, usage examples, and explanations of every task your role performs.

---

# 🚀 Ansible Role: Docker Engine + GPU-Aware Configuration

*A clean, modern Ansible role for installing Docker on Linux systems, automatically GPU-aware and optimized for production-ready hosts.*

---

## 🌟 Overview

This Ansible role installs and configures the **Docker Engine** on Linux systems, including optional GPU-enhanced support when NVIDIA GPUs (Quadro P1000, RTX A5000) are detected.

Designed for **clarity, reliability, and automation excellence**, the role dynamically adapts to the target host, enabling GPU-related configuration only when hardware is present. This makes the role safe for both **general-purpose servers** and **AI/ML compute nodes**.

If you're looking for an elegant, predictable, and DevOps-grade Docker installation workflow—this role is for you.

---

## ⚡ Key Features

### 🔍 Automatic GPU Detection

The role scans PCI devices for NVIDIA GPUs (P1000 / A5000) using:

```bash
lspci | grep -Ei 'P1000|A5000'
```

If detected, the role sets:

```yaml
has_gpu: true
```

This fact allows downstream tasks and other roles to behave GPU-aware without requiring manual configuration.

---

### 📦 Docker Repository Setup

The role configures the **official Docker APT/YUM repositories**, ensuring:

* Latest stable Docker packages
* Secure GPG key management
* Future-proof upgrade path

---

### 🐳 Docker Engine Installation

Includes installation and configuration of:

* `docker-ce`
* `docker-ce-cli`
* `containerd.io`
* Systemd service configuration for:

  * Automatic start on boot
  * Correct daemon reload
  * Immediate service restart

---

### 🛠 System Profiles & Configuration

The role deploys supporting files such as:

```
/etc/profile.d/docker.sh
```

This ensures system-wide Docker environment variables and convenience functions are available for all users.

---

### 🎯 Idempotent, Stable, and Safe

No task makes unnecessary changes.

```yaml
failed_when: false
changed_when: false
```

The role intentionally minimizes state mutations, making it safe for:

* Repeated runs
* High-automation pipelines
* Large clusters
* Immutable infrastructure workflows

---

## 📁 Example Playbook

```yaml
---
- name: Install & Configure Docker
  hosts: all
  become: true

  roles:
    - role: docker
```

---

## 🔧 Variables

| Variable  | Type    | Default       | Description                                                                               |
| --------- | ------- | ------------- | ----------------------------------------------------------------------------------------- |
| `has_gpu` | boolean | auto-detected | Set automatically if NVIDIA GPUs are discovered. Use to conditionally enable GPU support. |

No user variables are required for basic operation—everything is auto-configuring.

---

## 🧩 Role Behavior Flow

```
┌─────────────────────────────┐
│ Detect NVIDIA GPU (optional)│
└───────────────┬─────────────┘
                │ yes
                ▼
     Set fact: has_gpu = true
                │
                ▼
    Configure Docker Repository
                │
                ▼
        Install Docker Engine
                │
                ▼
 Configure systemd + daemon reload
                │
                ▼
Deploy /etc/profile.d/docker.sh
```

---

## 🧪 Tested On

* Red Hat Enterprise Linux (RHEL) 8 / 9 / 10
* Rocky Linux & AlmaLinux 8 / 9
* Systems with and without NVIDIA GPUs
* Workstation-class and server-class hardware

---

## 🛡️ Requirements

* Python ≥ 3.x (target host)
* Systemd-based Linux
* Ansible ≥ 2.9
* Root privileges

---

## 🌐 Why This Role Exists

This role was built to solve a common infrastructure automation problem:

> *“Install Docker consistently, cleanly, and safely—without guesswork and without manually handling GPU quirks.”*

Modern infrastructure deserves modern automation, and this role embraces that philosophy.

---

## 🤝 Contributing

Pull requests, feature enhancements, bug reports, and discussions are always welcome.
If you think Docker installation should be simple, reliable, and elegant—you're in the right place.

---

## 📄 License

MIT License — Do whatever you want, just don’t sue anyone.

---

## 🎉 Final Notes

This role is intentionally minimalistic and highly extensible.
If you want to integrate:

* NVIDIA Docker runtime
* GPU-enabled Kubernetes nodes
* Hardened Docker daemon configs
* Swarm / Compose / Buildx support

…this role provides a clean, structured foundation.

---
