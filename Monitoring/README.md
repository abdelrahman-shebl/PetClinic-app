# Complete Monitoring Stack with Prometheus, Grafana, and Exporters

## Overview

This comprehensive monitoring stack combines multiple open-source tools to provide complete observability for containerized applications and infrastructure. The stack includes container monitoring, system metrics, database monitoring, and visualization capabilities.

## Architecture Components

### 1. **cAdvisor (Container Advisor)**

#### Purpose
cAdvisor is Google's container monitoring tool that provides resource usage and performance metrics for running containers. It automatically discovers all containers on the host and collects CPU, memory, filesystem, and network usage statistics.

#### Key Features
- Real-time container resource monitoring
- Historical usage statistics
- Support for Docker, LXC, and other container runtimes
- Built-in web UI for visualization
- REST API for metrics collection

#### Configuration Details

```yaml
cadvisor:
    image: google/cadvisor:latest
    container_name: cadvisor
    ports:
      - "8085:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /proc:/host/proc
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk:/dev/disk:ro
    networks:
      - monitoring
```

**Port Configuration:**
- `8085:8080` - Maps host port 8085 to container port 8080 for web UI access

**Volume Mounts Explained:**
- `/:/rootfs:ro` - Read-only access to host root filesystem for container discovery
- `/var/run:/var/run:ro` - Access to Docker socket and runtime information
- `/proc:/host/proc` - Host process information for system metrics
- `/sys:/sys:ro` - Host system information and cgroup data
- `/var/lib/docker/:/var/lib/docker:ro` - Docker container storage information
- `/dev/disk:/dev/disk:ro` - Disk device information for storage metrics

**Access:** Web UI available at `http://localhost:8085`

---

### 2. **Node Exporter**

#### Purpose
Node Exporter is a Prometheus exporter that collects hardware and OS-level metrics from Unix-like systems. It provides detailed system metrics including CPU, memory, disk, network, and filesystem statistics.

#### Key Features
- Hardware metrics (CPU, memory, disk I/O)
- Operating system metrics
- Network interface statistics
- Filesystem usage and availability
- System load and uptime information

#### Configuration Details

```yaml
node-exporter:
  image: prom/node-exporter:latest
  container_name: node-exporter
  ports:
    - "9100:9100"
  command:
    - '--path.sysfs=/host/sys'
    - '--path.procfs=/host/proc'
    - '--collector.filesystem.ignored-mount-points=^/(sys|proc|dev|host|etc)($$|/)'
    - '--no-collector.ipvs'
  volumes:
    - /:/rootfs:ro
    - /proc:/host/proc
    - /sys:/host/sys
  networks:
    - monitoring
  restart: unless-stopped
```

**Port Configuration:**
- `9100:9100` - Standard Prometheus metrics endpoint

**Command Arguments Explained:**
- `--path.sysfs=/host/sys` - Points to host system filesystem information
- `--path.procfs=/host/proc` - Points to host process information
- `--collector.filesystem.ignored-mount-points` - Regex to ignore system mounts
- `--no-collector.ipvs` - Disables IPVS collector (not needed in most setups)

**Volume Mounts:**
- `/proc:/host/proc` - Host process information
- `/sys:/host/sys` - Host system information
- `/:/rootfs:ro` - Read-only root filesystem access

**Restart Policy:** `unless-stopped` ensures the exporter restarts automatically

---

### 3. **MySQL Exporter**

#### Purpose
MySQL Exporter collects MySQL/MariaDB server metrics and exposes them in Prometheus format. It provides database performance metrics, connection statistics, query performance, and replication status.

#### Key Features
- Database performance metrics
- Connection pool statistics
- Query execution metrics
- InnoDB engine metrics
- Replication lag monitoring
- Table and index statistics

#### Configuration Details

