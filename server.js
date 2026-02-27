const express = require("express");
const app = express();
const cors = require("cors");
require("dotenv").config();
const pool = require("./db");
const validator = require('validator');
const bcrypt = require('bcrypt');
//const { authenticateUser } = require("./middleware/auth"); // JWT middleware
const router = express.Router();
const weatherRoutes = require('./routes/weatherRoutes');
// Middleware
app.use(cors()); 
app.use(express.json());

// Test user endpoint (for development bypass)
app.get('/api/test-user', async (req, res) => {
  try {
    const userId = 'f08ffb63-ebec-4cae-a1c3-027a62fe2f7a';
    const user = await pool.query(
      "SELECT id, name, email, country, mobile_number, address, created_at, updated_at FROM users WHERE id = $1", 
      [userId]
    );
    
    if (user.rows.length === 0) {
      return res.status(404).json({ error: "Test user not found" });
    }
    
    // Return user data along with a mock token
    res.json({
      user: user.rows[0],
      token: 'predefined_token', // Matching your Flutter app
      userName: 'Postgres User'  // Matching your Flutter app
    });
  } catch (err) {
    console.error(err.message);
    res.status(500).json({ error: "Server error" });
  }
});

// Routes
app.use("/users", require("./routes/userRoutes"));
app.use("/tasks", require("./routes/taskRoutes"));
app.use("/", require("./routes/missionRoutes"));
app.use('/api', weatherRoutes);


// Get all notes for a user
app.get('/api/notes/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const result = await pool.query(
      'SELECT * FROM notes WHERE user_id = $1 ORDER BY created_at DESC',
      [userId]
    );
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching notes:', error);
    res.status(500).json({ error: 'Failed to fetch notes' });
  }
});

// Add a new note
app.post('/api/notes', async (req, res) => {
  try {
    const { user_id, title, content } = req.body;
    
    if (!user_id || !content) {
      return res.status(400).json({ error: 'User ID and content are required' });
    }

    const result = await pool.query(
      'INSERT INTO notes (user_id, title, content) VALUES ($1, $2, $3) RETURNING *',
      [user_id, title, content]
    );
    
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error adding note:', error);
    res.status(500).json({ error: 'Failed to add note' });
  }
});

