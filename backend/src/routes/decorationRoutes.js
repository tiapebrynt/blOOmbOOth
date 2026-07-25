const express = require('express');
const router = express.Router();
const decorationController = require('../controllers/decorationController');

router.put('/:id', decorationController.update);
router.delete('/:id', decorationController.remove);

module.exports = router;
