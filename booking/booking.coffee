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

# get param
user = casper.cli.raw.get("user")
password = casper.cli.raw.get('password')
class_time = casper.cli.raw.get("class-time")
class_name = casper.cli.raw.get("class-name")
scan_time = "21:59:00"
casper.echo "#{scan_time} #{delaytime} #{user}:#{password} #{class_time} #{class_name}", "INFO"

casper.Waiter = ->
  if not @.exists 'tr.virginRowStyle, tr.virginAltRowStyle'
    @.wait delaytime, ->
      @.echo "#{moment().format('HH:mm:ss')} #{loopcnt++}: Wait 1s", "INFO"
      if test_flag?
        # Date start from 0 to 8, 8 is the last one
        @.click '#phContentTop_lbDate_7'
        @.waitForSelector '#phContentTop_lbDate_7.dateActive'
      else
        @.click '#phContentTop_lbDate_8'
        @.waitForSelector '#phContentTop_lbDate_8.dateActive'
  else
    @.echo "#{moment().format('HH:mm:ss')} Open", "INFO"
    selector = 'tr.virginRowStyle, tr.virginAltRowStyle'
    rows = this.getElementsInfo(selector)
    @.echo "#{moment().format('HH:mm:ss')} After getElement #{rows.length}", 'INFO'
    for row,i in rows
      # @.echo "#{i} ---------------", 'ERROR'
      # @.echo util.dump rows[i].html
      td = row.html.match /<td[^>]*>\s*([^<]*)/g
      t = []
      for r,index in td
        s = r.match(/<td[^>]*>\s*([^<]*)/)
        t.push s[1]
      # @.echo util.dump t
      # 0:time,3:class,5:instructor
      idtext = row.html.match /classdetail\.aspx\?id\=([^\"]*)/
      # @.echo "#{t[0]}, #{t[3]}, #{t[5]}, #{idtext[1]}"
      if t[0].toLowerCase() == class_time.toLowerCase() and t[3].toLowerCase().indexOf(class_name.toLowerCase()) >= 0
        id = idtext[1]
        break
    @.echo "#{moment().format('HH:mm:ss')} Click Booking", 'INFO'
    @.click "a[href='classdetail.aspx?id=#{id}']"
    @.waitForSelector 'a#btnNextStep.virginButtonGreen', ->
        @.echo "#{moment().format('HH:mm:ss')} Click Next Step", 'INFO'
        @.click "a#btnNextStep"
        @.waitForSelector 'a#phContentBottom_btnBookAnother', ->
          @.echo "#{moment().format('HH:mm:ss')} Finish", 'INFO'
          @.exit()

  true

# sleep
now = moment()
end_time_str = "#{now.format('YYYY-MM-DD')} #{scan_time}"
end_time = moment(end_time_str,'YYYY-MM-DD HH:mm:ss')
sleep_time = parseInt end_time.diff(now,'milliseconds')
# casper.echo "sleep #{end_time.format('HH:mm:ss')} - #{now.format('HH:mm:ss')} = #{sleep_time/1000}s", "INFO"

casper.start "http://mylocker.virginactive.co.th/"
casper.then ->
  @.echo "#{moment().format('HH:mm:ss')} Sleep #{sleep_time}",'INFO'
  @.wait sleep_time if not test_flag? and sleep_time > 0
casper.then ->
  @.echo "#{moment().format('HH:mm:ss')} Start", "INFO"

# begin
casper.thenOpen "http://mylocker.virginactive.co.th/www/login.aspx"
casper.then ->
  @.echo "#{moment().format('HH:mm:ss')} Login #{user}:#{password}",'INFO'
  @.sendKeys('input#phContentBottom_txtMemberID', "#{user}")
  @.sendKeys('input#phContentBottom_txtPassword', password)
  @.click '#phContentBottom_btnLogin'
  @.echo "#{moment().format('HH:mm:ss')} Click Login", 'INFO'
  @.waitForSelector '#phNavBar_MainNavigation1_hlClass'

casper.then ->
  @.click '#phNavBar_MainNavigation1_hlClass'
  @.echo "#{moment().format('HH:mm:ss')} Click Book Class", 'INFO'
  @.waitForSelector '#bookingSheet'

casper.then ->
  if test_flag?
    @.click '#phContentTop_lbDate_7'
    @.waitForSelector '#phContentTop_lbDate_7.dateActive'
  else
    @.click '#phContentTop_lbDate_8'
    @.waitForSelector '#phContentTop_lbDate_8.dateActive'
  @.echo "#{moment().format('HH:mm:ss')} Click Last Date", 'INFO'

# loop until booking
casper.then ->
  for i in [0..maxloop]
    @.waitFor ->
      @.Waiter()

  @.echo 'Olayy!', 'INFO'

casper.run()
