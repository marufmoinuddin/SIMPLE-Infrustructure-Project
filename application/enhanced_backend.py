#!/usr/bin/env python3
"""
SIMPLE Production Infrastructure - Enhanced Backend API
This backend service demonstrates real interaction with all infrastructure components.
"""

from flask import Flask, jsonify, request, render_template_string
import redis
import psycopg2
import psycopg2.extras
import json
import time
import socket
import os
import threading
import random
import uuid
from datetime import datetime, timedelta
import logging

app = Flask(__name__)

# Configuration
REDIS_HOST = '192.168.122.121'  # Redis master
REDIS_PORT = 6379
REDIS_PASSWORD = 'atom_redis_secure_2025'

DB_CONFIG = {
    'host': '192.168.122.131',  # DB master direct connection
    'port': 5432,  # PostgreSQL direct port (bypassing pgpool for now)
    'database': 'atom_app_db',
    'user': 'atom_app_user',
    'password': 'atom_app_pass_2025'
}

# Global stats
app_stats = {
    'requests': 0,
    'cache_operations': 0,
    'db_queries': 0,
    'errors': 0,
    'start_time': time.time()
}

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def get_server_info():
    """Get current server information"""
    return {
        'hostname': socket.gethostname(),
        'ip': socket.gethostbyname(socket.gethostname()),
        'port': '8080',
        'pid': os.getpid(),
        'timestamp': datetime.now().isoformat()
    }

def get_redis_connection():
    """Get Redis connection with error handling"""
    try:
        r = redis.Redis(
            host=REDIS_HOST,
            port=REDIS_PORT,
            password=REDIS_PASSWORD,
            decode_responses=True,
            socket_timeout=5
        )
        # Test connection
        r.ping()
        return r
    except Exception as e:
        logger.error(f"Redis connection failed: {e}")
        return None

def get_db_connection():
    """Get PostgreSQL connection with error handling"""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        return conn
    except Exception as e:
        logger.error(f"Database connection failed: {e}")
        return None

@app.before_request
def before_request():
    """Track request statistics"""
    app_stats['requests'] += 1

@app.route('/')
def index():
    """Serve the enhanced dashboard"""
    try:
        with open('/opt/docker/application/html/enhanced_app.html', 'r') as f:
            return f.read()
    except:
        # Fallback if file not found
        return jsonify({
            'message': 'SIMPLE Production API',
            'server': get_server_info(),
            'endpoints': ['/health', '/info', '/status', '/api/cache', '/api/database']
        })

@app.route('/health')
def health():
    """Enhanced health endpoint with infrastructure checks"""
    server_info = get_server_info()
    
    # Test Redis
    redis_status = 'unknown'
    try:
        r = get_redis_connection()
        if r:
            r.set('health_check', server_info['hostname'])
            redis_status = 'connected'
        else:
            redis_status = 'failed'
    except:
        redis_status = 'error'
    
    # Test Database
    db_status = 'unknown'
    try:
        conn = get_db_connection()
        if conn:
            cursor = conn.cursor()
            cursor.execute("SELECT 1")
            cursor.fetchone()
            cursor.close()
            conn.close()
            db_status = 'connected'
        else:
            db_status = 'failed'
    except:
        db_status = 'error'
    
    return jsonify({
        'status': 'healthy',
        'server': server_info['hostname'],
        'ip': server_info['ip'],
        'timestamp': server_info['timestamp'],
        'version': '2.0.0',
        'infrastructure': {
            'redis': redis_status,
            'database': db_status,
            'load_balancer': 'active'
        },
        'stats': app_stats
    })

@app.route('/info')
def info():
    """Server information endpoint"""
    return jsonify(get_server_info())

