# SIMPLE Infrastructure Project - Complete Walkthrough

## 🚀 Overview

This comprehensive walkthrough demonstrates the deployment of a **production-grade, high-availability infrastructure** using the SIMPLE Infrastructure Project. This guide combines the **VM Toolkit** for VM management with the **Ansible automation** for infrastructure deployment.

### 🎯 What You'll Build

A complete multi-tier application stack with:
- **Load Balancers**: HAProxy with Keepalived (VIP: 192.168.122.100)
- **Application Servers**: Flask application with Docker containers
- **Cache Layer**: Redis Master-Slave cluster
- **Database Layer**: PostgreSQL with pgpool-II failover
- **Monitoring**: Health checks and infrastructure metrics

### 🏗️ Architecture Diagram

```
Internet → [VIP: 192.168.122.100] → Load Balancers (lb1/lb2)
                                    ↓
Application Servers (app1/app2) ←→ Redis (redis1/redis2)
                                    ↓
Database (db1/db2) with pgpool-II
```

---

## 📋 Prerequisites

### System Requirements
- **Host OS**: Ubuntu 22.04 or similar Linux distribution
- **CPU**: 4+ cores recommended
- **RAM**: 16GB+ recommended (32GB+ for optimal performance)
- **Storage**: 200GB+ free space
- **Network**: KVM/QEMU virtualization support

### Required Software
```bash
# Install virtualization tools
sudo apt update
sudo apt install -y qemu-kvm libvirt-daemon-system virtinst genisoimage libxml2-utils

# Install Ansible
sudo apt install -y ansible

# Install additional tools
sudo apt install -y git curl wget htop
```

### VM Toolkit Setup
1. **Download the VM Toolkit**:
   ```bash
   # The VM toolkit should be located at: /mnt/Storage/VMs/prod/vm_toolkit.sh
   ls -la /mnt/Storage/VMs/prod/vm_toolkit.sh
   ```

2. **Prepare Base Image**:
   ```bash
   cd /mnt/Storage/VMs/prod
   # Ensure base.qcow2 exists (Ubuntu 22.04 base image)
   ls -la base.qcow2
   ```

---

## 🖥️ Phase 1: VM Infrastructure Setup

### Step 1: Create VMs Using VM Toolkit

```bash
cd /mnt/Storage/VMs/prod

# Make the toolkit executable
chmod +x vm_toolkit.sh

# Create all VMs (this will take several minutes)
./vm_toolkit.sh create
```

**What happens during VM creation:**
- Creates 7 VMs with standardized configurations (15GB disk, 1536MB RAM, 2 vCPUs each)
- Assigns static IPs in the 192.168.122.0/24 network
- Configures cloud-init for automatic setup
- Enables shared memory support for better performance

### Step 2: Verify VM Creation

```bash
# Check VM status
./vm_toolkit.sh list

# Expected output:
# Id   Name   State
# ------------------
# 1    lb1    running
# 2    lb2    running
# 3    app1   running
# 4    app2   running
# 5    redis1 running
# 6    redis2 running
# 7    db1    running
# 8    db2    running
```

### Step 3: Test SSH Access

```bash
# Test SSH to load balancer 1
./vm_toolkit.sh ssh lb1

# You should see:
# VM: lb1 (192.168.122.101)
# Login with user 'root' and password 'mysecret123'
```

**Default Credentials:**
- **Username**: `root`
- **Password**: `mysecret123`

### Step 4: Verify Network Configuration

```bash
# From within a VM, check network
ip addr show
ping 192.168.122.1  # Gateway test
ping 8.8.8.8        # Internet connectivity test
```

---

## 🔧 Phase 2: Infrastructure Deployment

### Step 1: Clone the Infrastructure Project

```bash
# If not already cloned
git clone https://github.com/marufmoinuddin/SIMPLE-Infrastructure-Project.git
cd SIMPLE-Infrastructure-Project
```

### Step 2: Review Project Structure

