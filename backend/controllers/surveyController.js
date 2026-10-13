const pool = require('../db/pool')

function normalizeResponses(responses) {
  if (!Array.isArray(responses) || responses.length === 0)
    return { error: 'Se requiere al menos una respuesta' }

  const seenQuestionIds = new Set()
  const normalized = []

  for (const response of responses) {
    const questionId = Number(response.question_id)
    const questionText = typeof response.question_text === 'string'
      ? response.question_text.trim()
      : ''
    const selectedOption = typeof response.selected_option === 'string'
      ? response.selected_option.trim()
      : ''
    const followUpText = typeof response.follow_up_text === 'string'
      ? response.follow_up_text.trim()
      : null

    if (!Number.isInteger(questionId))
      return { error: 'question_id debe ser un entero' }
    if (seenQuestionIds.has(questionId))
      return { error: 'No se permiten respuestas duplicadas para la misma pregunta' }
    if (!questionText)
      return { error: 'question_text es requerido' }
    if (!selectedOption)
      return { error: 'selected_option es requerido' }

    seenQuestionIds.add(questionId)
    normalized.push({
      question_id: questionId,
      question_text: questionText,
      selected_option: selectedOption,
      follow_up_text: followUpText || null
    })
  }

  return { responses: normalized }
}

async function getStatus(req, res) {
  try {
    const { rows } = await pool.query(
      `SELECT
         up.survey_completed_at,
         EXISTS (
           SELECT 1 FROM survey_responses sr WHERE sr.user_id = up.user_id
         ) AS has_responses
       FROM user_profiles up
       WHERE up.user_id = $1`,
      [req.userId]
    )

    if (rows.length === 0)
      return res.status(404).json({ error: 'Perfil no encontrado' })

    const completed = Boolean(rows[0].survey_completed_at || rows[0].has_responses)
    res.json({
      completed,
      completed_at: rows[0].survey_completed_at
    })
  } catch (err) {
    console.error('survey status:', err.message)
    res.status(500).json({ error: 'Error al obtener estado de encuesta' })
  }
}

async function submit(req, res) {
  const userId = req.userId
  const { responses, app_version } = req.body
  const normalized = normalizeResponses(responses)

  if (normalized.error)
    return res.status(400).json({ error: normalized.error })

  const client = await pool.connect()
  try {
    await client.query('BEGIN')

    const { rows: profileRows } = await client.query(
      'SELECT survey_completed_at FROM user_profiles WHERE user_id = $1 FOR UPDATE',
      [userId]
    )

    if (profileRows.length === 0) {
      await client.query('ROLLBACK')
      return res.status(404).json({ error: 'Perfil no encontrado' })
    }

    const { rows: existingRows } = await client.query(
      'SELECT COUNT(*)::int AS total FROM survey_responses WHERE user_id = $1',
      [userId]
    )

    if (profileRows[0]?.survey_completed_at) {
      await client.query('ROLLBACK')
      return res.status(409).json({
        error: 'Encuesta ya completada',
        completed_at: profileRows[0].survey_completed_at
      })
    }

    if (existingRows[0].total > 0) {
      const { rows: updated } = await client.query(
        `UPDATE user_profiles
         SET survey_completed_at = COALESCE(survey_completed_at, NOW())
         WHERE user_id = $1
         RETURNING survey_completed_at`,
        [userId]
      )
      await client.query('COMMIT')
      return res.status(409).json({
        error: 'Encuesta ya completada',
        completed_at: updated[0]?.survey_completed_at
      })
    }

    const appVersion = typeof app_version === 'string' && app_version.trim()
      ? app_version.trim().slice(0, 20)
      : null

    for (const response of normalized.responses) {
      await client.query(
        `INSERT INTO survey_responses
           (user_id, question_id, question_text, selected_option, follow_up_text, app_version)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [
          userId,
          response.question_id,
          response.question_text,
          response.selected_option,
          response.follow_up_text || null,
          appVersion
        ]
      )
    }

    const { rows: updated } = await client.query(
      `UPDATE user_profiles
       SET survey_completed_at = NOW()
       WHERE user_id = $1
       RETURNING survey_completed_at`,
      [userId]
    )

    await client.query('COMMIT')
    return res.status(201).json({
      message: 'Encuesta enviada correctamente',
      submitted_at: updated[0]?.survey_completed_at
    })
  } catch (err) {
    await client.query('ROLLBACK')
    console.error('survey submit:', err.message)
    return res.status(500).json({ error: 'Error al guardar encuesta' })
  } finally {
    client.release()
  }
}

module.exports = { getStatus, submit }
