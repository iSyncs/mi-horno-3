const pool = require('../db/pool')

async function startSession(req, res) {
  const { session_id } = req.body
  if (!session_id?.trim())
    return res.status(422).json({ error: 'session_id es requerido' })
  try {
    await pool.query(
      `INSERT INTO wrapped_sessions (session_id, user_id, started_at)
       VALUES ($1, $2, NOW()) ON CONFLICT (session_id) DO NOTHING`,
      [session_id.trim(), req.userId]
    )
    res.status(201).json({ success: true })
  } catch (err) {
    console.error('wrapped/session/start:', err.message)
    res.status(500).json({ error: 'Error al iniciar sesión wrapped' })
  }
}

async function endSession(req, res) {
  const { session_id } = req.body
  if (!session_id?.trim())
    return res.status(422).json({ error: 'session_id es requerido' })
  try {
    await pool.query(
      `UPDATE wrapped_sessions SET ended_at = NOW()
       WHERE session_id = $1 AND user_id = $2`,
      [session_id.trim(), req.userId]
    )
    res.json({ success: true })
  } catch (err) {
    console.error('wrapped/session/end:', err.message)
    res.status(500).json({ error: 'Error al cerrar sesión wrapped' })
  }
}

async function registerRoom(req, res) {
  const { session_id, room_name, duration_seconds } = req.body
  if (!session_id?.trim() || !room_name?.trim())
    return res.status(422).json({ error: 'session_id y room_name son requeridos' })
  try {
    await pool.query(
      `INSERT INTO wrapped_room_visits (session_id, room_name, duration_seconds)
       VALUES ($1, $2, $3)`,
      [session_id.trim(), room_name.trim(), duration_seconds ?? 0]
    )
    res.status(201).json({ success: true })
  } catch (err) {
    console.error('wrapped/room:', err.message)
    res.status(500).json({ error: 'Error al registrar sala en wrapped' })
  }
}

module.exports = { startSession, endSession, registerRoom }