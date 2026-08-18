// vuln-server.js — the deliberately vulnerable "Wishful Thinking Inc." file server.
//
// THE VULNERABILITY: it appends the requested URL path onto FTP_ROOT and opens it
// with NO check for "..", so a request like `GET /../../../etc/passwd` walks straight
// out of the served folder and reads anything on the host filesystem.
//
// This is a ~20-line server we control, replacing the abandoned `hftp` npm package —
// so the `../` traversal behaves predictably and there is no external dependency that
// can vanish or misbehave.
//
// It is started AS ROOT by the container entrypoint (see docker/entrypoint.sh). That is
// deliberate and is what makes the lab meaningful: the student's own shell cannot read
// root-only files like /etc/shadow, but this root-run service can — and the traversal
// bug makes it read them on the student's behalf. That privilege crossing is the point.
const http = require('http');
const fs = require('fs');

const ROOT = process.env.FTP_ROOT || '/home/student/ftp_folder';

http.createServer((req, res) => {
  const target = ROOT + decodeURIComponent(req.url); // VULN: no sanitization of ".."
  fs.stat(target, (err, st) => {
    if (err) { res.writeHead(404); return res.end('404 Not Found\n'); }
    if (st.isDirectory()) {                            // a directory -> a listing (like `ls`)
      res.writeHead(200);
      return res.end(fs.readdirSync(target).join('\n') + '\n');
    }
    res.writeHead(200);                                // a file -> its contents
    res.end(fs.readFileSync(target));
  });
}).listen(8888, () => console.error('Wishful Thinking Inc. FTP service serving ' + ROOT + ' on :8888'));