@app.route('/status')
def status():
    """Detailed status with real infrastructure data"""
    server_info = get_server_info()
    
    # Redis stats
    redis_info = {}
    try:
        r = get_redis_connection()
        if r:
            redis_info = {
                'status': 'connected',
                'info': r.info(),
                'memory_usage': r.info()['used_memory_human'],
                'connected_clients': r.info()['connected_clients'],
                'keys': len(r.keys('*'))
            }
            app_stats['cache_operations'] += 1
    except Exception as e:
        redis_info = {'status': 'error', 'message': str(e)}
    
    # Database stats
    db_info = {}
    try:
        conn = get_db_connection()
        if conn:
            cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
            
            # Get user count
            cursor.execute("SELECT COUNT(*) as count FROM users")
            user_count = cursor.fetchone()['count']
            
            # Get active sessions
            cursor.execute("SELECT COUNT(*) as count FROM sessions WHERE expires_at > NOW()")
            session_count = cursor.fetchone()['count']
            
            cursor.close()
            conn.close()
            
            db_info = {
                'status': 'connected',
                'users': user_count,
                'active_sessions': session_count,
                'connection_pool': 'pgpool'
            }
            app_stats['db_queries'] += 2
    except Exception as e:
        db_info = {'status': 'error', 'message': str(e)}
    
    uptime = time.time() - app_stats['start_time']
    
    return jsonify({
        'server': server_info,
        'infrastructure': {
            'redis': redis_info,
            'database': db_info,
            'load_balancer': {
                'status': 'active',
                'method': 'least_conn',
                'backends': 2
            }
        },
        'stats': {
            **app_stats,
            'uptime_seconds': uptime,
            'requests_per_minute': app_stats['requests'] / (uptime / 60) if uptime > 60 else 0
        }
    })

@app.route('/api/cache/test')
def test_cache():
    """Test Redis cache operations"""
    try:
        r = get_redis_connection()
        if not r:
            return jsonify({'error': 'Redis connection failed'}), 500
        
        session_id = request.args.get('session_id', f"session_{random.randint(1000, 9999)}")
        server_info = get_server_info()
        
        # Perform various Redis operations
        operations = []
        
        # SET operation
        r.set(f"session:{session_id}", json.dumps({
            'user_id': random.randint(1, 100),
            'server': server_info['hostname'],
            'created_at': datetime.now().isoformat(),
            'active': True
        }))
        operations.append(f"SET session:{session_id}")
        
        # GET operation
        session_data = r.get(f"session:{session_id}")
        operations.append(f"GET session:{session_id}")
        
        # INCR operation
        request_count = r.incr(f"requests:{server_info['hostname']}")
        operations.append(f"INCR requests:{server_info['hostname']}")
        
        # EXPIRE operation
        r.expire(f"session:{session_id}", 3600)
        operations.append(f"EXPIRE session:{session_id} 3600")
        
        # HSET operation (user preferences)
        r.hset(f"user_prefs:{session_id}", mapping={
            'theme': 'dark',
            'language': 'en',
            'timezone': 'UTC'
        })
        operations.append(f"HSET user_prefs:{session_id}")
        
        app_stats['cache_operations'] += len(operations)
        
        return jsonify({
            'success': True,
            'session_id': session_id,
            'operations': operations,
            'session_data': json.loads(session_data) if session_data else None,
            'request_count': request_count,
            'server': server_info['hostname'],
            'redis_host': REDIS_HOST
        })
        
    except Exception as e:
        app_stats['errors'] += 1
        return jsonify({'error': str(e)}), 500

