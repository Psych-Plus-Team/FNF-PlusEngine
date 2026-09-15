package backend.ui.haxecompose.material3;

import backend.ui.haxecompose.foundation.Column;
import backend.ui.haxecompose.foundation.Row;
import backend.ui.haxecompose.md3e.WavyProgressIndicator;
import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.runtime.Composer.Composable;
import backend.ui.haxecompose.ui.Constraints;
import backend.ui.haxecompose.ui.Layout;
import backend.ui.haxecompose.ui.Measure.MeasureResult;
import backend.ui.haxecompose.ui.Modifier;
import backend.ui.md3.MD3Theme;
import flixel.util.FlxColor;

enum abstract ButtonStyle(String) from String to String
{
	var Filled = "filled";
	var Tonal = "tonal";
	var Outlined = "outlined";
	var TextOnly = "text";
}

class Material3
{
	public static function TextLabel(composer:Composer, text:String, ?modifier:Modifier, size:Int = 16, ?color:FlxColor):Void
		backend.ui.haxecompose.foundation.Text.compose(composer, text, modifier, size, color != null ? color : MD3Theme.onSurface);

	public static function Button(composer:Composer, label:String, onClick:Void->Void, ?style:ButtonStyle = Filled, ?modifier:Modifier):Void
	{
		var colors = buttonColors(style);
		var buttonModifier = (modifier != null ? modifier : Modifier.empty())
			.paddingXY(style == TextOnly ? 8 : 18, 10)
			.background(colors.container, style == TextOnly ? 0 : 20)
			.clickable(onClick);

		composer.emit("MD3Button", label, buttonModifier, function(node)
		{
			node.setProp("style", style);
			node.setProp("outlineColor", style == Outlined ? MD3Theme.outline : FlxColor.TRANSPARENT);
			node.measurePolicy = function(n, constraints:Constraints)
			{
				var size = Layout.measureBox(n, constraints);
				return new MeasureResult(Math.max(style == TextOnly ? 48 : 72, size.width), Math.max(40, size.height));
			};
		}, function(c) backend.ui.haxecompose.foundation.Text.compose(c, label, null, 15, colors.content));
	}

	public static function Card(composer:Composer, ?modifier:Modifier, ?content:Composable):Void
	{
		var cardModifier = (modifier != null ? modifier : Modifier.empty()).padding(10).background(MD3Theme.surfaceContainerHigh, 8);
		composer.emit("MD3Card", null, cardModifier, function(node)
		{
			node.setProp("outlineColor", MD3Theme.outlineVariant);
			node.measurePolicy = Layout.measureBox;
		}, content);
	}

	public static function Surface(composer:Composer, ?modifier:Modifier, ?color:FlxColor, radius:Float = 0, ?content:Composable):Void
	{
		var surfaceModifier = (modifier != null ? modifier : Modifier.empty()).background(color != null ? color : MD3Theme.surface, radius);
		composer.emit("MD3Surface", null, surfaceModifier, function(node)
		{
			node.measurePolicy = Layout.measureBox;
		}, content);
	}

	public static function FilledBox(composer:Composer, ?modifier:Modifier, ?content:Composable):Void
	{
		var boxModifier = (modifier != null ? modifier : Modifier.empty()).padding(10).background(MD3Theme.surfaceContainer, 8);
		composer.emit("MD3Box", null, boxModifier, function(node)
		{
			node.measurePolicy = Layout.measureBox;
		}, content);
	}

	public static function OutlinedBox(composer:Composer, ?modifier:Modifier, ?content:Composable):Void
	{
		var boxModifier = (modifier != null ? modifier : Modifier.empty()).padding(10).background(MD3Theme.surface, 8);
		composer.emit("MD3Box", null, boxModifier, function(node)
		{
			node.setProp("outlineColor", MD3Theme.outlineVariant);
			node.measurePolicy = Layout.measureBox;
		}, content);
	}

