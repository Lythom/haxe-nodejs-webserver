import js.npm.express.Request;

/**
 * Application data model
 */
typedef User = {
	var username:String;
	var password:String;
	var email:String;
}

/**
 * Mysql externs for npm package "mysql"
 * See documentation at https://github.com/mysqljs/mysql
 * Those types are extrapolated (deduced) from usages seen on the documentation.
 */
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
