const router     = require('express').Router()
const authGuard  = require('../middleware/authGuard')
const controller = require('../controllers/sensoryController')

router.post('/sensory/visit', authGuard, controller.registerVisit)

module.exports = router