```yaml
mysql-exporter:
  image: prom/mysqld-exporter:latest
  container_name: mysql-exporter
  command:
    - --mysqld.username=petclinic
    - --mysqld.address=mysql-db:3306
  environment:
    - MYSQLD_EXPORTER_PASSWORD=petclinic
  ports:
    - "9104:9104"
  networks:
    - monitoring
    - net
```

**Command Arguments:**
- `--mysqld.username=petclinic` - Database username for connection
- `--mysqld.address=mysql-db:3306` - Database host and port

**Environment Variables:**
- `MYSQLD_EXPORTER_PASSWORD=petclinic` - Database password (consider using secrets)

**Network Configuration:**
- `monitoring` - For Prometheus scraping
- `net` - For database connectivity

#### Required Database Setup

**Step 1: Access the MySQL Container**
```bash
# Method 1: Using docker exec to access MySQL container directly
docker exec -it mysql-db mysql -u root -p

# Method 2: If MySQL container name is different, find it first
docker ps | grep mysql
docker exec -it <mysql_container_name> mysql -u root -p

# Method 3: Using docker-compose (if using compose)
docker-compose exec mysql-db mysql -u root -p
```

**Step 2: Create Monitoring User and Grant Privileges**
```sql
-- Create dedicated monitoring user
CREATE USER 'petclinic'@'%' IDENTIFIED BY 'petclinic';

-- Grant required privileges for comprehensive monitoring
GRANT PROCESS ON *.* TO 'petclinic'@'%';
GRANT REPLICATION CLIENT ON *.* TO 'petclinic'@'%';
GRANT SELECT ON performance_schema.* TO 'petclinic'@'%';
GRANT SELECT ON information_schema.* TO 'petclinic'@'%';
GRANT SELECT ON mysql.* TO 'petclinic'@'%';

-- Additional privileges for detailed metrics
GRANT SELECT ON sys.* TO 'petclinic'@'%';
GRANT SLAVE MONITOR ON *.* TO 'petclinic'@'%'; -- For MariaDB

-- Apply changes
FLUSH PRIVILEGES;

-- Verify user creation and privileges
SELECT User, Host FROM mysql.user WHERE User='petclinic';
SHOW GRANTS FOR 'petclinic'@'%';

-- Exit MySQL
EXIT;
```

**Key Privileges Explained:**
- `PROCESS` - View running processes and queries
- `REPLICATION CLIENT` - Access replication status
- `SELECT on performance_schema.*` - Performance metrics access
- `SELECT on information_schema.*` - Schema and table metadata
- `SELECT on mysql.*` - MySQL system tables
- `SELECT on sys.*` - MySQL 5.7+ sys schema views

---

### 4. **PostgreSQL Exporter**

#### Purpose
PostgreSQL Exporter collects PostgreSQL database metrics and exposes them for Prometheus scraping. It provides detailed database performance, connection, and operational metrics.

#### Key Features
- Database connection metrics
- Query performance statistics
- Table and index usage metrics
- Transaction and lock information
- WAL (Write-Ahead Logging) metrics
- Replication status monitoring

#### Configuration Details

```yaml
postgres-exporter:
  image: wrouesnel/postgres_exporter
  container_name: postgres-exporter
  environment:
    - DATA_SOURCE_NAME=postgresql://petclinic:petclinic@pg-db:5432/petclinic?sslmode=disable
  ports:
    - "9187:9187"
  networks:
    - monitoring
    - net
```

**Environment Variables:**
- `DATA_SOURCE_NAME` - PostgreSQL connection string with format:
  - `postgresql://username:password@host:port/database?options`
  - `sslmode=disable` - Disables SSL (use `require` in production)

#### Required Database Setup

**Step 1: Access the PostgreSQL Container**
```bash
# Method 1: Using docker exec to access PostgreSQL container as postgres user
docker exec -it pg-db psql -U postgres

# Method 2: Access specific database directly
docker exec -it pg-db psql -U postgres -d petclinic

# Method 3: If container name is different, find it first
docker ps | grep postgres
docker exec -it <postgres_container_name> psql -U postgres

# Method 4: Using docker-compose (if using compose)
docker-compose exec pg-db psql -U postgres -d petclinic
```