	public static function TopAppBar(composer:Composer, title:String, ?navigationLabel:String, ?actionLabel:String, ?onNavigationClick:Void->Void,
			?onActionClick:Void->Void, ?modifier:Modifier):Void
	{
		Row.compose(composer, (modifier != null ? modifier : Modifier.empty()).fillMaxWidth().paddingXY(8, 6).background(MD3Theme.surfaceContainer, 0).spacing(8),
			function(c)
			{
				if (navigationLabel != null && navigationLabel.length > 0)
					IconButton(c, navigationLabel, onNavigationClick);
				backend.ui.haxecompose.foundation.Text.compose(c, title, Modifier.empty().paddingXY(4, 7), 17, MD3Theme.onSurface);
				if (actionLabel != null && actionLabel.length > 0)
					IconButton(c, actionLabel, onActionClick);
			});
	}

	public static function Icon(composer:Composer, name:String, ?modifier:Modifier, size:Int = 24, ?color:FlxColor):Void
	{
		var iconModifier = (modifier != null ? modifier : Modifier.empty()).size(size, size);
		composer.emit("MD3Icon", name, iconModifier, function(node)
		{
			node.setProp("icon", name);
			node.setProp("glyph", MaterialIconRegistry.glyph(name));
			node.setProp("size", size);
			node.setProp("color", color != null ? color : MD3Theme.onSurfaceVariant);
			node.measurePolicy = function(n, constraints:Constraints)
			{
				var iconSize:Int = n.props.get("size");
				return new MeasureResult(constraints.constrainWidth(iconSize), constraints.constrainHeight(iconSize));
			};
		});
	}

	public static function IconButton(composer:Composer, iconName:String, onClick:Void->Void, ?modifier:Modifier):Void
	{
		var buttonModifier = (modifier != null ? modifier : Modifier.empty()).size(36, 36).background(FlxColor.TRANSPARENT, 18).clickable(onClick);
		composer.emit("MD3IconButton", iconName, buttonModifier, function(node)
		{
			node.measurePolicy = Layout.measureBox;
		}, function(c) Icon(c, iconName, Modifier.empty().offset(6, 6), 24, MD3Theme.primary));
	}

	public static function FloatingActionButton(composer:Composer, label:String, onClick:Void->Void, ?modifier:Modifier, ?iconName:String):Void
	{
		var buttonModifier = (modifier != null ? modifier : Modifier.empty()).paddingXY(16, 12).background(MD3Theme.primaryContainer, 14).clickable(onClick);
		composer.emit("MD3FAB", label, buttonModifier, function(node)
		{
			node.measurePolicy = Layout.measureBox;
		}, function(c)
		{
			if (iconName != null && iconName.length > 0)
				Row.compose(c, Modifier.empty().spacing(8), function(row)
				{
					Icon(row, iconName, null, 18, MD3Theme.onPrimaryContainer);
					backend.ui.haxecompose.foundation.Text.compose(row, label, null, 15, MD3Theme.onPrimaryContainer);
				});
			else
				backend.ui.haxecompose.foundation.Text.compose(c, label, null, 15, MD3Theme.onPrimaryContainer);
		});
	}

	public static function TextField(composer:Composer, label:String, value:String, ?onClick:Void->Void, ?modifier:Modifier):Void
	{
		var fieldModifier = (modifier != null ? modifier : Modifier.empty()).fillMaxWidth().paddingXY(12, 8).background(MD3Theme.surfaceContainerHighest, 8)
			.clickable(onClick);
		composer.emit("MD3TextField", label, fieldModifier, function(node)
		{
			node.setProp("outlineColor", MD3Theme.outlineVariant);
			node.measurePolicy = Layout.measureColumn;
		}, function(c)
		{
			backend.ui.haxecompose.foundation.Text.compose(c, label, null, 11, MD3Theme.onSurfaceVariant);
			backend.ui.haxecompose.foundation.Text.compose(c, value, null, 15, MD3Theme.onSurface);
		});
	}

