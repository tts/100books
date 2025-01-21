// Install Node.js and run in command line with 'run korvaakirjat.js'
// Install additional packages with 'npm install <package>'

const fs = require('fs');
const csv = require('csv-parser');
const streamifier = require('streamifier');

// Step 1: Read the CSV file, replace "" with single quotes, and then parse it
const books = [];

fs.createReadStream('kirjat.csv', { encoding: 'utf-8' })
  .on('data', (chunk) => {
    // Replace double double-quotes (""), which are used for quoted words, with single quotes
    const cleanedChunk = chunk.replace(/""/g, "'");

    // Step 2: Pipe the cleaned data through csv-parser
    streamifier.createReadStream(cleanedChunk)
      .pipe(csv())  // Pipe through csv-parser to process each row
      .on('data', (row) => {
        // Process each row here
        const fullTitle = `${row.givenname} ${row.surname}: ${row.title}`;
        books.push({
          title: `${fullTitle}`,  // The title in the required format
          sentence: `${row.text}` // Assuming the "text" is in the 'text' column
        });
      })
      .on('end', () => {

        // Read the existing 'kpeli.js' file
        fs.readFile('temp.js', 'utf8', (err, data) => {
          if (err) {
            console.error('Error reading the file:', err);
            return;
          }

          // Step 3: Prepare the new allBooks array content
          const newBookEntries = books.map(book => 
            `  { title: "${book.title}", sentence: "${book.sentence}" }`
          ).join(',\n');

          // Step 4: Replace the entire (mockup) allBooks array with the new one
          const updatedData = data.replace(/const allBooks = \[.*?\];/s, `const allBooks = [\n${newBookEntries}\n];`);

          // Step 5: Write the updated content back to the kpeli.js file
          fs.writeFile('temp.js', updatedData, 'utf8', (err) => {
            if (err) {
              console.error('Error writing to file:', err);
            } else {
              console.log('Updated allBooks in kpeli.js successfully.');
            }
          });
        });
      });
  })
  .on('error', (err) => {
    console.error('Error reading the CSV file:', err);
  });
