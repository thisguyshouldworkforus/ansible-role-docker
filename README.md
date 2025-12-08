# ansible-role-docker

## Overview

This role installs and configures **Docker Engine** on a RHEL-style homelab server.  
It sets up the official Docker repository, optionally configures the NVIDIA Container Toolkit when a supported GPU is found, manages daemon overrides, and adds a convenience profile script for managing Docker services.  
The result is a Docker host that is GPU-aware (when applicable) and exposes Docker in a predictable, tuned configuration.

---

## Task-by-Task Breakdown

### Scanning for NVIDIA GPUs

This task runs `lspci` and searches for specific GPU models (e.g., Quadro P1000, RTX A5000).  
The output is stored in `gpu_info` and is used to decide whether to enable GPU-specific configuration later.  
It lets the role behave differently on GPU and non-GPU hosts without hardcoding that decision.

### Setting a “has_gpu” Fact

If the GPU scan finds a supported device, this task sets an Ansible fact `has_gpu: true`.  
Subsequent tasks check this fact in their `when` clauses to determine whether the NVIDIA container runtime should be installed and configured.  
It keeps the play lightweight on hosts without GPUs.

### Adding the Docker Repository

This task configures the official `docker-ce-stable` yum repository.  
It points DNF to Docker’s upstream packages (docker-ce, cli, plugins) and installs the repo’s GPG key.  
Using the official repo ensures you’re getting actively maintained Docker builds rather than stale distribution packages.

### Adding the NVIDIA Container Toolkit Repository (GPU Hosts Only)

If `has_gpu` is true, the role adds the NVIDIA Container Toolkit repository.  
This repository provides `nvidia-container-toolkit` and related utilities used to make GPUs visible inside containers.  
It’s only added when a GPU exists, to keep non-GPU hosts clean.

### Dropping Cached DNF Metadata

This task expires the existing DNF cache.  
It’s a housekeeping step that ensures the next metadata refresh pulls fresh repo information, including Docker’s and NVIDIA’s new repos.

### Rebuilding the DNF Cache

Immediately after expiring the cache, the role triggers a cache rebuild.  
This ensures that package lookups for Docker and NVIDIA tools work reliably on the next install tasks.

### Installing Docker Engine Packages

This task installs the core Docker components: engine, CLI, and the Docker Compose plugin (among others listed in the task).  
It’s the core of making the host a usable Docker node.  
After this step, `docker` and `docker compose` are available on the system.

### Installing NVIDIA Container Toolkit (GPU Hosts Only)

On GPU-equipped hosts, this task installs `nvidia-container-toolkit`.  
This package provides integration between Docker and the NVIDIA driver stack so containers can request GPU access.  
It’s skipped on hosts that don’t have a GPU, keeping their environment minimal.

### Configuring the NVIDIA Container Runtime (GPU Hosts Only)

This task runs `nvidia-ctk runtime configure` and checks the result.  
It updates Docker’s configuration to register the NVIDIA runtime, so containers can use `--gpus` and similar options.  
If the command fails, the task is marked failed so you can see and fix GPU runtime issues early.

### Placing the Docker Daemon Configuration

Here the role copies a `daemon.json` into `/etc/docker/daemon.json`.  
This file typically sets Docker to listen both on the Unix socket and optionally a TCP socket, and may define default runtimes or other tunables.  
It gives you centralized control over Docker’s global behavior.

### Creating the Docker Service Override Directory

This task ensures `/etc/systemd/system/docker.service.d/` exists.  
Systemd uses this folder to hold override snippets that adjust how the `docker.service` unit is started.  
Creating the directory is required before placing any override files.

### Installing the Docker Service Override File

The role then copies `docker-override.conf` into the override directory.  
This override clears and redefines the `ExecStart` line so Docker starts exactly the way you want (e.g., with specific flags).  
It’s how the role takes precise control over the daemon startup command.

### Restarting and Enabling the Docker Service

This task restarts the `docker` service, enables it at boot, and triggers a daemon reload.  
It ensures your new daemon.json and override configuration are actually used and that Docker comes up after a reboot.

### Installing the Docker Profile Script

Finally, the role copies `docker.sh` into `/etc/profile.d/docker.sh` and makes it executable.  
This script exposes helper functions and shortcuts for managing Docker containers and services from the shell.  
Because it lives in `/etc/profile.d`, those helpers are automatically available to users who log into the host.

---
