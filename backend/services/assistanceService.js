const crypto = require('crypto')
const pool = require('../db/pool')
const { ASSISTANCE_SCHEMA_SQL } = require('../db/assistanceSchema')

const INCIDENT_CATALOG = {
  LOST_CHILD: {
    title: 'Niño extraviado',
    priority: 'critical',
    emergency: true,
    eta: 2
  },
  MEDICAL_EMERGENCY: {
    title: 'Emergencia médica',
    priority: 'critical',
    emergency: true,
    eta: 3
  },
  SECURITY_ISSUE: {
    title: 'Incidente de seguridad',
    priority: 'high',
    emergency: true,
    eta: 4
  },
  EXHIBIT_ISSUE: {
    title: 'Problema en exhibición',
    priority: 'medium',
    emergency: false,
    eta: 8
  },
  ACCESSIBILITY_HELP: {
    title: 'Apoyo de accesibilidad',
    priority: 'high',
    emergency: false,
    eta: 5
  },
  GENERAL_HELP: {
    title: 'Ayuda general',
    priority: 'medium',
    emergency: false,
    eta: 6
  }
}

const DB_STATUS_FROM_ADMIN = {
  PENDING: 'OPEN',
  IN_PROGRESS: 'IN_PROGRESS',
  RESOLVED: 'RESOLVED'
}

const ADMIN_STATUS_FROM_DB = {
  OPEN: 'PENDING',
  ACKNOWLEDGED: 'PENDING',
  IN_PROGRESS: 'IN_PROGRESS',
  RESOLVED: 'RESOLVED',
  CANCELLED: 'RESOLVED'
}

async function listAssistanceRequests() {
  await ensureAssistanceSchema()
  return listAssistanceRequestsFromDB()
}

async function listHotspots() {
  const requests = await listAssistanceRequests()
  return buildHotspotsFromRequests(requests)
}

async function listHourlyTrend() {
  const requests = await listAssistanceRequests()
  return buildHourlyTrendFromRequests(requests)
}

async function createAssistanceRequest(input) {
  const payload = normalizeIncomingPayload(input)
  await ensureAssistanceSchema()
  return createAssistanceRequestInDB(payload)
}

async function updateAssistanceRequestStatus(requestID, status) {
  const normalizedStatus = normalizeAdminStatus(status)
  await ensureAssistanceSchema()
  return updateAssistanceRequestStatusInDB(requestID, normalizedStatus)
}

async function listAssistanceRequestsFromDB() {
  const { rows } = await pool.query(`
    SELECT
      ar.id::text AS id,
      COALESCE(ar.public_folio, 'SOS-' || ar.id::text) AS folio,
      ait.code AS incident_type,
      st.code AS status_code,
      COALESCE(ar.reported_at, ar.created_at, NOW()) AS created_at,
      COALESCE(ar.description, '') AS details,
      COALESCE(ar.accessibility_required, false) AS accessibility_required,
      COALESCE(ar.translation_required, false) AS translation_required,
      COALESCE(su.full_name, NULL) AS assigned_to,
      COALESCE(ar.extra_data->>'requester_name', NULL) AS requester_name,
      COALESCE(ar.extra_data->>'source_context', initcap(replace(ar.source_type, '_', ' '))) AS source_context,
      COALESCE(ar.extra_data->>'location_label', NULL) AS location_label,
      COALESCE(n.nombre, NULL) AS node_name,
      COALESCE(ar.floor_code, n.floor_code, NULL) AS floor_code,
      COALESCE(ar.zone_code, NULL) AS zone_code,
      COALESCE(ar.x, n.x) AS x,
      COALESCE(ar.y, n.y) AS y,
      COALESCE(ar.is_emergency, false) AS is_emergency,
      COALESCE(ar.priority, 'medium') AS priority,
      COALESCE(ar.qr_code_scanned, NULL) AS qr_code_scanned
    FROM assistance_reports ar
    JOIN assistance_incident_types ait ON ait.id = ar.incident_type_id
    JOIN assistance_statuses st ON st.id = ar.status_id
    LEFT JOIN insidemap n ON n.id = ar.map_node_id
    LEFT JOIN staff_users su ON su.id = ar.assigned_staff_user_id
    ORDER BY COALESCE(ar.reported_at, ar.created_at, NOW()) DESC
    LIMIT 200
  `)

  return rows.map(mapDBRowToRequest)
}

