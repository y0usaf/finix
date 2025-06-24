#!/usr/bin/env python3
"""
Simple streaming server that serves a web page at a clean URL
People can just visit http://YOUR_IP:8000 to watch the stream
"""

import http.server
import socketserver
import os

# HTML content with embedded player
HTML_CONTENT = '''<!DOCTYPE html>
<html>
<head>
    <title>Live Stream</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script src="https://cdn.jsdelivr.net/npm/hls.js@latest"></script>
    <style>
        body { margin: 0; padding: 20px; background: #000; color: white; font-family: Arial; }
        .container { max-width: 800px; margin: 0 auto; text-align: center; }
        video { width: 100%; max-width: 800px; height: auto; }
        h1 { color: #fff; }
        .status { margin: 10px 0; padding: 10px; border-radius: 4px; background: #333; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔴 Live Stream</h1>
        <video id="video" controls autoplay muted></video>
        <div id="status" class="status">Loading stream...</div>
    </div>
    
    <script>
        const video = document.getElementById('video');
        const status = document.getElementById('status');
        const streamUrl = 'http://142.198.182.118:8888/smya/index.m3u8';
        
        function loadStream() {
            if (Hls.isSupported()) {
                const hls = new Hls();
                hls.loadSource(streamUrl);
                hls.attachMedia(video);
                hls.on(Hls.Events.MEDIA_ATTACHED, () => {
                    status.textContent = '✅ Stream connected!';
                    status.style.background = '#0a5d0a';
                });
                hls.on(Hls.Events.ERROR, (event, data) => {
                    status.textContent = '❌ Stream error: ' + data.details;
                    status.style.background = '#5d0a0a';
                });
            } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
                video.src = streamUrl;
                status.textContent = '✅ Stream connected!';
                status.style.background = '#0a5d0a';
            } else {
                status.textContent = '❌ HLS not supported in this browser';
                status.style.background = '#5d0a0a';
            }
        }
        
        loadStream();
    </script>
</body>
</html>'''

class MyHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/' or self.path == '/index.html':
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(HTML_CONTENT.encode())
        else:
            self.send_response(404)
            self.end_headers()

PORT = 8000
print(f"🌐 Starting simple stream server on port {PORT}")
print(f"📺 Share this URL: http://142.198.182.118:{PORT}")
print(f"🏠 Local URL: http://localhost:{PORT}")

with socketserver.TCPServer(("", PORT), MyHTTPRequestHandler) as httpd:
    httpd.serve_forever()