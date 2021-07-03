package sugoi.db;
import sys.db.Types;
import db.User;
import sugoi.Web;

@:id(sid)
class Session extends sys.db.Object
{
	public var sid : SString<32>;
	public var ip : SString<15>;
	public var lang : SString<2>;
	public var messages : SData<Array<{ error : Bool, text : String }>>;
	public var createTime : SDateTime;
	public var sdata : SText;

	@:skip public var data : Dynamic;

	public var uid : Null<SInt>;

	@:skip public var user(get, set): db.User;
	public function get_user() {
		if (uid == null)
			return null;

		return db.User.manager.get(uid);
	}

	public function set_user(user:db.User) {
		this.uid = if (user == null) null else user.id;
		return user;
	}


	/**
	 * Stores a message in session
	 */
	public function addMessage( text : String, ?error=false ) {
		messages.push({ error : error, text : text });
		update();
	}


	public function setUser( u : User ):Void
	{
		lang = u.lang;
		user = u;
		update();

		App.current.user = u;
	}

	public override function update() {
		sdata = haxe.Serializer.run(data);
		super.update();
	}

	private static function get( sid:String ):Session {
		if ( sid == null ) return null;

		var s = manager.get(sid,true);
		if ( s == null ) return null;
		try {
			s.data = haxe.Unserializer.run(s.sdata);
		}catch (e:Dynamic) {
			s.data = null;
		}

		return s;
	}


	public static function init( sids : Array<String> ) {
		for( sid in sids ) {
			var s = get(sid);
			if( s != null ) return s;
		}
		var ip = Web.getClientIP();
		var s = new Session();
		s.ip = ip;
		s.createTime = Date.now();
		s.uid = null;

		s.sid = generateId();
		var count = 20;
		while( try { s.insert(); false; } catch( e : Dynamic ) true ) {
			s.sid = generateId();
			// prevent infinite loop in SQL error
			if( count-- == 0 ) {
				s.insert();
				break;
			}
		}

		return s;
	}

	/**
	 * Generate a random 32 chars string
	 */
	public static var S = "abcdefjhijklmnopqrstuvwxyABCDEFJHIJKLMNOPQRSTUVWXYZ0123456789";
	public static function generateId():String {

		var id = "";
		for ( x in 0...32 ) {
			id += S.charAt(Std.random(S.length));
		}
		return id;
	}
}