// Get a specific note
app.get('/api/notes/detail/:noteId', async (req, res) => {
  try {
    const { noteId } = req.params;
    const result = await pool.query('SELECT * FROM notes WHERE id = $1', [noteId]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Note not found' });
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error fetching note:', error);
    res.status(500).json({ error: 'Failed to fetch note' });
  }
});

// Update a note
app.put('/api/notes/:noteId', async (req, res) => {
  try {
    const { noteId } = req.params;
    const { title, content } = req.body;
    
    const result = await pool.query(
      'UPDATE notes SET title = $1, content = $2 WHERE id = $3 RETURNING *',
      [title, content, noteId]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Note not found' });
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error updating note:', error);
    res.status(500).json({ error: 'Failed to update note' });
  }
});

// Delete a note
app.delete('/api/notes/:noteId', async (req, res) => {
  try {
    const { noteId } = req.params;
    const result = await pool.query('DELETE FROM notes WHERE id = $1 RETURNING *', [noteId]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Note not found' });
    }
    
    res.json({ message: 'Note deleted successfully' });
  } catch (error) {
    console.error('Error deleting note:', error);
    res.status(500).json({ error: 'Failed to delete note' });
  }
});


/*router.post("/save-mission", async (req, res) => {
  try {
      const { user_id, mission_name, accuracy, goal_time, spent_time, distraction_time } = req.body;
      
      // Validate required fields
      if (!user_id || !mission_name || accuracy === undefined) {
          return res.status(400).json({ error: "Missing required fields" });
      }

      console.log("Received mission data:", req.body); // Debug log

      const result = await pool.query(
          `INSERT INTO past_missions 
           (user_id, mission_name, accuracy, goal_time, spent_time, distraction_time) 
           VALUES ($1, $2, $3, $4::interval, $5::interval, $6::interval) 
           RETURNING *`,
          [
              user_id, 
              mission_name, 
              accuracy,
              goal_time || '00:00:00', // Default if null
              spent_time || '00:00:00',
              distraction_time || '00:00:00'
          ]
      );

      console.log("Mission saved:", result.rows[0]); // Debug log
      res.json({ message: "Mission saved successfully", mission: result.rows[0] });
  } catch (error) {
      console.error("Insert error:", error);
      res.status(500).json({ 
          error: "Internal Server Error",
          details: error.message 
      });
  }
});



// Fetch user's past missions
router.get("/past-missions", async (req, res) => {
  try {
      const user_id = req.user.id;
      const result = await pool.query(
          "SELECT * FROM past_missions WHERE user_id = $1 ORDER BY date DESC",
          [user_id]
      );

      res.json(result.rows);
  } catch (error) {
      console.error(error);
      res.status(500).json({ error: "Internal Server Error" });
  }
});

// Delete a past mission
router.delete("/delete-mission/:id", async (req, res) => {
  try {
      const { id } = req.params;
      const user_id = req.user.id;

      await pool.query(
          "DELETE FROM past_missions WHERE id = $1 AND user_id = $2",
          [id, user_id]
      );

      res.json({ message: "Mission deleted successfully" });
  } catch (error) {
      console.error(error);
      res.status(500).json({ error: "Internal Server Error" });
  }
});*/


// Expense Routes
// Add Expense
app.post("/expenses", async (req, res) => {
  try {
    const { user_id, amount, category, description } = req.body;
    
    // Validate inputs
    if (!user_id || !amount || !category) {
      return res.status(400).json({ error: "Missing required fields: user_id, amount, category" });
    }
    
    // Validate UUID format
    if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(user_id)) {
      return res.status(400).json({ error: "Invalid UUID format for user_id" });
    }
    
    console.log("Adding expense:", { user_id, amount, category, description });
    
    const newExpense = await pool.query(
      "INSERT INTO expenses (user_id, amount, category, description) VALUES ($1, $2, $3, $4) RETURNING *",
      [user_id, amount, category, description || ""]
    );
    
    console.log("New expense added:", newExpense.rows[0]);
    res.status(201).json(newExpense.rows[0]);
  } catch (err) {
    console.error("Error adding expense:", err);
    res.status(500).json({ error: err.message });
  }
});

// Get All Expenses by User
app.get("/expenses/:user_id", async (req, res) => {
  try {
    const { user_id } = req.params;
    
    // Validate UUID format
    if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(user_id)) {
      return res.status(400).json({ error: "Invalid UUID format for user_id" });
    }
    
    console.log("Fetching expenses for user:", user_id);
    
    const expenses = await pool.query(
      "SELECT * FROM expenses WHERE user_id = $1 ORDER BY created_at DESC",
      [user_id]
    );
    
    console.log(`Found ${expenses.rows.length} expenses`);
    res.json(expenses.rows);
  } catch (err) {
    console.error("Error fetching expenses:", err);
    res.status(500).json({ error: err.message });
  }
});

// Delete Expense
app.delete("/expenses/:id", async (req, res) => {
  try {
    const { id } = req.params;
    
    // Validate UUID format
    if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id)) {
      return res.status(400).json({ error: "Invalid UUID format for expense id" });
    }
    
    console.log("Deleting expense:", id);
    
    const result = await pool.query("DELETE FROM expenses WHERE id = $1 RETURNING *", [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Expense not found" });
    }
    
    console.log("Expense deleted successfully");
    res.json({ message: "Expense deleted successfully", deletedExpense: result.rows[0] });
  } catch (err) {
    console.error("Error deleting expense:", err);
    res.status(500).json({ error: err.message });
  }
});

// ===== BUDGET ROUTES =====

// Modify the budgets table structure:
// ALTER TABLE budgets ADD COLUMN budget_type VARCHAR(20) DEFAULT 'monthly';

