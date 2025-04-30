# Redis Bootstrap Provisioning

This repository contains a fully automated and production-ready Redis setup script, optimized for Amazon EC2 instances using Amazon Linux 2023 or Ubuntu 22.04+.

## 🔧 What It Does

- Installs Redis 7.2.4 from source
- Automatically configures memory based on instance type
- Secures Redis with a generated or provided password
- Sets up systemd for Redis and auto-configuration on every boot
- Stores password securely in `/etc/redis/.redis-pass`
- Optional `redis-show-pass` helper to retrieve it

## 📦 Repository Structure

```
.
├── provision-redis.sh            # One-shot installer script
├── redis-autoconfig.sh           # Auto-reconfigures memory at boot
├── redis-show-pass               # Simple CLI to show Redis password
├── systemd/
│   ├── redis.service             # systemd unit for Redis
│   └── redis-autoconfig.service  # systemd unit for memory reconfig
├── README.md
├── LICENSE
└── .gitignore
```

## 🚀 Usage

### 1. Launch EC2 Instance

Amazon Linux 2023 or Ubuntu 22.04 preferred. You can use this script in EC2 User Data:

```bash
#!/bin/bash
echo "REDIS_PASSWORD=super-secret-password" > /etc/redis/boot-env
cd /tmp
git clone https://github.com/jeffwray/redis-bootstrap.git
cd redis-bootstrap
chmod +x provision-redis.sh
./provision-redis.sh
```

If no password is provided, one will be generated and stored at `/etc/redis/.redis-pass`.

### 2. Reboots Automatically Tune Memory

Each time the instance boots, Redis will:

- Recalculate `maxmemory` to use 70% of total RAM
- Restart with updated settings

### 3. View the Current Redis Password

```bash
redis-show-pass
```

---

## 🧠 Notes

- Compatible with both Graviton and x86 instances
- Use this with custom AMIs or as part of an EC2 Launch Template
- The `redis-autoconfig.service` ensures memory reconfig on every reboot

## 🪪 License

MIT — see [LICENSE](./LICENSE) for details.
