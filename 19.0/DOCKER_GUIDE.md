# Odoo 19.0 Docker Setup Guide

## Quick Start

### 1. Start the Services
```bash
docker compose up -d
```

This will:
- Build the Odoo image (first time only)
- Start PostgreSQL database
- Start Odoo 19.0 instance
- Create necessary volumes for data persistence

### 2. Access Odoo
Open your browser and go to: `http://localhost:8069`

### 3. Initial Setup
- First time setup will require creating a database
- Default database name: `odoo` (you can create any name)
- Admin password: set during database creation

## Key Commands

### View logs
```bash
docker compose logs -f odoo
docker compose logs -f db
```

### Stop services
```bash
docker compose down
```

### Stop and remove volumes (clean slate)
```bash
docker compose down -v
```

### Restart Odoo (after Python code changes)
```bash
docker compose restart odoo
```

### Access PostgreSQL directly
```bash
docker exec -it odoo-postgres psql -U odoo -d postgres
```

## Project Structure

```
19.0/
├── docker-compose.yml      # Docker Compose configuration
├── Dockerfile              # Odoo image definition
├── entrypoint.sh           # Container startup script
├── odoo.conf               # Odoo configuration file
├── wait-for-psql.py        # Database readiness check
├── custom-apps/            # Your custom modules go here
└── README.md               # This file
```

## Custom Modules

Place your custom Odoo modules in the `custom-apps/` folder. They will automatically be available in Odoo.

See `custom-apps/README.md` for module structure examples.

## Environment Variables

You can customize settings by editing the `environment:` section in `docker-compose.yml`:

- `HOST`: Database hostname (default: db)
- `PORT`: Database port (default: 5432)
- `USER`: Database user (default: odoo)
- `PASSWORD`: Database password (default: odoo)

## Ports

- **8069**: Odoo web interface (HTTP)
- **8071**: Odoo web interface (HTTPS)
- **8072**: Odoo longpolling port
- **5432**: PostgreSQL (exposed for direct access if needed)

## Troubleshooting

### Container won't start
Check logs: `docker compose logs odoo`

### Database connection error
- Ensure PostgreSQL is running: `docker compose logs db`
- Check health: `docker compose ps`

### Can't access Odoo at localhost:8069
- Wait a few seconds for startup
- Check if port 8069 is already in use
- Try: `docker compose restart odoo`

### Python module changes not appearing
Restart Odoo: `docker compose restart odoo`

## Data Persistence

Your data is stored in Docker volumes:
- `postgres_data`: PostgreSQL database
- `odoo_data`: Odoo file storage

These are preserved even when containers stop. To clean them: `docker compose down -v`

## Development Tips

1. Edit files in `custom-apps/` directly - they're mounted into the container
2. For code changes, just restart the odoo container
3. Monitor logs while developing: `docker compose logs -f odoo`
4. Enable debug mode in odoo.conf for more detailed logging
