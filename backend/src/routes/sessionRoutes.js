const express = require('express');
const router = express.Router();
const sessionController = require('../controllers/sessionController');

router.get('/', sessionController.getAll);
router.post('/', sessionController.create);
router.get('/:id', sessionController.getOne);
router.put('/:id', sessionController.update);
router.delete('/:id', sessionController.remove);

// Nested resources
router.post('/:id/photos', sessionController.addPhoto);
router.post('/:id/decorations', sessionController.addDecoration);

module.exports = router;
