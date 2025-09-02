# SIMPLE Infrastructure Shortcut Guidebook

## 🚀 Quick Overview
**Infrastructure:** High-Availability Multi-Tier Application Stack  
**Status:** Production-Ready (100% Operational)  
**Network:** 192.168.122.0/24 (KVM/QEMU VMs)  
**Containerization:** Docker + Docker Compose  
**Application:** Enhanced SIMPLE v2.0.0 (Flask + Real Integration)

## 🏗️ Architecture Summary
```
Internet → [VIP: 192.168.122.100] → Load Balancers (lb1/lb2)
                                    ↓
Application Servers (app1/app2) ←→ Redis (redis1/redis2)
                                    ↓
Database (db1/db2) with pgpool-II
```

**Components:**
- **Frontend:** NGINX + KeepAlived (Docker containers, SSL Termination, HA)
- **Application:** Flask App in Docker containers (Ports 8080/8081)
- **Cache:** Redis Master-Slave (Docker containers, Port 6379)
- **Database:** PostgreSQL 15 + pgpool-II (Docker containers, Ports 5432/9999)

## 📋 Docker-Based Setup Process

### Prerequisites Setup
```bash
# Install Docker and Docker Compose on each VM
sudo dnf update -y
sudo dnf install -y docker docker-compose

# Start and enable Docker
sudo systemctl enable docker
sudo systemctl start docker

# Add user to docker group (optional)
sudo usermod -aG docker $USER
```

### Load Balancer Setup (lb1/lb2)
```bash
# Create directories
sudo mkdir -p /opt/docker/loadbalancer/{nginx,keepalived}

# Copy configuration files
sudo cp nginx.conf /opt/docker/loadbalancer/nginx/
sudo cp keepalived.conf /opt/docker/loadbalancer/keepalived/

# Deploy with Docker Compose
cd /opt/docker/loadbalancer
sudo docker-compose up -d

# Check status
sudo docker-compose ps
sudo docker logs nginx-lb-lb1
```

### Application Setup (app1/app2)
```bash
# Create directories
sudo mkdir -p /opt/docker/application

# Copy application files and requirements
sudo cp enhanced_backend.py /opt/docker/application/
sudo cp requirements.txt /opt/docker/application/
sudo cp -r templates/ /opt/docker/application/
sudo cp -r static/ /opt/docker/application/

# Deploy with Docker Compose
cd /opt/docker/application
sudo docker-compose up -d

# Check status
sudo docker-compose ps
sudo docker logs simple-enhanced-app
```

### Redis Setup (redis1/redis2)
```bash
# Create directories
sudo mkdir -p /opt/docker/redis/{config,data,logs}

# Copy Redis configuration
sudo cp redis.conf /opt/docker/redis/config/

# Deploy with Docker Compose
cd /opt/docker/redis
sudo docker-compose up -d

# Check status
sudo docker-compose ps
sudo docker exec redis redis-cli -a atom_redis_secure_2025 ping
```

### Database Setup (db1/db2)
```bash
# Create directories for persistent data
sudo mkdir -p /opt/docker/postgres/db1/data /opt/docker/postgres/db1/config
sudo mkdir -p /opt/docker/postgres/db2/data /opt/docker/postgres/db2/config
sudo mkdir -p /opt/docker/pgpool/config /opt/docker/pgpool/logs

# Set proper permissions
sudo chown -R 999:999 /opt/docker/postgres/db1/data
sudo chown -R 999:999 /opt/docker/postgres/db2/data

# Copy configuration files
sudo cp postgresql.conf /opt/docker/postgres/db1/config/
sudo cp postgresql.conf /opt/docker/postgres/db2/config/
sudo cp pg_hba.conf /opt/docker/postgres/db1/config/
sudo cp pg_hba.conf /opt/docker/postgres/db2/config/
sudo cp pgpool.conf /opt/docker/pgpool/config/
sudo cp pool_hba.conf /opt/docker/pgpool/config/

# Deploy PostgreSQL containers with Docker Compose
cd /opt/docker/postgres
sudo docker-compose up -d

# Wait for PostgreSQL to start
sleep 30

# Initialize database and users
sudo docker exec postgresql-db1 psql -U postgres -c "CREATE USER atom_app_user WITH PASSWORD 'atom_app_pass_2025';"
sudo docker exec postgresql-db1 psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE atom_app_db TO atom_app_user;"
sudo docker exec postgresql-db1 psql -U postgres -c "CREATE USER replicator WITH REPLICATION PASSWORD 'atom_repl_secure_2025';"

# Setup replication on db2
sudo docker exec postgresql-db2 psql -U postgres -c "CREATE USER replicator WITH REPLICATION PASSWORD 'atom_repl_secure_2025';"
```

