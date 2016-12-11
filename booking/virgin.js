/* TODO
- select date : check header active before check detail
- booking : diff before click with date before
- log moment
- check function
- using repeat to loop, each loop 0.5 sec
- calculate start time, parameter starttime

- calculate repeat count
- test-flag to use 8 instead of 9
*/

// var development = true;
var development = false;
function dumpFile(filename,value) {
    if (development) {
        var fs = require('fs');
        fs.write(filename, value, 'w');
    }
}

var casper = require("casper").create({
    verbose: true,
    // logLevel: 'debug',
    logLevel: 'error',
    waitTimeout: 120000,
    pageSettings: {
        loadImages:  false,        // To enable screen capture
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
var class_name = casper.cli.raw.get('classname');
var class_time = casper.cli.raw.get('classtime');
var testdate = 8;
var row_select = -1;
var loop_check_time = 30000;



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
    // dumpFile('findClass.html',this.getHTML());
        row_select = findClass(getClass(this.getHTML('table')),class_name, class_time);
        if(row_select == -1) {
            dumpFile('findClass.html',this.getHTML());
        }
        logMsg(row_select);
        this.click('table.table tbody tr:nth-of-type(' + (2 + row_select*2) + ')');
        this.waitForSelector('table.table tbody tr:nth-of-type(' + (2 + row_select*2) + ').active');
    });

    casper.then(function() {
        logMsg('select class');
    // dumpFile('clickSelect.html',this.getHTML());
        this.click('table tr.classDetailRow.active a.memberBooking');
        this.waitForSelector('#modalBooking.modal.fade.ng-scope.in .modal-footer button[ng-click="vm.makeBooking()"]:not(.ng-hide)');
    // this.waitForSelector('#modalBooking button.vaRoundButton-Red[ng-click="vm.makeBooking()"]');
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

logMsg('Start');

casper.start('https://mylocker.virginactive.co.th/#/login', function(){
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
    var i = 0;
    var openFlag = false;
    function thenFunc() {
    }
    function timeoutFunc() {
        casper.exit();
    }
    function checkFunc() {
        if (i == 9) {
            openFlag = true;
        }
        return true;
    }
    casper.repeat(10, function() {
        i++;
        this.waitFor(checkFunc, thenFunc, timeoutFunc, loop_check_time, null);
        if (openFlag) {
            booking();
        } else {
            selectDate();
        }
        logMsg(i);
    });
});

casper.run();