async function createAssistanceRequestInDB(payload) {
  const folio = payload.folio || generateFolio()
  const incidentTypeID = await lookupIncidentTypeID(payload.incidentType)
  const openStatusID = await lookupStatusID('OPEN')
  const node = await resolveNodeFromPayload(payload)
  const locationLabel = buildLocationLabel({
    locationLabel: payload.locationLabel,
    nodeName: node?.nombre,
    floorCode: payload.floorCode || node?.floor_code,
    zoneCode: payload.zoneCode
  })

  const insertResult = await pool.query(`
    INSERT INTO assistance_reports (
      public_folio,
      user_id,
      incident_type_id,
      status_id,
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
      extra_data
    )
    VALUES (
      $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20::jsonb
    )
    RETURNING id::text AS id
  `, [
    folio,
    payload.userID,
    incidentTypeID,
    openStatusID,
    payload.title,
    payload.description,
    payload.sourceType,
    payload.locationSource,
    node?.id || payload.mapNodeID || null,
    payload.qrCodeScanned || null,
    payload.x ?? node?.x ?? null,
    payload.y ?? node?.y ?? null,
    payload.floorCode || node?.floor_code || null,
    payload.zoneCode || null,
    payload.preferredLanguageCode,
    payload.accessibilityRequired,
    payload.translationRequired,
    payload.priority,
    payload.isEmergency,
    JSON.stringify({
      source_context: payload.sourceContext,
      requester_name: payload.requesterName || null,
      requester_email: payload.requesterEmail || null,
      location_label: locationLabel,
      route_name: payload.routeName || null,
      destination_name: payload.destinationName || null,
      qr_code_scanned: payload.qrCodeScanned || null
    })
  ])

  const requests = await listAssistanceRequestsFromDB()
  return requests.find((item) => item.id === insertResult.rows[0].id)
}

async function updateAssistanceRequestStatusInDB(requestID, status) {
  const dbStatus = DB_STATUS_FROM_ADMIN[status]
  if (!dbStatus) {
    const error = new Error('Estado inválido')
    error.statusCode = 400
    throw error
  }

  const statusID = await lookupStatusID(dbStatus)
  const updateResult = await pool.query(`
    UPDATE assistance_reports
       SET status_id = $2
     WHERE id::text = $1 OR public_folio = $1
     RETURNING id::text AS id
  `, [requestID, statusID])

  if (updateResult.rowCount === 0) {
    const error = new Error('Solicitud no encontrada')
    error.statusCode = 404
    throw error
  }

  const requests = await listAssistanceRequestsFromDB()
  return requests.find((item) => item.id === updateResult.rows[0].id)
}

function buildHotspotsFromRequests(requests) {
  const grouped = new Map()

  for (const request of requests) {
    const key = `${request.floor || 'Nivel 1'}::${request.location}`
    const current = grouped.get(key) || {
      id: crypto.createHash('md5').update(key).digest('hex').slice(0, 12),
      location: request.location,
      requests: 0,
      emergencyRequests: 0,
      accessibilityRequests: 0,
      translationRequests: 0,
      averageResponseMinutes: 0,
      floor: request.floor || null,
      x: request.x ?? null,
      y: request.y ?? null,
      totalETA: 0
    }

    current.requests += 1
    current.emergencyRequests += request.incidentType === 'LOST_CHILD'
      || request.incidentType === 'MEDICAL_EMERGENCY'
      || request.incidentType === 'SECURITY_ISSUE'
      ? 1
      : 0
    current.accessibilityRequests += request.accessibilityRequired ? 1 : 0
    current.translationRequests += request.translationRequired ? 1 : 0
    current.totalETA += Number(request.responseETA || 0)

    if (current.x == null && request.x != null) current.x = request.x
    if (current.y == null && request.y != null) current.y = request.y
    if (current.floor == null && request.floor != null) current.floor = request.floor

    grouped.set(key, current)
  }

  return Array.from(grouped.values())
    .map((item) => ({
      id: item.id,
      location: item.location,
      requests: item.requests,
      emergencyRequests: item.emergencyRequests,
      accessibilityRequests: item.accessibilityRequests,
      translationRequests: item.translationRequests,
      averageResponseMinutes: item.requests > 0
        ? Number((item.totalETA / item.requests).toFixed(1))
        : 0,
      floor: item.floor,
      x: item.x,
      y: item.y
    }))
    .sort((a, b) => b.requests - a.requests)
}

function buildHourlyTrendFromRequests(requests) {
  const now = new Date()
  const buckets = []

  for (let offset = 7; offset >= 0; offset -= 1) {
    const bucketDate = new Date(now.getTime() - offset * 60 * 60 * 1000)
    const hourLabel = bucketDate.toLocaleTimeString('es-MX', {
      hour: '2-digit',
      minute: '2-digit',
      hour12: false
    })

    const incoming = requests.filter((request) => {
      const created = new Date(request.createdAt)
      return created.getHours() === bucketDate.getHours()
    }).length

    const resolved = requests.filter((request) => {
      const created = new Date(request.createdAt)
      return request.status === 'RESOLVED' && created.getHours() === bucketDate.getHours()
    }).length

    buckets.push({
      id: `hour-${bucketDate.getHours()}`,
      hourLabel,
      incoming,
      resolved
    })
  }

  return buckets
}

