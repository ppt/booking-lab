/* TODO
- select date : check header active before check detail
- booking : diff before click with date before
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
        userAgent: 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36'
    }
});

var user = casper.cli.raw.get("user");
var password = casper.cli.raw.get('password');
var class_name = casper.cli.raw.get('classname');
var class_time = casper.cli.raw.get('classtime');
var testdate = 8;
var row_select = -1;

casper.start('https://mylocker.virginactive.co.th/#/login', function(){
    var s = this.getHTML('.welcome');
    if (s.indexOf('ขอต้อนรับสู่') == 0) {
        this.clickLabel('Switch Language');
        this.waitForText('welcome to my');
    }
});

casper.then(function(){
    this.echo('login');
    this.sendKeys('input#memberID', user);
    this.sendKeys('input#password', password);
    this.clickLabel('Login','button');
    this.waitForUrl('https://mylocker.virginactive.co.th/#/home');
});

casper.then(function(){
    this.echo('book class');
    this.clickLabel('book a class','a');
    this.waitForUrl('https://mylocker.virginactive.co.th/#/bookaclass');
});

casper.then(function(){
    this.waitForSelector('table.vaTable:not(.ng-hide)');
});

casper.then(function(){
    this.echo('select date');
    this.click('a.datePicker:nth-of-type('+testdate+')');
    this.waitForSelector('table.vaTable.ng-hide');
});

casper.then(function(){
    this.waitForSelector('a.datePicker:nth-of-type('+testdate+').active');
});

casper.then(function(){
    this.waitForSelector('table.vaTable:not(.ng-hide)');
});

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
    // casper.echo('find class function');
    // casper.echo(class_time + ' ' + class_name);
    for(var i=0; i<classes.length; i++) {
        // casper.echo(classes[i].time + ' ' + classes[i].name);
        if (classes[i].time === class_time.toLowerCase() && classes[i].name.indexOf(class_name.toLowerCase()) >= 0) {
            return i;
        }
    }
    return -1;
}

casper.then(function(){
    // dumpFile('screen1.html',this.getHTML('table'));
    this.echo('find class');
    // dumpFile('findClass.html',this.getHTML());
    row_select = findClass(getClass(this.getHTML('table')),class_name, class_time);
    if(row_select == -1) {
        dumpFile('findClass.html',this.getHTML());
    }
    this.echo(row_select);
    this.click('table.table tbody tr:nth-of-type(' + (2 + row_select*2) + ')');
    this.waitForSelector('table.table tbody tr:nth-of-type(' + (2 + row_select*2) + ').active');
});

casper.then(function() {
    this.echo('select class');
    // dumpFile('clickSelect.html',this.getHTML());
    this.click('table tr.classDetailRow.active a.memberBooking');
    this.waitForSelector('#modalBooking.modal.fade.ng-scope.in .modal-footer button[ng-click="vm.makeBooking()"]:not(.ng-hide)');
    // this.waitForSelector('#modalBooking button.vaRoundButton-Red[ng-click="vm.makeBooking()"]');
});

casper.then(function() {
    this.echo('booking class');
    dumpFile('clickBooking.html',this.getHTML());
    this.click('#modalBooking.modal.fade.ng-scope.in .modal-footer button[ng-click="vm.makeBooking()"]');
    this.waitForText('Great - we\'ve made that booking.');
});

casper.then(function() {
    this.echo('click ok');
    dumpFile('clickOK.html',this.getHTML());
    this.click('button[data-dismiss="modal"]');

});
casper.run();
