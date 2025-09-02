#!/bin/bash

# vm_toolkit.sh
# Comprehensive VM management script with static IPs, guaranteed SSH access, and shared memory support
# Created August 21, 2025
# Updated August 22, 2025 - Standardized all VM configurations:
#   - Equal resources: 15GB disk, 1536MB RAM, 2 vCPUs for all VMs
#   - Same package set: podman, buildah, python3, htop, git, nano, vim for all VMs
#   - Unified configuration steps and setup procedures

set -e

# Base directories
BASE_DIR=$(pwd)
VM_DISKS_DIR="$BASE_DIR/vm_disks"
CLOUD_INIT_DIR="$BASE_DIR/cloud_init_ISOs"
BASE_IMAGE="$BASE_DIR/base.qcow2"

# Network configuration
NETWORK_CIDR="192.168.122.0/24"
GATEWAY="192.168.122.1"
DNS_SERVERS="192.168.122.1 8.8.8.8 1.1.1.1"

# Credentials - change these if needed
VM_USER="root"
VM_PASSWORD="mysecret123"

# VM specifications - Format: name:disk_size_GB:ram_MB:vcpus:static_ip
# All VMs now have equal resources: 15GB disk, 1536MB RAM, 2 vCPUs
declare -a VM_SPECS=(
  "lb1:15:1536:2:192.168.122.101"
  "lb2:15:1536:2:192.168.122.102"
  "app1:15:1536:2:192.168.122.111"
  "app2:15:1536:2:192.168.122.112"
  "redis1:15:1536:2:192.168.122.121"
  "redis2:15:1536:2:192.168.122.122"
  "db1:15:1536:2:192.168.122.131"
  "db2:15:1536:2:192.168.122.132"
)

