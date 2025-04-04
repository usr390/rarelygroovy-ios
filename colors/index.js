// index.js
const getColors = require('get-image-colors');

const imagePath = process.argv[2] || './image.png';

getColors(imagePath)
  .then(colors => {
    const hexColors = colors.map(color => color.hex());
    console.log(JSON.stringify(hexColors, null, 2));
  })
  .catch(err => {
    console.error("Error extracting colors:", err);
    process.exit(1);
  });