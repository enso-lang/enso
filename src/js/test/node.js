'use strict'

console.log("HERE fOO!!")

var ARGV = process.argv

var cwd = process.cwd()
console.log("CURRENT1", cwd)

var E = require(cwd + "/enso.js")
var cwd = process.cwd()
console.log("CURRENT2", cwd)
var L = require(cwd + "/core/grammar/render/layout.js")
var cwd = process.cwd()
console.log("CURRENT3", cwd)
var O = require(cwd + "/core/system/load/load.js")
var cwd = process.cwd()
console.log("CURRENT4", cwd)

var Stencil = require(cwd + "/core/diagram/code/stencil.js");

