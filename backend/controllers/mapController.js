const pool = require('../db/pool')
const { MAP_SCHEMA_SQL } = require('../db/mapSchema')

const mapNodeMetadata = {
  'Información':                { image: 'horno3', description: 'Punto de atención para orientación general.' },
  'Área de descanso':           { image: 'horno3', description: 'Espacio sugerido para hacer una pausa.' },
  'Salida de emergencia norte': { image: 'horno3', description: 'Ruta de evacuación norte.' },
  'Salida de emergencia sur':   { image: 'horno3', description: 'Ruta de evacuación sur.' },
  'Rampa norte':                { image: 'horno3', description: 'Acceso inclinado zona norte.' },
  'Rampa sur':                  { image: 'horno3', description: 'Acceso inclinado zona sur.' },
  'Elevador':                   { image: 'horno3', description: 'Elevador accesible.' },
  'Baños':                      { image: 'horno3', description: 'Servicios sanitarios.' },
  'Snacks':                     { image: 'horno3', description: 'Zona rápida para bebidas.' },
  'Recuerdos':                  { image: 'horno3', description: 'Tienda de recuerdos.' }
}

function sendServerError(res, err) {
  console.error('[map]', err)
  res.status(500).json({ error: 'Error interno del mapa.' })
}

async function getNodeByQR(req, res) {
  try {
    const { rows } = await pool.query(
      'SELECT id, nombre, x, y, node_type, floor_code FROM insidemap WHERE qr_code = $1 LIMIT 1',
      [req.params.qr]
    )
    if (rows.length === 0) {
      return res.status(404).json({ error: 'QR no encontrado' })
    }
    res.json(rows[0])
  } catch (err) {
    sendServerError(res, err)
  }
}

async function getNodeDetails(req, res) {
  try {
    let rows
    try {
      const result = await pool.query(
        `SELECT
           n.id,
           n.nombre,
           n.node_type,
           n.floor_code,
           n.qr_code,
           d.short_description,
           d.long_description,
           d.image_path
         FROM insidemap n
         LEFT JOIN map_node_details d ON d.node_id = n.id
         WHERE n.id = $1
         LIMIT 1`,
        [req.params.id]
      )
      rows = result.rows
    } catch (err) {
      if (err.code !== '42P01' && err.code !== '42703') throw err

      const result = await pool.query(
        'SELECT id, nombre, node_type, floor_code, qr_code FROM insidemap WHERE id = $1 LIMIT 1',
        [req.params.id]
      )
      rows = result.rows
    }
    if (rows.length === 0) return res.status(404).json({ error: 'No encontrado' })
    const node = rows[0]
    const meta = mapNodeMetadata[node.nombre] || { image: 'horno3', description: 'Sin descripción.' }
    res.json({
      id: node.id,
      name: node.nombre,
      nodeType: node.node_type,
      floorCode: node.floor_code,
      qrCode: node.qr_code,
      image: node.image_path || meta.image,
      description: node.long_description || node.short_description || meta.description
    })
  } catch (err) {
    sendServerError(res, err)
  }
}

async function getBathrooms(req, res) {
  try {
    const { rows } = await pool.query(
      "SELECT id, nombre, x, y, floor_code FROM insidemap WHERE node_type = 'bathroom'"
    )
    res.json(rows)
  } catch (err) {
    sendServerError(res, err)
  }
}

async function getGraph(req, res) {
  try {
    const nodes = await pool.query('SELECT id, nombre, x, y, node_type, floor_code FROM insidemap')
    const edges = await pool.query('SELECT from_node, to_node, weight FROM insidemap_edges')
    res.json({ nodes: nodes.rows, edges: edges.rows })
  } catch (err) {
    sendServerError(res, err)
  }
}

async function updateUserLocation(req, res) {
  try {
    const payload = normalizeUserLocationPayload(req.body)
    await ensureMapLocationSchema()

    await pool.query(`
      INSERT INTO user_map_locations (
        user_id,
        map_node_id,
        x,
        y,
        floor_code,
        qr_code,
        source,
        updated_at
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())
      ON CONFLICT (user_id) DO UPDATE SET
        map_node_id = EXCLUDED.map_node_id,
        x = EXCLUDED.x,
        y = EXCLUDED.y,
        floor_code = EXCLUDED.floor_code,
        qr_code = EXCLUDED.qr_code,
        source = EXCLUDED.source,
        updated_at = NOW()
    `, [
      payload.userId,
      payload.mapNodeID,
      payload.x,
      payload.y,
      payload.floorCode,
      payload.qrCode,
      payload.source
    ])

    await pool.query(`
      INSERT INTO user_map_location_events (
        user_id,
        map_node_id,
        x,
        y,
        floor_code,
        qr_code,
        source
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7)
    `, [
      payload.userId,
      payload.mapNodeID,
      payload.x,
      payload.y,
      payload.floorCode,
      payload.qrCode,
      payload.source
    ])

    res.status(204).send()
  } catch (err) {
    const statusCode = err.statusCode || 500
    if (statusCode >= 500) {
      sendServerError(res, err)
      return
    }
    res.status(statusCode).json({ error: err.message })
  }
}

async function ensureMapLocationSchema() {
  const { rows } = await pool.query(`
    SELECT
      to_regclass('public.user_map_locations') AS current_locations,
      to_regclass('public.user_map_location_events') AS location_events
  `)
  const schema = rows[0] || {}
  if (schema.current_locations && schema.location_events) return
  await pool.query(MAP_SCHEMA_SQL)
}

function normalizeUserLocationPayload(payload = {}) {
  const userId = Number(payload.userId ?? payload.user_id)
  if (!Number.isInteger(userId) || userId <= 0) {
    const error = new Error('userId requerido')
    error.statusCode = 422
    throw error
  }

  const mapNodeIDValue = payload.mapNodeID ?? payload.map_node_id
  const mapNodeID = mapNodeIDValue == null ? null : Number(mapNodeIDValue)
  const x = payload.x == null ? null : Number(payload.x)
  const y = payload.y == null ? null : Number(payload.y)

  if (mapNodeID == null && (x == null || y == null)) {
    const error = new Error('Envía mapNodeID o coordenadas x/y')
    error.statusCode = 422
    throw error
  }

  if (mapNodeID != null && (!Number.isInteger(mapNodeID) || mapNodeID <= 0)) {
    const error = new Error('mapNodeID inválido')
    error.statusCode = 422
    throw error
  }

  if (x != null && !Number.isFinite(x)) {
    const error = new Error('x inválida')
    error.statusCode = 422
    throw error
  }

  if (y != null && !Number.isFinite(y)) {
    const error = new Error('y inválida')
    error.statusCode = 422
    throw error
  }

  return {
    userId,
    mapNodeID,
    x,
    y,
    floorCode: normalizeNullableString(payload.floorCode ?? payload.floor_code),
    qrCode: normalizeNullableString(payload.qrCode ?? payload.qr_code),
    source: normalizeLocationSource(payload.source)
  }
}

function normalizeNullableString(value) {
  return typeof value === 'string' && value.trim() ? value.trim() : null
}

function normalizeLocationSource(value) {
  const normalized = typeof value === 'string' ? value.trim().toLowerCase() : ''
  return ['qr', 'node', 'coordinates', 'manual'].includes(normalized) ? normalized : 'unknown'
}

module.exports = {
  getNodeByQR,
  getNodeDetails,
  getBathrooms,
  getGraph,
  updateUserLocation
}
