const pool = require('../db/pool')
const assistanceService = require('../services/assistanceService')

async function getUsers(req, res) {
  try {
    const { rows } = await pool.query(
      'SELECT id, full_name, email, auth_provider, created_at FROM users ORDER BY created_at DESC'
    )
    res.json(rows)
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
}

async function getAssistanceRequests(req, res) {
  try {
    const requests = await assistanceService.listAssistanceRequests()
    res.json({ requests })
  } catch (err) {
    res.status(err.statusCode || 500).json({ error: err.message })
  }
}

async function getAssistanceHotspots(req, res) {
  try {
    const hotspots = await assistanceService.listHotspots()
    res.json({ hotspots })
  } catch (err) {
    res.status(err.statusCode || 500).json({ error: err.message })
  }
}

async function getAssistanceHourly(req, res) {
  try {
    const hourlyTrend = await assistanceService.listHourlyTrend()
    res.json({ hourlyTrend })
  } catch (err) {
    res.status(err.statusCode || 500).json({ error: err.message })
  }
}

async function updateAssistanceRequestStatus(req, res) {
  try {
    const request = await assistanceService.updateAssistanceRequestStatus(
      req.params.id,
      req.body?.status
    )
    res.json({ request })
  } catch (err) {
    res.status(err.statusCode || 500).json({ error: err.message })
  }
}

module.exports = {
  getUsers,
  getAssistanceRequests,
  getAssistanceHotspots,
  getAssistanceHourly,
  updateAssistanceRequestStatus
}
