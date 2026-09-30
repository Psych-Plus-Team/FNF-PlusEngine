package backend;

/** Small, script-safe HTTP bridge for optional mod content. */
class ScriptHttp
{
	public static function get(url:String, onData:Dynamic, ?onError:Dynamic):Void
	{
		if (url == null || url.length == 0)
		{
			if (onError != null)
				onError('empty URL');
			return;
		}

		try
		{
			final request = new haxe.Http(url);
			request.onData = function(data:String)
			{
				if (onData != null)
					onData(data);
			};
			request.onError = function(error:String)
			{
				if (onError != null)
					onError(error);
			};
			request.request(false);
		}
		catch (e:Dynamic)
		{
			if (onError != null)
				onError(Std.string(e));
		}
	}
}