async function hasAssistanceSchema() {
  try {
    const { rows } = await pool.query(`
      SELECT
        to_regclass('public.assistance_reports') AS reports,
        to_regclass('public.assistance_incident_types') AS incident_types,
        to_regclass('public.assistance_statuses') AS statuses
    `)
    const schema = rows[0] || {}
    return Boolean(schema.reports && schema.incident_types && schema.statuses)
  } catch (error) {
    return false
  }
}

async function ensureAssistanceSchema() {
  if (await hasAssistanceSchema()) return

  try {
    await pool.query(ASSISTANCE_SCHEMA_SQL)
  } catch (cause) {
    const error = new Error('No se pudo preparar el esquema de asistencia.')
    error.statusCode = 503
    error.cause = cause
    throw error
  }

  if (await hasAssistanceSchema()) return

  const error = new Error('La base de datos no tiene habilitado el esquema de asistencia.')
  error.statusCode = 503
  throw error
}

async function lookupIncidentTypeID(code) {
  const { rows } = await pool.query(
    'SELECT id FROM assistance_incident_types WHERE code = $1 LIMIT 1',
    [code]
  )
  if (!rows[0]) {
    const error = new Error('Tipo de incidencia no encontrado')
    error.statusCode = 400
    throw error
  }
  return rows[0].id
}

async function lookupStatusID(code) {
  const { rows } = await pool.query(
    'SELECT id FROM assistance_statuses WHERE code = $1 LIMIT 1',
    [code]
  )
  if (!rows[0]) {
    const error = new Error('Estado no encontrado')
    error.statusCode = 400
    throw error
  }
  return rows[0].id
}

async function resolveNodeFromPayload(payload) {
  if (payload.mapNodeID) {
    const { rows } = await pool.query(
      'SELECT id, nombre, x, y, floor_code FROM insidemap WHERE id = $1 LIMIT 1',
      [payload.mapNodeID]
    )
    return rows[0] || null
  }

  if (payload.qrCodeScanned) {
    const { rows } = await pool.query(
      'SELECT id, nombre, x, y, floor_code FROM insidemap WHERE qr_code = $1 LIMIT 1',
      [payload.qrCodeScanned]
    )
    return rows[0] || null
  }

  return null
}

function mapDBRowToRequest(row) {
  const floor = floorLabelFromCode(row.floor_code)
  return {
    id: row.id,
    folio: row.folio,
    incidentType: normalizeIncidentType(row.incident_type),
    location: buildLocationLabel({
      locationLabel: row.location_label,
      nodeName: row.node_name,
      floorCode: row.floor_code,
      zoneCode: row.zone_code
    }),
    sourceContext: row.source_context || 'Botón SOS',
    details: row.details || '',
    accessibilityRequired: Boolean(row.accessibility_required),
    translationRequired: Boolean(row.translation_required),
    status: ADMIN_STATUS_FROM_DB[row.status_code] || 'PENDING',
    createdAt: new Date(row.created_at).toISOString(),
    assignedTo: row.assigned_to || null,
    requesterName: row.requester_name || null,
    responseETA: etaForIncident(row.incident_type),
    floor,
    x: row.x == null ? null : Number(row.x),
    y: row.y == null ? null : Number(row.y),
    zoneCode: row.zone_code || null
  }
}

