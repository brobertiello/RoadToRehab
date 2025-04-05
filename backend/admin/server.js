const express = require('express');
const path = require('path');
const app = express();

// Serve static files from the current directory
app.use(express.static(__dirname));

// Serve the admin page
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'index.html'));
});

// Start the server
const PORT = 3330;
app.listen(PORT, () => {
    console.log(`Admin panel running at http://localhost:${PORT}`);
}); 