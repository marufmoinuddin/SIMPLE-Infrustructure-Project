#!/bin/bash
# Quick Infrastructure Verification Script
# Date: September 1, 2025
# Purpose: Rapid health check of all SIMPLE infrastructure components

echo "================================================================="
echo "🔍 SIMPLE INFRASTRUCTURE QUICK VERIFICATION"
echo "================================================================="
echo "Timestamp: $(date)"
echo

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check service
check_service() {
    local service_name="$1"
    local host="$2"
    local port="$3"
    local protocol="${4:-http}"
    
    if [ "$protocol" = "http" ]; then
        if curl -s -o /dev/null -w "%{http_code}" "http://$host:$port" | grep -q "200\|302"; then
            echo -e "  ${GREEN}✅${NC} $service_name ($host:$port) - HEALTHY"
            return 0
        else
            echo -e "  ${RED}❌${NC} $service_name ($host:$port) - UNHEALTHY"
            return 1
        fi
    elif [ "$protocol" = "tcp" ]; then
        if nc -z -w 3 "$host" "$port" 2>/dev/null; then
            echo -e "  ${GREEN}✅${NC} $service_name ($host:$port) - HEALTHY"
            return 0
        else
            echo -e "  ${RED}❌${NC} $service_name ($host:$port) - UNHEALTHY"
            return 1
        fi
    fi
}

# Function to check HTTP endpoint
check_http_endpoint() {
    local name="$1"
    local url="$2"
    local expected_codes="${3:-200,302}"
    
    local response_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    
    if echo "$expected_codes" | grep -q "$response_code"; then
        echo -e "  ${GREEN}✅${NC} $name - HEALTHY (HTTP $response_code)"
        return 0
    else
        echo -e "  ${RED}❌${NC} $name - UNHEALTHY (HTTP $response_code)"
        return 1
    fi
}

# Initialize counters
total_checks=0
passed_checks=0

echo "🔸 LOAD BALANCERS:"
# Check Load Balancers - Accept 301 redirects as healthy
check_http_endpoint "lb1 (192.168.122.101:80)" "http://192.168.122.101" "200,301,302"
[ $? -eq 0 ] && ((passed_checks++))
((total_checks++))

check_http_endpoint "lb2 (192.168.122.102:80)" "http://192.168.122.102" "200,301,302"
[ $? -eq 0 ] && ((passed_checks++))
((total_checks++))

# Check VIP - Accept 301 redirects as healthy
check_http_endpoint "VIP (192.168.122.100)" "http://192.168.122.100" "200,301,302"
[ $? -eq 0 ] && ((passed_checks++))
((total_checks++))

echo
echo "🔸 APPLICATION SERVERS:"
# Check Application Servers
check_http_endpoint "app1" "http://192.168.122.111:8080/health"
[ $? -eq 0 ] && ((passed_checks++))
((total_checks++))

check_http_endpoint "app2" "http://192.168.122.112:8080/health"
[ $? -eq 0 ] && ((passed_checks++))
((total_checks++))

echo
echo "🔸 REDIS SERVERS:"
# Check Redis
check_service "redis1" "192.168.122.121" "6379" "tcp"
[ $? -eq 0 ] && ((passed_checks++))
((total_checks++))

check_service "redis2" "192.168.122.122" "6379" "tcp"
[ $? -eq 0 ] && ((passed_checks++))
((total_checks++))

echo
echo "🔸 DATABASE SERVERS:"
# Check PostgreSQL
check_service "db1-postgresql" "192.168.122.131" "5432" "tcp"
[ $? -eq 0 ] && ((passed_checks++))
((total_checks++))

check_service "db2-postgresql" "192.168.122.132" "5432" "tcp"
[ $? -eq 0 ] && ((passed_checks++))
((total_checks++))

# Check pgpool
check_service "db1-pgpool" "192.168.122.131" "9999" "tcp"
[ $? -eq 0 ] && ((passed_checks++))
((total_checks++))

check_service "db2-pgpool" "192.168.122.132" "9999" "tcp"
[ $? -eq 0 ] && ((passed_checks++))
((total_checks++))

echo
echo "🔸 END-TO-END TESTS:"
# End-to-end tests
check_http_endpoint "Full Stack HTTP" "http://192.168.122.100/" "200,301,302"
[ $? -eq 0 ] && ((passed_checks++))
((total_checks++))

# HTTPS test (ignore SSL errors for self-signed cert)
if curl -k -s -o /dev/null -w "%{http_code}" "https://192.168.122.100/" | grep -q "200\|302"; then
    echo -e "  ${GREEN}✅${NC} Full Stack HTTPS - HEALTHY"
    ((passed_checks++))
else
    echo -e "  ${RED}❌${NC} Full Stack HTTPS - UNHEALTHY"
fi
((total_checks++))

echo
echo "================================================================="
echo "📊 VERIFICATION SUMMARY"
echo "================================================================="

# Calculate percentage
if [ $total_checks -gt 0 ]; then
    percentage=$((passed_checks * 100 / total_checks))
else
    percentage=0
fi

echo "Total Checks: $total_checks"
echo "Passed: $passed_checks"
echo "Failed: $((total_checks - passed_checks))"
echo "Success Rate: $percentage%"

if [ $percentage -eq 100 ]; then
    echo -e "${GREEN}🎉 ALL SYSTEMS OPERATIONAL!${NC}"
    exit_code=0
elif [ $percentage -ge 80 ]; then
    echo -e "${YELLOW}⚠️  MOSTLY OPERATIONAL - Some issues detected${NC}"
    exit_code=1
else
    echo -e "${RED}❌ CRITICAL ISSUES - Multiple systems down${NC}"
    exit_code=2
fi

echo
echo "================================================================="
echo "🔧 TROUBLESHOOTING COMMANDS"
echo "================================================================="
echo "Check all services:"
echo "  ansible all -i /mnt/Storage/VMs/prod/ansible_scripts/inventory.ini -m ping"
echo
echo "Restart failed components:"
echo "  cd /mnt/Storage/VMs/prod/ansible_scripts"
echo "  ansible-playbook 01-loadbalancer-setup.yml"
echo "  ansible-playbook 02-app-setup.yml"
echo "  ansible-playbook 03-redis-setup.yml"
echo "  ansible-playbook 04-database-setup.yml"
echo
echo "Full infrastructure monitoring:"
echo "  bash /tmp/monitor-infrastructure.sh"
echo
echo "Load testing:"
echo "  bash /tmp/load_test.sh"
echo "================================================================="

exit $exit_code