### pgpool-II Setup
```bash
# Deploy pgpool with Docker Compose
cd /opt/docker/pgpool
sudo docker-compose up -d

# Check pgpool status
sudo docker logs pgpool-db1
sudo docker exec pgpool-db1 psql -h localhost -p 9999 -U postgres -c "SHOW POOL_NODES;"
```

### Verification
```bash
cd /mnt/Storage/VMs/prod
./quick-verify.sh
# Expected: 13/13 checks passed
# Tests: HTTP endpoints, TCP ports, VIP failover
```

## 🔧 Component Details

### Load Balancers (lb1/lb2)
- **VIP:** 192.168.122.100 (HTTP)
- **Priority:** lb1:110 (Master), lb2:100 (Backup)
- **Config Path:** `/opt/docker/loadbalancer/nginx/nginx.conf`
- **KeepAlived:** `/opt/docker/loadbalancer/keepalived/keepalived.conf`
- **Test:** `curl http://192.168.122.100`
- **Service Management:** `docker-compose up/down` in `/opt/docker/loadbalancer`

### Application Servers (app1/app2)
- **Ports:** 8080 (App), 8080/health (Health)
- **IPs:** 192.168.122.111 / 192.168.122.112
- **App Path:** `/opt/docker/application`
- **Logs:** `docker logs simple-enhanced-app`
- **Health Check:** `curl http://<IP>:8080/health`
- **Service Management:** `docker-compose up/down` in `/opt/docker/application`

### Redis (redis1/redis2)
- **Port:** 6379
- **Master:** redis1 (192.168.122.121)
- **Slave:** redis2 (192.168.122.122)
- **Password:** `atom_redis_secure_2025`
- **Test:** `docker exec redis redis-cli -a atom_redis_secure_2025 ping`
- **Service Management:** `docker-compose up/down` in `/opt/docker/redis`

### Database (db1/db2)
- **PostgreSQL Port:** 5432
- **pgpool Port:** 9999
- **Master:** db1 (192.168.122.131)
- **Slave:** db2 (192.168.122.132)
- **Database:** `atom_app_db`
- **User:** `atom_app_user` / `atom_app_pass_2025`
- **Test:** `docker exec postgresql-db1 psql -U atom_app_user -d atom_app_db -c "SELECT version();"`
- **Service Management:** `docker-compose up/down` in `/opt/docker/postgres` and `/opt/docker/pgpool`

## 🔑 Key Credentials

| Component | Username | Password | Notes |
|-----------|----------|----------|-------|
| PostgreSQL | postgres | atom_postgres_secure_2025 | Admin |
| PostgreSQL | atom_app_user | atom_app_pass_2025 | App User |
| PostgreSQL | replicator | atom_repl_secure_2025 | Replication |
| pgpool | pgpool_admin | atom_pgpool_admin_2025 | Admin |
| Redis | - | atom_redis_secure_2025 | All |

## 📁 Important Paths

### VM Disks
- **Location:** `/mnt/Storage/VMs/prod/vm_disks/`
- **Base:** `base.qcow2`
- **Individual:** `app1.qcow2`, `db1.qcow2`, etc.

### Cloud-Init ISOs
- **Location:** `/mnt/Storage/VMs/prod/cloud_init_ISOs/`
- **Purpose:** VM initialization configs

### Application Files
- **Enhanced App:** `application/enhanced_app.html`
- **Backend:** `application/enhanced_backend.py`
- **Requirements:** `application/requirements.txt`
- **Templates:** `application/templates/`
- **Static:** `application/static/`
- **Docker Configs:** `/opt/docker/` (on each VM)
- **Logs:** `/opt/docker/*/logs/` (container logs)

## 🔍 Troubleshooting

### Common Issues & Fixes

#### pgpool Not Starting
```bash
# Check container status
docker ps | grep pgpool

# Check pgpool logs
docker logs pgpool-db1

# Restart pgpool container
docker restart pgpool-db1

# Check if PostgreSQL containers are running
docker ps | grep postgresql
```

