/* TODO
- select date : check header active before check detail
- booking : diff before click with date before
*/

function dumpFile(filename,value) {
    var fs = require('fs');
    fs.write(filename, value, 'w');
}

var casper = require("casper").create({
    verbose: true,
    logLevel: 'error',
    pageSettings: {
        userAgent: 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36'
    }
});

var user = casper.cli.raw.get("user");
var password = casper.cli.raw.get('password');
var class_name = casper.cli.raw.get('classname');
var class_time = casper.cli.raw.get('classtime');
var testdate = 8;

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
    this.echo('select date');
    dumpFile('selectDate.html',this.getHTML());
    this.click('.datePicker:nth-of-type('+testdate+')');
    this.waitForSelector('.classDetail');
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
        casper.echo(classes[i].time + ' ' + classes[i].name);
        if (classes[i].time === class_time.toLowerCase() && classes[i].name.indexOf(class_name.toLowerCase()) >= 0) {
            return i;
        }
    }
    return -1;
}

casper.then(function(){
    // dumpFile('screen1.html',this.getHTML('table'));
    this.echo('find class');
    var index = findClass(getClass(this.getHTML('table')),class_name, class_time);
    this.echo(index);
    this.click('table tr:nth-of-type(' + (2+index*2) + ')');
    this.waitForSelector('table tr.classDetailRow.active');
});

casper.then(function() {
    this.click('table tr.classDetailRow.active a[ng-click="vm.moreDetails(class)"]');
    this.waitForSelector('#modalBooking button[ng-click="vm.makeBooking()"]');
});

casper.then(function() {
    this.echo('click booking');
    dumpFile('clickBooking',this.getHTML());
    this.click('#modalBooking button[ng-click="vm.makeBooking()"]');
    this.waitForText('Great - we\'ve made that booking.');
});

casper.then(function() {
    this.echo('click ok');
    dumpFile('clickOK',this.getHTML());
    this.click('button[data-dismiss="modal"]');

});
casper.run();