	public static function SearchBar(composer:Composer, query:String, placeholder:String, ?onClick:Void->Void, ?modifier:Modifier):Void
	{
		var searchModifier = (modifier != null ? modifier : Modifier.empty()).fillMaxWidth().paddingXY(12, 8).background(MD3Theme.surfaceContainerHigh, 24)
			.clickable(onClick);
		composer.emit("MD3SearchBar", query, searchModifier, function(node)
		{
			node.measurePolicy = Layout.measureBox;
		}, function(c)
		{
			Row.compose(c, Modifier.empty().spacing(8), function(row)
			{
				Icon(row, "search", null, 20, MD3Theme.onSurfaceVariant);
				backend.ui.haxecompose.foundation.Text.compose(row, query != null && query.length > 0 ? query : placeholder, null, 14,
					query != null && query.length > 0 ? MD3Theme.onSurface : MD3Theme.onSurfaceVariant);
			});
		});
	}

	public static function DockedSearchBar(composer:Composer, query:String, suggestions:Array<String>, onSelect:Int->String->Void, ?modifier:Modifier):Void
	{
		var dockModifier = (modifier != null ? modifier : Modifier.empty()).fillMaxWidth().padding(8).background(MD3Theme.surfaceContainer, 16);
		composer.emit("MD3DockedSearchBar", query, dockModifier, function(node)
		{
			node.setProp("outlineColor", MD3Theme.outlineVariant);
			node.measurePolicy = Layout.measureColumn;
		}, function(c)
		{
			SearchBar(c, query, "Search chart", null);
			if (suggestions != null)
				for (i in 0...suggestions.length)
				{
					var index = i;
					ListItem(c, suggestions[i], null, "?", null, function()
					{
						if (onSelect != null)
							onSelect(index, suggestions[index]);
					});
				}
		});
	}

	public static function Checkbox(composer:Composer, label:String, checked:Bool, onChange:Bool->Void, ?modifier:Modifier):Void
	{
		Row.compose(composer, (modifier != null ? modifier : Modifier.empty()).spacing(8), function(c)
		{
			composer.emit("MD3Checkbox", label, Modifier.empty().size(28, 28).clickable(function()
			{
				if (onChange != null)
					onChange(!checked);
			}), function(node)
			{
				node.setProp("checked", checked);
				node.setProp("onChange", onChange);
				node.measurePolicy = function(n, constraints:Constraints)
					return new MeasureResult(constraints.constrainWidth(28), constraints.constrainHeight(28));
			});
			if (label != null && label.length > 0)
				backend.ui.haxecompose.foundation.Text.compose(c, label, Modifier.empty().clickable(function()
				{
					if (onChange != null)
						onChange(!checked);
				}), 14, MD3Theme.onSurfaceVariant);
		});
	}

	public static function RadioButton(composer:Composer, label:String, selected:Bool, onSelect:Void->Void, ?modifier:Modifier):Void
	{
		Row.compose(composer, (modifier != null ? modifier : Modifier.empty()).spacing(8).clickable(onSelect), function(c)
		{
			composer.emit("MD3RadioButton", label, Modifier.empty().size(28, 28).clickable(onSelect), function(node)
			{
				node.setProp("selected", selected);
				node.measurePolicy = function(n, constraints:Constraints)
					return new MeasureResult(constraints.constrainWidth(28), constraints.constrainHeight(28));
			});
			if (label != null && label.length > 0)
				backend.ui.haxecompose.foundation.Text.compose(c, label, Modifier.empty().paddingXY(0, 5), 14, MD3Theme.onSurfaceVariant);
		});
	}

	public static function Switch(composer:Composer, checked:Bool, onChange:Bool->Void, ?label:String, ?modifier:Modifier):Void
	{
		Row.compose(composer, (modifier != null ? modifier : Modifier.empty()).spacing(10), function(c)
		{
			composer.emit("MD3Switch", label, Modifier.empty().size(52, 32).clickable(function()
			{
				if (onChange != null)
					onChange(!checked);
			}), function(node)
			{
				node.setProp("checked", checked);
				node.setProp("onChange", onChange);
				node.measurePolicy = function(n, constraints:Constraints)
					return new MeasureResult(constraints.constrainWidth(52), constraints.constrainHeight(32));
			});
			if (label != null && label.length > 0)
				backend.ui.haxecompose.foundation.Text.compose(c, label, Modifier.empty().clickable(function()
				{
					if (onChange != null)
						onChange(!checked);
				}), 14, MD3Theme.onSurfaceVariant);
		});
	}

