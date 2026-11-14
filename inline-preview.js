const fs = require('fs');
const html = fs.readFileSync('preview.html','utf8');
const js = fs.readFileSync('preview-content.js','utf8');

// Replace the script tag with inline content
const newHtml = html.replace(
  '<script src="preview-content.js"></script>',
  '<script>' + js + '</script>'
);
fs.writeFileSync('preview.html', newHtml);
console.log('Inlined preview-content.js');