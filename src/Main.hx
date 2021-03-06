import js.npm.express.Static;
import js.npm.ws.WebSocket;
import js.Node;
import js.npm.express.Request;
import js.npm.express.Response;
import js.npm.Express;
import js.npm.express.BodyParser;
import js.npm.express.Session;
import TypeDefinitions;

extern class RequestWithSession extends Request {
	public var session:{token:String};
}

extern class RequestLogin extends RequestWithSession {
	public var body:{username:String, password:String};
}

extern class RequestSubscribe extends RequestWithSession {
	public var body:{username:String, password:String, email:String};
}

extern class RequestSave extends RequestWithSession {
	public var body:Dynamic;
}

class Main {
	// Declare a static property with a get but no setter. See https://haxe.org/manual/class-field-property.html
	// Act as a readonly singleton.
	static var mysqlDB(default, never):MySQL = Node.require("mysql");

	static var lastSocketId:Int = 0;
	static var sockets:List<WebSocket> = new List<WebSocket>();
	static var tickets:Map<String, String> = new Map<String, String>();

	static function main() {
		// load environment variables from .env file
		// .env file must be present at the location the "node" command is run (Working directory)
		Node.require('dotenv').config();
		var cors = Node.require('cors');

		// create a connection to the database and start the connection immediatly
		var connection = mysqlDB.createPool({
			host: Sys.getEnv("MYSQL_ADDON_HOST") != null ? Sys.getEnv("MYSQL_ADDON_HOST") : Sys.getEnv("DB_HOST"),
			user: Sys.getEnv("MYSQL_ADDON_USER") != null ? Sys.getEnv("MYSQL_ADDON_USER") : Sys.getEnv("DB_USER"),
			password: Sys.getEnv("MYSQL_ADDON_PASSWORD") != null ? Sys.getEnv("MYSQL_ADDON_PASSWORD") : Sys.getEnv("DB_PASSWORD"),
			database: Sys.getEnv("MYSQL_ADDON_DB") != null ? Sys.getEnv("MYSQL_ADDON_DB") : Sys.getEnv("DB_NAME")
		});

		// Setup express server with middlewares
		var server:Express = new js.npm.Express();
		server.use(BodyParser.json({limit: '5mb', type: 'application/json'}));
		server.use(cors({
			credentials: true,
			origin: function(req:Request, callback:String->Bool->Void) {
				callback(null, true);
			}
		}));

		server.use(new Static("wsclient"));
		server.use("/doc", new Static("generated-doc"));

		server.use(new Session({
			secret: 'shhhh, very secret',
			resave: true,
			saveUninitialized: true,
			cookie: {
				sameSite: 'none'
			}
		}));

		var expressWs = Node.require('express-ws')(server);

		expressWs.app.ws('/', function(socket:WebSocket, req) {
			// use a closure to keep socket related data
			// if username have a value the user is logged in.
			var username:String = null;
			trace("User connected");

			/**
			 * @api {websocket} /close Close
			 * @apiDescription Gently stops connection with the server.
			 * <br/> URL: ws://serverurl/close
			 * @apiName Close
			 * @apiGroup Websocket
			 */
			socket.on('close', function() {
				sockets.remove(socket);
				if (username == null)
					return;
				for (remoteSocket in sockets) {
					if (remoteSocket.readyState == ReadyState.OPEN) remoteSocket.send(username + " disconnected !", null);
				}
			});

			/**
			 * @api {websocket} /message Message
			 * @apiDescription Send a message on the websocket channel
			 * <br/> The first message must be the authentication ticket provided by the /wsTicket route (POST). Any other message will have the server close the connexion.
			 * <br/> URL: ws://serverurl/message
			 * @apiName Message
			 * @apiGroup Websocket
			 *
			 * @apiParam {String} message
			 */
			socket.on('message', function(msg:Dynamic) {
				trace("message: " + msg);
				if (username == null) {
					if (tickets.exists(msg)) {
						// allow socket to talk by setting its username
						username = tickets[msg];
						// consume ticket
						tickets.remove(msg);
						// add socket to destination list
						sockets.add(socket);
						// welcome
						socket.send("Bienvenue sur le chat " + username, null);
						trace("User authenticated : " + username);
					} else {
						trace("Please provide a ticket first to log in.");
						socket.send("Please provide a ticket first to log in.", null);
						socket.close();
					}
					return;
				}
				for (remoteSocket in sockets) {
					remoteSocket.send(username + " : " + Std.string(msg), null);
				}
			});
		});

		/**
		 * @api {get} /random Random
		 * @apiDescription Return a random number between 0 and 1
		 * @apiName Random
		 * @apiGroup Random
		 *
		 * @apiSuccessExample Success-Response:
		 *     HTTP/1.1 200 OK
		 *     0.546821
		 */
		server.get('/random', function(req:Request, res:Response) {
			res.writeHead(200, {'Content-Type': 'text/plain'});
			res.end(Std.string(Math.random()));
		});

		/**
		 * @api {post} /login Login
		 * @apiDescription Authenticate a registered user. Set a session token as server cookie.
		 * @apiName Login
		 * @apiGroup Users
		 *
		 * @apiParam {String} username Login used by the user
		 * @apiParam {String} password Password to check
		 *
		 * @apiSuccessExample Success-Response:
		 *     HTTP/1.1 200 OK
		 *     OK
		 *
		 * @apiError (Error 401) Unauthorized Authentication information doesn't match.
		 * @apiError (Error 500) MissingInformation Could not register the user because some information is missing.
		 * @apiError (Error 500) TechnicalError Could not create user because of technical error %s.
		 *
		 * @apiErrorExample Error-Response:
		 *     HTTP/1.1 401 Unauthorized
		 *     {
		 *        "errorKey": "Unauthorized",
		 *        "errorMessage": "Authentication information doesn't match.",
		 *      }
		 */
		server.post('/login', function(expressReq:Request, res:Response) {
			var req:RequestLogin = cast(expressReq);
			switch (req.body) {
				case {username: uname, password: pwd}
					if (uname == null || pwd == null):
					// username and password must be provided
					req.session.token = null;
					res.send(400, "Bad Request");
				case {username: username, password: password}:
					db.User.userExists(connection, username, password, result -> switch (result) {
						case UserExistsResult.Error(err):
							trace(err);
							res.send(500, err.message);
						case UserExistsResult.Yes:
							db.Token.createToken(connection, username, 59, createTokenResult -> switch createTokenResult {
								case OK(token):
									req.session.token = token;
									res.send(200, "OK");
								case Error(err):
									trace(err);
									res.send(500, err.message);
							});
						case UserExistsResult.Missing | UserExistsResult.WrongPassword:
							req.session.token = null;
							res.send(401, "Unauthorized");
					});
			}
		});

		/**
		 * @api {post} /subscribe Subscribe
		 * @apiDescription Register a new user
		 * @apiName Subscribe
		 * @apiGroup Users
		 *
		 * @apiParam {String} username Login that will be used by the user
		 * @apiParam {String} password Password to use for authentication
		 * @apiParam {String} email Email
		 *
		 * @apiSuccessExample Success-Response:
		 *     HTTP/1.1 200 OK
		 *     OK
		 *
		 * @apiError (Error 500) MissingInformation Could not register the user because some information is missing.
		 * @apiError (Error 500) UserCreationFailed Could not create nor find user %s.
		 * @apiError (Error 500) TechnicalError Could not create user because of technical error %s.
		 *
		 * @apiErrorExample Error-Response:
		 *     HTTP/1.1 500 MissingInformation
		 *     {
		 *        "errorKey": "MissingInformation",
		 *        "errorMessage": "Could not register the user because some information is missing.",
		 *      }
		 */
		server.post('/subscribe', function(expressReq:Request, res:Response) {
			var req:RequestSubscribe = cast(expressReq);
			switch (req.body) {
				case {username: username, password: password, email: email}
					if (username == null || password == null || email == null):
					res.send(400, "Username and password and email must be provided");
				case {username: username, password: password, email: email}:
					db.User.userExists(connection, username, password, result -> switch (result) {
						case UserExistsResult.Error(err):
							trace(err);
							res.send(500, err.message);
						case UserExistsResult.Yes, UserExistsResult.WrongPassword:
							res.send(500, "User already exists, please use another login");
						case UserExistsResult.Missing:
							db.User.createUser(connection, {
								username: username,
								password: password,
								email: email
							}, response -> switch (response) {
								case Error(err):
									res.send(500, "An error occured\n" + err.message);
								case OK(_):
									res.send(200, "OK");
							});
					});
			}
		});

		/**
		 * @api {post} /logout [Authenticated] Logout
		 * @apiDescription Logout the user, remove the session token from the server cookies.
		 * @apiName Logout
		 * @apiGroup Users
		 *
		 * @apiSuccessExample Success-Response:
		 *     HTTP/1.1 200 OK
		 *     OK
		 */
		server.post('/logout', function(expressReq:Request, res:Response) {
			var req:RequestWithSession = cast(expressReq);
			req.session.token = null;
			res.send(200, "OK");
			return;
		});

		/**
		 * @api {post} /status [Authenticated] Status
		 * @apiDescription Tell if the user is currently logged in ("Bonjour {username}") or logged out ("Visiteur").
		 * @apiName Status
		 * @apiGroup Users
		 *
		 * @apiSuccessExample Success-Response:
		 *     HTTP/1.1 200 OK
		 *     Visiteur
		 *
		 * @apiError (Error 401) Invalid Token.
		 * @apiError (Error 500) TechnicalError %s.
		 */
		server.get('/status', function(expressReq:Request, res:Response) {
			var req:RequestWithSession = cast(expressReq);
			if (req.session.token == null) {
				res.send(200, "Visiteur");
				return;
			}
			db.Token.fromToken(connection, req.session.token, result -> switch (result) {
				case User(login):
					res.send(200, "Bonjour " + login);
				case Missing:
					res.send(401, "Token invalide. Vous devez vous re-connecter.");
				case Error(err):
					res.send(500, err);
			});
		});

		/**
		 * @api {post} /save [Authenticated] Save
		 * @apiDescription Overwrite authenticated user data.
		 * @apiName save
		 * @apiGroup Users
		 *
		 * @apiSuccessExample Success-Response:
		 *     HTTP/1.1 200 OK
		 *     OK
		 *
		 * @apiError (Error 401) Invalid Token.
		 * @apiError (Error 500) An error occured %s.
		 */
		server.post('/save', function(expressReq:Request, res:Response) {
			var req:RequestSave = cast(expressReq);
			if (req.session.token == null) {
				res.send(401, "Token invalide. Vous devez vous re-connecter.");
				return;
			}
			db.Token.fromToken(connection, req.session.token, result -> switch (result) {
				case User(login):
					db.User.save(connection, login, req.body, result -> switch (result) {
						case Error(err):
							res.send(500, "An error occured\n" + err.message);
						case OK(_):
							res.send(200, "OK");
					});
				case Missing:
					res.send(401, "Token invalide. Vous devez vous re-connecter.");
				case Error(err):
					res.send(500, err);
			});
		});

		/**
		 * @api {post} /load [Authenticated] load
		 * @apiDescription Get user data
		 * @apiName load
		 * @apiGroup Users
		 *
		 * @apiSuccessExample Success-Response:
		 *     HTTP/1.1 200 OK
		 *     OK
		 *
		 * @apiError (Error 401) Invalid Token.
		 * @apiError (Error 500) An error occured %s.
		 */
		server.post('/load', function(expressReq:Request, res:Response) {
			var req:RequestSave = cast(expressReq);
			if (req.session.token == null) {
				res.send(401, "Token invalide. Vous devez vous re-connecter.");
				return;
			}
			db.Token.fromToken(connection, req.session.token, result -> switch (result) {
				case User(login):
					db.User.load(connection, login, result -> switch (result) {
						case Error(err):
							res.send(500, "An error occured\n" + err.message);
						case OK(data):
							res.send(200, data);
					});
				case Missing:
					res.send(401, "Token invalide. Vous devez vous re-connecter.");
				case Error(err):
					res.send(500, err);
			});
		});

		/**
		 * @api {get} /wsTicket [Authenticated] wsTicket
		 * @apiDescription Get a ticket for websocket access. The ticket must be sent using the websocket /message route and be the first message.
		 * @apiName wsTicket
		 * @apiGroup Websocket
		 *
		 * @apiSuccessExample Success-Response:
		 *     HTTP/1.1 200 OK
		 *     OK
		 *
		 * @apiError (Error 401) Invalid Token.
		 * @apiError (Error 500) An error occured %s.
		 */
		server.get('/wsTicket', function(expressReq:Request, res:Response) {
			var req:RequestWithSession = cast(expressReq);
			if (req.session.token == null) {
				res.send(401, "Token invalide. Vous devez vous re-connecter.");
				return;
			}
			db.Token.fromToken(connection, req.session.token, result -> switch (result) {
				case User(login):
					var ticket = haxe.crypto.BCrypt.generateSalt().substr(0, 32);
					tickets[ticket] = login;
					res.send(200, ticket);
				case Missing:
					res.send(401, "Token invalide. Vous devez vous re-connecter.");
				case Error(err):
					res.send(500, err);
			});
		});

		var port = 1337;

		if (Sys.getEnv("PORT") != null) {
			port = Std.parseInt(Sys.getEnv("PORT"));
		}
		server.listen(port);
		trace('Server running at http://localhost:${port}/');
		Node.process.on('SIGTERM', function onSigterm() {
			trace('Got SIGTERM. Graceful shutdown start');
		});
	}
}
