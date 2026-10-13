const router     = require('express').Router()
const controller = require('../controllers/mapController')

router.get('/node/:qr',         controller.getNodeByQR)
router.get('/node-details/:id', controller.getNodeDetails)
router.get('/bathrooms',        controller.getBathrooms)
router.get('/graph',            controller.getGraph)
router.post('/user-location',   controller.updateUserLocation)

module.exports = router
