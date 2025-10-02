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

### 4. Creating an EC2 Launch Template

For consistently deploying Redis instances:

1. Open the EC2 console and navigate to "Launch Templates"
2. Click "Create launch template"
3. Fill in the basic details:
   - Name: `redis-server-template`
   - Description: `Redis server with auto-configuration`
4. Choose Amazon Linux 2023 or Ubuntu 22.04 AMI
5. Select your desired instance type (t3.micro, r6g.large, etc.)
6. Configure your key pair and network settings
7. Expand the "Advanced details" section
8. In the "User data" field, paste the following:

```bash
#!/bin/bash
# Optional: Set password explicitly
# echo "REDIS_PASSWORD=your-strong-password" > /etc/redis/boot-env
cd /tmp
git clone https://github.com/jeffwray/redis-bootstrap.git
cd redis-bootstrap
chmod +x provision-redis.sh
./provision-redis.sh
```

9. Add any tags or resource groups as needed
10. Click "Create launch template"

To launch instances using this template:
- Go to "Launch Templates" in the EC2 console
- Select your template and click "Actions" > "Launch instance from template"
- Review settings and click "Launch instance"

---

## 🧠 Notes

- Compatible with both Graviton and x86 instances
- Use this with custom AMIs or as part of an EC2 Launch Template
- The `redis-autoconfig.service` ensures memory reconfig on every reboot

## 🪪 License

MIT — see [LICENSE](./LICENSE) for details.
