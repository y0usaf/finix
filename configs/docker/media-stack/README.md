# Media Stack - Arr Services

Dockerized media automation stack with Radarr, Sonarr, Prowlarr, and qBittorrent.

## Services

- **Prowlarr** (port 6969): Unified indexer management
- **Radarr** (port 7878): Automated movie downloading
- **Sonarr** (port 8989): Automated TV show downloading
- **qBittorrent** (port 6881): Torrent client

## Setup

### 1. Prepare directories

```bash
cd /home/y0usaf/Jellyfin
mkdir -p media
```

### 2. Deploy

```bash
cd /path/to/media-stack
docker-compose up -d
```

### 3. Initial Configuration

#### Prowlarr (http://localhost:6969)
1. Complete setup wizard
2. Add indexers (TPB, 1337x, etc.)

#### Radarr (http://localhost:7878)
1. Settings → Indexers → Add Prowlarr
   - Name: Prowlarr
   - URL: `http://prowlarr:6969`
   - API Key: (get from Prowlarr Settings)
2. Settings → Download Clients → Add qBittorrent
   - Host: `qbittorrent`
   - Port: 6881
3. Settings → Media Management
   - Movie folder: `/media/movies`

#### Sonarr (http://localhost:8989)
1. Settings → Indexers → Add Prowlarr
   - Name: Prowlarr
   - URL: `http://prowlarr:6969`
   - API Key: (get from Prowlarr Settings)
2. Settings → Download Clients → Add qBittorrent
   - Host: `qbittorrent`
   - Port: 6881
3. Settings → Media Management
   - TV folder: `/media/tv`

#### qBittorrent (http://localhost:6881)
1. Set default download location to `/media/downloads`
2. Optional: Configure bandwidth limits

### 4. Point Jellyfin

Jellyfin should auto-discover media at `/home/y0usaf/Jellyfin/media` since it's already configured to watch that directory.

## Networking

All services communicate via the internal `media` Docker network using service names as hostnames:
- `prowlarr:6969`
- `radarr:7878`
- `sonarr:8989`
- `qbittorrent:6881`

## Stopping/Starting

```bash
# Stop all services
docker-compose down

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f [service]
```
