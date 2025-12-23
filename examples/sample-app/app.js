const express = require('express');
const morgan = require('morgan');
const os = require('os');

const app = express();
const PORT = process.env.PORT || 3000;
const VERSION = process.env.APP_VERSION || '1.0.0';

// Middleware
app.use(morgan('combined'));
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    version: VERSION
  });
});

// Ready check endpoint
app.get('/ready', (req, res) => {
  res.status(200).json({
    status: 'ready',
    timestamp: new Date().toISOString()
  });
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'Welcome to AWS ECS Demo Application',
    version: VERSION,
    hostname: os.hostname(),
    platform: os.platform(),
    architecture: os.arch(),
    environment: process.env.NODE_ENV || 'production',
    region: process.env.AWS_REGION || 'unknown'
  });
});

// API endpoint
app.get('/api/info', (req, res) => {
  const info = {
    application: 'ECS Demo App',
    version: VERSION,
    server: {
      hostname: os.hostname(),
      platform: os.platform(),
      architecture: os.arch(),
      cpus: os.cpus().length,
      totalMemory: `${(os.totalmem() / 1024 / 1024 / 1024).toFixed(2)} GB`,
      freeMemory: `${(os.freemem() / 1024 / 1024 / 1024).toFixed(2)} GB`,
      uptime: `${(os.uptime() / 60 / 60).toFixed(2)} hours`
    },
    process: {
      nodeVersion: process.version,
      pid: process.pid,
      uptime: `${(process.uptime() / 60).toFixed(2)} minutes`,
      memoryUsage: process.memoryUsage()
    },
    environment: {
      nodeEnv: process.env.NODE_ENV || 'production',
      awsRegion: process.env.AWS_REGION || 'unknown',
      port: PORT
    },
    timestamp: new Date().toISOString()
  };
  
  res.json(info);
});

// Metrics endpoint (Prometheus format)
app.get('/metrics', (req, res) => {
  const metrics = `
# HELP app_info Application information
# TYPE app_info gauge
app_info{version="${VERSION}",hostname="${os.hostname()}"} 1

# HELP process_uptime_seconds Process uptime in seconds
# TYPE process_uptime_seconds gauge
process_uptime_seconds ${process.uptime()}

# HELP system_memory_total_bytes Total system memory in bytes
# TYPE system_memory_total_bytes gauge
system_memory_total_bytes ${os.totalmem()}

# HELP system_memory_free_bytes Free system memory in bytes
# TYPE system_memory_free_bytes gauge
system_memory_free_bytes ${os.freemem()}

# HELP process_cpu_usage Process CPU usage
# TYPE process_cpu_usage gauge
process_cpu_usage ${process.cpuUsage().user / 1000000}
  `.trim();
  
  res.set('Content-Type', 'text/plain');
  res.send(metrics);
});

// Simulate load endpoint (for testing auto-scaling)
app.get('/api/load/:duration', (req, res) => {
  const duration = parseInt(req.params.duration) || 5000;
  const start = Date.now();
  
  // CPU intensive operation
  while (Date.now() - start < duration) {
    Math.sqrt(Math.random());
  }
  
  res.json({
    message: 'Load simulation completed',
    duration: `${duration}ms`,
    actualDuration: `${Date.now() - start}ms`
  });
});

// Error simulation endpoint (for testing monitoring)
app.get('/api/error', (req, res) => {
  throw new Error('Simulated error for monitoring testing');
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    path: req.path,
    timestamp: new Date().toISOString()
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Error:', err.message);
  res.status(500).json({
    error: 'Internal Server Error',
    message: err.message,
    timestamp: new Date().toISOString()
  });
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
    process.exit(0);
  });
});

const server = app.listen(PORT, () => {
  console.log(`
    ╔═══════════════════════════════════════╗
    ║   AWS ECS Demo Application Started   ║
    ╠═══════════════════════════════════════╣
    ║  Version: ${VERSION.padEnd(27)} ║
    ║  Port:    ${PORT.toString().padEnd(27)} ║
    ║  Environment: ${(process.env.NODE_ENV || 'production').padEnd(21)} ║
    ║  Hostname: ${os.hostname().padEnd(24)} ║
    ╚═══════════════════════════════════════╝
  `);
  console.log(`Health check: http://localhost:${PORT}/health`);
  console.log(`Ready check:  http://localhost:${PORT}/ready`);
  console.log(`API info:     http://localhost:${PORT}/api/info`);
  console.log(`Metrics:      http://localhost:${PORT}/metrics`);
});

module.exports = app;