```bash
tree -L 2
# Output:
# .
# ├── README.md
# ├── ansible_scripts/
# │   ├── 00-master-deployment.yml
# │   ├── 00-prerequisites-setup.yml
# │   ├── 01-loadbalancer-setup.yml
# │   ├── 02-app-setup-enhanced.yml
# │   ├── 02-app-setup.yml
# │   ├── 03-redis-setup.yml
# │   ├── 04-database-setup.yml
# │   ├── 05-integration-testing.yml
# │   └── inventory.ini
# ├── application/
# │   ├── enhanced_app.html
# │   ├── enhanced_backend.py
# │   ├── requirements.txt
# │   ├── static/
# │   └── templates/
# ├── documentation/
# │   ├── infrastructure-guidebook.md
# │   └── presentation-flow.md
# └── scripts/
#     ├── demo-commands.sh
#     └── quick-verify.sh
```

### Step 3: Configure Ansible Inventory

```bash
# Review the inventory file
cat ansible_scripts/inventory.ini

# The inventory should match your VM IPs:
# [loadbalancers]
# lb1 ansible_host=192.168.122.101
# lb2 ansible_host=192.168.122.102
# [appservers]
# app1 ansible_host=192.168.122.111
# app2 ansible_host=192.168.122.112
# [redis]
# redis1 ansible_host=192.168.122.121
# redis2 ansible_host=192.168.122.122
# [databases]
# db1 ansible_host=192.168.122.131
# db2 ansible_host=192.168.122.132
```

### Step 4: Run Prerequisites Setup

```bash
cd ansible_scripts

# Install system prerequisites on all VMs
ansible-playbook -i inventory.ini 00-prerequisites-setup.yml
```

### Step 5: Deploy Load Balancers

```bash
# Deploy HAProxy and Keepalived
ansible-playbook -i inventory.ini 01-loadbalancer-setup.yml
```

**What gets deployed:**
- HAProxy load balancer on lb1 and lb2
- Keepalived for VIP management (192.168.122.100)
- Health checks and failover configuration

### Step 6: Deploy Application Servers

```bash
# Deploy Flask application with Docker
ansible-playbook -i inventory.ini 02-app-setup-enhanced.yml
```

**What gets deployed:**
- Flask application in Docker containers
- NGINX reverse proxy
- Application health endpoints
- Static file serving

### Step 7: Deploy Redis Cluster

```bash
# Deploy Redis master-slave cluster
ansible-playbook -i inventory.ini 03-redis-setup.yml
```

**What gets deployed:**
- Redis master on redis1 (192.168.122.121)
- Redis slave on redis2 (192.168.122.122)
- Replication configuration
- Persistence settings

### Step 8: Deploy Database Layer

```bash
# Deploy PostgreSQL with pgpool-II
ansible-playbook -i inventory.ini 04-database-setup.yml
```

**What gets deployed:**
- PostgreSQL master on db1 (192.168.122.131)
- PostgreSQL slave on db2 (192.168.122.132)
- pgpool-II connection pooling and failover
- Database replication

### Step 9: Run Integration Tests

```bash
# Run comprehensive integration tests
ansible-playbook -i inventory.ini 05-integration-testing.yml
```

---

## 🧪 Phase 3: Testing and Verification

### Step 1: Quick Infrastructure Verification

```bash
# Run the verification script
./scripts/quick-verify.sh
```

### Step 2: Test Application Access

```bash
# Test via load balancer VIP
curl http://192.168.122.100

# Test health endpoint
curl http://192.168.122.100/health

# Test individual application servers
curl http://192.168.122.111:8080
curl http://192.168.122.112:8080
```

### Step 3: Test Database Connectivity

```bash
# Test via pgpool (from any VM)
psql -h 192.168.122.131 -p 9999 -U atom_app_user -d atom_app_db
```

### Step 4: Test Redis Connectivity

```bash
# Test Redis master
redis-cli -h 192.168.122.121 -p 6379 ping

# Test Redis slave
redis-cli -h 192.168.122.122 -p 6379 ping
```

---

## 🎬 Phase 4: Demo and Presentation

### Step 1: Run Demo Commands

```bash
# Execute the demo presentation
./scripts/demo-commands.sh
```

### Step 2: Access Web Dashboard