# Function to create cloud-init ISO with static IP
create_cloud_init_iso() {
  local name=$1
  local ip=$2
  local iso_path="$CLOUD_INIT_DIR/${name}.iso"
  local temp_dir=$(mktemp -d)
  
  echo "Creating cloud-init ISO for $name with IP $ip..."
  
  # Meta-data
  cat > "$temp_dir/meta-data" <<EOF
instance-id: $name
hostname: $name
local-hostname: $name
EOF

  # Network config with static IP
  cat > "$temp_dir/network-config" <<EOF
version: 2
ethernets:
  ens2:
    dhcp4: false
    addresses: [$ip/24]
    gateway4: $GATEWAY
    nameservers:
      addresses: [8.8.8.8, 1.1.1.1, 192.168.122.1]
    routes:
      - to: 0.0.0.0/0
        via: $GATEWAY
EOF
  
  # User-data with extensive SSH and password configuration
  cat > "$temp_dir/user-data" <<EOF
#cloud-config
# Debug output
debug: True
verbosity: 3
output: {all: '| tee -a /var/log/cloud-init-output.log'}

# Password auth and root access
ssh_pwauth: true
disable_root: false

# User creation
users:
  - default
  - name: $VM_USER
    groups: [ adm, audio, cdrom, dialout, floppy, video, plugdev, dip, netdev, sudo ]
    shell: /bin/bash
    sudo: [ "ALL=(ALL) NOPASSWD:ALL" ]
    plain_text_passwd: $VM_PASSWORD
    lock_passwd: false
    
# Set password
password: $VM_PASSWORD
chpasswd:
  expire: false
  list: |
    $VM_USER:$VM_PASSWORD
    
# Generate SSH keys
ssh:
  emit_keys_to_console: false
  ssh_deletekeys: false
  ssh_keys:
    rsa_private: |
      -----BEGIN OPENSSH PRIVATE KEY-----
      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
      -----END OPENSSH PRIVATE KEY-----
    rsa_public: ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDM6qKAuhFWfVRXzYsYObBc+zBQsp0jZcbcYlQO1O8aHRwHX1+4ojJ1y4akn/mV2xDonmj5O/d/L2Zm1vSzyhXPF3+ZBQUlsWhc/C35fa0hruGylCg1hMegfLwSUjapLkH5A8HD8WmljNhCmeRi2bkUvBA65ABgl9HGsL5gWntnq9PPEa5Cxh0keLNQIzYOavmogky3twWQf5YFhsaVOXwtkQNU6fZ0VTWuNMlr3EGStDIJPmpwhmWHTYuI55TW6tVVKH/YoQliQRUttIZHerRMMIkvskdTnQZUTjiZhGLUYOXXOEEuNHTgtjVUbX0ACYqzt5Jg5B8UhT3F2+qdD033BuRsG1WNPUCFkEECDHn13FORnYf74nS38QVEG8mD0PXzbOLUI2xjbQrN7gt3ExEwLVBCIYfq9AIjX7p/+FT61Jenq0HXqTQzY3mkN6N9EcH4p8ITo4+GmjQVWQiJOQ4JQEcLYj8ZMsTJ5FmVS/JyQ6dVJ+OqE9AoGknD root@hostname

# Package installation - same for all VMs
packages:
  - openssh-server
  - qemu-guest-agent
  - bind-utils
  - wget
  - curl
  - podman
  - buildah
  - python3
  - htop
  - git
  - nano
  - vim
# Package management and configuration
package_update: true
package_reboot_if_required: false
package_upgrade: false
EOF

  # Add strong SSH configuration and service enablement
  cat >> "$temp_dir/user-data" <<EOF
# SSH configuration
write_files:
  - path: /etc/ssh/sshd_config.d/override.conf
    permissions: '0644'
    content: |
      PasswordAuthentication yes
      PermitRootLogin yes
      PubkeyAuthentication yes
  - path: /etc/issue
    content: |
      VM: $name ($ip)
      Login with user '$VM_USER' and password '$VM_PASSWORD'

# Run commands to finalize setup - same for all VMs
runcmd:
  # Fix any permissions
  - chmod 600 /root/.ssh/id_rsa
  - chmod 644 /root/.ssh/id_rsa.pub
  # Configure SSH properly
  - systemctl enable sshd
  - systemctl restart sshd
  # Ensure password is set
  - echo '$VM_USER:$VM_PASSWORD' | chpasswd
  # Configure networking with explicit DNS
  - echo "nameserver 8.8.8.8" >> /etc/resolv.conf
  - echo "nameserver 1.1.1.1" >> /etc/resolv.conf
  - ip route add default via $GATEWAY || true
  - ping -c 3 8.8.8.8 || echo "Network ping failed, but continuing"
  # Enable and start qemu-guest-agent for all VMs
  - systemctl enable qemu-guest-agent
  - systemctl start qemu-guest-agent
  # Set timezone
  - timedatectl set-timezone UTC
  # Enable and start podman socket for container management
  - systemctl enable podman.socket
  - systemctl start podman.socket
  # Create a common working directory
  - mkdir -p /opt/app
  - chown $VM_USER:$VM_USER /opt/app
  # Set up basic firewall rules (allow SSH)
  - firewall-cmd --permanent --add-service=ssh || true
  - firewall-cmd --reload || true
  # Update system packages
  - dnf update -y || apt-get update && apt-get upgrade -y || true
  # Final setup completion marker
  - echo "Setup complete for $name on $(date)" > /root/setup-complete.txt
  - echo "VM Type: Standard configuration" >> /root/setup-complete.txt
  - echo "Resources: 15GB disk, 1536MB RAM, 2 vCPUs" >> /root/setup-complete.txt
EOF

  # Create the ISO with all three files (meta-data, user-data, network-config)
  echo "Generating ISO at $iso_path"
  genisoimage -output "$iso_path" -volid cidata -joliet -rock \
    "$temp_dir/meta-data" "$temp_dir/user-data" "$temp_dir/network-config"
  
  # Cleanup
  rm -rf "$temp_dir"
  
  echo "Cloud-init ISO created for $name"
}

