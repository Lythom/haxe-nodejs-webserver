package db;

import haxe.crypto.BCrypt;
import haxe.ds.Either;
import TypeDefinitions;

enum UserExistsResult {
	Yes;
	Missing;
	WrongPassword;
	Error(err:js.lib.Error);
}

enum FromTokenResult {
	User(login:String);
	Missing;
	Error(err:js.lib.Error);
}

class UserDataAccessor {
	static private var PEPPER:String = "REGDQngkIasbXqT2@oWbcx42$ZwWF&@1d1or1k%p1F0YSfmAxHk5vxHJZp5D*Boh";

	/**
	 * Check if a user exists in database
	 * @param connection MySQLConnection The connection to the database
	 * @param uname String the username or login
	 * @param pwd 	String user password
	 * @param callback UserExistsResult->Void A callback to handle the response.
	 */
	public static function userExists(connection:MySQLConnection, uname:String, pwd:String, callback:UserExistsResult->Void):Void {
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
	 * @param connection MySQLConnection The connection to the database
	 * @param user User user to insert
	 * @param callback Either<js.lib.Error, Bool>->Void A callback to handle the response, response can be either the "user is in database" information or a JavaScript error.
	 */
	public static function createUser(connection:MySQLConnection, user:User, callback:Either<js.lib.Error, Bool>->Void) {
		var encodedPassword = BCrypt.encode(user.password + PEPPER, BCrypt.generateSalt());
		connection.query("INSERT INTO user(login, password, email)  VALUES(?,?,?)", [user.username, encodedPassword, user.email],
			(error:js.lib.Error, results, fields) -> {
				if (error != null) {
					callback(Left(error));
					return;
				}
				callback(Right(true));
			});
	}

	/**
	 * Create a authentication token for a user
	 * @param connection  MySQLConnection The connection to the database
	 * @param login  String user login to insert
	 * @param durationInMinute After this duration, the token must expire
	 */
	public static function createToken(connection:MySQLConnection, login:String, durationInMinute:Float = 0, callback:Either<js.lib.Error, String>->Void) {
		var token:String = BCrypt.generateSalt().substr(0, 32);
		var today = Date.now();
		var dayInMs:Float = 24 * 60 * 60 * 1000;
		connection.query("INSERT INTO token(id, login, expiration)  VALUES(?,?,?)", [
			login,
			token,
			(durationInMinute <= 0 ? "DEFAULT" : formatDateForMySQL(DateTools.delta(Date.now(), dayInMs)))
		], (error:js.lib.Error, results, fields) -> {
				if (error != null) {
					callback(Left(error));
					return;
				}
				callback(Right(token));
			});
	}

	/**
	 * Get user login from token if the token is valid
	 * @param connection connection  MySQLConnection The connection to the database
	 * @param token  String user login to insert
	 * @param callback 
	 */
	public static function fromToken(connection:MySQLConnection, token:String, callback:FromTokenResult->Void):Void {
		connection.query("DELETE FROM token WHERE expiration < now()", (error:js.lib.Error, results, fields) -> {
			connection.query("SELECT user.login, token.exiration FROM user INNER JOIN token ON user.login = token.id_user WHERE token.id = ?", [token],
				(error:js.lib.Error, results, fields) -> {
					if (error != null) {
						callback(Error(error));
						return;
					}
					if (results.length <= 0) {
						callback(Missing);
						return;
					}
					callback(User(results[0].login));
				});
		});
	}

	private static function formatDateForMySQL(date:Date):String {
		return DateTools.format(date, "%Y-%m-%d_%H:%M:%S");
	}
}