	public static function Slider(composer:Composer, value:Float, min:Float, max:Float, onChange:Float->Void, ?modifier:Modifier):Void
	{
		composer.emit("MD3Slider", null, modifier != null ? modifier : Modifier.empty().width(180), function(node)
		{
			var safeMax = max <= min ? min + 1 : max;
			var normalized = Math.max(0, Math.min(1, (value - min) / (safeMax - min)));
			node.setProp("value", value);
			node.setProp("min", min);
			node.setProp("max", safeMax);
			node.setProp("normalized", normalized);
			node.measurePolicy = function(n, constraints:Constraints)
			{
				var width = n.modifier.fixedWidth != null ? n.modifier.fixedWidth : Math.min(180, constraints.maxWidth);
				return new MeasureResult(constraints.constrainWidth(width), constraints.constrainHeight(28));
			};
			node.modifier = node.modifier.clickable(function()
			{
				if (onChange != null)
					onChange(value >= safeMax ? min : Math.min(safeMax, value + (safeMax - min) * 0.1));
			});
		});
	}

	public static function Progress(composer:Composer, progress:Null<Float> = null, expressive:Bool = false, ?modifier:Modifier):Void
	{
		if (expressive)
			WavyProgressIndicator.compose(composer, progress, modifier);
		else
			composer.emit("MD3Progress", null, modifier != null ? modifier : Modifier.empty().width(180), function(node)
			{
				node.setProp("progress", progress == null ? null : Math.max(0, Math.min(1, progress)));
				node.measurePolicy = function(n, constraints:Constraints)
				{
					var width = n.modifier.fixedWidth != null ? n.modifier.fixedWidth : Math.min(140, constraints.maxWidth);
					return new MeasureResult(constraints.constrainWidth(width), constraints.constrainHeight(6));
				};
			});
	}

	public static function Chip(composer:Composer, label:String, selected:Bool = false, ?onClick:Void->Void, ?modifier:Modifier):Void
	{
		var bg = selected ? MD3Theme.secondaryContainer : MD3Theme.surface;
		var fg = selected ? MD3Theme.onSecondaryContainer : MD3Theme.onSurfaceVariant;
		var chipModifier = (modifier != null ? modifier : Modifier.empty()).paddingXY(12, 7).background(bg, 8).clickable(onClick);
		composer.emit("MD3Chip", label, chipModifier, function(node)
		{
			node.setProp("outlineColor", selected ? FlxColor.TRANSPARENT : MD3Theme.outline);
			node.measurePolicy = Layout.measureBox;
		}, function(c) backend.ui.haxecompose.foundation.Text.compose(c, label, null, 14, fg));
	}

	public static function Badge(composer:Composer, label:String, ?modifier:Modifier):Void
	{
		var badgeModifier = (modifier != null ? modifier : Modifier.empty()).paddingXY(6, 2).background(MD3Theme.error, 999);
		composer.emit("MD3Badge", label, badgeModifier, function(node)
		{
			node.measurePolicy = Layout.measureBox;
		}, function(c) backend.ui.haxecompose.foundation.Text.compose(c, label, null, 11, MD3Theme.onError));
	}

	public static function Toast(composer:Composer, message:String, ?modifier:Modifier):Void
	{
		var toastModifier = (modifier != null ? modifier : Modifier.empty()).paddingXY(16, 10).background(MD3Theme.inverseSurface, 18);
		composer.emit("MD3Toast", message, toastModifier, function(node)
		{
			node.measurePolicy = Layout.measureBox;
		}, function(c) backend.ui.haxecompose.foundation.Text.compose(c, message, null, 13, MD3Theme.inverseOnSurface));
	}

	public static function Banner(composer:Composer, message:String, ?actionLabel:String, ?onAction:Void->Void, ?modifier:Modifier):Void
	{
		var bannerModifier = (modifier != null ? modifier : Modifier.empty()).fillMaxWidth().padding(10).background(MD3Theme.surfaceContainerHigh, 8);
		composer.emit("MD3Banner", message, bannerModifier, function(node)
		{
			node.setProp("outlineColor", MD3Theme.outlineVariant);
			node.measurePolicy = Layout.measureColumn;
		}, function(c)
		{
			backend.ui.haxecompose.foundation.Text.compose(c, message, null, 14, MD3Theme.onSurface);
			if (actionLabel != null && actionLabel.length > 0)
				Button(c, actionLabel, onAction, TextOnly);
		});
	}