#### Redis Replication Issues
```bash
# Check master status
docker exec redis-redis1 redis-cli -a atom_redis_secure_2025 info replication

# Check slave status
docker exec redis-redis2 redis-cli -a atom_redis_secure_2025 info replication

# Manual slave setup (if needed)
docker exec redis-redis2 redis-cli -a atom_redis_secure_2025 slaveof 192.168.122.121 6379
```

#### Load Balancer Failover
```bash
# Check KeepAlived container status
docker ps | grep keepalived

# Check KeepAlived logs
docker logs keepalived-lb1

# Check NGINX container status
docker ps | grep nginx

# Test VIP
curl http://192.168.122.100
```

#### Database Connection Issues
```bash
# Test direct PostgreSQL
docker exec postgresql-db1 psql -U atom_app_user -d atom_app_db -c "SELECT version();"

# Test via pgpool
docker exec pgpool-db1 psql -h localhost -p 9999 -U atom_app_user -d atom_app_db -c "SELECT version();"
```

### Logs to Check
- **Application:** `docker logs simple-enhanced-app`
- **Load Balancer:** `docker logs nginx-lb-lb1`
- **KeepAlived:** `docker logs keepalived-lb1`
- **Redis:** `docker logs redis-redis1`
- **PostgreSQL:** `docker logs postgresql-db1`
- **pgpool:** `docker logs pgpool-db1`

## 📊 Monitoring & Health Checks

### Built-in Health Endpoints
- **App Health:** `http://<app-ip>:8080/health`
- **VIP Status:** `http://192.168.122.100` (should return app page)
- **Load Balancer Health:** `http://192.168.122.100/lb-health`

### Service Status Commands
```bash
# Check all services
docker ps

# Check specific containers
docker-compose ps  # in each service directory

# Check container logs
docker logs <container_name>

# Check container resource usage
docker stats

# Network connectivity
ping 192.168.122.100
```

## 🚀 Scaling & Maintenance

### Horizontal Scaling
- **Application:** Add more app servers, update LB config
- **Database:** Add read replicas, update pgpool config
- **Cache:** Add more Redis slaves

### Backup Strategy
- **Database:** pg_dump via cron
- **Redis:** RDB snapshots
- **Configs:** Manual configuration files backup

### Updates
- **Application:** Update Docker image, redeploy
- **Database:** Use pgpool for zero-downtime updates
- **Infrastructure:** Manual configuration updates

## 📚 Reference Documents
- **Full Wiki:** `ATOM_INFRASTRUCTURE_WIKI.md`
- **Architecture:** `FINAL-ARCHITECTURE.md`
- **Presentation:** `presentation-outline.md`
- **Demo Commands:** `demo-commands.sh`

## 📄 Configuration Files