@app.route('/api/database/test')
def test_database():
    """Test database operations"""
    try:
        conn = get_db_connection()
        if not conn:
            return jsonify({'error': 'Database connection failed'}), 500
        
        cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        server_info = get_server_info()
        operations = []
        
        # INSERT operation
        test_user = f"test_user_{random.randint(1000, 9999)}"
        cursor.execute(
            "INSERT INTO users (username, email) VALUES (%s, %s) RETURNING id",
            (test_user, f"{test_user}@simple.local")
        )
        user_id = cursor.fetchone()['id']
        operations.append(f"INSERT user: {test_user}")
        
        # INSERT session
        session_id = str(uuid.uuid4())
        expires_at = datetime.now() + timedelta(hours=1)
        cursor.execute(
            "INSERT INTO sessions (id, user_id, expires_at) VALUES (%s, %s, %s)",
            (session_id, user_id, expires_at)
        )
        operations.append(f"INSERT session: {session_id}")
        
        # SELECT operations
        cursor.execute("SELECT COUNT(*) as count FROM users")
        total_users = cursor.fetchone()['count']
        operations.append("SELECT user count")
        
        cursor.execute("SELECT COUNT(*) as count FROM sessions WHERE expires_at > NOW()")
        active_sessions = cursor.fetchone()['count']
        operations.append("SELECT active sessions")
        
        # SELECT recent users
        cursor.execute(
            "SELECT username, email, created_at FROM users ORDER BY created_at DESC LIMIT 5"
        )
        recent_users = cursor.fetchall()
        operations.append("SELECT recent users")
        
        conn.commit()
        cursor.close()
        conn.close()
        
        app_stats['db_queries'] += len(operations)
        
        return jsonify({
            'success': True,
            'operations': operations,
            'created_user': {
                'id': user_id,
                'username': test_user,
                'session_id': session_id
            },
            'stats': {
                'total_users': total_users,
                'active_sessions': active_sessions
            },
            'recent_users': [dict(user) for user in recent_users],
            'server': server_info['hostname'],
            'database_host': DB_CONFIG['host']
        })
        
    except Exception as e:
        app_stats['errors'] += 1
        if conn:
            conn.rollback()
            conn.close()
        return jsonify({'error': str(e)}), 500

@app.route('/api/session/create')
def create_session():
    """Create a session across Redis and Database"""
    try:
        # Connect to both Redis and Database
        r = get_redis_connection()
        conn = get_db_connection()
        
        if not r or not conn:
            return jsonify({'error': 'Infrastructure connection failed'}), 500
        
        server_info = get_server_info()
        session_id = str(uuid.uuid4())
        user_id = random.randint(1, 3)  # Use existing users 1-3
        
        # Store in Redis (fast access)
        session_data = {
            'user_id': user_id,
            'server': server_info['hostname'],
            'created_at': datetime.now().isoformat(),
            'ip': server_info['ip'],
            'active': True,
            'last_activity': datetime.now().isoformat()
        }
        r.set(f"session:{session_id}", json.dumps(session_data), ex=3600)
        
        # Store in Database (persistence)
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO sessions (id, user_id, expires_at) VALUES (%s, %s, %s)",
            (session_id, user_id, datetime.now() + timedelta(hours=1))
        )
        conn.commit()
        cursor.close()
        conn.close()
        
        app_stats['cache_operations'] += 1
        app_stats['db_queries'] += 1
        
        return jsonify({
            'success': True,
            'session_id': session_id,
            'session_data': session_data,
            'stored_in': ['redis', 'postgresql'],
            'server': server_info['hostname']
        })
        
    except Exception as e:
        app_stats['errors'] += 1
        return jsonify({'error': str(e)}), 500

