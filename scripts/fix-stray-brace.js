const fs = require('fs');
const files = [
  'server/public/admin/build/main.dart.v20251021.js',
  'server/public/admin/build/main.dart.js'
];
files.forEach(p => {
  try{
    const s = fs.readFileSync(p,'utf8');
    // find first negative brace index
    let brace = 0;
    let negIndex = -1;
    for(let i=0;i<s.length;i++){
      const ch = s[i];
      if(ch==='{') brace++;
      else if(ch==='}') brace--;
      if(brace<0){ negIndex = i; break; }
    }
    if(negIndex===-1){ console.log(p + ': no negative brace found'); return; }
    console.log(p + ': negative brace at index', negIndex);
    const bak = p + '.bak.fix.' + Date.now();
    fs.copyFileSync(p, bak);
    // remove the character at negIndex
    const fixed = s.slice(0,negIndex) + s.slice(negIndex+1);
    fs.writeFileSync(p, fixed, 'utf8');
    console.log(p + ': wrote fixed file (backup at ' + bak + ')');
    // quick parse
    try{ new Function(fixed); console.log(p + ': PARSE_OK after fix'); }
    catch(e){ console.error(p + ': PARSE_ERROR after fix', e && e.message); }
  }catch(e){ console.error('error processing', p, e && e.message); }
});
