-- Core taxonomies
INSERT INTO taxonomies (key,name,description,multiple,sort) VALUES
('event_types','Tipologie evento','Classificazione principale degli eventi',true,10),
('interests','Interessi','Modalità di esplorazione turistica',true,20),
('target_audiences','Destinatari','Pubblici di riferimento',true,30),
('seasons','Stagioni','Stagionalità dei contenuti',true,40),
('place_types','Tipologie luogo','Tipologie dei luoghi',false,50),
('organization_types','Tipologie organizzazione','Tipologie dei soggetti',false,60),
('localities','Località','Località del territorio comunale',false,70);

INSERT INTO taxonomy_terms (taxonomy,key,label,sort)
SELECT t.id,v.key,v.label,v.sort FROM taxonomies t JOIN (VALUES
('event_types','cultural','Evento culturale',10),('event_types','sports','Evento sportivo',20),('event_types','tradition','Festa e tradizione',30),('event_types','music','Musica e spettacolo',40),('event_types','public_meeting','Incontro pubblico',50),('event_types','families','Attività per famiglie',60),('event_types','food_market','Mercato e gastronomia',70),('event_types','excursion','Escursione',80),
('interests','nature','Natura',10),('interests','family','Famiglia',20),('interests','culture','Cultura',30),('interests','food','Gusto',40),('interests','sport','Sport',50),('interests','wellbeing','Benessere',60),('interests','quiet','Quiete',70),('interests','memory','Memoria',80),
('target_audiences','everyone','Tutti',10),('target_audiences','families','Famiglie',20),('target_audiences','children','Bambini',30),('target_audiences','young_people','Giovani',40),('target_audiences','adults','Adulti',50),('target_audiences','seniors','Anziani',60),('target_audiences','tourists','Turisti',70),('target_audiences','residents','Residenti',80),
('seasons','spring','Primavera',10),('seasons','summer','Estate',20),('seasons','autumn','Autunno',30),('seasons','winter','Inverno',40),
('place_types','park','Parco',10),('place_types','village','Centro abitato',20),('place_types','mountain_locality','Località montana',30),('place_types','cultural_site','Luogo culturale',40),('place_types','trailhead','Partenza sentiero',50),
('organization_types','municipality','Comune',10),('organization_types','cultural_association','Associazione culturale',20),('organization_types','sports_association','Associazione sportiva',30),('organization_types','public_body','Ente pubblico',40),('organization_types','business','Impresa',50),
('localities','roncegno_centre','Roncegno centro',10),('localities','marter','Marter',20),('localities','santa_brigida','Santa Brigida',30),('localities','monte_di_mezzo','Monte di Mezzo',40),('localities','cinquevalli','Cinquevalli',50),('localities','serot','Serot',60),('localities','mountain','Montagna',70)
) AS v(taxonomy_key,key,label,sort) ON t.key=v.taxonomy_key;

INSERT INTO channels (key,name,channel_type,description,active,sort) VALUES
('visit_roncegno','Visit Roncegno','website','Portale turistico del territorio',true,10),
('screen_municipio','Schermo Municipio','screen','Schermo informativo presso il Municipio',true,20),
('screen_biblioteca','Schermo Biblioteca','screen','Schermo informativo della biblioteca',true,30),
('screen_tourism','Schermo turistico','screen','Schermo o totem turistico',true,40),
('public_api','API pubblica','api','Dati pubblicati per consumer esterni',true,50),
('municipal_website','Sito istituzionale','external','Integrazione futura OpenCity',false,60);

-- Demo organization
INSERT INTO organizations (status,identifier,slug,name,short_name,organization_type,description,email,website_url,address,public_profile)
SELECT 'published','RT-ORG-000001','comune-di-roncegno-terme','Comune di Roncegno Terme','Comune',tt.id,'Ente locale e soggetto promotore del Content Hub.','comune@comune.roncegnoterme.tn.it','https://www.comune.roncegnoterme.tn.it','Piazza Achille De Giovanni, Roncegno Terme',true
FROM taxonomy_terms tt JOIN taxonomies t ON t.id=tt.taxonomy WHERE t.key='organization_types' AND tt.key='municipality';

