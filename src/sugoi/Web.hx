package sugoi;

/**
 * Shortcut to system class
 */
#if (!macro && php)
import php.Lib;
import php.Syntax;
import php.Syntax.*;
import php.Global.*;
import php.SuperGlobal.*;

class Web
{
	public static function redirect(to:String)
    {
        setHeader("Location", to);
    }

	public static function getCookies():Map<String, String>
    {
		return Lib.hashOfAssociativeArray(_COOKIE);
	}

    static public function getParams()
    {
        return Lib.hashOfAssociativeArray(array_merge(_GET, _POST));
    }

    static public function getClientIP()
    {
        return _SERVER['REMOTE_ADDR'];
    }

    static public function getURI()
    {
		var s:String = _SERVER['REQUEST_URI'];
		return s.split("?")[0];
    }

    static public function setHeader(k:String, v:String)
    {
        header(k+": "+v);
    }

    static public function getCwd():String
    {
        return getcwd()+"/";
    }

    static public function getClientHeaders()
    {
		var headers = loadClientHeaders();
		var result = new List();
		for (key in headers.keys()) {
			result.push({value: headers.get(key), header: key});
		}
		return result;
    }

    static public function getClientHeader(k:String)
    {
        return loadClientHeaders().get(str_replace('-', '_', strtoupper(k)));
    }

    private static var _clientHeaders:Map<String, String>;
    static function loadClientHeaders():Map<String, String> {
        if (_clientHeaders != null)
            return _clientHeaders;

        _clientHeaders = new Map();

        if (function_exists('getallheaders')) {
            foreach(getallheaders(), function(key:String, value:Dynamic) {
                _clientHeaders.set(str_replace('-', '_', strtoupper(key)), Std.string(value));
            });
            return _clientHeaders;
        }

        var copyServer = Syntax.assocDecl({
            CONTENT_TYPE: 'Content-Type',
            CONTENT_LENGTH: 'Content-Length',
            CONTENT_MD5: 'Content-Md5'
        });
        foreach(_SERVER, function(key:String, value:Dynamic) {
            if ((substr(key, 0, 5) : String) == 'HTTP_') {
                key = substr(key, 5);
                if (!isset(copyServer[key]) || !isset(_SERVER[key])) {
                    _clientHeaders[key] = Std.string(value);
                }
            } else if (isset(copyServer[key])) {
                _clientHeaders[key] = Std.string(value);
            }
        });
        if (!_clientHeaders.exists('AUTHORIZATION')) {
            if (isset(_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
                _clientHeaders['AUTHORIZATION'] = Std.string(_SERVER['REDIRECT_HTTP_AUTHORIZATION']);
            } else if (isset(_SERVER['PHP_AUTH_USER'])) {
                var basic_pass = isset(_SERVER['PHP_AUTH_PW']) ? Std.string(_SERVER['PHP_AUTH_PW']) : '';
                _clientHeaders['AUTHORIZATION'] = 'Basic ' + base64_encode(_SERVER['PHP_AUTH_USER'] + ':' + basic_pass);
            } else if (isset(_SERVER['PHP_AUTH_DIGEST'])) {
                _clientHeaders['AUTHORIZATION'] = Std.string(_SERVER['PHP_AUTH_DIGEST']);
            }
        }

        return _clientHeaders;
    }
}
#else
    //Web.getCwd() will work in macros
    typedef Web = Sys;
#end
