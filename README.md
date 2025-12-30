# DataBaseImager

A simple Docker-based PostgreSQL database setup with optional pgAdmin web interface.

## 📥 Clone

```bash
git clone https://github.com/immo2n/pgdb.git
cd pgdb
```

## 🚀 Quick Start

1. **Setup Docker** (first time only):
   ```bash
   ./setup.sh
   ```
   > Note: You'll need to log out and back in after setup for Docker permissions to take effect.

2. **Configure environment variables**:
   Create a `.env` file in the project root:
   ```bash
   POSTGRES_USER=your_username
   POSTGRES_PASSWORD=your_password
   POSTGRES_DB=your_database_name
   
   # Optional: Enable pgAdmin
   ENABLE_PGADMIN=true
   PGADMIN_DEFAULT_EMAIL=admin@example.com
   PGADMIN_DEFAULT_PASSWORD=admin_password
   ```

3. **Start services**:
   ```bash
   ./run.sh
   ```

## 📋 Requirements

- Debian-based Linux system (Ubuntu, Debian, etc.)
- Internet connection (for downloading Docker and images)

## 🔧 Setup

The `setup.sh` script will:
- Install Docker Engine and Docker Compose
- Configure your user to run Docker without sudo
- Set up everything needed to run the database

## 🎮 Usage

### Start Services
```bash
./run.sh
```

The script will:
- Check if services are already running
- Start only what's needed
- Show you the status of all containers

### Stop Services
```bash
./stop.sh
```

### View Logs
```bash
docker compose logs -f
```

### Restart Services
```bash
docker compose restart
```

## 🌐 Access

- **PostgreSQL**: `localhost:5432`
- **pgAdmin** (if enabled): `http://localhost:8080`

## ⚙️ Configuration

### Environment Variables

Create a `.env` file with the following variables:

| Variable | Required | Description |
|----------|----------|-------------|
| `POSTGRES_USER` | Yes | PostgreSQL username |
| `POSTGRES_PASSWORD` | Yes | PostgreSQL password |
| `POSTGRES_DB` | Yes | Database name |
| `ENABLE_PGADMIN` | No | Set to `true` to enable pgAdmin (default: disabled) |
| `PGADMIN_DEFAULT_EMAIL` | If pgAdmin enabled | pgAdmin login email |
| `PGADMIN_DEFAULT_PASSWORD` | If pgAdmin enabled | pgAdmin login password |

### Enable/Disable pgAdmin

To enable pgAdmin, add to your `.env` file:
```bash
ENABLE_PGADMIN=true
PGADMIN_DEFAULT_EMAIL=admin@example.com
PGADMIN_DEFAULT_PASSWORD=your_password
```

To disable, either remove `ENABLE_PGADMIN` or set it to `false`.

## 📁 Project Structure

```
DataBaseImager/
├── docker-compose.yaml  # Service definitions
├── setup.sh            # Docker installation script
├── run.sh              # Start services script
├── stop.sh             # Stop services script
└── .env                # Environment variables (create this)
```

## 🛠️ Troubleshooting

**Docker permission denied?**
- Make sure you logged out and back in after running `setup.sh`
- Or run: `newgrp docker`

**Services won't start?**
- Check that your `.env` file exists and has all required variables
- Verify Docker is running: `docker info`
- Check logs: `docker compose logs`

**Port already in use?**
- Change the port mappings in `docker-compose.yaml`
- Or stop the service using the port

## 📝 Notes

- Data is persisted in a Docker volume (`pgdata`)
- Services automatically restart unless stopped manually
- The `run.sh` script intelligently checks what's already running

