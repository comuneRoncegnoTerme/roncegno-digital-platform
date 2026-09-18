.PHONY: dev-up dev-down staging-up staging-down staging-status staging-health staging-deploy prod-up prod-down prod-status prod-health backup migrate migrate-staging editorial-verify publication-refresh seed-content seed-content-dry-run

dev-up:
	docker compose up -d

dev-down:
	docker compose down

staging-up:
	sh ./scripts/staging-up.sh

staging-down:
	sh ./scripts/staging-down.sh

staging-status:
	sh ./scripts/staging-status.sh

staging-health:
	sh ./scripts/staging-healthcheck.sh

staging-deploy:
	sh ./scripts/staging-deploy.sh

prod-up:
	sh ./scripts/production-up.sh

prod-down:
	sh ./scripts/production-down.sh

prod-status:
	sh ./scripts/production-status.sh

prod-health:
	sh ./scripts/production-healthcheck.sh

backup:
	sh ./scripts/backup.sh

migrate:
	sh ./scripts/migrate.sh

migrate-staging:
	ENV_FILE=.env.staging COMPOSE_FILE=compose.staging.yaml COMPOSE_PROJECT_NAME=roncegno-staging sh ./scripts/migrate.sh

editorial-verify:
	sh ./scripts/verify-editorial-studio.sh

publication-refresh:
	sh ./scripts/refresh-publication-statuses.sh

seed-content:
	python3 ./scripts/seed-content.py

seed-content-dry-run:
	python3 ./scripts/seed-content.py --dry-run
