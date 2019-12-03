import js.npm.express.Request;

typedef MySQLConfig = {
	?host:String,
	?port:Int,
	?user:String,
	?password:String,
	database:String
}

typedef MySQL = {
	createConnection:Dynamic->MySQLConnection,
	format:String->Array<String>->Dynamic
}

typedef MySQLConnection = {
	connect:Void->Void,
	changeUser:Dynamic->(Dynamic->Void)->Void,
	escape:String->String,
	escapeId:String->String,
	pause:(Dynamic->Void)->Void,
	end:Void->Void,
	query:String->?Array<Dynamic>->?(Dynamic->Dynamic->Array<Dynamic>->Void)->Dynamic
}

extern class RequestWithSession extends Request {
	public var session:{authenticated:Bool};
}

extern class RequestLogin extends RequestWithSession {
	public var body:{username:String, password:String};
}

extern class RequestSubscribe extends RequestWithSession {
	public var body:{username:String, password:String, email:String};
}