var tern=require('tern');

tern.registerPlugin("chrome-extension", function(server, options) {
  return {
    defs: require("./chrome-extension.json")
  }
});
