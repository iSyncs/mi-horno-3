const bcrypt = require('bcrypt')
const jwt    = require('jsonwebtoken')
const pool   = require('../db/pool')

const JWT_SECRET      = process.env.JWT_SECRET
const JWT_EXPIRES     = '15m'
const REFRESH_EXPIRES = '30d'
const BCRYPT_ROUNDS   = 12

function makeTokens(userId) {
  const access  = jwt.sign({ sub: userId },                  JWT_SECRET, { expiresIn: JWT_EXPIRES })
  const refresh = jwt.sign({ sub: userId, type: 'refresh' }, JWT_SECRET, { expiresIn: REFRESH_EXPIRES })
  return { access, refresh }
}

function safeUser(u) {
  return {
    id:            u.id,
    full_name:     u.full_name,
    email:         u.email,
    auth_provider: u.auth_provider,
    avatar_url:    u.avatar_url ?? null,
    user_type:     u.user_type
  }
}

async function register(req, res) {
  const { full_name, email, password } = req.body
  if (!full_name?.trim())
    return res.status(422).json({ error: 'El nombre es requerido' })
  if (!email?.includes('@'))
    return res.status(422).json({ error: 'Correo inválido' })
  if (!password || password.length < 6)
    return res.status(422).json({ error: 'La contraseña debe tener mínimo 6 caracteres' })

  const emailClean = email.trim().toLowerCase()
  try {
    const exists = await pool.query('SELECT id FROM users WHERE email = $1', [emailClean])
    if (exists.rows.length > 0)
      return res.status(409).json({ error: 'El correo ya está registrado' })

    const hash = await bcrypt.hash(password, BCRYPT_ROUNDS)
    const { rows } = await pool.query(
      `INSERT INTO users (full_name, email, password_hash, auth_provider, email_verified)
       VALUES ($1, $2, $3, 'local', false) RETURNING *`,
      [full_name.trim(), emailClean, hash]
    )
    const user = rows[0]
    await pool.query('INSERT INTO user_profiles (user_id) VALUES ($1)', [user.id])
    const tokens = makeTokens(user.id)
    res.status(201).json({ access_token: tokens.access, refresh_token: tokens.refresh, user: safeUser(user) })
  } catch (err) {
    console.error('register:', err.message)
    res.status(500).json({ error: 'Error interno del servidor' })
  }
}

async function login(req, res) {
  const { email, password } = req.body
  if (!email || !password)
    return res.status(422).json({ error: 'Correo y contraseña requeridos' })

  const emailClean = email.trim().toLowerCase()
  try {
    const { rows } = await pool.query(
      'SELECT * FROM users WHERE email = $1 AND is_active = true', [emailClean]
    )
    if (rows.length === 0)
      return res.status(404).json({ error: 'No existe una cuenta con ese correo' })

    const user = rows[0]
    if (!user.password_hash)
      return res.status(401).json({ error: `Esta cuenta usa ${user.auth_provider}. Inicia sesión con ese método.` })

    const valid = await bcrypt.compare(password, user.password_hash)
    if (!valid) return res.status(401).json({ error: 'Contraseña incorrecta' })

    await pool.query('UPDATE users SET last_login_at = NOW() WHERE id = $1', [user.id])
    const tokens = makeTokens(user.id)
    res.json({ access_token: tokens.access, refresh_token: tokens.refresh, user: safeUser(user) })
  } catch (err) {
    console.error('login:', err.message)
    res.status(500).json({ error: 'Error interno del servidor' })
  }
}

async function refresh(req, res) {
  const { refresh_token } = req.body
  if (!refresh_token)
    return res.status(422).json({ error: 'refresh_token requerido' })
  try {
    const payload = jwt.verify(refresh_token, JWT_SECRET)
    if (payload.type !== 'refresh')
      return res.status(401).json({ error: 'Token inválido' })
    const { rows } = await pool.query(
      'SELECT id FROM users WHERE id = $1 AND is_active = true', [payload.sub]
    )
    if (rows.length === 0)
      return res.status(401).json({ error: 'Usuario no encontrado' })
    const tokens = makeTokens(payload.sub)
    res.json({ access_token: tokens.access, refresh_token: tokens.refresh })
  } catch {
    res.status(401).json({ error: 'refresh_token expirado o inválido' })
  }
}

function logout(req, res) {
  res.status(204).send()
}

async function me(req, res) {
  try {
    const { rows } = await pool.query(
      `SELECT u.id, u.full_name, u.email, u.auth_provider, u.avatar_url, u.user_type,
              up.first_name, up.last_name, up.country, up.age_range, up.avatar_id
       FROM users u
       LEFT JOIN user_profiles up ON up.user_id = u.id
       WHERE u.id = $1`,
      [req.userId]
    )
    if (rows.length === 0)
      return res.status(404).json({ error: 'Usuario no encontrado' })
    res.json(rows[0])
  } catch (err) {
    console.error('me:', err.message)
    res.status(500).json({ error: 'Error interno del servidor' })
  }
}

async function changePassword(req, res) {
  const { current_password, new_password } = req.body
  if (!current_password || !new_password)
    return res.status(422).json({ error: 'Campos requeridos' })
  if (new_password.length < 6)
    return res.status(422).json({ error: 'La contraseña debe tener mínimo 6 caracteres' })
  try {
    const { rows } = await pool.query('SELECT password_hash FROM users WHERE id = $1', [req.userId])
    const valid = await bcrypt.compare(current_password, rows[0].password_hash)
    if (!valid) return res.status(401).json({ error: 'Contraseña actual incorrecta' })
    const hash = await bcrypt.hash(new_password, BCRYPT_ROUNDS)
    await pool.query('UPDATE users SET password_hash = $1 WHERE id = $2', [hash, req.userId])
    res.json({ success: true })
  } catch (err) {
    res.status(500).json({ error: 'Error al cambiar contraseña' })
  }
}

async function deleteAccount(req, res) {
  try {
    await pool.query('DELETE FROM users WHERE id = $1', [req.userId])
    res.status(204).send()
  } catch (err) {
    res.status(500).json({ error: 'Error al eliminar cuenta' })
  }
}

module.exports = { register, login, refresh, logout, me, changePassword, deleteAccount }