### NGINX Load Balancer Configuration (HTTP Setup)
```nginx
### NGINX Load Balancer Configuration (HTTP Setup)
```nginx
# /opt/docker/loadbalancer/nginx/nginx.conf (Docker container path)
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging format
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    # Performance settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 100M;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    # Include additional configurations
    include /etc/nginx/conf.d/*.conf;
}
```

```nginx
# /opt/docker/loadbalancer/nginx/conf.d/upstream.conf (Docker container path)
# Upstream configuration for application servers
upstream app_backend {
    least_conn;
    keepalive 32;
    
    server 192.168.122.111:8080 max_fails=3 fail_timeout=30s weight=1;
    server 192.168.122.112:8080 max_fails=3 fail_timeout=30s weight=1;
}

# Health check endpoint
upstream health_check {
    server 192.168.122.111:8080;
    server 192.168.122.112:8080;
}
```

```nginx
# /opt/docker/loadbalancer/nginx/conf.d/default.conf (Docker container path)
server {
    listen 80;
    server_name simple.local 192.168.122.100;

    # Load balancer health check
    location /lb-health {
        access_log off;
        return 200 "healthy
";
        add_header Content-Type text/plain;
    }

    # Backend health check proxy
    location /health {
        proxy_pass http://health_check/health;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 5s;
        proxy_send_timeout 10s;
        proxy_read_timeout 10s;
    }

    # Main application proxy
    location / {
        proxy_pass http://app_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Port $server_port;
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
        
        # Buffer settings
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        proxy_busy_buffers_size 8k;
        
        # Keep alive
        proxy_http_version 1.1;
        proxy_set_header Connection "";
    }
}
```
```

```nginx
# /etc/nginx/conf.d/upstream.conf
# Upstream configuration for application servers
upstream app_backend {
    least_conn;
    keepalive 32;
    
    server 192.168.122.111:8080 max_fails=3 fail_timeout=30s weight=1;
    server 192.168.122.112:8080 max_fails=3 fail_timeout=30s weight=1;
}

# Health check endpoint
upstream health_check {
    server 192.168.122.111:8080;
    server 192.168.122.112:8080;
}
```

```nginx
# /etc/nginx/conf.d/default.conf (HTTP Configuration)
server {
    listen 80;
    server_name simple.local 192.168.122.100;

    # Load balancer health check
    location /lb-health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }

    # Backend health check proxy
    location /health {
        proxy_pass http://health_check/health;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 5s;
        proxy_send_timeout 10s;
        proxy_read_timeout 10s;
    }

    # Main application proxy
    location / {
        proxy_pass http://app_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Port $server_port;
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
        
        # Buffer settings
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        proxy_busy_buffers_size 8k;
        
        # Keep alive
        proxy_http_version 1.1;
        proxy_set_header Connection "";
    }
}
```

### KeepAlived Configuration (HTTP VIP)
```bash
# /opt/docker/loadbalancer/keepalived/keepalived.conf (Docker container path - lb1 MASTER)
vrrp_script chk_nginx {
    script "/usr/local/bin/curl -f http://localhost/lb-health || exit 1"
    interval 2
    weight -2
    fall 3
    rise 2
}

vrrp_instance VI_1 {
    state MASTER
    interface ens2
    virtual_router_id 51
    priority 110
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass atom_lab_pass
    }
    virtual_ipaddress {
        192.168.122.100/24
    }
    track_script {
        chk_nginx
    }
    notify_master "/bin/echo 'MASTER' > /tmp/keepalived.state"
    notify_backup "/bin/echo 'BACKUP' > /tmp/keepalived.state"
    notify_fault "/bin/echo 'FAULT' > /tmp/keepalived.state"
}
```

```bash
# /opt/docker/loadbalancer/keepalived/keepalived.conf (Docker container path - lb2 BACKUP)
vrrp_script chk_nginx {
    script "/usr/local/bin/curl -f http://localhost/lb-health || exit 1"
    interval 2
    weight -2
    fall 3
    rise 2
}

vrrp_instance VI_1 {
    state BACKUP
    interface ens2
    virtual_router_id 51
    priority 100
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass atom_lab_pass
    }
    virtual_ipaddress {
        192.168.122.100/24
    }
    track_script {
        chk_nginx
    }
    notify_master "/bin/echo 'MASTER' > /tmp/keepalived.state"
    notify_backup "/bin/echo 'BACKUP' > /tmp/keepalived.state"
    notify_fault "/bin/echo 'FAULT' > /tmp/keepalived.state"
}
```

### Redis Configuration
```redis
# /opt/docker/redis/config/redis.conf (Docker container path - Master redis1)
bind 0.0.0.0
port 6379
protected-mode no
timeout 0
tcp-keepalive 300

# Authentication
requirepass atom_redis_secure_2025
masterauth atom_redis_secure_2025

# Memory management
maxmemory 1024mb
maxmemory-policy allkeys-lru

# Persistence - RDB snapshots
save 900 1
save 300 10
save 60 10000

# Persistence - AOF
appendonly yes
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
aof-load-truncated yes

# Logging
loglevel notice

# Security
rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command DEBUG ""

# Performance tuning
tcp-backlog 511
databases 16

# Slow log
slowlog-log-slower-than 10000
slowlog-max-len 128

# Client output buffer limits
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit replica 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60

# Memory usage optimization
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
list-max-ziplist-size -2
list-compress-depth 0
set-max-intset-entries 512
zset-max-ziplist-entries 128
zset-max-ziplist-value 64

# Advanced configuration
hz 10
dynamic-hz yes

# Lazy freeing
lazyfree-lazy-eviction no
lazyfree-lazy-expire no
lazyfree-lazy-server-del no
replica-lazy-flush no
```

```redis
# /opt/docker/redis/config/redis.conf (Docker container path - Slave redis2)
bind 0.0.0.0
port 6379
protected-mode no
timeout 0
tcp-keepalive 300

# Authentication
requirepass atom_redis_secure_2025
masterauth atom_redis_secure_2025

# Replication configuration
replicaof 192.168.122.121 6379
replica-serve-stale-data yes
replica-read-only yes
replica-priority 100

# Memory management
maxmemory 1024mb
maxmemory-policy allkeys-lru

# Persistence - RDB snapshots
save 900 1
save 300 10
save 60 10000

# Persistence - AOF
appendonly yes
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
aof-load-truncated yes

# Logging
loglevel notice

# Security
rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command DEBUG ""

# Performance tuning
tcp-backlog 511
databases 16

# Slow log
slowlog-log-slower-than 10000
slowlog-max-len 128

# Client output buffer limits
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit replica 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60

# Memory usage optimization
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
list-max-ziplist-size -2
list-compress-depth 0
set-max-intset-entries 512
zset-max-ziplist-entries 128
zset-max-ziplist-value 64

# Advanced configuration
hz 10
dynamic-hz yes

# Lazy freeing
lazyfree-lazy-eviction no
lazyfree-lazy-expire no
lazyfree-lazy-server-del no
replica-lazy-flush no
```

### PostgreSQL Configuration
```postgresql
# /opt/docker/postgres/db1/config/postgresql.conf (Docker container path - Master db1)
listen_addresses = '*'
port = 5432
max_connections = 100

# Memory settings
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB
maintenance_work_mem = 64MB

# WAL settings
wal_level = replica
wal_buffers = 16MB
checkpoint_segments = 32

# Archiving settings
archive_mode = on
archive_command = 'cp %p /opt/docker/postgres/backups/wal_archive/%f'

# Replication settings
hot_standby = on
hot_standby_feedback = on

# Logging settings
log_destination = 'stderr'
logging_collector = on
log_directory = 'log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_statement = 'mod'
log_min_duration_statement = 1000
log_checkpoints = on
log_connections = on
log_disconnections = on
log_lock_waits = on

# Security settings
ssl = off
password_encryption = scram-sha-256

# Performance tuning
checkpoint_timeout = 5min
max_wal_size = 1GB
min_wal_size = 80MB

# Vacuum settings
autovacuum = on
autovacuum_max_workers = 3
autovacuum_naptime = 1min
```

```postgresql
# /opt/docker/postgres/db2/config/postgresql.conf (Docker container path - Slave db2)
listen_addresses = '*'
port = 5432
max_connections = 100

# Memory settings
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB
maintenance_work_mem = 64MB

# WAL settings
wal_level = replica
wal_buffers = 16MB
checkpoint_segments = 32

# Archiving settings
archive_mode = on
archive_command = 'cp %p /opt/docker/postgres/backups/wal_archive/%f'

# Replication settings
hot_standby = on
hot_standby_feedback = on

# Logging settings
log_destination = 'stderr'
logging_collector = on
log_directory = 'log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_statement = 'mod'
log_min_duration_statement = 1000
log_checkpoints = on
log_connections = on
log_disconnections = on
log_lock_waits = on

# Security settings
ssl = off
password_encryption = scram-sha-256

# Performance tuning
checkpoint_timeout = 5min
max_wal_size = 1GB
min_wal_size = 80MB

# Vacuum settings
autovacuum = on
autovacuum_max_workers = 3
autovacuum_naptime = 1min
```

```postgresql
# /opt/docker/postgres/db1/config/pg_hba.conf (Docker container path - Both db1 and db2)
# PostgreSQL Client Authentication Configuration
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# Local connections
local   all             all                                     trust
local   replication     all                                     trust

# IPv4 local connections
host    all             all             127.0.0.1/32            scram-sha-256
host    all             all             ::1/128                 scram-sha-256

# Application connections
host    atom_app_db     atom_app_user   192.168.122.0/24        scram-sha-256
host    postgres        postgres        192.168.122.0/24        scram-sha-256

# Replication connections
host    replication     replicator      192.168.122.0/24        scram-sha-256
host    replication     postgres        192.168.122.0/24        scram-sha-256

# pgpool connections
host    all             pgpool_admin    192.168.122.0/24        scram-sha-256

# Allow all connections from internal network
host    all             all             192.168.122.0/24         scram-sha-256
```

### pgpool-II Configuration
```bash
### pgpool-II Configuration
```bash
# /opt/docker/pgpool/config/pgpool.conf (Docker container path - Both db1 and db2)
# pgpool-II Configuration
listen_addresses = '*'
port = 9999
socket_dir = '/tmp'
pcp_listen_addresses = '*'
pcp_port = 9898

# PID file location
pid_file_name = '/tmp/pgpool.pid'

# Backend connections
backend_hostname0 = '192.168.122.131'
backend_port0 = 5432
backend_weight0 = 1
backend_data_directory0 = '/var/lib/postgresql/data'
backend_flag0 = 'ALLOW_TO_FAILOVER'
backend_application_name0 = 'db1'

backend_hostname1 = '192.168.122.132'
backend_port1 = 5432
backend_weight1 = 1
backend_data_directory1 = '/var/lib/postgresql/data'
backend_flag1 = 'ALLOW_TO_FAILOVER'
backend_application_name1 = 'db2'

# Authentication
enable_pool_hba = on
pool_passwd = 'pool_passwd'

# Connection pooling
num_init_children = 32
max_pool = 4
child_life_time = 300
child_max_connections = 0
connection_life_time = 0
client_idle_limit = 0

# Load balancing
load_balance_mode = on
ignore_leading_white_space = on

# Master/Slave mode
master_slave_mode = on
master_slave_sub_mode = 'stream'
sr_check_period = 10
sr_check_user = 'replicator'
sr_check_password = 'atom_repl_secure_2025'
sr_check_database = 'postgres'

# Health check
health_check_period = 30
health_check_timeout = 20
health_check_user = 'postgres'
health_check_password = 'atom_postgres_secure_2025'
health_check_database = 'postgres'

# Logging
log_destination = 'stderr'
log_line_prefix = '%t: pid %p: '
log_connections = on
log_hostname = on
log_statement = on
```

```bash
# /opt/docker/pgpool/config/pool_hba.conf (Docker container path - Both db1 and db2)
# pgpool-II Host-Based Authentication Configuration
# TYPE  DATABASE    USER        CIDR-ADDRESS          METHOD
```
```

```bash
# /etc/pgpool-II/pool_hba.conf (Both db1 and db2)
# pgpool-II Host-Based Authentication Configuration
# TYPE  DATABASE    USER        CIDR-ADDRESS          METHOD

# Allow local connections
local   all         all                               trust

# Allow connections from database servers
host    all         all         192.168.122.0/24      md5

# Allow connections from application servers  
host    all         all         192.168.122.0/24      md5

# Allow connections from localhost
host    all         all         127.0.0.1/32          trust
host    all         all         ::1/128               trust
```

```bash
# /opt/docker/pgpool/config/pool_passwd (Docker container path - Both db1 and db2)
postgres:md5_hash_of_password
atom_app_user:md5_hash_of_password
replicator:md5_hash_of_password
```

### Docker Compose Files

#### Load Balancer Docker Compose (HTTP)
```yaml
# /opt/docker/loadbalancer/docker-compose.yml
version: '3.8'

services:
  nginx:
    image: nginx:1.25-alpine
    container_name: nginx-lb-lb1
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      - /opt/docker/loadbalancer/nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - /opt/docker/loadbalancer/nginx/conf.d:/etc/nginx/conf.d:ro
      - /opt/docker/loadbalancer/logs/nginx:/var/log/nginx
    networks:
      - lb_network
    depends_on:
      - keepalived

  keepalived:
    image: osixia/keepalived:2.0.20
    container_name: keepalived-lb1
    restart: unless-stopped
    network_mode: host
    volumes:
      - /opt/docker/loadbalancer/keepalived/keepalived.conf:/usr/local/etc/keepalived/keepalived.conf:ro
      - /usr/local/bin/curl:/usr/local/bin/curl:ro
    cap_add:
      - NET_ADMIN
      - NET_BROADCAST
      - NET_RAW

networks:
  lb_network:
    driver: bridge
```

#### Redis Docker Compose
```yaml
# /opt/docker/redis/docker-compose.yml
version: '3.8'

services:
  redis:
    image: redis:7.2-alpine
    container_name: redis-redis1
    restart: unless-stopped
    ports:
      - "6379:6379"
    volumes:
      - /opt/docker/redis/data:/data
      - /opt/docker/redis/config/redis.conf:/etc/redis/redis.conf:ro
      - /opt/docker/redis/logs:/var/log/redis
    command: redis-server /etc/redis/redis.conf
    networks:
      - redis_network

networks:
  redis_network:
    driver: bridge
```

#### Application Docker Compose
```yaml
# /opt/docker/application/docker-compose.yml
version: '3.8'
services:
  enhanced-simple-app:
    image: python:3.11-slim
    container_name: simple-enhanced-app
    restart: unless-stopped
    working_dir: /app
    volumes:
      - /opt/docker/application:/app
    ports:
      - "8080:8080"
    environment:
      - FLASK_APP=enhanced_backend.py
      - FLASK_ENV=production
      - PYTHONUNBUFFERED=1
      - REDIS_HOST=192.168.122.121
      - DATABASE_HOST=192.168.122.131
    command: >
      bash -c "
      apt-get update > /dev/null 2>&1 &&
      apt-get install -y postgresql-client redis-tools curl > /dev/null 2>&1 &&
      pip install --no-cache-dir -r requirements.txt > /dev/null 2>&1 &&
      mkdir -p templates static/css static/js &&
      python enhanced_backend.py
      "
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
    networks:
      - simple-network

networks:
  simple-network:
    driver: bridge
```

#### PostgreSQL Docker Compose
```yaml
# /opt/docker/postgres/docker-compose.yml
version: '3.8'

services:
  postgresql-db1:
    image: postgres:15
    container_name: postgresql-db1
    restart: unless-stopped
    ports:
      - "5432:5432"
    volumes:
      - /opt/docker/postgres/db1/data:/var/lib/postgresql/data
      - /opt/docker/postgres/db1/config/postgresql.conf:/etc/postgresql/postgresql.conf:ro
      - /opt/docker/postgres/db1/config/pg_hba.conf:/etc/postgresql/pg_hba.conf:ro
      - /opt/docker/postgres/backups:/opt/docker/postgres/backups
    environment:
      - POSTGRES_PASSWORD=atom_postgres_secure_2025
      - POSTGRES_DB=atom_app_db
      - POSTGRES_USER=postgres
    command: postgres -c config_file=/etc/postgresql/postgresql.conf
    networks:
      - postgres_network

  postgresql-db2:
    image: postgres:15
    container_name: postgresql-db2
    restart: unless-stopped
    ports:
      - "5432:5432"
    volumes:
      - /opt/docker/postgres/db2/data:/var/lib/postgresql/data
      - /opt/docker/postgres/db2/config/postgresql.conf:/etc/postgresql/postgresql.conf:ro
      - /opt/docker/postgres/db2/config/pg_hba.conf:/etc/postgresql/pg_hba.conf:ro
      - /opt/docker/postgres/backups:/opt/docker/postgres/backups
    environment:
      - POSTGRES_PASSWORD=atom_postgres_secure_2025
      - POSTGRES_DB=atom_app_db
      - POSTGRES_USER=postgres
    command: postgres -c config_file=/etc/postgresql/postgresql.conf
    networks:
      - postgres_network

networks:
  postgres_network:
    driver: bridge
```

#### pgpool-II Docker Compose
```yaml
# /opt/docker/pgpool/docker-compose.yml
version: '3.8'

services:
  pgpool-db1:
    image: pgpool/pgpool:4.4
    container_name: pgpool-db1
    restart: unless-stopped
    ports:
      - "9999:9999"
    volumes:
      - /opt/docker/pgpool/config/pgpool.conf:/opt/pgpool-II/etc/pgpool.conf:ro
      - /opt/docker/pgpool/config/pool_hba.conf:/opt/pgpool-II/etc/pool_hba.conf:ro
      - /opt/docker/pgpool/config/pool_passwd:/opt/pgpool-II/etc/pool_passwd:ro
      - /opt/docker/pgpool/logs:/var/log/pgpool-II
    environment:
      - PGPOOL_BACKEND_NODES=0:postgresql-db1:5432,1:postgresql-db2:5432
      - PGPOOL_ENABLE_LOAD_BALANCING=1
      - PGPOOL_SR_CHECK_USER=replicator
      - PGPOOL_SR_CHECK_PASSWORD=atom_repl_secure_2025
    depends_on:
      - postgresql-db1
      - postgresql-db2
    networks:
      - postgres_network

networks:
  postgres_network:
    driver: bridge
```
