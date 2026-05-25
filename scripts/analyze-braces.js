const fs = require('fs');
const path = process.argv[2] || './server/public/admin/build/main.dart.v20251021.js';
const line = parseInt(process.argv[3] || '88229', 10);
const col = parseInt(process.argv[4] || '74', 10);
try{
  const s = fs.readFileSync(path, 'utf8');
  const lines = s.split(/\r?\n/);
  if(line < 1 || line > lines.length){
    console.error('line out of range', lines.length);
    process.exit(2);
  }
  const contextStart = Math.max(1, line-5);
  const contextEnd = Math.min(lines.length, line+5);
  console.log('File:', path);
  console.log('Total lines:', lines.length);
  console.log('Inspecting line', line, 'col', col);
  console.log('--- Context ---');
  for(let i=contextStart;i<=contextEnd;i++){
    const marker = (i===line)? '>>':'  ';
    console.log(marker, i.toString().padStart(6), '|', lines[i-1].slice(0,200));
  }
  // compute balances up to the error index
  let idx = 0;
  for(let i=0;i<line-1;i++) idx += lines[i].length + 1; // +1 for newline
  idx += Math.max(0, col-1);
  const upTo = s.slice(0, Math.min(idx+1, s.length));
  const counts = { '{':0, '}':0, '(':0, ')':0, '[':0, ']':0 };
  for(const ch of upTo){ if(counts.hasOwnProperty(ch)) counts[ch]++; }
  console.log('--- Counts up to error position ---');
  console.log(counts);
  console.log('brace balance (open - close):', counts['{'] - counts['}']);
  console.log('paren balance (open - close):', counts['('] - counts[')']);
  console.log('bracket balance (open - close):', counts['['] - counts[']']);
  // show a bit more after the position
  const after = s.slice(Math.max(0, idx-200), Math.min(s.length, idx+200));
  console.log('--- Surrounding snippet (200 chars before and after) ---');
  console.log(after);
}catch(e){ console.error(e && e.message); process.exit(3); }
