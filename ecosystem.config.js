module.exports = {
  apps: [{
    name: 'fin-custome-app',
    script: 'npm',
    args: 'start',
    cwd: '/fin-custome',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: '/fin-custome/logs/err.log',
    out_file: '/fin-custome/logs/out.log',
    log_file: '/fin-custome/logs/combined.log',
    time: true
  }]
};