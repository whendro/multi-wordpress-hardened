# WordPress Multi-Site Stack

## Architecture

```
Internet
   │
   ▼
Nginx Proxy Manager  (poolnet — handles SSL + domain routing)
   │
   ├── wp-site1-nginx:80  ──→  wp-site1-php:9000  ──→  MariaDB (poolnet/srv_db)
   ├── wp-site2-nginx:80  ──→  wp-site2-php:9000  ──→  MariaDB
   └── ...                                         ──→  Redis   (poolnet)
```

- **No ports exposed to host** — NPM reaches each site by container name on `poolnet`
- **One Dockerfile** — built once as `wp-hardened:6.7`, reused by all sites
- **One PHP/NGINX config** — lives in `_template/`, all sites share it via volume mount
- **Per-site isolation** — each site has its own `internal` network between nginx ↔ php

## Directory Structure

```
/srv/wordpress/
├── _template/              ← single source of truth
│   ├── Dockerfile
│   ├── docker-compose.yml  ← copied to each site
│   ├── .env.example
│   ├── nginx/
│   │   ├── nginx.conf
│   │   └── wordpress.conf
│   └── php/
│       ├── hardened.ini
│       └── www.conf
├── new-site.sh             ← scaffold a new site
├── site1/
│   ├── docker-compose.yml
│   ├── .env
│   └── logs/
├── site2/
...
```

## Adding a New Site

```bash
# 1. Scaffold
chmod +x new-site.sh
./new-site.sh site2

# 2. Configure
cd site2
cp .env.example .env
nano .env   # fill in all values

# 3. Create DB (run inside MariaDB container)
docker exec -it your_mariadb_container mariadb -u root -p
  CREATE DATABASE wp_site2;
  CREATE USER 'wp_site2_user'@'%' IDENTIFIED BY 'strongpassword';
  GRANT ALL ON wp_site2.* TO 'wp_site2_user'@'%';
  FLUSH PRIVILEGES;

# 4. Build image (first time only — reused after)
docker compose build

# 5. Start
docker compose up -d

# 6. NPM: add proxy host
#    Domain: site2.com
#    Scheme: http
#    Forward hostname: wp-site2-nginx
#    Forward port: 80
#    Enable: Block Common Exploits, Websockets
```

## Redis DB Index Per Site

Use a different `REDIS_DB` (0–15) and unique `REDIS_PREFIX` per site:

| Site   | REDIS_DB | REDIS_PREFIX |
|--------|----------|--------------|
| site1  | 0        | s1_          |
| site2  | 1        | s2_          |
| site3  | 2        | s3_          |
| ...    | ...      | ...          |

## Useful Commands

```bash
# View all running WP containers
docker ps --format 'table {{.Names}}\t{{.Status}}' | grep wp-

# Restart one site
cd /srv/wordpress/site2 && docker compose restart

# Update PHP image (rebuild + recreate all sites)
cd /srv/wordpress/_template && docker build -t wp-hardened:6.7 .
# then for each site:
cd /srv/wordpress/site1 && docker compose up -d --force-recreate php

# Watch logs for one site
docker logs -f wp-site1-nginx
docker logs -f wp-site1-php

# Run WP-CLI on a site
docker exec -it wp-site1-php wp --info --allow-root
```

## After WordPress Install (per site)

1. Install **Redis Object Cache** plugin → activate
2. Install **Wordfence** → run initial scan
3. Change admin username from `admin` to something unique
4. Enable 2FA on admin account
5. Verify `DISALLOW_FILE_EDIT` is working (Appearance → Editor should be gone)
