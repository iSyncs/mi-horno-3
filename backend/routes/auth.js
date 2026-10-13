const router     = require('express').Router()
const authGuard  = require('../middleware/authGuard')
const controller = require('../controllers/authController')

router.post('/register',         controller.register)
router.post('/login',            controller.login)
router.post('/refresh',          controller.refresh)
router.post('/logout',           authGuard, controller.logout)
router.get('/me',                authGuard, controller.me)
router.patch('/change-password', authGuard, controller.changePassword)
router.delete('/account',        authGuard, controller.deleteAccount)

module.exports = router