// Update the budget route to include budget type
/*app.post("/budgets", async (req, res) => {
  try {
    const { user_id, budget_amount, budget_type } = req.body;
    
    // Validate inputs
    if (!user_id || !budget_amount || !budget_type) {
      return res.status(400).json({ error: "Missing required fields: user_id, budget_amount, budget_type" });
    }
    
    // Validate UUID format
    if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(user_id)) {
      return res.status(400).json({ error: "Invalid UUID format for user_id" });
    }
    
    // Validate budget type
    const validBudgetTypes = ["daily", "weekly", "monthly"];
    if (!validBudgetTypes.includes(budget_type)) {
      return res.status(400).json({ error: "Invalid budget_type. Must be one of: daily, weekly, monthly" });
    }
    
    console.log("Setting budget:", { user_id, budget_amount, budget_type });
    
    const newBudget = await pool.query(
      "INSERT INTO budgets (user_id, monthly_budget, budget_type) VALUES ($1, $2, $3) ON CONFLICT (user_id) DO UPDATE SET monthly_budget = $2, budget_type = $3 RETURNING *",
      [user_id, budget_amount, budget_type]
    );
    
    console.log("Budget set:", newBudget.rows[0]);
    res.json(newBudget.rows[0]);
  } catch (err) {
    console.error("Error setting budget:", err);
    res.status(500).json({ error: err.message });
  }
});

// Get Current Budget & Spending Progress with time period filtering
/*app.get("/budgets/:user_id", async (req, res) => {
  try {
    const { user_id } = req.params;
    
    // Validate UUID format
    if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(user_id)) {
      return res.status(400).json({ error: "Invalid UUID format for user_id" });
    }
    
    console.log("Fetching budget for user:", user_id);
    
    const budget = await pool.query(
      "SELECT * FROM budgets WHERE user_id = $1", 
      [user_id]
    );
    
    if (budget.rows.length === 0) {
      return res.status(404).json({ error: "Budget not set" });
    }
    
    const budgetType = budget.rows[0].budget_type || 'monthly';
    
    // Determine date range based on budget type
    let fromDate;
    const currentDate = new Date();
    
    if (budgetType === 'daily') {
      // Start of today
      fromDate = new Date(currentDate);
      fromDate.setHours(0, 0, 0, 0);
    } else if (budgetType === 'weekly') {
      // Start of current week (Sunday)
      fromDate = new Date(currentDate);
      fromDate.setDate(currentDate.getDate() - currentDate.getDay());
      fromDate.setHours(0, 0, 0, 0);
    } else {
      // Start of current month
      fromDate = new Date(currentDate.getFullYear(), currentDate.getMonth(), 1);
    }
    
    console.log(`Calculating expenses from ${fromDate.toISOString()} for ${budgetType} budget`);
    
    // Get expenses for the specified period
    const totalSpent = await pool.query(
      "SELECT SUM(amount) AS spent FROM expenses WHERE user_id = $1 AND created_at >= $2",
      [user_id, fromDate]
    );
    
    const spent = parseFloat(totalSpent.rows[0].spent || 0);
    const percentage = ((spent / budget.rows[0].monthly_budget) * 100).toFixed(2);
    
    console.log(`Budget: ${budget.rows[0].monthly_budget}, Spent: ${spent}, Percentage: ${percentage}%`);
    
    res.json({
      budget_amount: budget.rows[0].monthly_budget,
      budget_type: budgetType,
      spent,
      percentage,
      alert: generateSpendingAlert(percentage),
      remaining: budget.rows[0].monthly_budget - spent,
      period_start: fromDate,
      period_end: currentDate
    });
  } catch (err) {
    console.error("Error fetching budget info:", err);
    res.status(500).json({ error: err.message });
  }
});*/
// Create a new budget
/*app.post("/budgets", async (req, res) => {
  try {
    const { user_id, budget_amount, budget_type, name } = req.body;
    
    // Validate inputs
    if (!user_id || !budget_amount || !budget_type || !name) {
      return res.status(400).json({ error: "Missing required fields" });
    }
    
    // Validate budget type
    const validBudgetTypes = ["daily", "weekly", "monthly"];
    if (!validBudgetTypes.includes(budget_type)) {
      return res.status(400).json({ error: "Invalid budget_type" });
    }
    
    // Insert with conflict handling
    const newBudget = await pool.query(
      `INSERT INTO budgets (user_id, monthly_budget, budget_type, name, is_active) 
       VALUES ($1, $2, $3, $4, true) 
       ON CONFLICT (user_id) WHERE is_active = true 
       DO UPDATE SET monthly_budget = $2, budget_type = $3, name = $4 
       RETURNING *`,
      [user_id, budget_amount, budget_type, name]
    );
    
    res.json(newBudget.rows[0]);
  } catch (err) {
    console.error("Error creating budget:", err);
    res.status(500).json({ error: err.message });
  }
});*/

