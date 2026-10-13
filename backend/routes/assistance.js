const router = require('express').Router()
const controller = require('../controllers/assistanceController')

router.post('/requests', controller.createRequest)

module.exports = router
