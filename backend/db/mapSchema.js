const MAP_SCHEMA_SQL = `
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

ALTER TABLE user_map_locations
  ADD COLUMN IF NOT EXISTS user_id INTEGER,
  ADD COLUMN IF NOT EXISTS map_node_id INTEGER,
  ADD COLUMN IF NOT EXISTS x NUMERIC(10,2),
  ADD COLUMN IF NOT EXISTS y NUMERIC(10,2),
  ADD COLUMN IF NOT EXISTS floor_code VARCHAR(20),
  ADD COLUMN IF NOT EXISTS qr_code VARCHAR(100),
  ADD COLUMN IF NOT EXISTS source VARCHAR(30) NOT NULL DEFAULT 'unknown',
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP NOT NULL DEFAULT NOW();

CREATE UNIQUE INDEX IF NOT EXISTS uq_user_map_locations_user_id
  ON user_map_locations(user_id);

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
`;

module.exports = { MAP_SCHEMA_SQL };
