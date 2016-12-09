console.log 'hello'
casper = require("casper").create
  verbose: true
  logLevel: 'error'
  waitTimeout: 120000
  pageSettings:
    userAgent: 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36'

util = require "utils"
moment = require 'moment'

if casper.cli.has('test-flag')
  test_flag = true
maxloop = 1200
loopcnt = 0
delaytime = 1000

casper.run()
