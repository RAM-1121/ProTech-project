const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const sqlite3 = require('sqlite3').verbose();
const app = express();

app.use(cors());
app.use(express.json());

const db = new sqlite3.Database('./ac_service.db');
const JWT_SECRET = 'supersecretkey123';

// Initialize DB
db.serialize(() => {
  db.run(`CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    mobile TEXT UNIQUE,
    role TEXT
  )`);
  db.run(`CREATE TABLE IF NOT EXISTS bookings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    customerId INTEGER,
    type TEXT,
    status TEXT DEFAULT 'Pending',
    date TEXT,
    address TEXT,
    assignedExecutiveId INTEGER,
    finalBill TEXT
  )`);

  // Insert dummy executive
  db.run(`INSERT OR IGNORE INTO users (mobile, role) VALUES ('9999999999', 'executive')`);
});

// Auth Middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (token == null) return res.sendStatus(401);
  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.sendStatus(403);
    req.user = user;
    next();
  });
};

// Login Route
app.post('/api/login', (req, res) => {
  const { mobile, role } = req.body;
  if (!mobile || !role) return res.status(400).json({ error: 'Mobile and role required' });

  db.get(`SELECT * FROM users WHERE mobile = ? AND role = ?`, [mobile, role], (err, row) => {
    if (err) return res.status(500).json({ error: err.message });
    let userId;
    if (!row) {
      db.run(`INSERT INTO users (mobile, role) VALUES (?, ?)`, [mobile, role], function(err) {
        userId = this.lastID;
        const token = jwt.sign({ id: userId, mobile, role }, JWT_SECRET);
        res.json({ token, user: { id: userId, mobile, role } });
      });
    } else {
      userId = row.id;
      const token = jwt.sign({ id: userId, mobile, role }, JWT_SECRET);
      res.json({ token, user: row });
    }
  });
});

// Customer Bookings
app.get('/api/customer/bookings', authenticateToken, (req, res) => {
  if (req.user.role !== 'customer') return res.sendStatus(403);
  db.all(`SELECT * FROM bookings WHERE customerId = ?`, [req.user.id], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});

app.post('/api/customer/bookings', authenticateToken, (req, res) => {
  if (req.user.role !== 'customer') return res.sendStatus(403);
  const { type, date, address } = req.body;
  db.run(`INSERT INTO bookings (customerId, type, date, address) VALUES (?, ?, ?, ?)`,
    [req.user.id, type, date, address], function(err) {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ id: this.lastID, type, date, address, status: 'Pending' });
  });
});

// Admin Bookings
app.get('/api/admin/bookings', authenticateToken, (req, res) => {
  if (req.user.role !== 'admin') return res.sendStatus(403);
  db.all(`SELECT * FROM bookings`, (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});

app.patch('/api/admin/bookings/:id/assign', authenticateToken, (req, res) => {
  if (req.user.role !== 'admin') return res.sendStatus(403);
  const { assignedExecutiveId } = req.body;
  db.run(`UPDATE bookings SET assignedExecutiveId = ?, status = 'Assigned' WHERE id = ?`,
    [assignedExecutiveId, req.params.id], function(err) {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ success: true });
  });
});

// Executive Tasks
app.get('/api/executive/tasks', authenticateToken, (req, res) => {
  if (req.user.role !== 'executive') return res.sendStatus(403);
  db.all(`SELECT * FROM bookings WHERE assignedExecutiveId = ?`, [req.user.id], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});

app.patch('/api/executive/tasks/:id/status', authenticateToken, (req, res) => {
  if (req.user.role !== 'executive') return res.sendStatus(403);
  const { status, finalBill } = req.body;
  db.run(`UPDATE bookings SET status = ?, finalBill = ? WHERE id = ? AND assignedExecutiveId = ?`,
    [status, finalBill, req.params.id, req.user.id], function(err) {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ success: true });
  });
});

// Start Server
app.listen(3000, () => {
  console.log('Server is running on port 3000');
});
