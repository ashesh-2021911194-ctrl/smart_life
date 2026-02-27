const express = require('express');
const router = express.Router();
const axios = require('axios');
const { Pool } = require('pg');



// OpenWeatherMap API key
const WEATHER_API_KEY = process.env.WEATHER_API_KEY;


const testUserId = 'f08ffb63-ebec-4cae-a1c3-027a62fe2f7a';
// Get weather advice based on condition
function getWeatherAdvice(condition, temp) {
  switch (condition.toLowerCase()) {
    case 'clear':
      if (temp > 30) return "It's hot and sunny! Don't forget sunscreen.";
      return "Enjoy the clear skies today!";
    
    case 'clouds':
      return "Partly cloudy today. A light jacket might be useful.";
    
    case 'rain':
      return "It's going to rain. Take an umbrella while going outside!";
    
    case 'thunderstorm':
      return "Thunderstorms expected. Better stay indoors if possible.";
    
    case 'snow':
      return "It's snowing! Wear warm clothes and drive carefully.";
    
    case 'mist':
    case 'fog':
      return "Visibility is low today. Be careful when driving.";
    
    case 'drizzle':
      return "Light rain expected. A light raincoat might be useful.";
    
    default:
      return "Check the weather before going out!";
  }
}

// Map OpenWeatherMap icon codes to our simplified codes
function mapWeatherIcon(iconCode) {
  // OpenWeatherMap uses codes like 01d, 02d, 10n, etc.
  const prefix = iconCode.substring(0, 2);
  
  switch (prefix) {
    case '01': return 'clear';    // clear sky
    case '02': 
    case '03': 
    case '04': return 'clouds';   // clouds
    case '09': 
    case '10': return 'rain';     // rain
    case '11': return 'thunderstorm'; // thunderstorm
    case '13': return 'snow';     // snow
    case '50': return 'mist';     // mist
    default: return 'clouds';     // default
  }
}

// Weather endpoint
router.get('/', async (req, res) => {
  try {
    const { lat, lon } = req.query;
    
    if (!lat || !lon) {
      return res.status(400).json({ error: 'Latitude and longitude are required' });
    }

    // Call OpenWeatherMap API
    const response = await axios.get(
      `https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lon}&units=metric&appid=${WEATHER_API_KEY}`
    );

    const weatherData = response.data;
    
    // Extract relevant data
    const temperature = weatherData.main.temp;
    const condition = weatherData.weather[0].main;
    const iconCode = weatherData.weather[0].icon;
    
    // Map icon code and get advice
    const mappedIcon = mapWeatherIcon(iconCode);
    const advice = getWeatherAdvice(condition, temperature);
    
    // Save weather data in database for analysis (optional)
    await pool.query(
      'INSERT INTO weather_logs (user_id, latitude, longitude, temperature, condition) VALUES ($1, $2, $3, $4, $5)',
      [testUserId, lat, lon, temperature, condition]
    );

    // Return formatted response
    res.json({
      temperature: temperature,
      condition: condition,
      icon: mappedIcon,
      advice: advice
    });
  } catch (error) {
    console.error('Weather API error:', error);
    res.status(500).json({ error: 'Failed to fetch weather data' });
  }
});

module.exports = router;