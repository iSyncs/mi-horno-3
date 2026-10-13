const { Pool } = require('pg')

const isLocalDB = !process.env.DB_HOST || ['localhost', '127.0.0.1'].includes(process.env.DB_HOST)
const ssl = process.env.DB_SSL === 'true' || (!isLocalDB && process.env.DB_SSL !== 'false')
  ? { rejectUnauthorized: false }
  : false

const pool = new Pool({
  user:     process.env.DB_USER,
  host:     process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port:     process.env.DB_PORT,
  ssl
})

module.exports = pool
