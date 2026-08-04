# Query Editorial Studio

## Dashboard

```http
GET /items/hub_editorial_dashboard
```

## Prossimi eventi

```http
GET /items/hub_upcoming_events?sort=start_datetime&limit=20
```

## Calendario settimanale

```http
GET /items/hub_calendar?filter[start_datetime][_between]=2026-08-03T00:00:00+02:00,2026-08-09T23:59:59+02:00&sort=start_datetime
```

## Eventi pubblici per Visit Roncegno

```http
GET /items/hub_public_events?sort=-featured,-editorial_priority,start_datetime
```

## Oggi a Roncegno

```http
GET /items/hub_today
```