```bash
# Open in browser
firefox http://192.168.122.100

# Or use curl to see the dashboard
curl http://192.168.122.100/enhanced_app.html
```

### Step 3: Monitor Infrastructure Health

```bash
# Check all component health
curl http://192.168.122.100/health
curl http://192.168.122.111:8080/health
curl http://192.168.122.112:8080/health
```

---

## 🔧 Phase 5: Maintenance and Troubleshooting

### VM Management Commands

```bash
cd /mnt/Storage/VMs/prod

# List all VMs and their status
./vm_toolkit.sh list

# SSH to specific VM
./vm_toolkit.sh ssh app1

# Destroy and recreate all VMs
./vm_toolkit.sh recreate

# Clean up everything
./vm_toolkit.sh clean
```

### Infrastructure Management

```bash
cd SIMPLE-Infrastructure-Project/ansible_scripts

# Redeploy specific component
ansible-playbook -i inventory.ini 02-app-setup-enhanced.yml

# Run only on specific hosts
ansible-playbook -i inventory.ini 02-app-setup-enhanced.yml --limit appservers

# Check Ansible connectivity
ansible -i inventory.ini all -m ping
```

### Common Troubleshooting

#### VM Issues
```bash
# Check VM console logs
virsh console lb1

# View VM XML configuration
virsh dumpxml lb1

# Check VM memory configuration
./vm_toolkit.sh check-mem lb1
```

#### Network Issues
```bash
# Test connectivity between VMs
ping 192.168.122.111  # From lb1

# Check firewall rules
sudo firewall-cmd --list-all
```

#### Application Issues
```bash
# Check Docker containers
docker ps -a

# View application logs
docker logs simple-enhanced-app

# Restart application
docker restart simple-enhanced-app
```

---

## 📊 Phase 6: Monitoring and Metrics

### Health Check Endpoints

```bash
# Load balancer health
curl http://192.168.122.100/health

# Application server health
curl http://192.168.122.111:8080/health
curl http://192.168.122.112:8080/health

# Individual component checks
curl http://192.168.122.111:8081/health  # Dedicated health port
```

### Performance Monitoring

```bash
# Check Redis performance
redis-cli -h 192.168.122.121 info stats

# Check PostgreSQL connections
psql -h 192.168.122.131 -p 9999 -U pgpool_admin -d postgres -c "SHOW POOL_NODES"

# Monitor system resources
htop
```

---

## 🏆 Success Criteria

Your infrastructure is successfully deployed when:

✅ **All VMs are running**: `./vm_toolkit.sh list` shows 8 running VMs
✅ **Load balancer responds**: `curl http://192.168.122.100` returns HTML
✅ **Application is healthy**: `curl http://192.168.122.100/health` returns "healthy"
✅ **Database is accessible**: Can connect via pgpool-II
✅ **Redis is responsive**: Both master and slave respond to pings
✅ **Failover works**: VIP moves when primary LB fails
✅ **Web dashboard loads**: `http://192.168.122.100/enhanced_app.html` shows dashboard

---

## 📚 Additional Resources

- **Infrastructure Guidebook**: `documentation/infrastructure-guidebook.md`
- **Presentation Flow**: `documentation/presentation-flow.md`
- **VM Toolkit Documentation**: Check comments in `vm_toolkit.sh`
- **Ansible Playbooks**: Review individual playbooks for detailed configuration

---

## 🎯 Next Steps

1. **Customize the Application**: Modify `application/enhanced_backend.py`
2. **Add Monitoring**: Integrate Prometheus/Grafana
3. **Implement CI/CD**: Add automated deployment pipelines
4. **Security Hardening**: Configure SSL certificates and firewall rules
5. **Backup Strategy**: Implement database and configuration backups

---

**🎉 Congratulations!** You have successfully deployed a production-grade, high-availability infrastructure using the SIMPLE Infrastructure Project and VM Toolkit. Your multi-tier application stack is now running with load balancing, caching, and database failover capabilities.</content>
<parameter name="filePath">/home/maruf/git/SIMPLE-Infrastructure-Project/WALKTHROUGH.md
