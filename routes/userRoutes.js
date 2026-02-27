const express = require("express");
const app = express();
const router = express.Router();
const pool = require("../db");
// Input validation function
function validateUserInput(userData) {
  const errors = {};

  // First Name validation
  if (!userData.first_name || userData.first_name.trim().length < 2) {
    errors.first_name = 'First name is required and must be at least 2 characters long';
  }

  // Last Name validation
  if (!userData.last_name || userData.last_name.trim().length < 2) {
    errors.last_name = 'Last name is required and must be at least 2 characters long';
  }

  // Username validation
  if (!userData.username || userData.username.trim().length < 3) {
    errors.username = 'Username is required and must be at least 3 characters long';
  }

  // Email validation
  if (!userData.email || !validator.isEmail(userData.email)) {
    errors.email = 'Valid email is required';
  }

  // Password validation
  if (!userData.password || userData.password.length < 8) {
    errors.password = 'Password must be at least 8 characters long';
  }

  // Confirm Password validation
  if (userData.password !== userData.confirm_password) {
    errors.confirm_password = 'Passwords do not match';
  }

  // Mobile Number validation (optional, but if provided, must be valid)
  if (userData.mobile_number && !validator.isMobilePhone(userData.mobile_number, 'any')) {
    errors.mobile_number = 'Invalid mobile number format';
  }

  return {
    isValid: Object.keys(errors).length === 0,
    errors
  };
}

// POST route to create a new user
app.post('/', async (req, res) => {
  try {
    const userData = req.body;

    // Validate input
    const validationResult = validateUserInput(userData);
    if (!validationResult.isValid) {
      return res.status(400).json({ 
        error: 'Validation Failed', 
        details: validationResult.errors 
      });
    }

    // Check if email or username already exists
    const existingUserQuery = 'SELECT * FROM users WHERE email = $1 OR username = $2';
    const existingUserResult = await pool.query(existingUserQuery, [userData.email, userData.username]);

    if (existingUserResult.rows.length > 0) {
      return res.status(409).json({ 
        error: 'User with this email or username already exists' 
      });
    }

    // Hash the password
    const saltRounds = 10;
    const passwordHash = await bcrypt.hash(userData.password, saltRounds);

    // Insert new user
    const insertQuery = `
      INSERT INTO users (
        first_name, last_name, username, email, password_hash, 
        country, mobile_number, address
      ) 
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8) 
      RETURNING id, first_name, last_name, username, email, 
                country, mobile_number, address, created_at
    `;
    
    const values = [
      userData.first_name, 
      userData.last_name, 
      userData.username, 
      userData.email, 
      passwordHash,
      userData.country || null,
      userData.mobile_number || null,
      userData.address || null
    ];
    
    const result = await pool.query(insertQuery, values);

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error creating user:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// GET route to fetch user details
app.get('/:id', async (req, res) => {
  try {
    const userId = req.params.id;

    const query = `
      SELECT 
        id, first_name, last_name, username, email, 
        country, mobile_number, address, 
        created_at, updated_at, last_login
      FROM users 
      WHERE id = $1
    `;
    
    const result = await pool.query(query, [userId]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error fetching user:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// PUT route to update user profile
app.put('/:id', async (req, res) => {
  try {
    const userId = req.params.id;
    const userData = req.body;

    // Validate input (excluding password-related fields)
    const { first_name, last_name, country, mobile_number, address } = userData;

    const updateQuery = `
      UPDATE users 
      SET 
        first_name = COALESCE($1, first_name),
        last_name = COALESCE($2, last_name),
        country = $3,
        mobile_number = $4,
        address = $5
      WHERE id = $6
      RETURNING 
        id, first_name, last_name, username, email, 
        country, mobile_number, address, updated_at
    `;

    const values = [
      first_name || null, 
      last_name || null, 
      country || null, 
      mobile_number || null, 
      address || null, 
      userId
    ];

    const result = await pool.query(updateQuery, values);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error updating user:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});


// JWT Secret Key (store in environment variable in production)
const JWT_SECRET = 'your_jwt_secret_key';

// Login Route
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validate input
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    // Find user by email
    const query = 'SELECT * FROM users WHERE email = $1';
    const result = await pool.query(query, [email]);

    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const user = result.rows[0];

    // Compare passwords
    const isPasswordValid = await bcrypt.compare(password, user.password_hash);

    if (!isPasswordValid) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    // Generate JWT token
    const token = jwt.sign(
      { 
        id: user.id, 
        email: user.email 
      }, 
      JWT_SECRET, 
      { expiresIn: '24h' }
    );

    // Update last login timestamp
    await pool.query(
      'UPDATE users SET last_login = NOW() WHERE id = $1', 
      [user.id]
    );

    // Remove sensitive information
    const { password_hash, ...userResponse } = user;

    res.status(200).json({
      token,
      user: userResponse
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Error handling for unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});

module.exports = router;

