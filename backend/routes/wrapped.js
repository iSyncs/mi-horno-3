const router     = require('express').Router()
const authGuard  = require('../middleware/authGuard')
const controller = require('../controllers/wrappedController')

router.post('/wrapped/session/start', authGuard, controller.startSession)
router.post('/wrapped/session/end',   authGuard, controller.endSession)
router.post('/wrapped/room',          authGuard, controller.registerRoom)

module.exports = router