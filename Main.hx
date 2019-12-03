import js.lib.Error;
import haxe.ds.Either;
import Externs;
import js.Node;
import js.npm.express.Request;
import js.npm.express.Response;
import js.npm.Express;
import js.npm.express.BodyParser;
import js.npm.express.Session;

typedef User = {
	var username:String;
	var password:String;
	var email:String;
} // TODO: parler de la mémoire dans les programmes

class Main {
	static var db:MySQL = Node.require("mysql");

	static function main() {
		var users:Array<User> = new Array<User>();

		var connection = db.createConnection({
			host: 'bosa3032.odns.fr',
			user: 'bosa3032_bosa3032',
			password: '&7gW3-Xb}]Zz',
			database: 'bosa3032_devback'
		});
		connection.connect();

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
					userExists(connection, username, password, result -> switch (result) {
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
					userExists(connection, username, password, result -> switch (result) {
						case Left(err):
							trace(err);
							res.send(500, err.message);
						case Right(true):
							res.send(200, "OK");
						case Right(false):
							createUser(connection, {
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

	static function userExists(connection:MySQLConnection, uname:String, pwd:String, callback:Either<Error, Bool>->Void):Void {
		connection.query("SELECT login FROM user WHERE login = ? AND password = ?", [uname, pwd], (error:Error, results, fields) -> {
			if (error != null) {
				callback(Left(error));
				return;
			}
			callback(Right(results.length > 0));
		});
	}

	static function createUser(connection:MySQLConnection, user:User, callback:Either<Error, Bool>->Void) {
		connection.query("INSERT INTO user(login, password, email)  VALUES(?,?,?)", [user.username, user.password, user.email],
			(error:Error, results, fields) -> {
				if (error != null) {
					callback(Left(error));
					return;
				}
				callback(Right(true));
			});
	}
}
