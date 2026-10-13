require('dotenv').config()
const express = require('express')
const cors    = require('cors')

const app = express()
app.use(cors())
app.use(express.json())

app.use('/api/v1/auth',         require('./routes/auth'))
app.use('/api/v1',              require('./routes/profile'))
app.use('/api/v1/assistance',   require('./routes/assistance'))
app.use('/map',                 require('./routes/map'))
app.use('/api/v1/admin',        require('./routes/admin'))
app.use('/api/v1/gamification', require('./routes/gamification'))
app.use('/api/v1',              require('./routes/sensory'))
app.use('/api/v1',              require('./routes/wrapped'))
app.use('/api/v1/survey',       require('./routes/survey'))

module.exports = app

if (process.env.NODE_ENV !== 'production') {
  const PORT = process.env.PORT || 3000
  app.listen(PORT, () => console.log(`API corriendo en puerto ${PORT}`))
}