-- Demo places (coordinates are indicative and must be verified before publication)
INSERT INTO places (status,identifier,slug,name,short_description,place_type,locality,address,location,altitude,territorial_level,visit_duration_minutes)
SELECT 'draft','RT-PLACE-000001','parco-delle-terme','Parco delle Terme','Giardini storici e passeggiate nel cuore del paese.',pt.id,loc.id,'Roncegno Terme',ST_SetSRID(ST_MakePoint(11.4090,46.0510),4326),535,'village',60
FROM taxonomy_terms pt,taxonomy_terms loc,taxonomies t1,taxonomies t2 WHERE pt.taxonomy=t1.id AND t1.key='place_types' AND pt.key='park' AND loc.taxonomy=t2.id AND t2.key='localities' AND loc.key='roncegno_centre';

INSERT INTO places (status,identifier,slug,name,short_description,place_type,locality,address,location,territorial_level)
SELECT 'draft','RT-PLACE-000002','marter','Marter','Frazione lungo il Brenta, collegata alla ciclabile della Valsugana.',pt.id,loc.id,'Marter, Roncegno Terme',ST_SetSRID(ST_MakePoint(11.4290,46.0430),4326),'valley'
FROM taxonomy_terms pt,taxonomy_terms loc,taxonomies t1,taxonomies t2 WHERE pt.taxonomy=t1.id AND t1.key='place_types' AND pt.key='village' AND loc.taxonomy=t2.id AND t2.key='localities' AND loc.key='marter';

INSERT INTO places (status,identifier,slug,name,short_description,place_type,locality,address,location,territorial_level)
SELECT 'draft','RT-PLACE-000003','cinquevalli','Cinquevalli','Località montana tra natura, comunità e memoria.',pt.id,loc.id,'Località Cinquevalli, Roncegno Terme',ST_SetSRID(ST_MakePoint(11.3500,46.0850),4326),'mountain'
FROM taxonomy_terms pt,taxonomy_terms loc,taxonomies t1,taxonomies t2 WHERE pt.taxonomy=t1.id AND t1.key='place_types' AND pt.key='mountain_locality' AND loc.taxonomy=t2.id AND t2.key='localities' AND loc.key='cinquevalli';

-- Demo event
INSERT INTO events (status,identifier,slug,title,short_title,abstract,description,schedule_type,start_datetime,end_datetime,place,is_free,booking_required,contact_organization,featured,editorial_priority)
SELECT 'draft','RT-EVENT-2026-000001','evento-dimostrativo-content-hub','Evento dimostrativo Content Hub','Evento demo','Contenuto di esempio per verificare il modello editoriale e la distribuzione multicanale.','Questo evento è un dato dimostrativo e deve essere sostituito prima della pubblicazione.','single','2026-08-15 18:00:00+02','2026-08-15 20:00:00+02',p.id,true,false,o.id,true,10
FROM places p,organizations o WHERE p.identifier='RT-PLACE-000001' AND o.identifier='RT-ORG-000001';

INSERT INTO event_occurrences(event,start_datetime,end_datetime,status)
SELECT id,start_datetime,end_datetime,'published' FROM events WHERE identifier='RT-EVENT-2026-000001';

INSERT INTO events_organizations(event,organization,relation_type)
SELECT e.id,o.id,'organizer' FROM events e,organizations o WHERE e.identifier='RT-EVENT-2026-000001' AND o.identifier='RT-ORG-000001';

INSERT INTO events_taxonomy_terms(event,term,relation_type)
SELECT e.id,tt.id,'event_type' FROM events e,taxonomy_terms tt JOIN taxonomies t ON t.id=tt.taxonomy WHERE e.identifier='RT-EVENT-2026-000001' AND t.key='event_types' AND tt.key='cultural';

INSERT INTO distributions(channel,content_collection,content_id,enabled,publish_from,publish_until,priority,status)
SELECT c.id,'events',e.id,true,'2026-08-04 12:00:00+02','2026-08-16 23:59:59+02',10,'scheduled'
FROM channels c,events e WHERE c.key='visit_roncegno' AND e.identifier='RT-EVENT-2026-000001';

INSERT INTO playlists(name,status,valid_from) VALUES ('Playlist Municipio — predefinita','draft',now());
INSERT INTO screens(key,name,location_name,orientation,default_playlist)
SELECT 'municipio-main','Schermo Municipio','Ingresso Municipio','landscape',id FROM playlists WHERE name='Playlist Municipio — predefinita';
