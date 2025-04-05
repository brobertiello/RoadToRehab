const express = require('express');
const router = express.Router();
const symptomController = require('../controllers/symptomController');
const auth = require('../middleware/auth');

// All routes are protected
router.use(auth);

router.post('/', symptomController.createSymptom);
router.get('/', symptomController.getSymptoms);
router.get('/:id', symptomController.getSymptom);
router.patch('/:id', symptomController.updateSymptom);
router.delete('/:id', symptomController.deleteSymptom);

module.exports = router; 