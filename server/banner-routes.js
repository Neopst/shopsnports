// Banner routes to add to content.js

// GET /api/v1/content/banners/active - Get active banners for frontend display
router.get('/banners/active', async (req, res) => {
  try {
    const { placement = 'home' } = req.query;

    const result = await pool.query(
      `SELECT id, title, description, image_url, link_url, placement, display_order, active, created_at
       FROM banners
       WHERE active = TRUE AND placement = $1
       ORDER BY display_order ASC`,
      [placement]
    );

    res.json({ success: true, data: result.rows });
  } catch (error) {
    console.error('Error fetching active banners:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// GET /api/v1/content/banners - Get all banners (admin)
router.get('/banners', verifyToken, async (req, res) => {
  try {
    const { page = 1, limit = 50, placement, active } = req.query;
    const offset = (page - 1) * limit;

    let query = `SELECT * FROM banners WHERE 1=1`;
    const params = [];
    let paramIndex = 1;

    if (placement) {
      query += ` AND placement = $${paramIndex++}`;
      params.push(placement);
    }
    if (active !== undefined) {
      query += ` AND active = $${paramIndex++}`;
      params.push(active === 'true');
    }

    query += ` ORDER BY display_order ASC, created_at DESC LIMIT $${paramIndex++} OFFSET $${paramIndex}`;
    params.push(limit, offset);

    const result = await pool.query(query, params);
    res.json({ success: true, data: result.rows });
  } catch (error) {
    console.error('Error fetching banners:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// GET /api/v1/content/banners/:id - Get single banner
router.get('/banners/:id', verifyToken, async (req, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(
      'SELECT * FROM banners WHERE id = $1',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Banner not found' });
    }

    res.json({ success: true, data: result.rows[0] });
  } catch (error) {
    console.error('Error fetching banner:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// POST /api/v1/content/banners - Create banner (admin)
router.post('/banners', verifyToken, async (req, res) => {
  try {
    const {
      title,
      description,
      image_url,
      link_url,
      placement = 'home',
      active = true,
      display_order = 0
    } = req.body;

    if (!image_url) {
      return res.status(400).json({ success: false, error: 'image_url is required' });
    }

    const result = await pool.query(
      `INSERT INTO banners (title, description, image_url, link_url, placement, active, display_order)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [title, description, image_url, link_url, placement, active, display_order]
    );

    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (error) {
    console.error('Error creating banner:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// PUT /api/v1/content/banners/:id - Update banner (admin)
router.put('/banners/:id', verifyToken, async (req, res) => {
  try {
    const { id } = req.params;
    const {
      title,
      description,
      image_url,
      link_url,
      placement,
      active,
      display_order
    } = req.body;

    const result = await pool.query(
      `UPDATE banners
       SET title = COALESCE($1, title),
           description = COALESCE($2, description),
           image_url = COALESCE($3, image_url),
           link_url = COALESCE($4, link_url),
           placement = COALESCE($5, placement),
           active = COALESCE($6, active),
           display_order = COALESCE($7, display_order),
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $8
       RETURNING *`,
      [title, description, image_url, link_url, placement, active, display_order, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Banner not found' });
    }

    res.json({ success: true, data: result.rows[0] });
  } catch (error) {
    console.error('Error updating banner:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// DELETE /api/v1/content/banners/:id - Delete banner (admin)
router.delete('/banners/:id', verifyToken, async (req, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(
      'DELETE FROM banners WHERE id = $1 RETURNING *',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Banner not found' });
    }

    res.json({ success: true, message: 'Banner deleted successfully' });
  } catch (error) {
    console.error('Error deleting banner:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
