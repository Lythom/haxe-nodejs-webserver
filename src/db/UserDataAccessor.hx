package db;

import haxe.ds.Either;
import TypeDefinitions;

class UserDataAccessor {
	/**
	 * Check if a user exists in database
	 * @param connection MySQLConnection The connection to the database
	 * @param uname String the username or login
	 * @param pwd 	String user password
	 * @param callback Either<js.lib.Error, Bool>->Void A callback to handle the response, response can be either a userExists information or a JavaScript error.
	 */
	public static function userExists(connection:MySQLConnection, uname:String, pwd:String, callback:Either<js.lib.Error, Bool>->Void):Void {
		connection.query("SELECT login FROM user WHERE login = ? AND password = ?", [uname, pwd], (error:js.lib.Error, results, fields) -> {
			if (error != null) {
				callback(Left(error));
				return;
			}
			callback(Right(results.length > 0));
		});
	}

	/**
	 * Insert a user in database.
	 * @param connection MySQLConnection The connection to the database
	 * @param user User user to insert
	 * @param callback Either<js.lib.Error, Bool>->Void A callback to handle the response, response can be either the "user is in database" information or a JavaScript error.
	 */
	public static function createUser(connection:MySQLConnection, user:User, callback:Either<js.lib.Error, Bool>->Void) {
		connection.query("INSERT INTO user(login, password, email)  VALUES(?,?,?)", [user.username, user.password, user.email],
			(error:js.lib.Error, results, fields) -> {
				if (error != null) {
					callback(Left(error));
					return;
				}
				callback(Right(true));
			});
	}
}
