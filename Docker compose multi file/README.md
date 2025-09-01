# PetClinic Multi-Environment Docker Compose Deployment

## Overview

This repository contains a multi-file Docker Compose setup for deploying the Spring PetClinic application with support for both MySQL and PostgreSQL databases across different environments (development and production). The architecture uses Docker Compose's file override feature to manage environment-specific configurations.

## Architecture Components

### File Structure
```
├── docker-compose.yml           # Base application configuration
├── docker-compose.dev.yml       # Development environment (MySQL)
├── docker-compose.prod.yml      # Production environment (PostgreSQL)
├── dev.env                      # Development application environment variables
├── dev.secrets.env              # Development database secrets
├── prod.env                     # Production application environment variables
└── prod.secrets.env             # Production database secrets
```

## Configuration Files Breakdown

### 1. **Base Configuration (`docker-compose.yml`)**

#### Purpose
Defines the core PetClinic application service with minimal configuration that's shared across all environments.

#### Configuration Details
```yaml
services:
  app:
    image: petclinic
    ports:
      - 5000:5000
    environment:
      - SERVER_PORT=5000
    depends_on:
      - db
    networks:
      - net 

networks:
  net: 
```

**Service Configuration:**
- **Image**: `petclinic` - Pre-built application image
- **Port Mapping**: `5000:5000` - Exposes application on port 5000
- **Environment**: Sets `SERVER_PORT=5000` for Spring Boot
- **Dependencies**: Waits for `db` service to start
- **Network**: Uses `net` network for service communication

**Design Pattern:**
- Contains only essential, environment-agnostic configuration
- Serves as foundation for environment-specific overrides
- Database service intentionally omitted (defined in override files)

---

### 2. **Development Environment (`docker-compose.dev.yml`)**

#### Purpose
Extends base configuration with MySQL database and development-specific settings.

#### Configuration Details
```yaml
services:
  app:
    env_file:
      - dev.env
    depends_on:
      - db

  db:
    image: mysql:9.2
    container_name: mysql-db
    ports:
      - "3306:3306"
    env_file:
      - dev.secrets.env
    networks:
      - net
    volumes:
      - vol1:/var/lib/mysql

volumes:
  vol1:

networks:
  net:
```

**App Service Overrides:**
- **env_file**: Loads `dev.env` for MySQL-specific configuration
- **depends_on**: Reinforces database dependency

**Database Service (MySQL 9.2):**
- **Container Name**: `mysql-db` for easy identification
- **Port Exposure**: `3306:3306` for external MySQL client access
- **Environment**: Loads `dev.secrets.env` for database credentials
- **Data Persistence**: `vol1` volume for MySQL data directory
- **Network**: Shares `net` network with application

**Development Features:**
- Exposed database port for local development tools
- Named containers for easier debugging
- Persistent storage for data retention

---

### 3. **Production Environment (`docker-compose.prod.yml`)**

#### Purpose
Extends base configuration with PostgreSQL database and production-focused security settings.

#### Configuration Details
```yaml
services:
  app:
    env_file:
      - prod.env
      
  db:
    image: postgres:17.5
    container_name: pg-db
    ports:
      - 5432 
    env_file:
      - prod.secrets.env
    networks:
      - net 
    volumes:
      - vol2:/var/lib/postgresql/data

volumes:
  vol2:
```

**App Service Overrides:**
- **env_file**: Loads `prod.env` for PostgreSQL-specific configuration

**Database Service (PostgreSQL 17.5):**
- **Container Name**: `pg-db` for production identification
- **Port Configuration**: `5432` (internal only - no host mapping for security)
- **Environment**: Loads `prod.secrets.env` for database credentials
- **Data Persistence**: `vol2` volume for PostgreSQL data directory
- **Network**: Internal `net` network communication only

**Production Security Features:**
- No external port exposure (port 5432 not mapped to host)
- Internal network communication only
- Separate volume for production data isolation

---

## Environment Variable Files

### 4. **Development Application Config (`dev.env`)**

```env
SERVER_PORT=5000
SPRING_PROFILES_ACTIVE=mysql
SPRING_DATASOURCE_URL=jdbc:mysql://db:3306/petclinic
SPRING_DATASOURCE_USERNAME=petclinic
SPRING_DATASOURCE_PASSWORD=petclinic
```

**Configuration Breakdown:**
- **SERVER_PORT**: Spring Boot server port (5000)
- **SPRING_PROFILES_ACTIVE**: Activates MySQL profile in Spring Boot
- **SPRING_DATASOURCE_URL**: MySQL JDBC connection string
  - `db:3306` uses Docker service name for internal connectivity
  - `petclinic` database name
