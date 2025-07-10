#!/usr/local/bin/node
const os = require("os");
const HOME = os.homedir();
const MODS = "/node_modules"
const modpath = "Node modules PATH:"+HOME+MODS
console.log(modpath)
