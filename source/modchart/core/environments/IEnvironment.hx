package modchart.core.environments;

interface IEnvironment {
	public var parent:Manager;

	public function setup(parent:Manager):Void;
	public function dispose():Void;
}
