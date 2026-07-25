const express = require('express');
const router = express.Router();
const filterController = require('../controllers/filterController');

router.get('/', filterController.getAll);
router.get('/:id', filterController.getOne);
router.post('/', filterController.create);
router.put('/:id', filterController.update);
router.delete('/:id', filterController.remove);

module.exports = router;
