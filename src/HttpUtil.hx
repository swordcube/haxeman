package;

import haxe.io.Bytes;
import haxe.Http;

class HttpUtil {
	public static var userAgent:String = "haxeman (https://github.com/swordcube/haxeman)";

	public static function requestText(url:String):String {
		var r = null;
		var h = new Http(url);
		h.setHeader("User-Agent", userAgent);

		h.onStatus = function(s) {
			if (isRedirect(s))
				r = requestText(h.responseHeaders.get("Location"));
		};
		h.onData = function(d) {
			if (r == null)
				r = d;
		}
		h.onError = function(e) {
			throw e;
		}
		h.request(false);
		return r;
	}

	public static function requestBytes(url:String):Bytes {
		var r = null;
		var h = new Http(url);
		h.setHeader("User-Agent", userAgent);

		h.onStatus = function(s) {
			if (isRedirect(s)) {
				r = requestBytes(h.responseHeaders.get("Location"));
			}
		};
		h.onBytes = function(d) {
			if (r == null)
				r = d;
		}
		h.onError = function(e) {
			throw e;
		}
		h.request(false);
		return r;
	}

	private static function isRedirect(status:Int):Bool {
		switch (status) {
			// 301: Moved Permanently, 302: Found (Moved Temporarily), 307: Temporary Redirect, 308: Permanent Redirect  - Nex
			case 301 | 302 | 307 | 308:
				// trace('Redirected with status code: ${status}');
				return true;
		}
		return false;
	}
}
