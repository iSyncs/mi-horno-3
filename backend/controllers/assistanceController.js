const assistanceService = require('../services/assistanceService')

async function createRequest(req, res) {
  try {
    const request = await assistanceService.createAssistanceRequest(req.body)
    res.status(201).json({
      folio: request.folio,
      request
    })
  } catch (error) {
    res.status(error.statusCode || 500).json({ error: error.message })
  }
}

module.exports = { createRequest }
