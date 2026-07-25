const express = require('express');
const router = express.Router();
const frameController = require('../controllers/frameController');

router.get('/', frameController.getAll);
router.get('/:id', frameController.getOne);
router.post('/', frameController.create);
router.put('/:id', frameController.update);
router.delete('/:id', frameController.remove);

module.exports = router;
