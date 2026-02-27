const express = require("express");
const router = express.Router();
const pool = require("../db"); // Import database connection
//const { authenticateUser } = require("../middleware/auth"); // JWT middleware

router.post("/save-mission", async (req, res) => {
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
// Add to your server file or missionRoutes.js
router.get("/past-missions", async (req, res) => {
    try {
      const user_id = req.query.user_id;
      
      if (!user_id) {
        return res.status(400).json({ error: "Missing user_id parameter" });
      }
      
      const result = await pool.query(
        "SELECT * FROM past_missions WHERE user_id = $1 ORDER BY date DESC",
        [user_id]
      );
      
  
      console.log(`Found ${result.rows.length} missions for user ${user_id}`);
      res.json(result.rows);
    } catch (error) {
      console.error("Error fetching missions:", error);
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
});

module.exports = router;