# Function to create a VM disk
create_vm_disk() {
  local name=$1
  local size=$2
  local disk_path="$VM_DISKS_DIR/${name}.qcow2"
  
  echo "Creating disk for $name (${size}GB)..."
  qemu-img create -f qcow2 -b "$BASE_IMAGE" -F qcow2 "$disk_path" "${size}G"
  
  if [ $? -eq 0 ]; then
    echo "Successfully created disk: $disk_path"
    return 0
  else
    echo "Failed to create disk: $disk_path"
    return 1
  fi
}

# Function to create and start a VM
create_vm() {
  local name=$1
  local vcpus=$2
  local memory=$3
  local disk_path="$VM_DISKS_DIR/${name}.qcow2"
  local iso_path="$CLOUD_INIT_DIR/${name}.iso"
  
  # Check if VM already exists
  if virsh dominfo "$name" &>/dev/null; then
    echo "VM $name already exists. Destroying and undefining..."
    virsh destroy "$name" &>/dev/null || true
    virsh undefine "$name" &>/dev/null || true
  fi
  
  echo "Creating VM: $name (vcpus=$vcpus, memory=${memory}MB)"
  
  # Create the VM using virt-install
  virt-install \
    --name "$name" \
    --vcpus "$vcpus" \
    --memory "$memory" \
    --disk path="$disk_path",bus=virtio \
    --disk path="$iso_path",device=cdrom,bus=sata \
    --network network=default,model=virtio \
    --graphics none \
    --console pty,target_type=serial \
    --osinfo detect=on,require=off \
    --noautoconsole \
    --import \
    --wait 0
    
  # Wait a bit for the VM to be defined
  sleep 2
  
  # Add shared memory configuration using direct XML editing
  echo "Adding shared memory configuration to $name"
  
  # Create temporary files for XML manipulation
  local original_xml=$(mktemp)
  local modified_xml=$(mktemp)
  
  # Dump the current XML
  virsh dumpxml "$name" > "$original_xml"
  
  # Check if memoryBacking is already configured
  if grep -q "<memoryBacking>" "$original_xml"; then
    echo "Memory backing already configured for $name"
  else
    # Insert memoryBacking section after the currentMemory tag
    awk '/<\/currentMemory>/ { 
      print $0;
      print "  <memoryBacking>";
      print "    <source type=\"memfd\"/>";
      print "    <access mode=\"shared\"/>";
      print "  </memoryBacking>";
      next;
    }
    { print $0 }' "$original_xml" > "$modified_xml"
    
    # Verify the XML is valid
    if xmllint --noout "$modified_xml" 2>/dev/null; then
      # Stop VM, update XML, and restart
      echo "Updating VM configuration with shared memory..."
      virsh destroy "$name" &>/dev/null || true
      virsh define "$modified_xml"
      virsh start "$name"
      echo "VM $name updated with shared memory configuration"
    else
      echo "WARNING: Failed to apply shared memory configuration to $name - invalid XML"
      # Start the VM anyway
      virsh start "$name"
    fi
  fi
  
  # Clean up
  rm -f "$original_xml" "$modified_xml"
}

# Function to destroy all VMs
destroy_all_vms() {
  echo "Destroying all existing VMs..."
  for vm in $(virsh list --all --name); do
    if [ -n "$vm" ]; then
      echo "Destroying VM: $vm"
      virsh destroy "$vm" &>/dev/null || true
      virsh undefine "$vm" --remove-all-storage &>/dev/null || true
    fi
  done
}

