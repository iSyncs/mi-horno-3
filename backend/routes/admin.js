const router     = require('express').Router()
const controller = require('../controllers/adminController')

router.get('/users', controller.getUsers)
router.get('/assistance/requests', controller.getAssistanceRequests)
router.get('/assistance/hotspots', controller.getAssistanceHotspots)
router.get('/assistance/hourly', controller.getAssistanceHourly)
router.patch('/assistance/requests/:id/status', controller.updateAssistanceRequestStatus)

module.exports = router