// Create a new budget
/*app.post("/budgets", async (req, res) => {
  try {
    const { user_id, budget_amount, budget_type, name } = req.body;
    
    // Validate inputs
    if (!user_id || !budget_amount || !budget_type || !name) {
      return res.status(400).json({ error: "Missing required fields" });
    }
    
    // Validate UUID format
    if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(user_id)) {
      return res.status(400).json({ error: "Invalid UUID format for user_id" });
    }
    
    // Validate budget type
    const validBudgetTypes = ["daily", "weekly", "monthly"];
    if (!validBudgetTypes.includes(budget_type)) {
      return res.status(400).json({ error: "Invalid budget_type" });
    }
    
    console.log("Setting budget:", { user_id, budget_amount, budget_type, name });
    
    // Insert with conflict handling
    const newBudget = await pool.query(
      `INSERT INTO budgets (user_id, monthly_budget, budget_type, name, is_active) 
       VALUES ($1, $2, $3, $4, true) 
       ON CONFLICT (user_id) WHERE is_active = true 
       DO UPDATE SET monthly_budget = $2, budget_type = $3, name = $4 
       RETURNING *`,
      [user_id, budget_amount, budget_type, name]
    );
    
    console.log("Budget set:", newBudget.rows[0]);
    res.json(newBudget.rows[0]);
  } catch (err) {
    console.error("Error creating budget:", err);
    res.status(500).json({ error: err.message });
  }
});*/
// Create a new budget
app.post("/budgets", async (req, res) => {
  try {
    const { user_id, budget_amount, budget_type, name } = req.body;
    
    // Validate inputs
    if (!user_id || !budget_amount || !budget_type || !name) {
      return res.status(400).json({ error: "Missing required fields" });
    }
    
    // Validate UUID format
    if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(user_id)) {
      return res.status(400).json({ error: "Invalid UUID format for user_id" });
    }
    
    // Validate budget type
    const validBudgetTypes = ["daily", "weekly", "monthly"];
    if (!validBudgetTypes.includes(budget_type)) {
      return res.status(400).json({ error: "Invalid budget_type" });
    }
    
    console.log("Setting budget:", { user_id, budget_amount, budget_type, name });

    // First, deactivate any existing active budgets for this user
    await pool.query(
      "UPDATE budgets SET is_active = false WHERE user_id = $1 AND is_active = true",
      [user_id]
    );
    
    // Then create a new active budget
    const newBudget = await pool.query(
      `INSERT INTO budgets (user_id, monthly_budget, budget_type, name, is_active) 
       VALUES ($1, $2, $3, $4, true)
       RETURNING *`,
      [user_id, budget_amount, budget_type, name]
    );
    
    console.log("Budget set:", newBudget.rows[0]);
    res.json(newBudget.rows[0]);
  } catch (err) {
    console.error("Error creating budget:", err);
    res.status(500).json({ error: err.message });
  }
});


// Get list of user's budgets
app.get("/budgets/list/:user_id", async (req, res) => {
  try {
    const { user_id } = req.params;
    
    const budgets = await pool.query(
      "SELECT id, name, monthly_budget, budget_type, is_active FROM budgets WHERE user_id = $1 ORDER BY created_at DESC",
      [user_id]
    );
    
    res.json(budgets.rows);
  } catch (err) {
    console.error("Error fetching budgets:", err);
    res.status(500).json({ error: err.message });
  }
});

