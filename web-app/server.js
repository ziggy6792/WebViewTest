const jsonServer = require('json-server');
const server = jsonServer.create();
const router = jsonServer.router('db.json');
const middlewares = jsonServer.defaults();
const cors = require('cors');
const util = require('util');

server.use(function (req, res, next) {
  setTimeout(next, 2000);
});

server.use(middlewares);

server.get('/hello', (req, res) => {
  console.log('headers', JSON.stringify(req.headers));

  res.header('Access-Control-Allow-Origin', 'http://127.0.0.1:8000');

  res.send('Hello World!');
});

server.use(router);

// server.use(cors);

// function logResponseBody(req, res, next) {
//   var oldWrite = res.write,
//     oldEnd = res.end;

//   var chunks = [];

//   res.write = function (chunk) {
//     chunks.push(chunk);

//     return oldWrite.apply(res, arguments);
//   };

//   res.end = function (chunk) {
//     if (chunk) chunks.push(chunk);

//     var body = Buffer.concat(chunks).toString('utf8');
//     console.log(req.path, body);

//     oldEnd.apply(res, arguments);
//   };

//   next();
// }

// server.use(logResponseBody);

server.listen(8001, () => {
  console.log('JSON Server is running');
});