	public static function Tooltip(composer:Composer, message:String, ?modifier:Modifier):Void
	{
		var tooltipModifier = (modifier != null ? modifier : Modifier.empty()).paddingXY(10, 6).background(MD3Theme.inverseSurface, 6);
		composer.emit("MD3Tooltip", message, tooltipModifier, function(node)
		{
			node.measurePolicy = Layout.measureBox;
		}, function(c) backend.ui.haxecompose.foundation.Text.compose(c, message, null, 12, MD3Theme.inverseOnSurface));
	}

	public static function Divider(composer:Composer, ?modifier:Modifier):Void
	{
		composer.emit("MD3Divider", null, modifier != null ? modifier : Modifier.empty().fillMaxWidth().height(1), function(node)
		{
			node.measurePolicy = function(n, constraints:Constraints)
			{
				var width = n.modifier.fixedWidth != null ? n.modifier.fixedWidth : constraints.maxWidth;
				var height = n.modifier.fixedHeight != null ? n.modifier.fixedHeight : 1;
				return new MeasureResult(constraints.constrainWidth(width), constraints.constrainHeight(height));
			};
		});
	}

	public static function Tabs(composer:Composer, tabs:Array<String>, selectedIndex:Int, onSelect:Int->String->Void, ?modifier:Modifier):Void
	{
		Row.compose(composer, (modifier != null ? modifier : Modifier.empty()).spacing(4), function(c)
		{
			for (i in 0...tabs.length)
			{
				var index = i;
				Chip(c, tabs[i], i == selectedIndex, function()
				{
					if (onSelect != null)
						onSelect(index, tabs[index]);
				});
			}
		});
	}

	public static function SegmentedButtonRow(composer:Composer, segments:Array<String>, selectedIndex:Int, onSelect:Int->String->Void, ?modifier:Modifier):Void
	{
		Row.compose(composer, (modifier != null ? modifier : Modifier.empty()).spacing(2), function(c)
		{
			for (i in 0...segments.length)
			{
				var index = i;
				Chip(c, segments[i], i == selectedIndex, function()
				{
					if (onSelect != null)
						onSelect(index, segments[index]);
				}, Modifier.empty().paddingXY(10, 6));
			}
		});
	}

	public static function ListItem(composer:Composer, headline:String, ?supportingText:String, ?leadingLabel:String, ?trailingLabel:String,
			?onClick:Void->Void, ?modifier:Modifier):Void
	{
		Row.compose(composer, (modifier != null ? modifier : Modifier.empty()).fillMaxWidth().paddingXY(10, 8).background(MD3Theme.surface, 0).spacing(10)
			.clickable(onClick), function(c)
			{
				if (leadingLabel != null && leadingLabel.length > 0)
					Badge(c, leadingLabel);
				Column.compose(c, Modifier.empty().spacing(2), function(col)
				{
					backend.ui.haxecompose.foundation.Text.compose(col, headline, null, 15, MD3Theme.onSurface);
					if (supportingText != null && supportingText.length > 0)
						backend.ui.haxecompose.foundation.Text.compose(col, supportingText, null, 12, MD3Theme.onSurfaceVariant);
				});
				if (trailingLabel != null && trailingLabel.length > 0)
					backend.ui.haxecompose.foundation.Text.compose(c, trailingLabel, Modifier.empty().paddingXY(0, 8), 12, MD3Theme.onSurfaceVariant);
			});
	}

	public static function Menu(composer:Composer, items:Array<String>, onSelect:Int->String->Void, ?modifier:Modifier):Void
	{
		var menuModifier = (modifier != null ? modifier : Modifier.empty()).padding(6).background(MD3Theme.surfaceContainer, 8);
		composer.emit("MD3Menu", null, menuModifier, function(node)
		{
			node.setProp("outlineColor", MD3Theme.outlineVariant);
			node.measurePolicy = Layout.measureColumn;
		}, function(c)
		{
			for (i in 0...items.length)
			{
				var index = i;
				ListItem(c, items[i], null, null, null, function()
				{
					if (onSelect != null)
						onSelect(index, items[index]);
				});
			}
		});
	}

