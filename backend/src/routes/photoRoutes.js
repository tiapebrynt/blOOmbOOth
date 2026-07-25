const express = require('express');
const router = express.Router();
const photoController = require('../controllers/photoController');

router.put('/:id', photoController.update);
router.delete('/:id', photoController.remove);

module.exports = router;
