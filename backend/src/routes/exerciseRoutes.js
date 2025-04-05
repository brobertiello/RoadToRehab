const express = require('express');
const router = express.Router();
const exerciseController = require('../controllers/exerciseController');
const auth = require('../middleware/auth');

// All routes are protected
router.use(auth);

router.post('/', exerciseController.createExercise);
router.get('/', exerciseController.getExercises);
router.get('/:id', exerciseController.getExercise);
router.patch('/:id', exerciseController.updateExercise);
router.delete('/:id', exerciseController.deleteExercise);

module.exports = router; 