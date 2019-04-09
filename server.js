'use strict';
var http = require('http');
var fs = require('fs');
var ejs = require('ejs');
var os = require('os');

var server = http.createServer(function (req, res) {
    fs.readFile('index.html', function (err, data) {
        res.writeHead(200, { 'Content-Type': 'text/html', 'Content-Length': data.length });
         var returns = ejs.render(data.toString(), {
           host: os.hostname()
       });
        res.end(returns);
    });
});

exports.listen = function () {
    server.listen.apply(server, arguments);
};
  
exports.close = function (callback) {
    server.close(callback);
};

server.listen(8080);
