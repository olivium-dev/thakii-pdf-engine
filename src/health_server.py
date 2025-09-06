#!/usr/bin/env python3
"""
Simple HTTP health check server for Thakii PDF Engine
"""

import json
import sys
from http.server import HTTPServer, BaseHTTPRequestHandler
from datetime import datetime
import threading
import time
import os

class HealthCheckHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            self.send_health_response()
        elif self.path == '/':
            self.send_info_response()
        else:
            self.send_error(404, "Not Found")
    
    def send_health_response(self):
        """Send health check response"""
        try:
            # Test if we can import the main application
            try:
                from src.main import CommandLineArgRunner
            except ImportError:
                # Try alternative import path
                import sys
                import os
                sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
                from src.main import CommandLineArgRunner
            
            health_data = {
                "status": "healthy",
                "service": "thakii-pdf-engine",
                "timestamp": datetime.utcnow().isoformat() + "Z",
                "version": "1.0.0",
                "uptime": self.get_uptime(),
                "checks": {
                    "application_import": "ok",
                    "dependencies": self.check_dependencies()
                }
            }
            
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps(health_data, indent=2).encode())
            
        except Exception as e:
            error_data = {
                "status": "unhealthy",
                "service": "thakii-pdf-engine", 
                "timestamp": datetime.utcnow().isoformat() + "Z",
                "error": str(e)
            }
            
            self.send_response(503)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps(error_data, indent=2).encode())
    
    def send_info_response(self):
        """Send service info response"""
        info_data = {
            "service": "Thakii PDF Engine",
            "description": "Video-to-PDF conversion service",
            "version": "1.0.0",
            "endpoints": {
                "/health": "Health check endpoint",
                "/": "Service information"
            },
            "timestamp": datetime.utcnow().isoformat() + "Z"
        }
        
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(json.dumps(info_data, indent=2).encode())
    
    def check_dependencies(self):
        """Check if required dependencies are available"""
        dependencies = {}
        
        try:
            import cv2
            dependencies["opencv"] = cv2.__version__
        except ImportError:
            dependencies["opencv"] = "missing"
        
        try:
            import fpdf
            dependencies["fpdf2"] = "available"
        except ImportError:
            dependencies["fpdf2"] = "missing"
        
        try:
            import numpy
            dependencies["numpy"] = numpy.__version__
        except ImportError:
            dependencies["numpy"] = "missing"
        
        return dependencies
    
    def get_uptime(self):
        """Get system uptime"""
        try:
            with open('/proc/uptime', 'r') as f:
                uptime_seconds = float(f.readline().split()[0])
                return f"{uptime_seconds:.2f} seconds"
        except:
            return "unknown"
    
    def log_message(self, format, *args):
        """Override to reduce logging noise"""
        pass

def run_health_server(port=8080, host='0.0.0.0'):
    """Run the health check server"""
    server_address = (host, port)
    httpd = HTTPServer(server_address, HealthCheckHandler)
    
    print(f"Health check server starting on {host}:{port}")
    print(f"Health endpoint: http://{host}:{port}/health")
    print(f"Info endpoint: http://{host}:{port}/")
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down health server...")
        httpd.shutdown()

if __name__ == '__main__':
    port = int(os.environ.get('HEALTH_PORT', 8080))
    host = os.environ.get('HEALTH_HOST', '0.0.0.0')
    
    run_health_server(port, host)
