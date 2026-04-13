const express = require('express');
const { processIncident } = require('../services/agentService');

const router = express.Router();

router.post('/trigger-incident', async (req, res) => {
  const { vehicle_id, incident_type, severity } = req.body || {};

  if (!vehicle_id || !incident_type || !severity) {
    return res.status(400).json({
      error: 'Missing required fields: vehicle_id, incident_type, severity',
    });
  }

  try {
    const result = await processIncident({
      ...req.body,
      vehicle_id,
      incident_type,
      severity,
    });

    return res.status(200).json({
      message: 'Incident triage completed',
      received_at: new Date().toISOString(),
      result,
    });
  } catch (error) {
    return res.status(500).json({
      error: 'Failed to process incident',
      details: error.message,
    });
  }
});

module.exports = router;
