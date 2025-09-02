# Demo Commands for Presentation

## Show Load Balancer Setup
```bash
# Show NGINX config on lb1
ssh lb1 "cat /opt/docker/loadbalancer/nginx/nginx.conf"

# Show KeepAlived status
ssh lb1 "docker exec keepalived-lb1 cat /usr/local/etc/keepalived/keepalived.conf"

# Test VIP failover
curl http://192.168.122.100
```

## Show Application Setup
```bash
# Show Flask app logs
ssh app1 "docker logs simple-enhanced-app"

# Show Docker Compose status
ssh app1 "cd /opt/docker/application && docker-compose ps"

# Test app health
curl http://192.168.122.111:8080/health
```

## Show Redis Setup
```bash
# Show Redis master status
ssh redis1 "docker exec redis redis-cli -a atom_redis_secure_2025 info replication"

# Show slave status
ssh redis2 "docker exec redis redis-cli -a atom_redis_secure_2025 info replication"

# Test Redis connection
ssh redis1 "docker exec redis redis-cli -a atom_redis_secure_2025 ping"
```

## Show Database Setup
```bash
# Show PostgreSQL master status
ssh db1 "docker exec postgresql-db1 psql -U postgres -c 'SELECT * FROM pg_stat_replication;'"

# Show pgpool status
ssh db1 "docker exec pgpool-db1 psql -h localhost -p 9999 -U pgpool_admin -d postgres -c 'SHOW POOL_NODES;'"

# Test database connection via pgpool
ssh db1 "docker exec postgresql-db1 psql -h localhost -p 9999 -U atom_app_user -d atom_app_db -c 'SELECT version();'"
```
