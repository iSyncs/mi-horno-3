const pool = require('../db/pool')

async function registerVisit(req, res) {
  const { room_name, duration_seconds } = req.body
  if (!room_name?.trim())
    return res.status(422).json({ error: 'room_name es requerido' })
  try {
    await pool.query(
      `INSERT INTO sensory_visits (room_name, duration_seconds) VALUES ($1, $2)`,
      [room_name.trim(), duration_seconds ?? 0]
    )
    res.status(201).json({ success: true })
  } catch (err) {
    console.error('sensory/visit:', err.message)
    res.status(500).json({ error: 'Error al registrar visita sensorial' })
  }
}

module.exports = { registerVisit }