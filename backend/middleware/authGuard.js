const jwt = require('jsonwebtoken')

function authGuard(req, res, next) {
  const header = req.headers.authorization
  if (!header?.startsWith('Bearer '))
    return res.status(401).json({ error: 'Token requerido' })
  try {
    const payload = jwt.verify(header.split(' ')[1], process.env.JWT_SECRET)
    req.userId = payload.sub
    next()
  } catch {
    res.status(401).json({ error: 'Token inválido o expirado' })
  }
}

module.exports = authGuard