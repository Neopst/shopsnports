const fs = require('fs');
const p = process.argv[2] || 'server/public/admin/build/main.dart.v20251021.js';
const s = fs.readFileSync(p,'utf8');
let brace = 0; let paren=0; let bracket=0;
for(let i=0;i<s.length;i++){
  const ch = s[i];
  if(ch==='{') brace++;
  else if(ch==='}') brace--;
  if(ch==='(') paren++;
  else if(ch===')') paren--;
  if(ch==='[') bracket++;
  else if(ch===']') bracket--;
  if(brace<0){
    // compute line/col
    const up = s.slice(0,i);
    const lines = up.split(/\r?\n/);
    const line = lines.length;
    const col = lines[lines.length-1].length + 1;
    console.log('NEGATIVE at index', i, 'line', line, 'col', col);
    const start = Math.max(0, i-100);
    const end = Math.min(s.length, i+100);
    console.log('--- snippet ---');
    console.log(s.slice(start,end));
    process.exit(0);
  }
}
console.log('No negative brace found; final balances:', {brace, paren, bracket});