// Set a budget as active
app.post("/budgets/:budget_id/activate", async (req, res) => {
  try {
    const { budget_id } = req.params;
    const { user_id } = req.body;
    
    // First deactivate all user's budgets
    await pool.query(
      "UPDATE budgets SET is_active = false WHERE user_id = $1",
      [user_id]
    );
    
    // Then activate the selected budget
    const activatedBudget = await pool.query(
      "UPDATE budgets SET is_active = true WHERE id = $1 AND user_id = $2 RETURNING *",
      [budget_id, user_id]
    );
    
    if (activatedBudget.rows.length === 0) {
      return res.status(404).json({ error: "Budget not found" });
    }
    
    res.json(activatedBudget.rows[0]);
  } catch (err) {
    console.error("Error activating budget:", err);
    res.status(500).json({ error: err.message });
  }
});

// Get Current Budget & Spending Progress (modified to use active budget)
app.get("/budgets/:user_id", async (req, res) => {
  try {
    const { user_id } = req.params;
    
    // Get the active budget for this user
    const budget = await pool.query(
      "SELECT * FROM budgets WHERE user_id = $1 AND is_active = true LIMIT 1", 
      [user_id]
    );
    
    if (budget.rows.length === 0) {
      return res.status(404).json({ error: "No active budget found" });
    }
    
    // Rest of your existing code for calculating spending...
    const budgetType = budget.rows[0].budget_type || 'monthly';
    
    // Determine date range based on budget type
    let fromDate;
    const currentDate = new Date();
    
    if (budgetType === 'daily') {
      // Start of today
      fromDate = new Date(currentDate);
      fromDate.setHours(0, 0, 0, 0);
    } else if (budgetType === 'weekly') {
      // Start of current week (Sunday)
      fromDate = new Date(currentDate);
      fromDate.setDate(currentDate.getDate() - currentDate.getDay());
      fromDate.setHours(0, 0, 0, 0);
    } else {
      // Start of current month
      fromDate = new Date(currentDate.getFullYear(), currentDate.getMonth(), 1);
    }
    
    // Get expenses for the specified period
    const totalSpent = await pool.query(
      "SELECT SUM(amount) AS spent FROM expenses WHERE user_id = $1 AND created_at >= $2",
      [user_id, fromDate]
    );
    
    const spent = parseFloat(totalSpent.rows[0].spent || 0);
    const percentage = ((spent / budget.rows[0].monthly_budget) * 100).toFixed(2);
    
    res.json({
      id: budget.rows[0].id,
      name: budget.rows[0].name,
      budget_amount: budget.rows[0].monthly_budget,
      budget_type: budgetType,
      spent,
      percentage,
      alert: generateSpendingAlert(percentage),
      remaining: budget.rows[0].monthly_budget - spent,
      period_start: fromDate,
      period_end: currentDate
    });
  } catch (err) {
    console.error("Error fetching budget info:", err);
    res.status(500).json({ error: err.message });
  }
});



// Enhanced spending alerts with more detailed messages
const generateSpendingAlert = (percentage) => {
  if (percentage >= 100) {
    return {
      level: "danger",
      message: "Budget exceeded! You've spent 100% of your budget."
    };
  }
  if (percentage >= 90) {
    return {
      level: "warning",
      message: "Warning! 90% of your budget is spent. Try to save where possible."
    };
  }
  if (percentage >= 75) {
    return {
      level: "caution",
      message: "You have reached 75% of your budget. Consider adjusting your spending."
    };
  }
  if (percentage >= 50) {
    return {
      level: "info",
      message: "Half of your budget is used (50%). Keep an eye on your expenses!"
    };
  }
  if (percentage >= 25) {
    return {
      level: "info",
      message: "You've spent 25% of your budget."
    };
  }
  return {
    level: "success",
    message: "You're doing great with your budget!"
  };
};

module.exports = router;

const PORT = process.env.PORT || 5000;
const HOST = '0.0.0.0';

app.listen(PORT, HOST, () => {
  console.log(`Server running on http://${HOST}:${PORT}`);
});

