import js.npm.express.Request;
import js.npm.express.Response;
import js.npm.Express;
import js.npm.express.BodyParser;
import js.npm.express.Router;
import js.npm.express.Session;

class Main {
	static function main() {
		var server:Express = new js.npm.Express();
		server.use(BodyParser.json({limit: '5mb', type: 'application/json'}));
		server.use(new Session({
			secret: 'shhhh, very secret'
		}));

		var router = new Router();

		router.get('/random', function(req:Request, res:Response) {
			res.writeHead(200, {'Content-Type': 'text/plain'});
			res.end(Std.string(Math.random()));
		});
		router.post('/login', function(req:Dynamic, res:Response) {
			if (req.body.username == "theuser" && req.body.password == "thepassword") {
				req.session.authenticated = true;
				res.send(200, "OK");
				return;
			} else {
				req.session.authenticated = false;
				res.send(401, "Unauthorized");
				return;
			}
		});
		router.get('/status', function(req:Dynamic, res:Response) {
			trace(req.session.authenticated);
			res.send(200, req.session.authenticated ? "Authentifié" : "Visiteur");
		});

		server.use(router);
		server.listen(1337, '127.0.0.1');
		trace('Server running at http://127.0.0.1:1337/');
	}
}
