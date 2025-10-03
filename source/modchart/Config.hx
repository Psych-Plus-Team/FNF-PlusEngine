package modchart;

/**
 * Configuration settings for modchart behavior.
 * 
 * This class contains various static variables that control rendering,
 * performance optimizations, and visual settings for modcharts.
 * Adjust these settings to customize how elements behave and render.
 */
class Config {
	/**
	 * Enables or disables 3D cameras.
	 * 
	 * Setting this to `false` will disable 3D camera functionality, which may improve performance.
	 * When disabled, all 3D-related transformations and rendering will be skipped.
	 * 
	 * Default: `true` (3D cameras enabled).
	 */
	public static var CAMERA3D_ENABLED:Bool = true;

	/**
	 * Defines the order of rotation axes.
	 * 
	 * Determines the sequence in which rotations are applied around the X, Y, and Z axes.
	 * Different orders can produce different final orientations due to rotational dependency.
	 * 
	 * Default: `Z_Y_X` (Rotates around the X-axis last).
	 */
	public static var ROTATION_ORDER:RotationOrder = Z_Y_X;

	/**
	 * Optimizes the rendering of hold arrows.
	 * 
	 * Theoretically, this makes calculations twice as fast by reducing redundant computations.
	 * However, it is not recommended for complex modcharts, as it may cause holds to look incorrect,
	 * especially when rotation or complex paths are applied.
	 * 
	  	 * Default: `false` (Regular hold rendering using the unit circle).
	 */
	public static var OPTIMIZE_HOLDS:Bool = false;

	/**
	 * Scales the Z-axis values.
	 * 
	 * This value is used to multiply the Z coordinate, effectively scaling depth.
	 * A higher value increases the perceived depth, while a lower value flattens it.
	 * 
	 * Default: `1` (No scaling applied).
	 */
	public static var Z_SCALE:Float = 1;

	/**
	 * Ignores or renders the arrow path lines.
	 * 
	 * When enabled, performance will be affected
	 * due to path computation. (and Cairo graphics :sob::sob::sob:)
	 */
	public static var RENDER_ARROW_PATHS:Bool = false;

	/**
	 * Applies the `visuals` function from modifiers to
	 * give the arrow path more style by changing its color,
	 * scale, and alpha.
	 * NOTE: Arrow paths also have thickness and color properties,
	 * but they are not affected by the arrow's alpha and color.
	 */
	public static var STYLED_ARROW_PATHS:Bool = false;

	/**
	 * Scales the hold end size.
	 */
	public static var HOLD_END_SCALE:Float = 1;
}
