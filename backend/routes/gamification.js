const router     = require('express').Router()
const controller = require('../controllers/gamificationController')

router.get('/progress/:userId',        controller.getProgress)
router.get('/history/:userId/:zoneId', controller.getHistory)
router.get('/generatedQuiz/:userId/:zoneId', controller.getGeneratedQuiz)
router.post('/complete',               controller.completeChallenge)
router.post('/generatedQuiz',          controller.saveGeneratedQuiz)
router.post('/resetZone',              controller.resetZone)

module.exports = router
