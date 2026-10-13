const router     = require('express').Router()
const authGuard  = require('../middleware/authGuard')
const controller = require('../controllers/profileController')

router.get('/avatars',   controller.getAvatars)
router.get('/interests', controller.getInterests)
router.get('/profile',   authGuard, controller.getProfile)
router.patch('/profile', authGuard, controller.updateProfile)

module.exports = router