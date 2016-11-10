#!/usr/bin/env node

require('coffee-script/register')
var IntervalToMinutemen = require('./interval-to-minutemen.coffee')
new IntervalToMinutemen(process.argv).run()
