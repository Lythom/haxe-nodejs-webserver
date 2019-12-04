import db.UserDataAccessor;
import js.Node;
import js.npm.express.Request;
import js.npm.express.Response;
import js.npm.Express;
import js.npm.express.BodyParser;
import js.npm.express.Session;

import TypeDefinitions;

extern class RequestWithSession extends Request {
	public var session:{authenticated:Bool};
}

extern class RequestLogin extends RequestWithSession {
	public var body:{username:String, password:String};
}

extern class RequestSubscribe extends RequestWithSession {
	public var body:{username:String, password:String, email:String};
}

class Main {
	// Declare a static property with a get but no setter. See https://haxe.org/manual/class-field-property.html
	// Act as a readonly singleton.
	static var db(default, never):MySQL = Node.require("mysql");

	static function main() {
		// load environment variables from .env file
		// .env file must be present at the location the "node" command is run (Working directory)
		Node.require('dotenv').config();

		// create a connection to the database and start the connection immediatly
		var connection = db.createConnection({
			host: Sys.getEnv("DB_HOST"),
			user: Sys.getEnv("DB_USER"),
			password: Sys.getEnv("DB_PASSWORD"),
			database: Sys.getEnv("DB_NAME")
		});
		connection.connect();

		// Setup express server with middlewares
		var server:Express = new js.npm.Express();
		server.use(BodyParser.json({limit: '5mb', type: 'application/json'}));
		server.use(new Session({
			secret: 'shhhh, very secret',
			resave: true,
			saveUninitialized: true
		}));

		server.get('/random', function(req:Request, res:Response) {
			res.writeHead(200, {'Content-Type': 'text/plain'});
			res.end(Std.string(Math.random()));
		});
		server.post('/login', function(expressReq:Request, res:Response) {
			var req:RequestLogin = cast(expressReq);
			switch (req.body) {
				case {username: "theuser", password: "thepassword"}:
					req.session.authenticated = true;
					res.send(200, "OK");
				case {username: uname, password: pwd}
					if (uname == null || pwd == null):
					// username and password must be provided
					req.session.authenticated = false;
					res.send(400, "Bad Request");
				case {username: username, password: password}:
					UserDataAccessor.userExists(connection, username, password, result -> switch (result) {
						case Left(err):
							trace(err);
							res.send(500, err.message);
						case Right(true):
							req.session.authenticated = true;
							res.send(200, "OK");
						case Right(false):
							req.session.authenticated = false;
							res.send(401, "Unauthorized");
					});
			}
		});

		server.post('/subscribe', function(expressReq:Request, res:Response) {
			var req:RequestSubscribe = cast(expressReq);
			switch (req.body) {
				case {username: username, password: password, email: email}
					if (username == null || password == null || email == null):
					// username and password and email must be provided
					res.send(400, "Bad Request");
				case {username: username, password: password, email: email}:
					UserDataAccessor.userExists(connection, username, password, result -> switch (result) {
						case Left(err):
							trace(err);
							res.send(500, err.message);
						case Right(true):
							res.send(200, "OK");
						case Right(false):
							UserDataAccessor.createUser(connection, {
								username: username,
								password: password,
								email: email
							}, response -> switch (response) {
								case Left(err):
									res.send(500, "An error occured\n" + err.message);
								case Right(_):
									res.send(200, "OK");
							});
					});
			}
		});

		server.post('/logout', function(expressReq:Request, res:Response) {
			var req:RequestWithSession = cast(expressReq);
			req.session.authenticated = false;
			res.send(200, "OK");
			return;
		});

		server.get('/status', function(expressReq:Request, res:Response) {
			var req:RequestWithSession = cast(expressReq);
			res.send(200, req.session.authenticated ? "Authentifié" : "Visiteur");
		});

		var port = 1337;

		if (Sys.getEnv("PORT") != null) {
			port = Std.parseInt(Sys.getEnv("PORT"));
		}
		server.listen(port, '127.0.0.1');
		trace('Server running at http://127.0.0.1:${port}/');
		Node.process.on('SIGTERM', function onSigterm() {
			trace('Got SIGTERM. Graceful shutdown start');
			connection.end();
		});
	}

	
}
