package sugoi.db;
import sys.db.Types;

class Error extends sys.db.Object {

	public var id : SId;
	public var date : SDateTime;
	public var error : SText;

	public var uid : SInt;

	public var ip : SNull<SString<15>>;
	public var userAgent : SNull<SString<256>>;
	public var url : SNull<STinyText>;

}