	public static function AlertDialog(composer:Composer, title:String, text:String, confirmLabel:String, onConfirm:Void->Void, ?dismissLabel:String,
			?onDismiss:Void->Void, ?modifier:Modifier):Void
	{
		var dialogModifier = (modifier != null ? modifier : Modifier.empty()).padding(16).background(MD3Theme.surfaceContainerHigh, 16);
		composer.emit("MD3Dialog", title, dialogModifier, function(node)
		{
			node.setProp("outlineColor", MD3Theme.outlineVariant);
			node.measurePolicy = Layout.measureColumn;
		}, function(c)
		{
			backend.ui.haxecompose.foundation.Text.compose(c, title, null, 18, MD3Theme.onSurface);
			backend.ui.haxecompose.foundation.Text.compose(c, text, null, 14, MD3Theme.onSurfaceVariant);
			Row.compose(c, Modifier.empty().spacing(8), function(row)
			{
				if (dismissLabel != null && dismissLabel.length > 0)
					Button(row, dismissLabel, onDismiss, TextOnly);
				Button(row, confirmLabel, onConfirm, Filled);
			});
		});
	}

	public static function MessageBox(composer:Composer, title:String, message:String, ?actionLabel:String = "OK", ?onAction:Void->Void,
			?modifier:Modifier):Void
	{
		var boxModifier = (modifier != null ? modifier : Modifier.empty()).padding(14).background(MD3Theme.surfaceContainerHighest, 12);
		composer.emit("MD3MessageBox", title, boxModifier, function(node)
		{
			node.setProp("outlineColor", MD3Theme.outlineVariant);
			node.measurePolicy = Layout.measureColumn;
		}, function(c)
		{
			Row.compose(c, Modifier.empty().spacing(8), function(row)
			{
				Icon(row, "info", null, 22, MD3Theme.primary);
				backend.ui.haxecompose.foundation.Text.compose(row, title, null, 16, MD3Theme.onSurface);
			});
			backend.ui.haxecompose.foundation.Text.compose(c, message, null, 13, MD3Theme.onSurfaceVariant);
			Button(c, actionLabel, onAction, TextOnly);
		});
	}

	public static function DatePicker(composer:Composer, label:String, value:String, onPrevious:Void->Void, onNext:Void->Void, ?modifier:Modifier):Void
	{
		var pickerModifier = (modifier != null ? modifier : Modifier.empty()).padding(10).background(MD3Theme.surfaceContainer, 10);
		composer.emit("MD3DatePicker", value, pickerModifier, function(node)
		{
			node.setProp("outlineColor", MD3Theme.outlineVariant);
			node.measurePolicy = Layout.measureColumn;
		}, function(c)
		{
			backend.ui.haxecompose.foundation.Text.compose(c, label, null, 12, MD3Theme.onSurfaceVariant);
			Row.compose(c, Modifier.empty().spacing(8), function(row)
			{
				IconButton(row, "chevron_left", onPrevious);
				backend.ui.haxecompose.foundation.Text.compose(row, value, Modifier.empty().paddingXY(4, 8), 16, MD3Theme.onSurface);
				IconButton(row, "chevron_right", onNext);
			});
		});
	}

	public static function TimePicker(composer:Composer, label:String, value:String, onPrevious:Void->Void, onNext:Void->Void, ?modifier:Modifier):Void
	{
		var pickerModifier = (modifier != null ? modifier : Modifier.empty()).padding(10).background(MD3Theme.surfaceContainer, 10);
		composer.emit("MD3TimePicker", value, pickerModifier, function(node)
		{
			node.setProp("outlineColor", MD3Theme.outlineVariant);
			node.measurePolicy = Layout.measureColumn;
		}, function(c)
		{
			backend.ui.haxecompose.foundation.Text.compose(c, label, null, 12, MD3Theme.onSurfaceVariant);
			Row.compose(c, Modifier.empty().spacing(8), function(row)
			{
				IconButton(row, "remove", onPrevious);
				backend.ui.haxecompose.foundation.Text.compose(row, value, Modifier.empty().paddingXY(4, 8), 16, MD3Theme.onSurface);
				IconButton(row, "add", onNext);
			});
		});
	}