function normalizeIncomingPayload(payload = {}) {
  const incidentType = normalizeIncidentType(payload.incidentType)
  const incidentMeta = INCIDENT_CATALOG[incidentType] || INCIDENT_CATALOG.GENERAL_HELP
  const floorCode = typeof payload.floorCode === 'string' ? payload.floorCode.trim() : null
  const zoneCode = typeof payload.zoneCode === 'string' ? payload.zoneCode.trim() : null

  return {
    folio: typeof payload.folio === 'string' && payload.folio.trim() ? payload.folio.trim() : null,
    userID: normalizePositiveInteger(payload.userID ?? payload.userId ?? payload.user_id),
    incidentType,
    title: typeof payload.title === 'string' && payload.title.trim()
      ? payload.title.trim()
      : incidentMeta.title,
    description: typeof payload.description === 'string' ? payload.description.trim() : '',
    sourceType: normalizeSourceType(payload.sourceType),
    locationSource: normalizeLocationSource(payload.locationSource),
    sourceContext: typeof payload.sourceContext === 'string' && payload.sourceContext.trim()
      ? payload.sourceContext.trim()
      : 'Botón SOS',
    locationLabel: typeof payload.locationLabel === 'string' && payload.locationLabel.trim()
      ? payload.locationLabel.trim()
      : null,
    floorCode,
    zoneCode,
    mapNodeID: payload.mapNodeID ?? null,
    qrCodeScanned: typeof payload.qrCodeScanned === 'string' && payload.qrCodeScanned.trim()
      ? payload.qrCodeScanned.trim()
      : null,
    destinationName: typeof payload.destinationName === 'string' && payload.destinationName.trim()
      ? payload.destinationName.trim()
      : null,
    routeName: typeof payload.routeName === 'string' && payload.routeName.trim()
      ? payload.routeName.trim()
      : null,
    x: payload.x == null ? null : Number(payload.x),
    y: payload.y == null ? null : Number(payload.y),
    requesterName: typeof payload.requesterName === 'string' && payload.requesterName.trim()
      ? payload.requesterName.trim()
      : null,
    requesterEmail: typeof payload.requesterEmail === 'string' && payload.requesterEmail.trim()
      ? payload.requesterEmail.trim()
      : null,
    preferredLanguageCode: typeof payload.preferredLanguageCode === 'string' && payload.preferredLanguageCode.trim()
      ? payload.preferredLanguageCode.trim()
      : 'es',
    accessibilityRequired: Boolean(payload.accessibilityRequired),
    translationRequired: Boolean(payload.translationRequired),
    priority: typeof payload.priority === 'string' && payload.priority.trim()
      ? payload.priority.trim().toLowerCase()
      : incidentMeta.priority,
    isEmergency: typeof payload.isEmergency === 'boolean'
      ? payload.isEmergency
      : incidentMeta.emergency
  }
}

function normalizePositiveInteger(value) {
  if (value == null || value === '') return null
  const number = Number(value)
  return Number.isInteger(number) && number > 0 ? number : null
}

function normalizeIncidentType(value) {
  if (typeof value !== 'string') return 'GENERAL_HELP'
  const upper = value.trim().toUpperCase()
  return INCIDENT_CATALOG[upper] ? upper : 'GENERAL_HELP'
}

function normalizeAdminStatus(value) {
  if (typeof value !== 'string') return 'PENDING'
  const upper = value.trim().toUpperCase()
  return ['PENDING', 'IN_PROGRESS', 'RESOLVED'].includes(upper) ? upper : 'PENDING'
}

function normalizeSourceType(value) {
  const allowed = ['help_button', 'qr_scan', 'map_tap', 'manual', 'staff']
  return allowed.includes(value) ? value : 'help_button'
}

function normalizeLocationSource(value) {
  const allowed = ['node', 'qr', 'manual', 'unknown']
  return allowed.includes(value) ? value : 'unknown'
}

function buildLocationLabel({
  locationLabel,
  nodeName,
  floorCode,
  zoneCode
}) {
  if (locationLabel) return locationLabel

  const floor = floorLabelFromCode(floorCode)
  if (nodeName && floor) return `${nodeName} · ${floor}`
  if (nodeName) return nodeName
  if (zoneCode && floor) return `Zona ${zoneCode} · ${floor}`
  if (floor) return floor
  return 'Museo Horno 3'
}

function floorLabelFromCode(value) {
  if (!value) return null
  const normalized = String(value).trim().toUpperCase()
  if (['PB', 'P1', 'L1', 'N1', 'LEVEL1', 'LEVEL_1'].includes(normalized)) return 'Nivel 1'
  if (['P2', 'L2', 'N2', 'LEVEL2', 'LEVEL_2'].includes(normalized)) return 'Nivel 2'
  if (['P3', 'L3', 'N3', 'LEVEL3', 'LEVEL_3'].includes(normalized)) return 'Nivel 3'
  if (normalized.includes('1')) return 'Nivel 1'
  if (normalized.includes('2')) return 'Nivel 2'
  if (normalized.includes('3')) return 'Nivel 3'
  return null
}

function etaForIncident(incidentType) {
  const meta = INCIDENT_CATALOG[normalizeIncidentType(incidentType)] || INCIDENT_CATALOG.GENERAL_HELP
  return meta.eta
}

function generateFolio() {
  return `SOS-${crypto.randomUUID().split('-')[0].toUpperCase()}`
}

module.exports = {
  listAssistanceRequests,
  listHotspots,
  listHourlyTrend,
  createAssistanceRequest,
  updateAssistanceRequestStatus
}
