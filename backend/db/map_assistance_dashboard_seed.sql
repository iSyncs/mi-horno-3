-- Mapa + asistencia: limpieza, esquema mínimo y datos de prueba para dashboard.
-- Flujo actual:
-- - Los nodos/rutas/detalles del mapa viven hardcodeados en la app.
-- - El backend solo guarda ubicación de usuario y reportes de asistencia.
-- - Se conserva insidemap como catálogo mínimo para que asistencia resuelva nombres por map_node_id.

BEGIN;

DROP TABLE IF EXISTS map_node_details;
DROP TABLE IF EXISTS insidemap_edges;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS user_map_locations (
  user_id INTEGER PRIMARY KEY,
  map_node_id INTEGER,
  x NUMERIC(10,2),
  y NUMERIC(10,2),
  floor_code VARCHAR(20),
  qr_code VARCHAR(100),
  source VARCHAR(30) NOT NULL DEFAULT 'unknown',
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_map_location_events (
  id BIGSERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  map_node_id INTEGER,
  x NUMERIC(10,2),
  y NUMERIC(10,2),
  floor_code VARCHAR(20),
  qr_code VARCHAR(100),
  source VARCHAR(30) NOT NULL DEFAULT 'unknown',
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_map_location_events_user_created
  ON user_map_location_events(user_id, created_at DESC);

TRUNCATE TABLE user_map_location_events RESTART IDENTITY;
TRUNCATE TABLE user_map_locations;
TRUNCATE TABLE assistance_staff_notifications RESTART IDENTITY;
TRUNCATE TABLE assistance_report_messages RESTART IDENTITY;
TRUNCATE TABLE assistance_report_history RESTART IDENTITY;
TRUNCATE TABLE assistance_reports RESTART IDENTITY;
TRUNCATE TABLE insidemap;

INSERT INTO assistance_incident_types
  (code, name, description, default_priority, target_role_code, is_emergency_default, is_active)
VALUES
  ('LOST_CHILD', 'Niño perdido', 'Reporte para localizar a un menor dentro del museo.', 'critical', 'SECURITY', true, true),
  ('MEDICAL_EMERGENCY', 'Emergencia médica', 'Accidente o situación médica que requiere atención inmediata.', 'critical', 'MEDICAL', true, true),
  ('SECURITY_ISSUE', 'Incidente de seguridad', 'Riesgo, conducta sospechosa o situación insegura.', 'high', 'SECURITY', true, true),
  ('EXHIBIT_ISSUE', 'Problema en exhibición', 'Falla o daño detectado en una exhibición.', 'medium', 'TECH_SUPPORT', false, true),
  ('ACCESSIBILITY_HELP', 'Ayuda de accesibilidad', 'Apoyo de movilidad, elevador o acompañamiento accesible.', 'high', 'GUIDE', false, true),
  ('GENERAL_HELP', 'Ayuda general', 'Orientación o apoyo general durante la visita.', 'medium', 'GUIDE', false, true)
ON CONFLICT (code) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  default_priority = EXCLUDED.default_priority,
  target_role_code = EXCLUDED.target_role_code,
  is_emergency_default = EXCLUDED.is_emergency_default,
  is_active = EXCLUDED.is_active;

INSERT INTO assistance_statuses (code, name, sort_order)
VALUES
  ('OPEN', 'Abierto', 1),
  ('ACKNOWLEDGED', 'Recibido', 2),
  ('IN_PROGRESS', 'En atención', 3),
  ('RESOLVED', 'Resuelto', 4),
  ('CANCELLED', 'Cancelado', 5)
ON CONFLICT (code) DO UPDATE SET
  name = EXCLUDED.name,
  sort_order = EXCLUDED.sort_order;

INSERT INTO staff_users (id, user_id, role_code, full_name, email, phone, preferred_language_code, is_active)
VALUES
  (101, 1, 'GUIDE', 'Guía de asistencia', 'guia@horno3.org', NULL, 'es', true),
  (102, 5, 'SECURITY', 'Seguridad Horno3', 'seguridad@horno3.org', NULL, 'es', true),
  (103, 7, 'MEDICAL', 'Primeros auxilios', 'auxilios@horno3.org', NULL, 'es', true)
ON CONFLICT (id) DO UPDATE SET
  role_code = EXCLUDED.role_code,
  full_name = EXCLUDED.full_name,
  email = EXCLUDED.email,
  is_active = EXCLUDED.is_active;

INSERT INTO insidemap
  (id, nombre, x, y, node_type, qr_code, zone_code, floor_code, is_accessible, is_active, assistance_enabled)
VALUES
  (1, 'Entrada principal', 180, 360, 'entry', 'QR_ENTRADA', NULL, 'N1', true, true, true),
  (2, 'Lobby', 600, 350, 'hall', 'QR_CENTRAL', NULL, 'N1', true, true, true),
  (3, 'Baños', 480, 851, 'bathroom', 'QR_BANO1', NULL, 'N1', true, true, true),
  (4, 'Tienda de souvenirs', 522, 433, 'shop', 'QR_RECUERDOS', NULL, 'N1', true, true, true),
  (5, 'Taquilla e información', 1279, 106, 'special', NULL, NULL, 'N1', true, true, true),
  (6, 'Snack H3', 1070, 160, 'food', 'QR_SNACKS', NULL, 'N1', true, true, true),
  (7, 'Elevador inclinado', 960, 184, 'accessibility', NULL, NULL, 'N1', true, true, true),
  (8, 'Patio de demostraciones', 1157, 550, 'special', NULL, NULL, 'N1', true, true, true),
  (9, 'Paseo por las Estufas', 1300, 306, 'special', NULL, NULL, 'N1', true, true, true),
  (10, 'Galería del Acero', 635, 690, 'special', NULL, NULL, 'N1', true, true, true),
  (11, 'Galería de la Historia', 727, 670, 'special', NULL, NULL, 'N1', true, true, true),
  (12, 'Horno Alto', 865, 500, 'special', NULL, NULL, 'N1', true, true, true),
  (13, 'Explanada Estufas', 1205.10, 757.30, 'special', NULL, NULL, 'N1', true, true, true),
  (16, 'Terraza', 300, 400, 'special', NULL, NULL, 'N2', true, true, true),
  (17, 'Show Horno', 750, 700, 'special', NULL, NULL, 'N2', true, true, true),
  (18, 'Horno Alto nivel 2', 750, 520, 'special', NULL, NULL, 'N2', true, true, true),
  (19, 'H3 Planeta Tierra', 1170, 650, 'special', NULL, NULL, 'N2', true, true, true),
  (20, 'Paseo por las Estufas nivel 2', 1597.40, 300, 'special', NULL, NULL, 'N2', true, true, true),
  (21, 'Restaurante El Lingote', 1566.70, 100, 'food', NULL, NULL, 'N2', true, true, true),
  (22, 'Salida acceso derecho nivel 2', 1810, 590, 'exit', NULL, NULL, 'N2', true, true, true),
  (23, 'Elevador inclinado nivel 2', 1210, 200, 'accessibility', NULL, NULL, 'N2', true, true, true),
  (24, 'Baños nivel 2', 960, 200, 'bathroom', NULL, NULL, 'N2', true, true, true),
  (26, 'Boca del Horno Alto', 610, 575, 'special', NULL, NULL, 'N3', true, true, true),
  (27, 'Mirador central', 610, 680, 'special', NULL, NULL, 'N3', true, true, true),
  (28, 'Mirador este', 1335, 430, 'special', NULL, NULL, 'N3', true, true, true),
  (29, 'Mirador sur', 1090, 430, 'special', NULL, NULL, 'N3', true, true, true),
  (31, 'Elevador inclinado nivel 3', 615, 280, 'accessibility', NULL, NULL, 'N3', true, true, true),
  (33, 'Escaleras nivel 1', 650, 465, 'stairs', NULL, NULL, 'N1', false, true, true),
  (34, 'Escaleras nivel 2', 530, 280, 'stairs', NULL, NULL, 'N2', false, true, true),
  (35, 'Escaleras nivel 3', 1645, 560, 'stairs', NULL, NULL, 'N3', false, true, true);

INSERT INTO user_map_locations
  (user_id, map_node_id, x, y, floor_code, qr_code, source, updated_at)
VALUES
  (1, 2, 600, 350, 'N1', 'QR_CENTRAL', 'qr', NOW() - INTERVAL '3 minutes'),
  (3, 10, 635, 690, 'N1', NULL, 'node', NOW() - INTERVAL '12 minutes'),
  (5, 20, 1597.40, 300, 'N2', NULL, 'node', NOW() - INTERVAL '7 minutes'),
  (7, 31, 615, 280, 'N3', NULL, 'node', NOW() - INTERVAL '1 minute'),
  (8, NULL, 1090, 430, 'N3', NULL, 'coordinates', NOW() - INTERVAL '20 minutes')
ON CONFLICT (user_id) DO UPDATE SET
  map_node_id = EXCLUDED.map_node_id,
  x = EXCLUDED.x,
  y = EXCLUDED.y,
  floor_code = EXCLUDED.floor_code,
  qr_code = EXCLUDED.qr_code,
  source = EXCLUDED.source,
  updated_at = EXCLUDED.updated_at;

INSERT INTO user_map_location_events
  (user_id, map_node_id, x, y, floor_code, qr_code, source, created_at)
VALUES
  (1, 1, 180, 360, 'N1', 'QR_ENTRADA', 'qr', NOW() - INTERVAL '28 minutes'),
  (1, 2, 600, 350, 'N1', 'QR_CENTRAL', 'qr', NOW() - INTERVAL '3 minutes'),
  (3, 10, 635, 690, 'N1', NULL, 'node', NOW() - INTERVAL '12 minutes'),
  (5, 16, 300, 400, 'N2', NULL, 'node', NOW() - INTERVAL '18 minutes'),
  (5, 20, 1597.40, 300, 'N2', NULL, 'node', NOW() - INTERVAL '7 minutes'),
  (7, 31, 615, 280, 'N3', NULL, 'node', NOW() - INTERVAL '1 minute'),
  (8, 27, 610, 680, 'N3', NULL, 'node', NOW() - INTERVAL '35 minutes'),
  (8, NULL, 1090, 430, 'N3', NULL, 'coordinates', NOW() - INTERVAL '20 minutes');

WITH status_ids AS (
  SELECT code, id FROM assistance_statuses
),
incident_ids AS (
  SELECT code, id FROM assistance_incident_types
)
INSERT INTO assistance_reports
  (
    public_folio,
    user_id,
    incident_type_id,
    status_id,
    status,
    title,
    description,
    source_type,
    location_source,
    map_node_id,
    qr_code_scanned,
    x,
    y,
    floor_code,
    zone_code,
    preferred_language_code,
    accessibility_required,
    translation_required,
    priority,
    is_emergency,
    assigned_staff_user_id,
    reported_at,
    created_at,
    updated_at,
    extra_data
  )
VALUES
  (
    'DASH-OPEN-N1-LOBBY',
    1,
    (SELECT id FROM incident_ids WHERE code = 'GENERAL_HELP'),
    (SELECT id FROM status_ids WHERE code = 'OPEN'),
    'OPEN',
    'Ayuda general',
    'Visitante solicita orientación en lobby.',
    'button_sos',
    'node',
    2,
    'QR_CENTRAL',
    600,
    350,
    'N1',
    NULL,
    'es',
    false,
    false,
    'medium',
    false,
    101,
    NOW() - INTERVAL '10 minutes',
    NOW() - INTERVAL '10 minutes',
    NOW() - INTERVAL '10 minutes',
    '{"source_context":"Botón SOS","requester_name":"Joel García","location_label":"Lobby"}'::jsonb
  ),
  (
    'DASH-ACCESS-N3-ELEVADOR',
    7,
    (SELECT id FROM incident_ids WHERE code = 'ACCESSIBILITY_HELP'),
    (SELECT id FROM status_ids WHERE code = 'IN_PROGRESS'),
    'IN_PROGRESS',
    'Ayuda de accesibilidad',
    'Visitante requiere apoyo para usar el elevador inclinado nivel 3.',
    'button_sos',
    'node',
    31,
    NULL,
    615,
    280,
    'N3',
    NULL,
    'es',
    true,
    false,
    'high',
    false,
    101,
    NOW() - INTERVAL '22 minutes',
    NOW() - INTERVAL '22 minutes',
    NOW() - INTERVAL '5 minutes',
    '{"source_context":"Botón SOS","requester_name":"Héctor Turrubiates","location_label":"Elevador inclinado nivel 3"}'::jsonb
  ),
  (
    'DASH-MED-N2-PASEO',
    5,
    (SELECT id FROM incident_ids WHERE code = 'MEDICAL_EMERGENCY'),
    (SELECT id FROM status_ids WHERE code = 'OPEN'),
    'OPEN',
    'Emergencia médica',
    'Mareo reportado cerca de Paseo por las Estufas nivel 2.',
    'button_sos',
    'node',
    20,
    NULL,
    1597.40,
    300,
    'N2',
    NULL,
    'es',
    false,
    false,
    'critical',
    true,
    103,
    NOW() - INTERVAL '4 minutes',
    NOW() - INTERVAL '4 minutes',
    NOW() - INTERVAL '4 minutes',
    '{"source_context":"Botón SOS","requester_name":"Joel Téllez","location_label":"Paseo por las Estufas nivel 2"}'::jsonb
  ),
  (
    'DASH-SEC-N1-ACERO',
    3,
    (SELECT id FROM incident_ids WHERE code = 'SECURITY_ISSUE'),
    (SELECT id FROM status_ids WHERE code = 'ACKNOWLEDGED'),
    'ACKNOWLEDGED',
    'Incidente de seguridad',
    'Objeto extraviado reportado en Galería del Acero.',
    'button_sos',
    'node',
    10,
    NULL,
    635,
    690,
    'N1',
    NULL,
    'es',
    false,
    false,
    'high',
    true,
    102,
    NOW() - INTERVAL '35 minutes',
    NOW() - INTERVAL '35 minutes',
    NOW() - INTERVAL '30 minutes',
    '{"source_context":"Botón SOS","requester_name":"Samantha Santos","location_label":"Galería del Acero"}'::jsonb
  ),
  (
    'DASH-EXHIBIT-N3-MIRADOR',
    8,
    (SELECT id FROM incident_ids WHERE code = 'EXHIBIT_ISSUE'),
    (SELECT id FROM status_ids WHERE code = 'RESOLVED'),
    'RESOLVED',
    'Problema en exhibición',
    'Barandal de mirador sur requiere revisión.',
    'button_sos',
    'coordinates',
    29,
    NULL,
    1090,
    430,
    'N3',
    NULL,
    'es',
    false,
    false,
    'medium',
    false,
    101,
    NOW() - INTERVAL '2 hours',
    NOW() - INTERVAL '2 hours',
    NOW() - INTERVAL '80 minutes',
    '{"source_context":"Botón SOS","requester_name":"Santiago Hernandez","location_label":"Mirador sur"}'::jsonb
  ),
  (
    'DASH-LOST-N1-ESTUFAS',
    NULL,
    (SELECT id FROM incident_ids WHERE code = 'LOST_CHILD'),
    (SELECT id FROM status_ids WHERE code = 'OPEN'),
    'OPEN',
    'Niño extraviado',
    'Menor separado de su grupo cerca de Explanada Estufas.',
    'button_sos',
    'node',
    13,
    NULL,
    1205.10,
    757.30,
    'N1',
    NULL,
    'es',
    false,
    false,
    'critical',
    true,
    102,
    NOW() - INTERVAL '1 minute',
    NOW() - INTERVAL '1 minute',
    NOW() - INTERVAL '1 minute',
    '{"source_context":"Botón SOS","requester_name":null,"location_label":"Explanada Estufas"}'::jsonb
  );

COMMIT;

-- Consultas de prueba para validar dashboard:

-- 1. Resumen por estado.
SELECT st.code AS status, count(*) AS total
FROM assistance_reports ar
JOIN assistance_statuses st ON st.id = ar.status_id
GROUP BY st.code, st.sort_order
ORDER BY st.sort_order;

-- 2. Resumen por piso.
SELECT COALESCE(ar.floor_code, n.floor_code, 'SIN_PISO') AS floor_code, count(*) AS total
FROM assistance_reports ar
LEFT JOIN insidemap n ON n.id = ar.map_node_id
GROUP BY COALESCE(ar.floor_code, n.floor_code, 'SIN_PISO')
ORDER BY floor_code;

-- 3. Hotspots con coordenadas.
SELECT
  COALESCE(n.nombre, ar.extra_data->>'location_label', 'Ubicación sin nombre') AS location,
  COALESCE(ar.floor_code, n.floor_code) AS floor_code,
  COALESCE(ar.x, n.x) AS x,
  COALESCE(ar.y, n.y) AS y,
  count(*) AS reports,
  count(*) FILTER (WHERE ar.is_emergency) AS emergency_reports,
  count(*) FILTER (WHERE ar.accessibility_required) AS accessibility_reports
FROM assistance_reports ar
LEFT JOIN insidemap n ON n.id = ar.map_node_id
GROUP BY location, COALESCE(ar.floor_code, n.floor_code), COALESCE(ar.x, n.x), COALESCE(ar.y, n.y)
ORDER BY reports DESC, location;

-- 4. Última ubicación de usuarios.
SELECT
  uml.user_id,
  COALESCE(u.full_name, 'Usuario ' || uml.user_id::text) AS user_name,
  COALESCE(n.nombre, 'Coordenada manual') AS location,
  uml.floor_code,
  uml.x,
  uml.y,
  uml.source,
  uml.updated_at
FROM user_map_locations uml
LEFT JOIN users u ON u.id = uml.user_id
LEFT JOIN insidemap n ON n.id = uml.map_node_id
ORDER BY uml.updated_at DESC;

-- 5. Últimos reportes para tabla del dashboard.
SELECT
  ar.public_folio,
  it.code AS incident_type,
  st.code AS status,
  ar.priority,
  COALESCE(n.nombre, ar.extra_data->>'location_label', 'Ubicación sin nombre') AS location,
  COALESCE(ar.floor_code, n.floor_code) AS floor_code,
  ar.x,
  ar.y,
  ar.is_emergency,
  ar.accessibility_required,
  ar.created_at
FROM assistance_reports ar
JOIN assistance_incident_types it ON it.id = ar.incident_type_id
JOIN assistance_statuses st ON st.id = ar.status_id
LEFT JOIN insidemap n ON n.id = ar.map_node_id
ORDER BY ar.created_at DESC;
