const router     = require('express').Router()
const authGuard  = require('../middleware/authGuard')
const controller = require('../controllers/surveyController')

router.get('/status', authGuard, controller.getStatus)
router.post('/submit', authGuard, controller.submit)

module.exports = router