**Step 2: Create Monitoring User and Grant Privileges**
```sql
-- Connect to the target database first
\c petclinic;

-- Create monitoring user
CREATE USER petclinic WITH PASSWORD 'petclinic';

-- Grant connection privileges
GRANT CONNECT ON DATABASE petclinic TO petclinic;

-- Grant schema usage
GRANT USAGE ON SCHEMA public TO petclinic;
GRANT USAGE ON SCHEMA information_schema TO petclinic;

-- Grant read access to system catalogs
GRANT SELECT ON ALL TABLES IN SCHEMA information_schema TO petclinic;
GRANT SELECT ON ALL TABLES IN SCHEMA pg_catalog TO petclinic;

-- Grant read access to statistics views
GRANT SELECT ON pg_stat_database TO petclinic;
GRANT SELECT ON pg_stat_user_tables TO petclinic;
GRANT SELECT ON pg_stat_user_indexes TO petclinic;
GRANT SELECT ON pg_stat_activity TO petclinic;
GRANT SELECT ON pg_stat_replication TO petclinic;
GRANT SELECT ON pg_stat_bgwriter TO petclinic;
GRANT SELECT ON pg_stat_archiver TO petclinic;

-- Additional system views
GRANT SELECT ON pg_settings TO petclinic;
GRANT SELECT ON pg_locks TO petclinic;
GRANT SELECT ON pg_stat_statements TO petclinic; -- If extension is installed

-- For PostgreSQL 10+ (monitoring role) - This grants most of the above automatically
GRANT pg_monitor TO petclinic;

-- Exit PostgreSQL
\q;
```

**Step 3: Alternative Simplified Approach (PostgreSQL 10+)**
```sql
-- Connect to database
\c petclinic;

-- Create user and grant monitoring role (includes most required permissions)
CREATE USER petclinic WITH PASSWORD 'petclinic';
GRANT CONNECT ON DATABASE petclinic TO petclinic;
GRANT pg_monitor TO petclinic;

```
---

### 5. **Prometheus**

#### Purpose
Prometheus is a time-series database and monitoring system that collects metrics from configured targets, stores them, and provides a query language (PromQL) for analysis. It serves as the central data collection and storage component.

#### Key Features
- Time-series data collection and storage
- Powerful query language (PromQL)
- Built-in alerting capabilities
- Service discovery mechanisms
- Multi-dimensional data model
- HTTP pull-based metric collection

#### Configuration Details

```yaml
prometheus:
  image: prom/prometheus
  container_name: prometheus
  ports:
    - "9090:9090"
  volumes:
    - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
    - prometheus_data:/prometheus
  depends_on:
    - node-exporter
    - cadvisor
    - mysql-exporter
  networks:
    - monitoring
```

**Port Configuration:**
- `9090:9090` - Prometheus web UI and API endpoint

**Volume Mounts:**
- `./prometheus.yml:/etc/prometheus/prometheus.yml:ro` - Configuration file
- `prometheus_data:/prometheus` - Persistent data storage

**Dependencies:**
- Ensures exporters start before Prometheus

#### Sample Prometheus Configuration (`prometheus.yml`):

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
    scrape_interval: 30s

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']
    scrape_interval: 30s

  - job_name: 'mysql-exporter'
    static_configs:
      - targets: ['mysql-exporter:9104']
    scrape_interval: 30s

  - job_name: 'postgres-exporter'
    static_configs:
      - targets: ['postgres-exporter:9187']
    scrape_interval: 30s
```

---

### 6. **Grafana**

#### Purpose
Grafana is a visualization and analytics platform that creates dashboards and graphs from Prometheus data. It provides rich, interactive dashboards for monitoring and alerting.

#### Key Features
- Rich dashboard creation
- Multiple data source support
- Advanced visualization options
- Alerting and notifications
- User management and permissions
- Template variables and dynamic dashboards

#### Configuration Details

```yaml
grafana:
  image: grafana/grafana:11.5-ubuntu
  container_name: grafana
  ports:
    - "3000:3000"
  volumes:
    - grafana_data:/var/lib/grafana
  networks:
    - monitoring
