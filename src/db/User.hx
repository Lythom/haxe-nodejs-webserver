package db;

import haxe.Json;
import haxe.crypto.BCrypt;

import TypeDefinitions;

class User {
	static private var PEPPER:String = "REGDQngkIasbXqT2@oWbcx42$ZwWF&@1d1or1k%p1F0YSfmAxHk5vxHJZp5D*Boh";

	/**
	 * Check if a user exists in database
	 * @param connection MySQLPool The connection to the database
	 * @param uname String the username or login
	 * @param pwd 	String user password
	 * @param callback UserExistsResult->Void A callback to handle the response.
	 */
	public static function userExists(connection:MySQLPool, uname:String, pwd:String, callback:UserExistsResult->Void):Void {
		connection.query("SELECT login, password FROM user WHERE login = ?", [uname], (error:js.lib.Error, results, fields) -> {
			if (error != null) {
				callback(Error(error));
				return;
			}
			if (results.length <= 0) {
				callback(Missing);
				return;
			}
			try {
				callback(BCrypt.verify(pwd + PEPPER, results[0].password) ? Yes : WrongPassword);
			} catch (e:Dynamic) {
				trace(e);
				callback(WrongPassword);
			}
		});
	}

	/**
	 * Insert a user in database.
	 * @param connection MySQLPool The connection to the database
	 * @param user User user to insert
	 * @param callback QueryResult<Bool>->Void A callback to handle the response, response can be either true if the creation completed or a JavaScript error.
	 */
	public static function createUser(connection:MySQLPool, user:model.User, callback:QueryResult<Bool>->Void) {
		var encodedPassword = BCrypt.encode(user.password + PEPPER, BCrypt.generateSalt());
		connection.query("INSERT INTO user(login, password, email)  VALUES(?,?,?)", [user.username, encodedPassword, user.email],
			(error:js.lib.Error, results, fields) -> {
				if (error != null) {
					callback(Error(error));
					return;
				}
				callback(OK(true));
			});
	}

	/**
	 * Save user data
	 * @param connection MySQLPool The connection to the database
	 * @param login String user to insert
	 * @param data Dynamic data to set, must be a serializable object.
	 * @param callback QueryResult<Dynamic>->Void A callback to handle the response, response can be either the Dynamic result or a JavaScript error.
	 */
	public static function save(connection:MySQLPool, login:String, data:Dynamic, callback:QueryResult<Dynamic>->Void):Void {
		connection.query("UPDATE user SET data=? WHERE login = ?", [Json.stringify(data), login],
		(error:js.lib.Error, results, fields) -> {
			if (error != null) {
				callback(Error(error));
				return;
			}
			callback(OK(results));
		});
	}

	/**
	 * Save user data
	 * @param connection MySQLPool The connection to the database
	 * @param login String user to insert
	 * @param data Dynamic data to set, must be a serializable object.
	 * @param callback QueryResult<Dynamic>->Void A callback to handle the response, response can be either the data of the user as string or a JavaScript error.
	 */
	public static function load(connection:MySQLPool, login:String, callback:QueryResult<String>->Void):Void {
		connection.query("SELECT data FROM user WHERE login = ?", [login],
		(error:js.lib.Error, results, fields) -> {
			if (error != null) {
				callback(Error(error));
				return;
			}
			callback(OK(results[0].data));
		});
	}
}