# Function to clean disks and ISOs
clean_artifacts() {
  echo "Cleaning up artifacts..."
  rm -f "$VM_DISKS_DIR"/*.qcow2
  rm -f "$CLOUD_INIT_DIR"/*.iso
}

# Function to list VMs and their status
list_vms() {
  echo "Existing VMs:"
  virsh list --all
  
  echo -e "\nVM IP addresses:"
  for vm in $(virsh list --name); do
    if [ -n "$vm" ]; then
      echo -n "$vm: "
      virsh domifaddr "$vm" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]+)?' || echo "No IP"
    fi
  done
}

# Function to check if a VM is accessible via SSH
check_ssh() {
  local vm=$1
  local ip=$2
  local tries=5
  local delay=5
  
  echo "Checking SSH access to $vm at $ip..."
  
  for ((i=1; i<=tries; i++)); do
    echo "Attempt $i of $tries..."
    if ping -c 1 -W 2 "$ip" >/dev/null; then
      echo "  VM is reachable by ping"
      if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$VM_USER@$ip" "echo SSH SUCCESS"; then
        echo "  SSH connection successful!"
        return 0
      else
        echo "  SSH connection failed"
      fi
    else
      echo "  VM not reachable by ping yet"
    fi
    sleep $delay
  done
  
  echo "Could not establish SSH connection to $vm at $ip after $tries attempts"
  return 1
}

# Function to configure host for shared memory using memfd and hugepages
configure_host_for_hugepages() {
  echo "Checking and configuring host for shared memory support (memfd and hugepages)..."
  
  # Check if hugepages are already configured
  local hugepages_config=$(grep -i hugepage /proc/meminfo | head -1 | awk '{print $2}')
  
  if [ "$hugepages_config" -gt 0 ] 2>/dev/null; then
    echo "Hugepages already configured: $hugepages_config"
  else
    # Calculate 20% of system memory for hugepages (if not already set)
    local mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local hugepages_count=$(( mem_total / 1024 / 2048 / 5 )) # 20% of memory in 2MB pages
    
    if [ "$hugepages_count" -lt 32 ]; then
      hugepages_count=32  # Minimum recommended
    fi
    
    echo "Setting up $hugepages_count hugepages for shared memory..."
    
    # Try to set hugepages if user has sufficient permissions
    if [ "$(id -u)" -eq 0 ]; then
      echo "$hugepages_count" > /proc/sys/vm/nr_hugepages
      echo "vm.nr_hugepages = $hugepages_count" > /etc/sysctl.d/99-hugepages.conf
      sysctl -p /etc/sysctl.d/99-hugepages.conf
    else
      echo "WARNING: Not running as root. Hugepages configuration requires root privileges."
      echo "Run the following commands with sudo to enable hugepages:"
      echo "  echo $hugepages_count > /proc/sys/vm/nr_hugepages"
      echo "  echo \"vm.nr_hugepages = $hugepages_count\" > /etc/sysctl.d/99-hugepages.conf"
      echo "  sysctl -p /etc/sysctl.d/99-hugepages.conf"
    fi
  fi
  
  # Check if memfd is available
  if [ ! -d "/dev/shm" ]; then
    echo "WARNING: /dev/shm directory not found. Shared memory via memfd might not work correctly."
    echo "Make sure tmpfs is mounted at /dev/shm for proper shared memory operation."
  else
    echo "Shared memory support via memfd is available (/dev/shm exists)."
    
    # Check if qemu user has proper permissions
    if [ "$(id -u)" -eq 0 ]; then
      # Ensure /dev/shm has proper permissions
      chmod 1777 /dev/shm
      echo "Set /dev/shm permissions to 1777 to ensure proper shared memory access."
    fi
  fi
}

# Check for required tools
check_dependencies() {
  local missing=""
  
  for cmd in virsh qemu-img genisoimage xmllint; do
    if ! command -v "$cmd" &>/dev/null; then
      missing="$missing $cmd"
    fi
  done
  
  if [ -n "$missing" ]; then
    echo "Error: The following required commands are missing:$missing"
    echo "Please install the missing packages and try again."
    echo "For xmllint: apt-get install libxml2-utils or yum install libxml2"
    exit 1
  fi
}

# Main function
main() {
  local operation=$1
  
  # Check for required tools
  check_dependencies
  
  # Make sure base image exists
  if [ ! -f "$BASE_IMAGE" ]; then
    echo "Error: Base image $BASE_IMAGE not found!"
    exit 1
  fi
  
  # Ensure required directories exist
  mkdir -p "$VM_DISKS_DIR" "$CLOUD_INIT_DIR"
  
  # Configure host for shared memory if needed
  if [ "$operation" = "create" ] || [ "$operation" = "recreate" ]; then
    configure_host_for_hugepages
  fi
  
  case "$operation" in
    "create")
      # Create VMs from scratch
      for vm_spec in "${VM_SPECS[@]}"; do
        IFS=':' read -r name disk_size memory vcpus ip <<< "$vm_spec"
        
        # Create disk
        create_vm_disk "$name" "$disk_size"
        
        # Create cloud-init ISO with static IP (same configuration for all VMs)
        create_cloud_init_iso "$name" "$ip"
      done
      
      for vm_spec in "${VM_SPECS[@]}"; do
        IFS=':' read -r name disk_size memory vcpus ip <<< "$vm_spec"
        
        # Create and start VM (in background)
        create_vm "$name" "$vcpus" "$memory" &
      done
      
      # Wait for all background processes
      wait
      
      echo "All VMs have been created and are starting."
      echo "Use '$0 list' to see VM status and IPs"
      echo "Use '$0 ssh <vm-name>' to connect to a VM when it's ready"
      echo "  Default username: $VM_USER"
      echo "  Default password: $VM_PASSWORD"
      ;;
    
    "recreate")
      # Destroy and recreate all VMs
      destroy_all_vms
      clean_artifacts
      main "create"
      ;;
      
    "destroy")
      # Just destroy VMs
      destroy_all_vms
      echo "All VMs destroyed"
      ;;
      
    "list")
      # List VMs and their IPs
      list_vms
      ;;
      
    "ssh")
      # SSH to a specific VM
      local vm_name=$2
      if [ -z "$vm_name" ]; then
        echo "Error: VM name required"
        echo "Usage: $0 ssh <vm-name>"
        exit 1
      fi
      
      # Find the VM's IP
      local vm_ip=$(virsh domifaddr "$vm_name" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)
      if [ -z "$vm_ip" ]; then
        # Try to use the configured static IP from VM_SPECS
        for vm_spec in "${VM_SPECS[@]}"; do
          IFS=':' read -r name disk_size memory vcpus ip <<< "$vm_spec"
          if [ "$name" = "$vm_name" ]; then
            vm_ip="${ip%%/*}" # Remove CIDR notation if present
            break
          fi
        done
        
        if [ -z "$vm_ip" ]; then
          echo "Error: Could not find IP address for VM $vm_name"
          exit 1
        fi
        echo "Using configured static IP: $vm_ip"
      fi
      
      echo "Connecting to $vm_name at $vm_ip..."
      ssh -o StrictHostKeyChecking=no "$VM_USER@$vm_ip"
      ;;
      
    "clean")
      # Clean up artifacts
      destroy_all_vms
      clean_artifacts
      echo "All artifacts cleaned"
      ;;
      
    "check-mem")
      # Check memory configuration of a VM
      local vm_name=$2
      if [ -z "$vm_name" ]; then
        echo "Error: VM name required"
        echo "Usage: $0 check-mem <vm-name>"
        exit 1
      fi
      
      # Check if VM exists
      if ! virsh dominfo "$vm_name" &>/dev/null; then
        echo "Error: VM $vm_name does not exist"
        exit 1
      fi
      
      echo "Memory configuration for $vm_name:"
      virsh dumpxml "$vm_name" | grep -A 10 "<memory" | grep -B 10 "</memoryBacking>" 2>/dev/null || echo "No shared memory configuration found"
      ;;
      
    *)
      echo "Usage: $0 <operation> [args]"
      echo "Operations:"
      echo "  create     - Create all VMs"
      echo "  recreate   - Destroy and recreate all VMs"
      echo "  destroy    - Destroy all VMs"
      echo "  list       - List VMs and their IPs"
      echo "  ssh VM     - SSH to a specific VM"
      echo "  clean      - Destroy VMs and clean up artifacts"
      echo "  check-mem VM - Check memory configuration of a VM"
      exit 1
      ;;
  esac
}

# Run main function with all arguments
main "$@"
