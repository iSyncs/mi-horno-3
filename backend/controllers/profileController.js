const pool = require('../db/pool')

async function getAvatars(req, res) {
  try {
    const { rows } = await pool.query(
      'SELECT id, name, image_path FROM avatars WHERE is_active = true ORDER BY id'
    )
    res.json(rows.map(a => ({ ...a, image_url: a.image_path })))
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
}

async function getInterests(req, res) {
  try {
    const { rows } = await pool.query(
      'SELECT id, name_es, icon FROM interests_catalog WHERE is_active = true ORDER BY id'
    )
    res.json(rows)
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
}

async function getProfile(req, res) {
  try {
    const { rows } = await pool.query(
      `SELECT u.full_name, u.email, u.auth_provider, u.avatar_url,
              up.first_name, up.last_name, up.country, up.age_range, up.avatar_id,
              COALESCE(
                json_agg(ui.interest_id) FILTER (WHERE ui.interest_id IS NOT NULL),
                '[]'
              ) AS interest_ids
       FROM users u
       LEFT JOIN user_profiles up ON up.user_id = u.id
       LEFT JOIN user_interests ui ON ui.user_id = u.id
       WHERE u.id = $1
       GROUP BY u.full_name, u.email, u.auth_provider, u.avatar_url,
                up.first_name, up.last_name, up.country, up.age_range, up.avatar_id`,
      [req.userId]
    )
    if (rows.length === 0)
      return res.status(404).json({ error: 'Usuario no encontrado' })
    res.json(rows[0])
  } catch (err) {
    console.error('profile get:', err.message)
    res.status(500).json({ error: 'Error al obtener perfil' })
  }
}

async function updateProfile(req, res) {
  const { first_name, last_name, country, age_range, avatar_id, interest_ids } = req.body
  if (interest_ids && interest_ids.length > 5)
    return res.status(422).json({ error: 'Máximo 5 intereses permitidos' })
  try {
    await pool.query(
      `UPDATE user_profiles
       SET first_name = $1, last_name = $2, country = $3,
           age_range = $4, avatar_id = $5, updated_at = NOW()
       WHERE user_id = $6`,
      [first_name, last_name, country, age_range, avatar_id || null, req.userId]
    )
    if (interest_ids) {
      await pool.query('DELETE FROM user_interests WHERE user_id = $1', [req.userId])
      for (const id of interest_ids) {
        await pool.query(
          'INSERT INTO user_interests (user_id, interest_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
          [req.userId, id]
        )
      }
    }
    res.json({ success: true })
  } catch (err) {
    console.error('profile patch:', err.message)
    res.status(500).json({ error: 'Error al actualizar perfil' })
  }
}

module.exports = { getAvatars, getInterests, getProfile, updateProfile }