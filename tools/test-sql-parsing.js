/**
 * Test SQL parsing logic
 */

const fs = require('fs');
const path = require('path');

function parseSQLContent(content) {
  console.log('📝 Parsing SQL content...');
  console.log('📋 Content length:', content.length);
  console.log('📋 Content preview:', content.substring(0, 200));
  
  // Check if content is valid
  if (!content || content.trim().length === 0) {
    console.warn('⚠️ Empty or invalid content');
    return [];
  }
  
  // Check if content looks like SQL by looking for common SQL keywords
  const contentLower = content.toLowerCase();
  const hasSqlKeywords = contentLower.includes('insert') || 
                        contentLower.includes('update') || 
                        contentLower.includes('create') || 
                        contentLower.includes('select') ||
                        contentLower.includes('delete');
  
  console.log('📋 SQL keywords check:', {
    insert: contentLower.includes('insert'),
    update: contentLower.includes('update'),
    create: contentLower.includes('create'),
    select: contentLower.includes('select'),
    delete: contentLower.includes('delete'),
    hasSqlKeywords
  });
  
  if (!hasSqlKeywords) {
    console.error('❌ Content does not contain SQL keywords');
    console.log('📋 Content sample:', content.substring(0, 500));
    return [];
  }
  
  // Split SQL content into individual statements
  // Use a more sophisticated approach to handle multi-line statements
  const lines = content.split('\n');
  const statements = [];
  let currentStatement = '';
  let inMultiLineComment = false;
  
  console.log('📋 Processing', lines.length, 'lines...');
  
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    
    // Skip empty lines
    if (!line) continue;
    
    // Handle multi-line comments
    if (line.startsWith('/*')) {
      inMultiLineComment = true;
      if (line.includes('*/')) {
        inMultiLineComment = false;
      }
      continue;
    }
    if (inMultiLineComment) {
      if (line.includes('*/')) {
        inMultiLineComment = false;
      }
      continue;
    }
    
    // Skip single-line comments
    if (line.startsWith('--')) {
      continue;
    }
    
    // Add line to current statement
    currentStatement += line + ' ';
    
    // Check if statement ends with semicolon
    if (line.endsWith(';')) {
      const statement = currentStatement.trim();
      if (statement && statement !== ';') {
        // Only include actual SQL statements (INSERT, UPDATE, CREATE, etc.)
        const statementLower = statement.toLowerCase();
        const isValidStatement = statementLower.startsWith('insert') || 
            statementLower.startsWith('update') || 
            statementLower.startsWith('create') || 
            statementLower.startsWith('alter') ||
            statementLower.startsWith('delete') ||
            statementLower.startsWith('drop');
            
        console.log('📋 Found statement (line', i + 1, '), valid:', isValidStatement, ', preview:', statement.substring(0, 50));
        
        if (isValidStatement) {
          statements.push(statement);
        }
      }
      currentStatement = '';
    }
  }

  console.log('📋 Parsed', statements.length, 'SQL statements');
  
  // Log first few statements preview
  if (statements.length > 0) {
    console.log('📋 First statement preview:', statements[0].substring(0, 200));
    if (statements.length > 1) {
      console.log('📋 Second statement preview:', statements[1].substring(0, 100));
    }
  }
  
  return statements;
}

// Test with actual file
const testFile = path.join(process.cwd(), 'test-decompressed-content.sql');
if (fs.existsSync(testFile)) {
  console.log('🧪 Testing SQL parsing with file:', testFile);
  const content = fs.readFileSync(testFile, 'utf8');
  const statements = parseSQLContent(content);
  console.log('🏁 Test completed, found', statements.length, 'statements');
} else {
  console.error('❌ Test file not found:', testFile);
}
