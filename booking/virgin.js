/* TODO
*/

/*
casperjs virgin.js --user=20040756 --password=2466 --class-name="body combat" --class-time="7:30am" --start-time='8:37:00' --test-flag
  - test-flag use 8th day not 9th day and if not specified start-time start imediatly
  - start-time use set start-time
*/

// var development = true;
// function dumpFile(filename,value) {
//     if (development) {
//         var fs = require('fs');
//         fs.write(filename, value, 'w');
//     }
// }

var casper = require("casper").create({
    verbose: true,
    // logLevel: 'debug',
    logLevel: 'error',
    waitTimeout: 360000,
    pageSettings: {
        // loadImages:  false,        // To enable screen capture
        userAgent: 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36'
    }
});

var moment = require('moment');

function logMsg(msg) {
    var time = moment().format('HH:mm:ss')+' : ';
    casper.echo(time+msg);
}

var user = casper.cli.raw.get("user");
var password = casper.cli.raw.get('password');
var class_name = casper.cli.raw.get('class-name');
var class_time = casper.cli.raw.get('class-time');
var row_select = -1;
var loop_check_time = 30000;
var pollloop = 2100; // repeat poll for 17 minutes, each poll takes 0.5 sec
var testdate = 9;
var start_time = casper.cli.raw.get('start-time');
if (start_time == undefined) {
    start_time = '22:08:00';
}
var test_flag = casper.cli.raw.get('test-flag');
if (test_flag == undefined) {
    test_flag = false;
} else {
    testdate = 8;
}

function selectDate() {
    casper.then(function(){
        this.click('a.datePicker:nth-of-type('+testdate+')');
    // check first table must hide to load data
        this.waitForSelector('table.vaTable.ng-hide');
    });

  // then header active
    casper.then(function(){
        this.waitForSelector('a.datePicker:nth-of-type('+testdate+').active');
    });

  // table unhide, data may not be complete load
    casper.then(function(){
        this.waitForSelector('table.vaTable:not(.ng-hide)');
    });
}

function booking() {
    function getClass(s) {
        var data = s.split(/<\/tr>/i);
        var size = (data.length - 3)/2;
        var start = 2;
        var result = [];
        var td = /<td[^>]*>\s*([^<]+)/ig;
        var txt = /[^>]+$/;
        for (var i=start; i<(size*2+start); i=i+2) {
            var row = data[i].match(td);
            result.push({
                'time': row[0].match(txt)[0].trim().toLowerCase(),
                'name': row[1].match(txt)[0].trim().toLowerCase()
            });
        }
        return result;
    }

    function findClass(classes,class_name,class_time) {
        for(var i=0; i<classes.length; i++) {
            if (classes[i].time === class_time.toLowerCase() && classes[i].name.indexOf(class_name.toLowerCase()) >= 0) {
                return i;
            }
        }
        return -1;
    }

    casper.then(function(){
        logMsg('find class');
        row_select = findClass(getClass(this.getHTML('table')),class_name, class_time);
        logMsg('row selected : '+row_select);
        this.click('table.table tbody tr:nth-of-type(' + (2 + row_select*2) + ')');
        this.waitForSelector('table.table tbody tr:nth-of-type(' + (2 + row_select*2) + ').active');
    });

    casper.then(function() {
        logMsg('select class');
        this.click('table tr.classDetailRow.active a.memberBooking');
        this.waitForSelector('#modalBooking.modal.fade.ng-scope.in .modal-footer button[ng-click="vm.makeBooking()"]:not(.ng-hide)');
    });

    casper.then(function() {
        logMsg('booking class');
        this.click('#modalBooking.modal.fade.ng-scope.in .modal-footer button[ng-click="vm.makeBooking()"]');
        this.waitForText('Great - we\'ve made that booking.');
    });

    casper.then(function() {
        logMsg('click ok');
        this.click('button[data-dismiss="modal"]');
        casper.exit();
    });
}


casper.start('https://mylocker.virginactive.co.th/', function(){
    casper.echo(user+' '+class_time+' '+class_name);
    logMsg('Start');
    var now = moment();
    var end_time_str = now.format('YYYY-MM-DD')+' '+ start_time;
    var end_time = moment(end_time_str,'YYYY-MM-DD HH:mm:ss');
    var sleep_time = parseInt(end_time.diff(now,'milliseconds'));
    if (!test_flag || (test_flag && casper.cli.has('start-time'))) {
        if (sleep_time > 0)
            casper.wait(sleep_time);
    }
});

casper.thenOpen('https://mylocker.virginactive.co.th/#/login', function(){
    var s = this.getHTML('.welcome');
    if (s.indexOf('ขอต้อนรับสู่') == 0) {
        this.clickLabel('Switch Language');
        this.waitForText('welcome to my');
    }
});

casper.then(function(){
    logMsg('login');
    this.sendKeys('input#memberID', user);
    this.sendKeys('input#password', password);
    this.clickLabel('Login','button');
    this.waitForUrl('https://mylocker.virginactive.co.th/#/home');
});

casper.then(function(){
    logMsg('book class');
    this.clickLabel('book a class','a');
    this.waitForUrl('https://mylocker.virginactive.co.th/#/bookaclass');
});

casper.then(function(){
    this.waitForSelector('table.vaTable:not(.ng-hide)');
});

casper.then(function() {
    selectDate();
});

// wait for opening
casper.then(function(){
    var openFlag = false;
    function thenFunc() {
    }
    function timeoutFunc() {
        logMsg('Check Timeout');
        casper.exit();
    }
    function checkFunc() {
        var s = casper.getHTML();
        logMsg('check');
        if (s.match(/classDetailRow/i)) {
            openFlag = true;
            logMsg('Open');
        }
        return true;
    }
    casper.repeat(pollloop, function() {
        this.waitFor(checkFunc, thenFunc, timeoutFunc, loop_check_time, null);
        if (openFlag) {
            booking();
        } else {
            selectDate();
        }
    });
});

casper.run();
