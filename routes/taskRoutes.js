const express = require("express");
const router = express.Router();
const pool = require("../db"); // Import PostgreSQL pool

// In your GET endpoint for fetching tasks
router.get("/:user_id", async (req, res) => {
    const { user_id } = req.params;
    try {
      const result = await pool.query(
        "SELECT id, user_id, title, description, due_date, reminder_option, reminder_time, COALESCE(is_completed, false) as is_completed, created_at FROM tasks WHERE user_id = $1::uuid ORDER BY created_at DESC",
        [user_id]
      );
      res.json(result.rows);
    } catch (error) {
      console.error("Error fetching tasks:", error);
      res.status(500).json({ error: "Internal Server Error" });
    }
  });
  
  // ✅ Insert (Create) a new task
  router.post("/", async (req, res) => {
    const { user_id, title, description, due_date, reminder_option, reminder_time } = req.body;
    try {
      const result = await pool.query(
        "INSERT INTO tasks (user_id, title, description, due_date, reminder_option, reminder_time) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *",
        [user_id, title, description, due_date, reminder_option, reminder_time]
      );
      res.status(201).json(result.rows[0]); // Return newly created task
    } catch (error) {
      console.error("Error inserting task:", error);
      res.status(500).json({ error: "Internal Server Error" });
    }
  });
  
  // ✅ Update a task (Title, Description, Due Date, Reminder Options, Completion Status)
  router.put("/:task_id", async (req, res) => {
    const { task_id } = req.params;
    const { title, description, due_date, reminder_option, reminder_time, is_completed } = req.body;
    try {
      const result = await pool.query(
        "UPDATE tasks SET title = $1, description = $2, due_date = $3, reminder_option = $4, reminder_time = $5, is_completed = $6 WHERE id = $7 RETURNING *",
        [title, description, due_date, reminder_option, reminder_time, is_completed, task_id]
      );
      res.json(result.rows[0]); // Return updated task
    } catch (error) {
      console.error("Error updating task:", error);
      res.status(500).json({ error: "Internal Server Error" });
    }
  });
  
  // ✅ Delete a task (No changes needed for this endpoint)
  router.delete("/:task_id", async (req, res) => {
    const { task_id } = req.params;
    try {
      await pool.query("DELETE FROM tasks WHERE id = $1", [task_id]);
      res.json({ message: "Task deleted successfully" });
    } catch (error) {
      console.error("Error deleting task:", error);
      res.status(500).json({ error: "Internal Server Error" });
    }
  });

module.exports = router;
