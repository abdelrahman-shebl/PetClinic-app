# Spring PetClinic
## Getting Started

### Prerequisites
- Docker installed on your system
- Git for cloning the repository

### Quick Start with Docker

1. **Clone the repository**
   ```bash
   git clone https://github.com/spring-projects/spring-petclinic.git
   ```

2. **Navigate to the project directory**
   ```bash
   cd spring-petclinic
   ```

3. **Build the Docker image**
   ```bash
   docker build -t petclinic-app .
   ```

4. **Run the container**
   ```bash
   docker run -d -p 3000:3000 petclinic --server.port=3000
   ```

5. **Access the application**
   Open your browser and navigate to: `http://localhost:3000`

## Development

### Running without Docker

If you prefer to run the application directly:

```bash
# Using Maven (requires Java 17+)
./mvnw spring-boot:run

# Using Gradle
./gradlew bootRun
```