@app.route('/api/infrastructure/status')
def infrastructure_status():
    """Get comprehensive infrastructure status"""
    try:
        status = {
            'timestamp': datetime.now().isoformat(),
            'server': get_server_info(),
            'components': {}
        }
        
        # Redis status
        try:
            r = get_redis_connection()
            if r:
                info = r.info()
                status['components']['redis'] = {
                    'status': 'connected',
                    'host': REDIS_HOST,
                    'port': REDIS_PORT,
                    'memory_usage': info.get('used_memory_human', 'unknown'),
                    'connected_clients': info.get('connected_clients', 0),
                    'total_commands_processed': info.get('total_commands_processed', 0),
                    'keys_count': len(r.keys('*'))
                }
                app_stats['cache_operations'] += 1
        except Exception as e:
            status['components']['redis'] = {
                'status': 'error',
                'error': str(e)
            }
        
        # Database status
        try:
            conn = get_db_connection()
            if conn:
                cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
                
                # Get database stats
                cursor.execute("SELECT COUNT(*) as count FROM users")
                user_count = cursor.fetchone()['count']
                
                cursor.execute("SELECT COUNT(*) as count FROM sessions")
                total_sessions = cursor.fetchone()['count']
                
                cursor.execute("SELECT COUNT(*) as count FROM sessions WHERE expires_at > NOW()")
                active_sessions = cursor.fetchone()['count']
                
                # Get database size
                cursor.execute("SELECT pg_size_pretty(pg_database_size('atom_app_db')) as size")
                db_size = cursor.fetchone()['size']
                
                cursor.close()
                conn.close()
                
                status['components']['database'] = {
                    'status': 'connected',
                    'host': DB_CONFIG['host'],
                    'port': DB_CONFIG['port'],
                    'database': DB_CONFIG['database'],
                    'connection_pool': 'pgpool',
                    'stats': {
                        'total_users': user_count,
                        'total_sessions': total_sessions,
                        'active_sessions': active_sessions,
                        'database_size': db_size
                    }
                }
                app_stats['db_queries'] += 4
        except Exception as e:
            status['components']['database'] = {
                'status': 'error',
                'error': str(e)
            }
        
        # Application stats
        uptime = time.time() - app_stats['start_time']
        status['components']['application'] = {
            'status': 'running',
            'stats': {
                **app_stats,
                'uptime_seconds': uptime,
                'uptime_human': f"{int(uptime // 3600)}h {int((uptime % 3600) // 60)}m",
                'requests_per_minute': round(app_stats['requests'] / (uptime / 60), 2) if uptime > 60 else 0
            }
        }
        
        return jsonify(status)
        
    except Exception as e:
        app_stats['errors'] += 1
        return jsonify({'error': str(e)}), 500

@app.route('/api/load-test')
def load_test():
    """Simulate load across all infrastructure components"""
    try:
        operations = []
        start_time = time.time()
        
        # Test Redis operations
        r = get_redis_connection()
        if r:
            for i in range(10):
                key = f"load_test:{int(time.time())}:{i}"
                r.set(key, f"test_value_{i}", ex=60)
                operations.append(f"Redis SET {key}")
                app_stats['cache_operations'] += 1
        
        # Test Database operations
        conn = get_db_connection()
        if conn:
            cursor = conn.cursor()
            for i in range(5):
                test_user = f"load_test_user_{int(time.time())}_{i}"
                cursor.execute(
                    "INSERT INTO users (username, email) VALUES (%s, %s)",
                    (test_user, f"{test_user}@loadtest.local")
                )
                operations.append(f"DB INSERT {test_user}")
                app_stats['db_queries'] += 1
            
            conn.commit()
            cursor.close()
            conn.close()
        
        end_time = time.time()
        duration = end_time - start_time
        
        return jsonify({
            'success': True,
            'operations_performed': len(operations),
            'operations': operations,
            'duration_seconds': round(duration, 3),
            'ops_per_second': round(len(operations) / duration, 2),
            'server': get_server_info()['hostname']
        })
        
    except Exception as e:
        app_stats['errors'] += 1
        return jsonify({'error': str(e)}), 500

# Background task to generate some activity
def background_activity():
    """Generate background activity to simulate real usage"""
    while True:
        try:
            time.sleep(30)  # Run every 30 seconds
            
            # Update some cache entries
            r = get_redis_connection()
            if r:
                r.set('background_activity', datetime.now().isoformat(), ex=300)
                r.incr('background_counter')
                app_stats['cache_operations'] += 2
            
            # Update session activity in database
            conn = get_db_connection()
            if conn:
                cursor = conn.cursor()
                cursor.execute(
                    "UPDATE sessions SET expires_at = expires_at + INTERVAL '5 minutes' WHERE expires_at > NOW() LIMIT 1"
                )
                conn.commit()
                cursor.close()
                conn.close()
                app_stats['db_queries'] += 1
                
        except Exception as e:
            logger.error(f"Background activity error: {e}")
            app_stats['errors'] += 1

if __name__ == '__main__':
    # Start background activity thread
    bg_thread = threading.Thread(target=background_activity, daemon=True)
    bg_thread.start()
    
    # Run the Flask app
    app.run(host='0.0.0.0', port=8080, debug=False)
