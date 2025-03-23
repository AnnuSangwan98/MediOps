const express = require('express');
const app = express();
const port = 3000;

// JSON बॉडी पार्सर मिडलवेयर
app.use(express.json());

// बेसिक रूट हैंडलर
app.get('/', (req, res) => {
  res.send('सर्वर चल रहा है!');
});

// सर्वर शुरू करें
app.listen(port, () => {
  console.log(`सर्वर पोर्ट ${port} पर चल रहा है`);
}); 