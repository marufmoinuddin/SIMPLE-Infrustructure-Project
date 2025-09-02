# SIMPLE Infrastructure Project

## 🏗️ Proj└── scripts/                          # Utility and demo scripts
    ├── vm_toolkit.sh               # VM management toolkit for infrastructure
    ├── quick-verify.sh             # Infrastructure health check
    └── demo-commands.sh            # Presentation demo commands Overview
The SIMPLE Infrastructure Project is a comprehensive demonstration of deploying a high-availability, multi-tier web application stack using modern DevOps practices. This project showcases enterprise-grade infrastructure components including load balancing, application servers, caching, and database clustering, all automated through Ansible playbooks and containerized with Docker.

The project includes a Flask-based web application that serves as the frontend, backed by Redis for caching and PostgreSQL for data persistence, all orchestrated in a highly available setup with redundant components.

## ✨ Features
- **High Availability**: Multi-tier architecture with redundant load balancers, application servers, Redis clusters, and database failover
- **Containerization**: Docker-based deployment for consistent environments
- **Infrastructure as Code**: Complete automation using Ansible playbooks
- **Monitoring Ready**: Infrastructure designed for easy integration with monitoring tools
- **Scalable Architecture**: Horizontal scaling capabilities for application and database layers
- **Production Ready**: Enterprise-grade setup with proper networking, security, and redundancy

## 📁 Directory Structure

```
SIMPLE-Infrastructure-Project/
├── README.md                          # Project documentation
├── documentation/                     # Detailed guides and presentations
│   ├── infrastructure-guidebook.md    # Complete setup and configuration guide
│   └── presentation-flow.md          # Presentation structure and demo flow
├── application/                       # Web application source code
│   ├── enhanced_backend.py           # Flask application with enhanced features
│   ├── enhanced_app.html             # Main HTML template
│   ├── requirements.txt              # Python dependencies
│   ├── static/                       # Static assets (CSS, JS)
│   │   ├── css/
│   │   │   └── style.css
│   │   └── js/
│   │       └── app.js
│   └── templates/                    # Jinja2 templates
│       └── enhanced_app.html
├── ansible_scripts/               # Ansible playbooks and inventory
│   ├── 00-master-deployment.yml  # Master deployment playbook
│   ├── 00-prerequisites-setup.yml # System prerequisites
│   ├── 01-loadbalancer-setup.yml # HAProxy load balancer configuration
│   ├── 02-app-setup-enhanced.yml # Enhanced application deployment
│   ├── 02-app-setup.yml          # Basic application deployment
│   ├── 03-redis-setup.yml        # Redis cluster setup
│   ├── 04-database-setup.yml     # PostgreSQL with pgpool-II
│   ├── 05-integration-testing.yml # Integration tests
│   └── inventory.ini             # Ansible inventory
└── scripts/                          # Utility and demo scripts
    ├── quick-verify.sh               # Infrastructure health check
    └── demo-commands.sh              # Presentation demo commands
```

## 🚀 Quick Start

### Prerequisites
- Ubuntu 22.04 host system
- KVM/QEMU virtualization with libvirt
- Ansible 2.9+
- Python 3.8+
- At least 16GB RAM and 100GB storage for VMs

### Installation
1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd SIMPLE-Infrastructure-Project
   ```

2. **Review documentation**:
   ```bash
   cat documentation/infrastructure-guidebook.md
   ```

3. **Run quick verification**:
   ```bash
   ./scripts/quick-verify.sh
   ```

4. **Deploy infrastructure**:
   ```bash
   cd ansible_scripts
   ansible-playbook -i inventory.ini 00-master-deployment.yml
   ```

## 🔧 VM Infrastructure Setup

The project includes a comprehensive VM management toolkit (`scripts/vm_toolkit.sh`) that automates the creation and configuration of the required virtual machines:

### VM Specifications
- **Load Balancers**: lb1 (192.168.122.101), lb2 (192.168.122.102)
- **Application Servers**: app1 (192.168.122.111), app2 (192.168.122.112)
- **Redis Cluster**: redis1 (192.168.122.121), redis2 (192.168.122.122)
- **Database Servers**: db1 (192.168.122.131), db2 (192.168.122.132)

### Quick VM Setup
```bash
# Copy toolkit to VM directory
cp scripts/vm_toolkit.sh /mnt/Storage/VMs/prod/
cd /mnt/Storage/VMs/prod

# Create all VMs
./vm_toolkit.sh create

# Check VM status
./vm_toolkit.sh list
```

See `WALKTHROUGH.md` for complete VM setup and infrastructure deployment instructions.

## 🎯 Infrastructure Status
- **Network**: 192.168.122.0/24 (Internal network)
- **Virtual IP**: 192.168.122.100 (HAProxy VIP)
- **Components**:
  - Load Balancers: lb1, lb2 (HAProxy with Keepalived)
  - Application Servers: app1, app2 (Flask + Docker)
  - Redis Cluster: redis1, redis2 (Master-Slave)
  - Database: db1, db2 (PostgreSQL with pgpool-II)
- **Status**: Production Ready (100% Operational)

## 📊 Architecture Diagram
```
Internet → [VIP: 192.168.122.100] → Load Balancers (lb1/lb2)
                                    ↓
Application Servers (app1/app2) ←→ Redis (redis1/redis2)
                                    ↓
Database (db1/db2) with pgpool-II
```

### Component Details
- **Load Balancers**: HAProxy with Keepalived for high availability
- **Application Layer**: Flask web application containerized with Docker
- **Cache Layer**: Redis cluster with master-slave replication
- **Database Layer**: PostgreSQL with pgpool-II for connection pooling and failover

## 📖 Usage

### Accessing the Application
Once deployed, access the web application at:
- **URL**: http://192.168.122.100
- **Health Check**: http://192.168.122.100/health

### Demo Commands
Run the demo presentation:
```bash
./scripts/demo-commands.sh
```

### Infrastructure Verification
Check the health of all components:
```bash
./scripts/quick-verify.sh
```

## 🔄 Deployment Process

1. **Prerequisites Setup** (`00-prerequisites-setup.yml`):
   - Install required packages
   - Configure system settings
   - Set up networking

2. **Load Balancer Setup** (`01-loadbalancer-setup.yml`):
   - Install and configure HAProxy
   - Set up Keepalived for VIP management

3. **Application Deployment** (`02-app-setup-enhanced.yml`):
   - Deploy Flask application
   - Configure Docker containers
   - Set up reverse proxy

4. **Redis Setup** (`03-redis-setup.yml`):
   - Install Redis servers
   - Configure master-slave replication

5. **Database Setup** (`04-database-setup.yml`):
   - Install PostgreSQL
   - Configure pgpool-II
   - Set up replication

6. **Integration Testing** (`05-integration-testing.yml`):
   - Run automated tests
   - Verify component communication

## 🛠️ Development

### Local Development
1. Set up Python environment:
   ```bash
   cd application
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

2. Run the Flask application:
   ```bash
   python enhanced_backend.py
   ```

3. Access at: http://localhost:5000

### Modifying Infrastructure
- Edit Ansible playbooks in `ansible_scripts/`
- Update application code in `application/`
- Modify configurations as needed

## 🤝 Contributing
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License
This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support
For questions or issues:
- Check the `documentation/infrastructure-guidebook.md`
- Review Ansible playbook outputs
- Verify VM connectivity and configurations

## 🔗 Related Documentation
- [Infrastructure Guidebook](documentation/infrastructure-guidebook.md)
- [Presentation Flow](documentation/presentation-flow.md)
