"use strict";

var fs = require("fs"), path = require("path"), tern = require("tern"), assert = require('assert');
require("../chrome-extension.js");
require("tern/plugin/node")

var projectDir = path.resolve(__dirname, "..");
var resolve = function(pth) {
  return path.resolve(projectDir, pth);
};
var ecma5 = JSON.parse(fs
                       .readFileSync(resolve("node_modules/tern/defs/ecma5.json")), "utf8");

var allDefs = {
  ecma5 : ecma5
};

var defaultQueryOptions = {
  types: true,
  docs: false,
  urls: false,
  origins: true
}

function createServer(defs, options) {
  var plugins = {'node': {}};
  if (options)
    plugins['chrome-extension'] = options;
  else
    plugins['chrome-extension'] = {};
  var server = new tern.Server({
    plugins : plugins,
    defs : defs
  });
  return server;
}

exports.assertCompletion = function(text, expected, name) {
  var defs = [];
  var defNames = ["ecma5"];
  if (defNames) {
    for (var i = 0; i < defNames.length; i++) {
      var def = allDefs[defNames[i]];
      defs.push(def);
    }
  }
  var queryOptions = defaultQueryOptions;

  var server = createServer(defs, {});
  server.addFile("background.js", text);
  server.request({
    query : {
      type: "completions",
      file: "background.js",
      end: text.length,
      types: queryOptions.types,
      docs: queryOptions.docs,
      urls: queryOptions.urls,
      origins: queryOptions.origins,
      caseInsensitive: true,
      lineCharPositions: true,
      expandWordForward: false,
      guess: false
    }
  }, function(err, resp) {
    if (err)
      throw err;
    var actualMessages = resp.messages;
    var expectedMessages = expected.messages;

    if(name) {
      var actualItem = {};
      var completions = resp["completions"];
      if (completions) {
        completions.forEach(function(item) {
          if (item['name'] === name) actualItem = item;
        });
      }
      assert.equal(JSON.stringify(actualItem), JSON.stringify(expected));
    } else {
      assert.equal(JSON.stringify(resp), JSON.stringify(expected));
    }
  });
}
