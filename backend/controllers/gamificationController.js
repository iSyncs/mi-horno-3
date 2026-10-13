const pool = require('../db/pool')

async function getProgress(req, res) {
  const { userId } = req.params
  try {
    const { rows } = await pool.query(
      `SELECT COALESCE(SUM(total_xp_accumulated), 0) AS total_xp
       FROM user_progress WHERE user_id = $1`,
      [userId]
    )
    res.status(200).json(rows[0])
  } catch (err) {
    console.error('getProgress:', err.message)
    res.status(500).json({ error: 'Error al obtener el progreso' })
  }
}

async function getHistory(req, res) {
  const { userId, zoneId } = req.params
  try {
    const { rows } = await pool.query(
      `SELECT challenge_id FROM challenge_history
       WHERE user_id = $1 AND zone_id = $2`,
      [userId, zoneId]
    )
    res.status(200).json(rows.map(r => r.challenge_id))
  } catch (err) {
    console.error('getHistory:', err.message)
    res.status(500).json({ error: 'Error al obtener el historial' })
  }
}

async function completeChallenge(req, res) {
  const { user_id, zone_id, challenge_type, challenge_id, xp_earned } = req.body
  if (!user_id || !zone_id || !challenge_id || xp_earned === undefined)
    return res.status(400).json({ error: 'Faltan campos obligatorios en el payload' })

  const client = await pool.connect()
  try {
    await client.query('BEGIN')

    const { rows: existingChallenge } = await client.query(
      `SELECT id FROM challenge_history
       WHERE user_id = $1 AND zone_id = $2 AND challenge_id = $3
       LIMIT 1`,
      [user_id, zone_id, challenge_id]
    )

    if (existingChallenge.length > 0) {
      await client.query('COMMIT')
      return res.status(201).json({
        success: true,
        duplicate: true,
        message: 'Reto ya registrado previamente'
      })
    }

    await client.query(
      `INSERT INTO challenge_history (user_id, zone_id, challenge_type, challenge_id, xp_earned, completed_at)
       VALUES ($1, $2, $3, $4, $5, NOW())`,
      [user_id, zone_id, challenge_type, challenge_id, xp_earned]
    )

    const { rows: progressRows } = await client.query(
      `INSERT INTO user_progress (user_id, zone_id, total_xp_accumulated, current_rank)
       VALUES ($1, $2, $3, 'Bronce')
       ON CONFLICT (user_id, zone_id) DO UPDATE SET
         total_xp_accumulated = user_progress.total_xp_accumulated + EXCLUDED.total_xp_accumulated
       RETURNING total_xp_accumulated`,
      [user_id, zone_id, xp_earned]
    )

    const totalXP = progressRows[0]?.total_xp_accumulated ?? 0
    const { rows: zoneRows } = await client.query(
      'SELECT xp_silver, xp_gold FROM zones WHERE id = $1',
      [zone_id]
    )
    const rank = totalXP >= (zoneRows[0]?.xp_gold ?? Infinity)
      ? 'Oro'
      : totalXP >= (zoneRows[0]?.xp_silver ?? Infinity)
        ? 'Plata'
        : 'Bronce'

    await client.query(
      `UPDATE user_progress
       SET current_rank = $3
       WHERE user_id = $1 AND zone_id = $2`,
      [user_id, zone_id, rank]
    )

    await client.query('COMMIT')
    res.status(201).json({
      success: true,
      message: 'Reto registrado y XP otorgada',
      total_xp: totalXP,
      current_rank: rank
    })
  } catch (err) {
    await client.query('ROLLBACK')
    console.error('completeChallenge:', err.message)
    res.status(500).json({ error: 'Error al procesar la recompensa del reto' })
  } finally {
    client.release()
  }
}

async function resetZone(req, res) {
  const { userId, zoneId } = req.body
  if (!userId || !zoneId)
    return res.status(400).json({ error: 'Faltan campos obligatorios en el payload' })

  const client = await pool.connect()
  try {
    await client.query('BEGIN')

    await client.query(
      `DELETE FROM challenge_history WHERE user_id = $1 AND zone_id = $2`,
      [userId, zoneId]
    )

    await client.query(
      `DELETE FROM generated_quiz_questions WHERE user_id = $1 AND zone_id = $2`,
      [userId, zoneId]
    )

    await client.query(
      `DELETE FROM user_progress WHERE user_id = $1 AND zone_id = $2`,
      [userId, zoneId]
    )

    await client.query('COMMIT')
    res.status(200).json({
      success: true,
      message: 'Zona restaurada correctamente',
      reset: {
        challenge_history: true,
        zone_progress: true,
        badges_preserved: true
      }
    })
  } catch (err) {
    await client.query('ROLLBACK')
    console.error('resetZone:', err.message)
    res.status(500).json({ error: 'Error al restaurar la zona' })
  } finally {
    client.release()
  }
}

async function saveGeneratedQuiz(req, res) {
  const questions = Array.isArray(req.body) ? req.body : req.body.questions
  if (!Array.isArray(questions) || questions.length === 0)
    return res.status(400).json({ error: 'No se recibieron preguntas generadas' })

  const client = await pool.connect()
  try {
    await client.query('BEGIN')

    for (const question of questions) {
      const userId = question.user_id || req.body.user_id
      const {
        quiz_id: quizId,
        challenge_id: challengeId,
        zone_id: zoneId,
        question: text,
        options,
        correct_answer: correctAnswer,
        type = 'quiz'
      } = question

      if (!userId || !quizId || !challengeId || !zoneId || !text || !Array.isArray(options) || !correctAnswer)
        throw new Error(`Pregunta generada inválida: ${challengeId || 'sin id'}`)

      await client.query(
        `INSERT INTO generated_quiz_questions
          (user_id, zone_id, quiz_id, challenge_id, question, options, correct_answer, type, created_at)
         VALUES ($1, $2, $3, $4, $5, $6::jsonb, $7, $8, NOW())
         ON CONFLICT (user_id, challenge_id) DO UPDATE SET
          question = EXCLUDED.question,
          options = EXCLUDED.options,
          correct_answer = EXCLUDED.correct_answer,
          type = EXCLUDED.type`,
        [userId, zoneId, quizId, challengeId, text, JSON.stringify(options), correctAnswer, type]
      )
    }

    await client.query('COMMIT')
    res.status(201).json({ success: true, saved: questions.length })
  } catch (err) {
    await client.query('ROLLBACK')
    console.error('saveGeneratedQuiz:', err.message)
    res.status(500).json({ error: 'Error al guardar la trivia generada' })
  } finally {
    client.release()
  }
}

async function getGeneratedQuiz(req, res) {
  const { userId, zoneId } = req.params
  try {
    const { rows } = await pool.query(
      `SELECT user_id, quiz_id, challenge_id, zone_id, question, options, correct_answer, type, created_at
       FROM generated_quiz_questions
       WHERE user_id = $1 AND zone_id = $2
       ORDER BY quiz_id ASC, challenge_id ASC`,
      [userId, zoneId]
    )
    res.status(200).json(rows)
  } catch (err) {
    console.error('getGeneratedQuiz:', err.message)
    res.status(500).json({ error: 'Error al obtener trivia generada' })
  }
}

module.exports = {
  getProgress,
  getHistory,
  completeChallenge,
  resetZone,
  saveGeneratedQuiz,
  getGeneratedQuiz
}