```

**Port Configuration:**
- `3000:3000` - Grafana web interface

**Volume Mounts:**
- `grafana_data:/var/lib/grafana` - Persistent dashboard and configuration storage

**Default Credentials:**
- Username: `admin`
- Password: `admin` (change on first login)

#### Initial Setup Steps

1. **Add Prometheus as Data Source:**
   - Go to Configuration → Data Sources
   - Click "Add data source"
   - Select "Prometheus"
   - Set URL: `http://prometheus:9090`
   - Click "Save & Test"

2. **Import Dashboard Templates:**
   - Go to "+" → Import
   - Use dashboard IDs or upload JSON files
   - Configure data source mappings

---

## Network Configuration

### Networks Explained

```yaml
networks:
  monitoring:  # Internal network for monitoring components
  net:        # Database connectivity network
```

**monitoring network:**
- Isolates monitoring components
- Enables secure inter-service communication
- Prometheus can reach all exporters

**net network:**
- Connects exporters to databases
- Shared with application containers
- Enables database metric collection

---

## Volume Configuration

```yaml
volumes:
  prometheus_data:  # Persistent storage for Prometheus metrics
  grafana_data:     # Persistent storage for Grafana dashboards and config
```

**prometheus_data:**
- Stores time-series metrics data
- Survives container restarts
- Essential for historical data retention

**grafana_data:**
- Stores dashboards, users, and settings
- Maintains configuration across restarts
- Contains data source configurations

---
### Access Points
- **Grafana Dashboard:** http://localhost:3000 (admin/admin)
- **Prometheus UI:** http://localhost:9090
- **cAdvisor UI:** http://localhost:8085
- **Node Exporter Metrics:** http://localhost:9100/metrics
- **MySQL Exporter Metrics:** http://localhost:9104/metrics
- **PostgreSQL Exporter Metrics:** http://localhost:9187/metrics

---

## Recommended Grafana Dashboards

### 1. **Node Exporter Dashboards**

#### **Dashboard: Node Exporter Full (ID: 1860)**
- **Purpose**: Comprehensive system monitoring dashboard
- **Metrics Covered**:
  - CPU usage, load average, and core utilization
  - Memory usage, swap utilization, and buffer/cache
  - Disk I/O, filesystem usage, and mount points
  - Network traffic, packet rates, and error rates
  - System uptime and process statistics

**Import Steps:**
```bash
 In Grafana UI:
 1. Go to "+" → Import
 2. Enter Dashboard ID: 1860
 3. Select Prometheus data source
 4. Click Import
```
### 2. **cAdvisor Container Monitoring Dashboards**

#### **Dashboard: Docker Container & Host Metrics (ID: 179)**
- **Purpose**: Container resource monitoring and performance
- **Metrics Covered**:
  - Container CPU usage per container
  - Container memory usage and limits
  - Container network I/O
  - Container filesystem usage
  - Container restart counts and status

### 3. **MySQL Database Dashboards**

#### **Dashboard: MySQL Overview (ID: 7362)**
- **Purpose**: Comprehensive MySQL performance monitoring
- **Metrics Covered**:
  - Connection statistics and active sessions
  - Query performance (QPS, slow queries)
  - InnoDB metrics (buffer pool, transactions)
  - Replication lag and status
  - Table and index usage statistics

### 4. **PostgreSQL Database Dashboards**

#### **Dashboard: PostgreSQL Database (ID: 9628)**
- **Purpose**: PostgreSQL performance and health monitoring
- **Metrics Covered**:
  - Database connections and session statistics
  - Transaction rates and commit/rollback ratios
  - Table and index usage metrics
  - Lock statistics and wait events
  - WAL generation and checkpoint performance