	public static function Carousel(composer:Composer, items:Array<String>, selectedIndex:Int, onSelect:Int->String->Void, ?modifier:Modifier):Void
	{
		var carouselModifier = (modifier != null ? modifier : Modifier.empty()).fillMaxWidth().padding(8).background(MD3Theme.surfaceContainerLow, 12);
		composer.emit("MD3Carousel", null, carouselModifier, function(node)
		{
			node.measurePolicy = Layout.measureBox;
		}, function(c)
		{
			Row.compose(c, Modifier.empty().spacing(6), function(row)
			{
				if (items != null)
					for (i in 0...items.length)
					{
						var index = i;
						Chip(row, items[i], i == selectedIndex, function()
						{
							if (onSelect != null)
								onSelect(index, items[index]);
						});
					}
			});
		});
	}

	public static function PullToRefresh(composer:Composer, refreshing:Bool, onRefresh:Void->Void, ?modifier:Modifier):Void
	{
		var refreshModifier = (modifier != null ? modifier : Modifier.empty()).fillMaxWidth().paddingXY(12, 8).background(MD3Theme.surfaceContainer, 12)
			.clickable(onRefresh);
		composer.emit("MD3PullToRefresh", null, refreshModifier, function(node)
		{
			node.measurePolicy = Layout.measureBox;
		}, function(c)
		{
			Row.compose(c, Modifier.empty().spacing(8), function(row)
			{
				Icon(row, refreshing ? "sync" : "refresh", null, 20, MD3Theme.primary);
				backend.ui.haxecompose.foundation.Text.compose(row, refreshing ? "Refreshing..." : "Pull to refresh", null, 14, MD3Theme.onSurface);
			});
		});
	}

	public static function RichTooltip(composer:Composer, title:String, text:String, ?actionLabel:String, ?onAction:Void->Void, ?modifier:Modifier):Void
	{
		var tooltipModifier = (modifier != null ? modifier : Modifier.empty()).padding(12).background(MD3Theme.inverseSurface, 8);
		composer.emit("MD3RichTooltip", title, tooltipModifier, function(node)
		{
			node.measurePolicy = Layout.measureColumn;
		}, function(c)
		{
			backend.ui.haxecompose.foundation.Text.compose(c, title, null, 14, MD3Theme.inverseOnSurface);
			backend.ui.haxecompose.foundation.Text.compose(c, text, null, 12, MD3Theme.inverseOnSurface);
			if (actionLabel != null && actionLabel.length > 0)
				Button(c, actionLabel, onAction, TextOnly);
		});
	}

	public static function BottomAppBar(composer:Composer, actions:Array<String>, ?fabIcon:String, ?onAction:Int->String->Void, ?onFab:Void->Void,
			?modifier:Modifier):Void
	{
		var barModifier = (modifier != null ? modifier : Modifier.empty()).fillMaxWidth().paddingXY(10, 8).background(MD3Theme.surfaceContainer, 18);
		composer.emit("MD3BottomAppBar", null, barModifier, function(node)
		{
			node.measurePolicy = Layout.measureBox;
		}, function(c)
		{
			Row.compose(c, Modifier.empty().spacing(8), function(row)
			{
				if (actions != null)
					for (i in 0...actions.length)
					{
						var index = i;
						IconButton(row, actions[i], function()
						{
							if (onAction != null)
								onAction(index, actions[index]);
						});
					}
				if (fabIcon != null && fabIcon.length > 0)
					FloatingActionButton(row, "", onFab, Modifier.empty().paddingXY(12, 10), fabIcon);
			});
		});
	}

