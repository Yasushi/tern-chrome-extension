# Tern plugin for chrome extensions API.

[![npm version](https://badge.fury.io/js/tern-chrome-extension.svg)](http://badge.fury.io/js/tern-chrome-extension) [![Build Status](https://travis-ci.org/Yasushi/tern-chrome-extension.svg?branch=master)](https://travis-ci.org/Yasushi/tern-chrome-extension)

This plugin is [Chrome extensions API][] JSON type definition.

[Chrome extensions API]: https://developer.chrome.com/extensions/api_index

## Install

    $ npm install -g tern-chrome-extension

## Configuration

Here is a minimal example `.tern-project` configuration file:

```json
{
  "libs":["ecma5"],
  "plugins": {
    "chrome-extension": {}
  }
}

