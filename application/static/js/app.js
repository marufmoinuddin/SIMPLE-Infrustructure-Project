// Enhanced SIMPLE Application JavaScript
let statsInterval;
let isAutoRefresh = false;

function startStatsMonitoring() {
    if (!isAutoRefresh) {
        isAutoRefresh = true;
        statsInterval = setInterval(loadStats, 5000);
        document.getElementById('autoRefreshBtn').textContent = 'Stop Auto Refresh';
        document.getElementById('autoRefreshBtn').classList.add('btn-warning');
    } else {
        isAutoRefresh = false;
        clearInterval(statsInterval);
        document.getElementById('autoRefreshBtn').textContent = 'Start Auto Refresh';
        document.getElementById('autoRefreshBtn').classList.remove('btn-warning');
    }
}

function formatJSON(obj) {
    return JSON.stringify(obj, null, 2);
}

function updateResponseArea(elementId, content, type = 'info') {
    const element = document.getElementById(elementId);
    element.textContent = typeof content === 'object' ? formatJSON(content) : content;
    element.className = 'response-area ' + type;
}

function setButtonLoading(buttonId, loading) {
    const button = document.getElementById(buttonId);
    button.disabled = loading;
    if (loading) {
        button.textContent = button.textContent.replace('Test', 'Testing...');
        button.classList.add('pulsing');
    } else {
        button.textContent = button.textContent.replace('Testing...', 'Test');
        button.classList.remove('pulsing');
    }
}

// Enhanced API call function with better error handling
async function makeAPICall(endpoint, buttonId, responseId) {
    setButtonLoading(buttonId, true);
    updateResponseArea(responseId, 'Loading...', 'loading');
    
    try {
        const response = await fetch(endpoint);
        const data = await response.json();
        
        if (response.ok) {
            updateResponseArea(responseId, data, 'success');
        } else {
            updateResponseArea(responseId, `Error: ${data.error || 'Unknown error'}`, 'error');
        }
    } catch (error) {
        updateResponseArea(responseId, `Network Error: ${error.message}`, 'error');
    } finally {
        setButtonLoading(buttonId, false);
    }
}

// Enhanced stats loading with real-time updates
async function loadStats() {
    try {
        const response = await fetch('/api/infrastructure/status');
        const data = await response.json();
        
        if (response.ok) {
            // Update server info
            document.getElementById('serverInfo').innerHTML = `
                <strong>Server:</strong> ${data.server.hostname} (${data.server.ip})<br>
                <strong>Timestamp:</strong> ${data.timestamp}
            `;
            
            // Update Redis status
            const redis = data.components.redis;
            if (redis.status === 'connected') {
                document.getElementById('redisStatus').innerHTML = `
                    <div class="stat-card status-connected">
                        <h4>✅ Redis Master</h4>
                        <p><strong>Host:</strong> ${redis.host}:${redis.port}</p>
                        <p><strong>Memory:</strong> ${redis.memory_usage}</p>
                        <p><strong>Clients:</strong> ${redis.connected_clients}</p>
                        <p><strong>Keys:</strong> ${redis.keys_count}</p>
                    </div>
                `;
            } else {
                document.getElementById('redisStatus').innerHTML = `
                    <div class="stat-card status-error">
                        <h4>❌ Redis Master</h4>
                        <p>Error: ${redis.error || 'Connection failed'}</p>
                    </div>
                `;
            }
            
            // Update Database status
            const db = data.components.database;
            if (db.status === 'connected') {
                document.getElementById('dbStatus').innerHTML = `
                    <div class="stat-card status-connected">
                        <h4>✅ PostgreSQL + pgpool</h4>
                        <p><strong>Host:</strong> ${db.host}:${db.port}</p>
                        <p><strong>Users:</strong> ${db.stats.total_users}</p>
                        <p><strong>Active Sessions:</strong> ${db.stats.active_sessions}</p>
                        <p><strong>DB Size:</strong> ${db.stats.database_size}</p>
                    </div>
                `;
            } else {
                document.getElementById('dbStatus').innerHTML = `
                    <div class="stat-card status-error">
                        <h4>❌ PostgreSQL + pgpool</h4>
                        <p>Error: ${db.error || 'Connection failed'}</p>
                    </div>
                `;
            }
            
            // Update Application stats
            const app = data.components.application;
            document.getElementById('appStatus').innerHTML = `
                <div class="stat-card status-connected">
                    <h4>✅ Application Server</h4>
                    <p><strong>Status:</strong> ${app.status}</p>
                    <p><strong>Uptime:</strong> ${app.stats.uptime_human}</p>
                    <p><strong>Requests:</strong> ${app.stats.requests}</p>
                    <p><strong>Req/min:</strong> ${app.stats.requests_per_minute}</p>
                </div>
            `;
            
        }
    } catch (error) {
        console.error('Failed to load stats:', error);
    }
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', function() {
    loadStats();
});