- **Database Credentials**: Username and password for application database access

**MySQL JDBC URL Format:**
- `jdbc:mysql://[host]:[port]/[database]`
- Uses Docker service discovery (`db` resolves to MySQL container IP)

---

### 5. **Development Database Secrets (`dev.secrets.env`)**

```env
MYSQL_USER=petclinic
MYSQL_PASSWORD=petclinic
MYSQL_ROOT_PASSWORD=root
MYSQL_DATABASE=petclinic
```

**MySQL Environment Variables:**
- **MYSQL_USER**: Creates application user during initialization
- **MYSQL_PASSWORD**: Password for application user
- **MYSQL_ROOT_PASSWORD**: MySQL root user password
- **MYSQL_DATABASE**: Creates `petclinic` database on startup

**Security Considerations:**
- Separate file for database secrets
- Should use stronger passwords in actual development
- Consider using Docker secrets in production

---

### 6. **Production Application Config (`prod.env`)**

```env
SERVER_PORT=5000
SPRING_PROFILES_ACTIVE=postgres
SPRING_DATASOURCE_URL=jdbc:postgresql://db:5432/petclinic
SPRING_DATASOURCE_USERNAME=petclinic
SPRING_DATASOURCE_PASSWORD=petclinic
```

**Configuration Breakdown:**
- **SPRING_PROFILES_ACTIVE**: Activates PostgreSQL profile
- **SPRING_DATASOURCE_URL**: PostgreSQL JDBC connection string
  - `jdbc:postgresql://[host]:[port]/[database]`
  - Uses `db` service name for internal communication
- **Database Credentials**: PostgreSQL application user credentials

**PostgreSQL vs MySQL Differences:**
- Different JDBC driver and URL format
- PostgreSQL-specific Spring Boot profile
- Different default port (5432 vs 3306)

---

### 7. **Production Database Secrets (`prod.secrets.env`)**

```env
POSTGRES_USER=petclinic
POSTGRES_PASSWORD=petclinic
POSTGRES_DB=petclinic
```

**PostgreSQL Environment Variables:**
- **POSTGRES_USER**: Creates application user during initialization
- **POSTGRES_PASSWORD**: Password for application user
- **POSTGRES_DB**: Creates `petclinic` database on startup

**PostgreSQL Initialization:**
- Automatically creates user and database
- User has full privileges on created database
- No separate root user (uses `postgres` superuser)

---

## Deployment Instructions

### Prerequisites
```bash
# Ensure Docker and Docker Compose are installed
docker --version
docker-compose --version

# Verify PetClinic image is available
docker images | grep petclinic
```

### Development Deployment (MySQL)

```bash
# Using -f flag for explicit file specification
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Verify services are running
docker-compose -f docker-compose.yml -f docker-compose.dev.yml ps

# Check application logs
docker-compose -f docker-compose.yml -f docker-compose.dev.yml logs app

# Check MySQL logs
docker-compose -f docker-compose.yml -f docker-compose.dev.yml logs db
```

**Service Access:**
- **PetClinic Application**: http://localhost:5000
- **MySQL Database**: localhost:3306 (accessible via MySQL clients)

### Production Deployment (PostgreSQL)

```bash
# Deploy production environment
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Verify deployment
docker-compose -f docker-compose.yml -f docker-compose.prod.yml ps

# Monitor application startup
docker-compose -f docker-compose.yml -f docker-compose.prod.yml logs -f app

# Check PostgreSQL initialization
docker-compose -f docker-compose.yml -f docker-compose.prod.yml logs db
```

**Service Access:**
- **PetClinic Application**: http://localhost:5000
- **PostgreSQL Database**: Internal only (no external port exposure)


---

## Management Commands

### Environment Switching

```bash
# Stop current environment
docker-compose down

# Switch from development to production
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Switch from production to development
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

### Service Scaling

```bash
# Scale application instances (load balancing)
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d --scale app=3
```

---

#### **Port Conflicts**
```bash
# Check port usage
netstat -nltp | grep :5000
netstat -nltp | grep :3306
netstat -nltp | grep :5432

# Use different ports if needed
# Edit port mapping in docker-compose files
```

### Health Checks
```yaml
# Add to app service
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:5000/actuator/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 60s

# Add to database services
# MySQL:
healthcheck:
  test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
  interval: 10s
  timeout: 5s
  retries: 5

# PostgreSQL:
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U petclinic"]
  interval: 10s
  timeout: 5s
  retries: 5
```