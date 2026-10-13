const ASSISTANCE_SCHEMA_SQL = `
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS assistance_incident_types (
  id SERIAL PRIMARY KEY,
  code VARCHAR(50) NOT NULL UNIQUE,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  default_priority VARCHAR(20) NOT NULL DEFAULT 'medium',
  target_role_code VARCHAR(50),
  is_emergency_default BOOLEAN NOT NULL DEFAULT false,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS assistance_statuses (
  id SERIAL PRIMARY KEY,
  code VARCHAR(50) NOT NULL UNIQUE,
  name VARCHAR(100) NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS assistance_reports (
  id BIGSERIAL PRIMARY KEY
);

ALTER TABLE assistance_reports
  ADD COLUMN IF NOT EXISTS public_folio VARCHAR(64),
  ADD COLUMN IF NOT EXISTS user_id INTEGER,
  ADD COLUMN IF NOT EXISTS incident_type_id INTEGER,
  ADD COLUMN IF NOT EXISTS status_id INTEGER,
  ADD COLUMN IF NOT EXISTS status VARCHAR(30),
  ADD COLUMN IF NOT EXISTS title VARCHAR(180),
  ADD COLUMN IF NOT EXISTS description TEXT,
  ADD COLUMN IF NOT EXISTS source_type VARCHAR(50) NOT NULL DEFAULT 'help_button',
  ADD COLUMN IF NOT EXISTS location_source VARCHAR(50) NOT NULL DEFAULT 'unknown',
  ADD COLUMN IF NOT EXISTS map_node_id INTEGER,
  ADD COLUMN IF NOT EXISTS qr_code_scanned VARCHAR(100),
  ADD COLUMN IF NOT EXISTS x NUMERIC(10,2),
  ADD COLUMN IF NOT EXISTS y NUMERIC(10,2),
  ADD COLUMN IF NOT EXISTS floor_code VARCHAR(20),
  ADD COLUMN IF NOT EXISTS zone_code VARCHAR(50),
  ADD COLUMN IF NOT EXISTS preferred_language_code VARCHAR(10) NOT NULL DEFAULT 'es',
  ADD COLUMN IF NOT EXISTS accessibility_required BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS translation_required BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS priority VARCHAR(20) NOT NULL DEFAULT 'medium',
  ADD COLUMN IF NOT EXISTS is_emergency BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS assigned_staff_user_id INTEGER,
  ADD COLUMN IF NOT EXISTS reported_at TIMESTAMP NOT NULL DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS acknowledged_at TIMESTAMP,
  ADD COLUMN IF NOT EXISTS in_progress_at TIMESTAMP,
  ADD COLUMN IF NOT EXISTS resolved_at TIMESTAMP,
  ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMP,
  ADD COLUMN IF NOT EXISTS extra_data JSONB,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP NOT NULL DEFAULT NOW();

ALTER TABLE assistance_reports
  ALTER COLUMN public_folio DROP DEFAULT,
  ALTER COLUMN public_folio TYPE VARCHAR(64) USING public_folio::text;

UPDATE assistance_reports
   SET public_folio = COALESCE(public_folio, 'SOS-' || UPPER(SUBSTRING(gen_random_uuid()::text FROM 1 FOR 8))),
       title = COALESCE(title, 'Ayuda general'),
       description = COALESCE(description, ''),
       created_at = COALESCE(created_at, reported_at, NOW()),
       updated_at = COALESCE(updated_at, reported_at, NOW());

ALTER TABLE assistance_reports
  ALTER COLUMN public_folio SET NOT NULL,
  ALTER COLUMN title SET NOT NULL;

ALTER TABLE assistance_reports
  DROP CONSTRAINT IF EXISTS assistance_reports_map_node_id_fkey,
  DROP CONSTRAINT IF EXISTS assistance_reports_priority_check,
  DROP CONSTRAINT IF EXISTS assistance_reports_status_check;

ALTER TABLE assistance_reports
  ADD CONSTRAINT assistance_reports_priority_check
    CHECK (priority IN ('low', 'medium', 'high', 'critical')),
  ADD CONSTRAINT assistance_reports_status_check
    CHECK (status IS NULL OR status IN ('OPEN', 'ACKNOWLEDGED', 'IN_PROGRESS', 'RESOLVED', 'CANCELLED', 'PENDING'));

CREATE UNIQUE INDEX IF NOT EXISTS uq_assistance_reports_public_folio
  ON assistance_reports(public_folio);

CREATE TABLE IF NOT EXISTS staff_users (
  id SERIAL PRIMARY KEY,
  user_id INTEGER,
  is_active BOOLEAN NOT NULL DEFAULT true
);

ALTER TABLE staff_users
  ADD COLUMN IF NOT EXISTS role_code VARCHAR(50),
  ADD COLUMN IF NOT EXISTS full_name VARCHAR(150),
  ADD COLUMN IF NOT EXISTS email VARCHAR(150),
  ADD COLUMN IF NOT EXISTS phone VARCHAR(30),
  ADD COLUMN IF NOT EXISTS preferred_language_code VARCHAR(10) NOT NULL DEFAULT 'es',
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMP NOT NULL DEFAULT NOW();

UPDATE staff_users
   SET role_code = COALESCE(role_code, 'GUIDE'),
       full_name = COALESCE(full_name, 'Personal de asistencia')
 WHERE full_name IS NULL OR role_code IS NULL;

CREATE TABLE IF NOT EXISTS assistance_report_history (
  id BIGSERIAL PRIMARY KEY,
  report_id BIGINT NOT NULL,
  old_status_id INTEGER,
  new_status_id INTEGER NOT NULL,
  changed_by_staff_user_id INTEGER,
  note TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS assistance_report_messages (
  id BIGSERIAL PRIMARY KEY,
  report_id BIGINT NOT NULL,
  sender_type VARCHAR(20) NOT NULL,
  staff_user_id INTEGER,
  message TEXT NOT NULL,
  is_internal BOOLEAN NOT NULL DEFAULT false,
  language_code VARCHAR(10) NOT NULL DEFAULT 'es',
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS assistance_staff_notifications (
  id BIGSERIAL PRIMARY KEY,
  report_id BIGINT NOT NULL,
  staff_user_id INTEGER,
  channel VARCHAR(30) NOT NULL DEFAULT 'dashboard',
  status VARCHAR(30) NOT NULL DEFAULT 'pending',
  sent_at TIMESTAMP,
  read_at TIMESTAMP,
  error_message VARCHAR(255),
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

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

UPDATE assistance_reports
   SET incident_type_id = COALESCE(incident_type_id, (SELECT id FROM assistance_incident_types WHERE code = 'GENERAL_HELP')),
       status_id = COALESCE(
         status_id,
         (
           SELECT id
             FROM assistance_statuses
            WHERE code = CASE COALESCE(NULLIF(status, ''), 'OPEN')
              WHEN 'PENDING' THEN 'OPEN'
              ELSE COALESCE(NULLIF(status, ''), 'OPEN')
            END
         )
       );

ALTER TABLE assistance_reports
  ALTER COLUMN incident_type_id SET NOT NULL,
  ALTER COLUMN status_id SET NOT NULL;

CREATE INDEX IF NOT EXISTS idx_assistance_reports_status_id ON assistance_reports(status_id);
CREATE INDEX IF NOT EXISTS idx_assistance_reports_incident_type_id ON assistance_reports(incident_type_id);
CREATE INDEX IF NOT EXISTS idx_assistance_reports_map_node_id ON assistance_reports(map_node_id);
CREATE INDEX IF NOT EXISTS idx_assistance_reports_reported_at ON assistance_reports(reported_at);
CREATE INDEX IF NOT EXISTS idx_assistance_reports_created_at ON assistance_reports(created_at);
CREATE INDEX IF NOT EXISTS idx_assistance_reports_priority_status ON assistance_reports(priority, status_id);
CREATE INDEX IF NOT EXISTS idx_assistance_history_report_id ON assistance_report_history(report_id);
CREATE INDEX IF NOT EXISTS idx_assistance_messages_report_id ON assistance_report_messages(report_id);
CREATE INDEX IF NOT EXISTS idx_assistance_notifications_report_id ON assistance_staff_notifications(report_id);
`;

module.exports = { ASSISTANCE_SCHEMA_SQL };
