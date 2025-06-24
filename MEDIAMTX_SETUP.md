# MediaMTX WebRTC Streaming Setup

## Overview
MediaMTX is now configured as a system service for WebRTC streaming with OBS. The configuration automatically detects your public IP and sets up firewall rules.

## Configuration Details
- **WebRTC Port**: 4200 (TCP/UDP)
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

#### Stream Setup in OBS:
1. **Go to Settings → Stream**
2. **Service**: Custom
3. **Server**: `http://localhost:4200/stream_name/whip` 
   - Replace `stream_name` with your desired stream name
4. **Stream Key**: Leave empty (no authentication required)

#### Alternative - Manual WHIP URL:
- **WHIP Endpoint**: `http://YOUR_PUBLIC_IP:4200/stream_name/whip`
- **WHEP Endpoint**: `http://YOUR_PUBLIC_IP:4200/stream_name/whep` (for viewing)

### 4. Test Stream

#### Start Streaming:
1. Start streaming in OBS
2. Check MediaMTX logs: `sudo journalctl -u mediamtx -f`
3. You should see connection logs

#### View Stream:
- Open browser to: `http://YOUR_PUBLIC_IP:4200/stream_name`
- Or use WHEP: `http://YOUR_PUBLIC_IP:4200/stream_name/whep`

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
1. **Check firewall rules are applied**
2. **Verify router port forwarding** (if behind NAT)
3. **Check MediaMTX logs** for connection attempts
4. **Test local streaming first** using `localhost:4200`

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