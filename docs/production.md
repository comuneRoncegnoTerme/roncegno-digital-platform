# Produzione — Roncegno Digital Platform 0.2

## Topologia

- Caddy espone esclusivamente 80/443.
- Directus è raggiungibile solo dalla rete Docker `proxy`.
- PostgreSQL e Redis risiedono nella rete `internal`, non esposta.
- Upload e database sono persistenti.

## Preparazione VPS Ubuntu

```bash
sudo ./scripts/install-docker-ubuntu.sh
```

Dopo logout/login:

```bash
cp .env.production.example .env.production
./scripts/generate-secrets.sh
```

Copiare i segreti generati nel file `.env.production`, impostare dominio e CORS, quindi:

```bash
./scripts/production-up.sh
./scripts/production-status.sh
./scripts/production-healthcheck.sh
```

## DNS

Creare un record A:

```text
hub.example.it → IPv4 del VPS
```

Caddy richiederà automaticamente il certificato TLS quando DNS e firewall saranno corretti.

## Firewall minimo

```bash
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 443/udp
sudo ufw enable
```

## Backup

```bash
./scripts/backup.sh
```

Automazione cron giornaliera:

```cron
15 2 * * * cd /opt/roncegno/roncegno-digital-platform && ./scripts/backup.sh >> /var/log/roncegno-backup.log 2>&1
```

I backup devono essere copiati anche fuori dal VPS.

## Restore

```bash
./scripts/restore-database.sh backups/database/FILE.dump
./scripts/restore-uploads.sh backups/uploads/FILE.tar.gz
```

## Deploy

```bash
./scripts/deploy.sh
```

Il deploy esegue backup, pull fast-forward, aggiornamento dei container e health check.

## Aggiornamenti Directus

Cambiare `DIRECTUS_VERSION` solo dopo test in staging. Non usare `latest`.
