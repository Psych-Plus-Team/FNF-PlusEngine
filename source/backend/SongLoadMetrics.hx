package backend;

import haxe.Timer;

/** One-shot timings for the current song load. No per-frame sampling. */
class SongLoadMetrics
{
	public static var chartMs(default, null):Float = 0;
	public static var checkerMs(default, null):Float = 0;
	public static var planMs(default, null):Float = 0;
	public static var assetsMs(default, null):Float = 0;
	public static var totalMs(default, null):Float = 0;
	public static var chartCacheHit(default, null):Bool = false;
	public static var planCacheHit(default, null):Bool = false;
	public static var assetCount(default, null):Int = 0;

	static var started:Float = 0;
	static var assetsStarted:Float = 0;
	static var activeLoading:Bool = false;

	public static function begin():Void
	{
		started = Timer.stamp();
		assetsStarted = 0;
		chartMs = checkerMs = planMs = assetsMs = totalMs = 0;
		chartCacheHit = planCacheHit = false;
		assetCount = 0;
		activeLoading = false;
	}

	public static function markLoading():Void
		activeLoading = true;

	public static function cancel():Void
		activeLoading = false;

	public static function recordChart(milliseconds:Float, cacheHit:Bool):Void
	{
		chartMs = milliseconds;
		chartCacheHit = cacheHit;
	}

	public static function recordChecker(milliseconds:Float):Void
		checkerMs = milliseconds;

	public static function recordPlan(plan:SongLoadPlan):Void
	{
		if (plan == null)
			return;
		planMs = plan.compileMs;
		planCacheHit = plan.cacheHit;
	}

	public static function beginAssets(count:Int):Void
	{
		assetCount = count;
		assetsStarted = Timer.stamp();
	}

	public static function finish():Void
	{
		if (!activeLoading)
			return;
		var now:Float = Timer.stamp();
		assetsMs = assetsStarted > 0 ? (now - assetsStarted) * 1000 : 0;
		totalMs = started > 0 ? (now - started) * 1000 : 0;
		trace('[Song Load] ${summary()}');
		activeLoading = false;
	}

	public static function summary():String
	{
		var chartSource:String = chartCacheHit ? 'cache' : 'json';
		var planSource:String = planCacheHit ? 'cache' : 'new';
		return 'total ${ms(totalMs)} | chart ${ms(chartMs)} ($chartSource) | checker ${ms(checkerMs)} | plan ${ms(planMs)} ($planSource) | assets ${ms(assetsMs)} ($assetCount)';
	}

	static inline function ms(value:Float):String
		return '${Math.round(value * 10) / 10}ms';
}
