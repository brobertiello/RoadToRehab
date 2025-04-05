const express = require('express');
const router = express.Router();
const geminiController = require('../controllers/geminiController');
const auth = require('../middleware/auth');

// All routes are protected
router.use(auth);

router.post('/chat', geminiController.chatInteraction);
router.post('/recovery-plan', geminiController.generateRecoveryPlan);
router.post('/save-recovery-plan', geminiController.saveRecoveryPlan);
router.get('/recovery-plan', geminiController.getUserRecoveryPlan);

module.exports = router; 