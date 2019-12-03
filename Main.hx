import js.npm.express.Request;
import js.npm.express.Response;
import js.npm.Express;
import js.npm.express.BodyParser;
import js.npm.express.Session;

extern class RequestWithSession extends Request {
	public var session:{authenticated:Bool};
}

extern class RequestLogin extends RequestWithSession {
	public var body:{username:String, password:String};
}

extern class RequestSubscribe extends RequestWithSession {
	public var body:{username:String, password:String, email:String};
}

typedef User = {
	var username:String;
	var password:String;
	var email:String;
}

// TODO: parler de la mémoire dans les programmes

class Main {
	static var users:Array<User> = new Array<User>();

	static function main() {
		var server:Express = new js.npm.Express();
		server.use(BodyParser.json({limit: '5mb', type: 'application/json'}));
		server.use(new Session({
			secret: 'shhhh, very secret'
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
				case {username: uname, password: pwd}:
					if (userexists(uname, pwd)) {
						req.session.authenticated = true;
						res.send(200, "OK");
					} else {
						// check uname and pwd in database
						req.session.authenticated = false;
						res.send(401, "Unauthorized");
					}
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
					if (!userexists(username, password))
						users.push({username: username, password: password, email: email});
					res.send(200, "OK");
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
			trace(req.session.authenticated);
			res.send(200, req.session.authenticated ? "Authentifié" : "Visiteur");
		});

		var port = 1337;
		if (Sys.getEnv("PORT") != null) {
			port = Std.parseInt(Sys.getEnv("PORT"));
		}
		server.listen(port, '127.0.0.1');
		trace('Server running at http://127.0.0.1:${port}/');
	}

	static function userexists(uname:String, pwd:String):Bool {
		return users.filter(u -> u.username == uname && u.password == pwd).length > 0;
	}
}
