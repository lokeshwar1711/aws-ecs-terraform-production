# Sample Application for AWS ECS

This is a production-ready Node.js application designed to demonstrate AWS ECS deployment with the Terraform infrastructure.

## Features

- ✅ Health check endpoints
- ✅ Prometheus metrics endpoint
- ✅ Graceful shutdown handling
- ✅ Structured logging
- ✅ Error handling
- ✅ Load simulation (for auto-scaling testing)
- ✅ Multi-stage Docker build
- ✅ Non-root container user
- ✅ Security best practices

## API Endpoints

### Health & Readiness

- `GET /health` - Health check endpoint
  ```json
  {
    "status": "healthy",
    "timestamp": "2025-12-19T10:00:00.000Z",
    "uptime": 3600.5,
    "version": "1.0.0"
  }
  ```

- `GET /ready` - Readiness check endpoint
  ```json
  {
    "status": "ready",
    "timestamp": "2025-12-19T10:00:00.000Z"
  }
  ```

### Information

- `GET /` - Root endpoint with basic info
- `GET /api/info` - Detailed system information
  ```json
  {
    "application": "ECS Demo App",
    "version": "1.0.0",
    "server": {
      "hostname": "ip-10-0-1-123",
      "platform": "linux",
      "architecture": "x64",
      "cpus": 2,
      "totalMemory": "1.95 GB",
      "freeMemory": "0.82 GB"
    },
    "process": {
      "nodeVersion": "v18.19.0",
      "pid": 1,
      "uptime": "60.25 minutes"
    }
  }
  ```

### Monitoring

- `GET /metrics` - Prometheus-compatible metrics
  ```
  # HELP app_info Application information
  # TYPE app_info gauge
  app_info{version="1.0.0",hostname="container-123"} 1
  
  # HELP process_uptime_seconds Process uptime in seconds
  # TYPE process_uptime_seconds gauge
  process_uptime_seconds 3600.5
  ```

### Testing

- `GET /api/load/:duration` - Simulate CPU load (milliseconds)
  - Example: `/api/load/5000` - Simulates 5 seconds of CPU load
  - Useful for testing auto-scaling policies

- `GET /api/error` - Trigger an error (for monitoring testing)

## Local Development

### Prerequisites

- Node.js >= 18.0.0
- npm >= 9.0.0
- Docker (optional)

### Installation

```bash
npm install
```

### Running Locally

```bash
# Development mode with auto-reload
npm run dev

# Production mode
npm start
```

The application will be available at `http://localhost:3000`

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Server port | `3000` |
| `NODE_ENV` | Environment | `production` |
| `APP_VERSION` | Application version | `1.0.0` |
| `AWS_REGION` | AWS region | `unknown` |

## Docker

### Build Image

```bash
docker build -t ecs-demo-app:latest .
```

### Run Container

```bash
docker run -d \
  -p 3000:3000 \
  -e NODE_ENV=production \
  -e APP_VERSION=1.0.0 \
  --name ecs-demo \
  ecs-demo-app:latest
```

### Test Container

```bash
# Health check
curl http://localhost:3000/health

# Get info
curl http://localhost:3000/api/info

# View metrics
curl http://localhost:3000/metrics
```

### Multi-stage Build Benefits

This Dockerfile uses a multi-stage build:

1. **Builder stage**: Installs dependencies
2. **Production stage**: Copies only necessary files
3. **Result**: Smaller image size (~150MB vs ~1GB)

### Security Features

- ✅ Non-root user (nodejs:nodejs)
- ✅ Minimal Alpine base image
- ✅ dumb-init for proper signal handling
- ✅ Health checks configured
- ✅ No unnecessary packages
- ✅ Optimized layers

## Testing

```bash
# Run tests
npm test

# Run tests with coverage
npm run test -- --coverage

# Lint code
npm run lint

# Format code
npm run format
```

## Deployment

This application is designed to be deployed on AWS ECS using the Terraform infrastructure in this repository.

### Build and Push to ECR

```bash
# Authenticate to ECR
aws ecr get-login-password --region us-west-2 | \
  docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-west-2.amazonaws.com

# Build image
docker build -t ecs-demo-app:v1.0.0 .

# Tag image
docker tag ecs-demo-app:v1.0.0 \
  <account-id>.dkr.ecr.us-west-2.amazonaws.com/ecs-demo-app:v1.0.0

# Push image
docker push <account-id>.dkr.ecr.us-west-2.amazonaws.com/ecs-demo-app:v1.0.0
```

### ECS Task Definition

The application expects:
- Port 3000 exposed
- Health check on `/health` endpoint
- Environment variables set
- At least 512 MB memory
- At least 0.25 vCPU

## Monitoring

### CloudWatch Logs

The application logs to stdout/stderr, which is captured by CloudWatch Logs in ECS.

### Prometheus Metrics

The `/metrics` endpoint provides Prometheus-compatible metrics that can be scraped for monitoring.

### Health Checks

ALB health checks should be configured:
- Path: `/health`
- Interval: 30 seconds
- Timeout: 5 seconds
- Healthy threshold: 2
- Unhealthy threshold: 3

## Auto-scaling Testing

Test auto-scaling by generating load:

```bash
# Generate CPU load for 30 seconds
for i in {1..10}; do
  curl "http://<alb-dns>/api/load/30000" &
done
```

Monitor CloudWatch metrics to see auto-scaling in action.

## Troubleshooting

### Container Won't Start

Check logs:
```bash
docker logs ecs-demo
```

### Health Check Failing

Verify the application is listening:
```bash
docker exec ecs-demo netstat -tlnp
```

### High Memory Usage

Check memory usage:
```bash
docker stats ecs-demo
```

## Production Considerations

- ✅ Graceful shutdown implemented
- ✅ Health checks configured
- ✅ Proper error handling
- ✅ Structured logging
- ✅ Metrics exposed
- ✅ Security hardened
- ✅ Resource limits set
- ✅ Non-root user
- ✅ Signal handling (SIGTERM)

## License

MIT License - See LICENSE file for details