	public static function NavigationRail(composer:Composer, items:Array<String>, selectedIndex:Int, onSelect:Int->String->Void, ?modifier:Modifier):Void
	{
		var railModifier = (modifier != null ? modifier : Modifier.empty()).padding(8).background(MD3Theme.surfaceContainer, 18);
		composer.emit("MD3NavigationRail", null, railModifier, function(node)
		{
			node.measurePolicy = Layout.measureColumn;
		}, function(c)
		{
			if (items != null)
				for (i in 0...items.length)
				{
					var index = i;
					var selected = i == selectedIndex;
					IconButton(c, items[i], function()
					{
						if (onSelect != null)
							onSelect(index, items[index]);
					}, Modifier.empty().background(selected ? MD3Theme.secondaryContainer : FlxColor.TRANSPARENT, 18));
				}
		});
	}

	public static function NavigationDrawer(composer:Composer, items:Array<String>, selectedIndex:Int, onSelect:Int->String->Void, ?modifier:Modifier):Void
	{
		var drawerModifier = (modifier != null ? modifier : Modifier.empty()).padding(8).background(MD3Theme.surfaceContainerLow, 12);
		composer.emit("MD3NavigationDrawer", null, drawerModifier, function(node)
		{
			node.measurePolicy = Layout.measureColumn;
		}, function(c)
		{
			if (items != null)
				for (i in 0...items.length)
				{
					var index = i;
					ListItem(c, items[i], null, i == selectedIndex ? "ON" : null, null, function()
					{
						if (onSelect != null)
							onSelect(index, items[index]);
					});
				}
		});
	}

	public static function ModalBottomSheet(composer:Composer, ?modifier:Modifier, ?content:Composable):Void
	{
		var sheetModifier = (modifier != null ? modifier : Modifier.empty()).fillMaxWidth().padding(12).background(MD3Theme.surfaceContainerHigh, 18);
		composer.emit("MD3BottomSheet", null, sheetModifier, function(node)
		{
			node.setProp("outlineColor", MD3Theme.outlineVariant);
			node.measurePolicy = Layout.measureBox;
		}, function(c)
		{
			Column.compose(c, Modifier.empty().spacing(8), function(col)
			{
				Surface(col, Modifier.empty().width(36).height(4), MD3Theme.outlineVariant, 2);
				if (content != null)
					content(col);
			});
		});
	}

	public static function NavigationBar(composer:Composer, items:Array<String>, selectedIndex:Int, onSelect:Int->String->Void, ?modifier:Modifier):Void
	{
		Row.compose(composer, (modifier != null ? modifier : Modifier.empty()).fillMaxWidth().paddingXY(8, 6).background(MD3Theme.surfaceContainer, 8).spacing(4),
			function(c)
			{
				for (i in 0...items.length)
				{
					var index = i;
					Chip(c, items[i], i == selectedIndex, function()
					{
						if (onSelect != null)
							onSelect(index, items[index]);
					});
				}
			});
	}

	public static function Snackbar(composer:Composer, message:String, ?actionLabel:String, ?onAction:Void->Void, ?modifier:Modifier):Void
	{
		Row.compose(composer, (modifier != null ? modifier : Modifier.empty()).paddingXY(16, 12).background(MD3Theme.inverseSurface, 8).spacing(12), function(c)
		{
			backend.ui.haxecompose.foundation.Text.compose(c, message, null, 14, MD3Theme.inverseOnSurface);
			if (actionLabel != null && actionLabel.length > 0)
				Button(c, actionLabel, onAction, TextOnly);
		});
	}

	public static function Scaffold(composer:Composer, ?modifier:Modifier, ?topBar:Composable, ?content:Composable):Void
	{
		Column.compose(composer, (modifier != null ? modifier : Modifier.empty()).fillMaxWidth(), function(c)
		{
			if (topBar != null)
				topBar(c);
			if (content != null)
				content(c);
		});
	}

	static function buttonColors(style:ButtonStyle):{container:FlxColor, content:FlxColor}
	{
		return switch (style)
		{
			case Filled:
				{container: MD3Theme.primary, content: MD3Theme.onPrimary};
			case Tonal:
				{container: MD3Theme.secondaryContainer, content: MD3Theme.onSecondaryContainer};
			case Outlined, TextOnly:
				{container: FlxColor.TRANSPARENT, content: MD3Theme.primary};
		}
	}
}
