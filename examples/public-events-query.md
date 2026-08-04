# Query API di esempio

Dopo aver configurato i permessi pubblici:

```http
GET /items/event_occurrences
  ?filter[start_datetime][_gte]=2026-08-03T00:00:00+02:00
  &filter[start_datetime][_lte]=2026-08-09T23:59:59+02:00
  &filter[status][_eq]=published
  &fields=*,event.*
  &sort=start_datetime
```

Eventi distribuiti su Visit Roncegno:

```http
GET /items/distributions
  ?filter[channel][key][_eq]=visit_roncegno
  &filter[status][_in]=scheduled,active
  &filter[enabled][_eq]=true
```
