const port = process.env.PORT || 3000;
const express = require("express");
var exec = require("child_process").exec;
const os = require("os");
var request = require("request");
const app = express();

app.get("/", (req, res) => {
  res.statusCode = 200;
  const msg = "No Parameters";
  res.end(msg);
});

//Start the core script
exec("bash entrypoint.sh", function (err, stdout, stderr) {
  if (err) {
    console.error(err);
    return;
  }
  console.log(stdout);
});

app.listen(port, () => console.log(`Example app listening on port ${port}!`));
