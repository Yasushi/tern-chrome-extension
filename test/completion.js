var util = require('./util');

exports['test chrome.download completion'] = function() {
  util.assertCompletion("chrome.dow", {
    "start":{"line": 0, "ch":7},
    "end":{"line": 0, "ch":10},
    "isProperty":true,
    "isObjectKey":false,
    "completions": [{"name":"downloads","type":"chrome.downloads","origin":"chrome-extension"}]
  });
}
