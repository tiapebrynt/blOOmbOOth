const express = require('express');
const router = express.Router();
const profileController = require('../controllers/profileController');

router.get('/', profileController.get);
router.put('/', profileController.update);

module.exports = router;
