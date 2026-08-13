.PHONY: dev-up dev-down prod-up prod-down prod-status prod-health backup migrate editorial-verify publication-refresh seed-content seed-content-dry-run

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

migrate:
	./scripts/migrate.sh

editorial-verify:
	./scripts/verify-editorial-studio.sh

publication-refresh:
	./scripts/refresh-publication-statuses.sh

seed-content:
	python3 ./scripts/seed-content.py

seed-content-dry-run:
	python3 ./scripts/seed-content.py --dry-run
