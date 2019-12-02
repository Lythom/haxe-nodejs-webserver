import js.npm.express.Request;
import js.npm.express.Response;
import js.npm.Express;
import js.npm.express.BodyParser;
import js.npm.express.Session;

extern class RequestWithMiddlwares extends Request {
	public var body:{username:String, password:String};
	public var session:{authenticated:Bool};
}

class Main {
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
			var req:RequestWithMiddlwares = cast(expressReq);
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
					// check uname and pwd in database
					req.session.authenticated = false;
					res.send(401, "Unauthorized");
			}
		});

		server.post('/logout', function(expressReq:Request, res:Response) {
			var req:RequestWithMiddlwares = cast(expressReq);
			req.session.authenticated = false;
			res.send(200, "OK");
			return;
		});
		server.get('/status', function(expressReq:Request, res:Response) {
			var req:RequestWithMiddlwares = cast(expressReq);
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
}
