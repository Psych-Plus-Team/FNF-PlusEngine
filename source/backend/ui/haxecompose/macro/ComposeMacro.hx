package backend.ui.haxecompose.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

class ComposeMacro
{
	#if macro
	public static function build():Array<Field>
	{
		var fields = Context.getBuildFields();
		for (field in fields)
		{
			var isComposable = hasMeta(field.meta, ["compose", "composable"]);
			var isExpressive = hasMeta(field.meta, ["experimentalexpressive", "experimentexpressive", "experimentexpresive"]);

			if (isComposable)
			{
				switch (field.kind)
				{
					case FFun(_):
						ensureMeta(field.meta, ":keep", field.pos);
					default:
						Context.warning("@:compose only applies to functions.", field.pos);
				}
			}

			if (isExpressive)
			{
				ensureMeta(field.meta, ":keep", field.pos);
				if (!isComposable)
					Context.warning("@:experimentalExpressive should normally go alongside @:compose.", field.pos);
			}
		}
		return fields;
	}

	public static function buildComposable():Array<Field>
	{
		return build();
	}

	static function hasMeta(meta:Metadata, names:Array<String>):Bool
	{
		if (meta == null)
			return false;

		for (entry in meta)
		{
			var name = normalizeMeta(entry.name);
			for (expected in names)
				if (name == expected)
					return true;
		}
		return false;
	}

	static function ensureMeta(meta:Metadata, name:String, pos:Position):Void
	{
		if (meta == null)
			return;

		for (entry in meta)
			if (entry.name == name)
				return;

		meta.push({name: name, params: [], pos: pos});
	}

	static function normalizeMeta(name:String):String
	{
		while (name.length > 0 && name.charAt(0) == ":")
			name = name.substr(1);
		return name.toLowerCase();
	}
	#end
}
