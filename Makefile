.PHONY: dev-up dev-down prod-up prod-down prod-status prod-health backup

dev-up:
	docker compose up -d

dev-down:
	docker compose down

prod-up:
	./scripts/production-up.sh

prod-down:
	./scripts/production-down.sh

prod-status:
	./scripts/production-status.sh

prod-health:
	./scripts/production-healthcheck.sh

backup:
	./scripts/backup.sh
