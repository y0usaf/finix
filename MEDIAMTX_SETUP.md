# MediaMTX WebRTC Streaming Setup

## Overview
MediaMTX is now configured as a system service for WebRTC streaming with OBS. The configuration automatically detects your public IP and sets up firewall rules.

## Configuration Details
- **WebRTC Port**: 4200 (TCP/UDP) - For OBS streaming and browser viewing
- **HLS Port**: 8888 (TCP) - For web browser viewing (alternative)
- **RTMP Port**: 1935 (TCP) - Traditional streaming
- **RTSP Port**: 8554 (TCP) - Professional streaming
- **API Port**: 9997 (localhost only)
- **Config File**: `/etc/mediamtx.yaml`
- **Public IP**: Auto-detected via api.ipify.org

## Setup Steps

### 1. Rebuild Your System
```bash
# Format and rebuild
alejandra .
nh os switch --dry  # Check what will change
nh os switch        # Apply changes
```

### 2. Verify MediaMTX Service
```bash
# Check service status
sudo systemctl status mediamtx

# View logs
sudo journalctl -u mediamtx -f

# Check configuration
sudo cat /etc/mediamtx.yaml
```

### 3. Configure OBS for WebRTC Streaming

#### Install WebRTC Plugin (if not already installed)
The OBS WebRTC plugin should be available through your OBS installation.

#### Method 1: WebRTC (Recommended)
1. **Go to Settings → Stream**
2. **Service**: Custom
3. **Server**: `http://localhost:4200/stream_name/whip` 
   - Replace `stream_name` with your desired stream name
4. **Stream Key**: Leave empty

#### Method 2: RTMP (Traditional)
1. **Go to Settings → Stream**
2. **Service**: Custom
3. **Server**: `rtmp://localhost:1935/stream_name`
4. **Stream Key**: Leave empty

#### Public URLs:
- **WebRTC**: `http://142.198.182.118:4200/stream_name/whip`
- **RTMP**: `rtmp://142.198.182.118:1935/stream_name`

### 4. Test Stream

#### Start Streaming:
1. Start streaming in OBS
2. Check MediaMTX logs: `sudo journalctl -u mediamtx -f`
3. You should see connection logs

#### View Stream:

**Local Viewing**:
- WebRTC: `http://localhost:4200/stream_name`
- HLS: `http://localhost:8888/stream_name/index.m3u8`

**Public Viewing**:
- WebRTC: `http://142.198.182.118:4200/stream_name`
- HLS: `http://142.198.182.118:8888/stream_name/index.m3u8`

**Note**: HLS streams can be played in any HLS-compatible player or browser with HLS support

### 5. Firewall Verification
```bash
# Check if ports are open
sudo ss -tlnp | grep 4200
sudo ss -ulnp | grep 4200

# Check firewall rules
sudo iptables -L | grep 4200
```

## Troubleshooting

### Service Not Starting
```bash
# Check detailed service status
sudo systemctl status mediamtx -l

# Restart service
sudo systemctl restart mediamtx
```

### Public IP Issues
```bash
# Check current public IP
curl -s https://api.ipify.org

# Manually update config (if needed)
sudo systemctl restart mediamtx
```

### Connection Issues
1. **No stream available**: You must start streaming from OBS first
2. **Page not found**: This is normal when no stream is active
3. **Check firewall rules are applied**
4. **Test different protocols**:
   - Try RTMP if WebRTC fails: `rtmp://localhost:1935/test`
   - Use HLS for viewing: `http://localhost:8888/test/index.m3u8`
5. **Verify router port forwarding** (if behind NAT)
6. **Check MediaMTX logs** for connection attempts

### Network Configuration
If you're behind a router, you may need to:
1. **Port forward 4200 (TCP/UDP)** to your machine
2. **Enable UPnP** if your router supports it
3. **Configure STUN servers** (MediaMTX handles this automatically)

## API Management
MediaMTX provides an API for management:
```bash
# Get stream list
curl http://localhost:9997/v3/paths/list

# Get stream info
curl http://localhost:9997/v3/paths/get/stream_name
```

## Security Notes
- The current configuration allows **unrestricted publishing**
- For production use, consider adding authentication:
  ```yaml
  paths:
    all_others:
      publishUser: "your_username"
      publishPass: "your_password"
  ```