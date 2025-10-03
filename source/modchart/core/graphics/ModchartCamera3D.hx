package modchart.core.graphics;

import flixel.FlxG;
import openfl.Vector;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;

/**
 * `FlxCamera3D` extends `FlxCamera` to provide basic 3D camera functionality,
 * including transformations for position, rotation, and movement in 3D space.
 *
 * Features:
 * - 3D position (`eyePos`) and target (`lookAt`).
 * - View matrix transformation for rendering.
 * - Support for pitch, yaw, and roll rotations.
 * - Camera movement functions (`moveForward`, `moveRight`, `moveUp`).
 * 
 * `NOTE`: All of those features only work on `FlxSprite3D` instances.
 */
class ModchartCamera3D {
	/**
	 * Represents the depth (Z-axis position) of the camera position.
	 */
	public var z:Float;

	/**
	 * The position of the camera (viewpoint) in world coordinates.
	 * 
	 * This represents the location of the viewer in 3D space.
	 * The camera will be positioned at this point and will look toward `lookAt`.
	 * Default: (0, 0, -10), meaning the camera starts 10 units back along the Z-axis.
	 */
	public var eyePos(default, null):Vector3D = new Vector3D(0, 0, -10);

	/**
	 * The target position that the camera is looking at.
	 * 
	 * This point determines the direction the camera is facing.
	 * The view matrix is calculated based on the vector from `eyePos` to `lookAt`.
	 * Default: (0, 0, 0), meaning the camera looks toward the origin.
	 */
	public var lookAt(default, null):Vector3D = new Vector3D(0, 0, 0);

	/**
	 * The up direction vector, defining the camera's vertical orientation.
	 * 
	 * This vector determines which direction is considered "up" for the camera.
	 * It is typically set to (0, 1, 0) to align with the Y-axis, but can be modified
	 * for custom orientations (e.g., to simulate a tilted horizon).
	 */
	public var up(default, null):Vector3D = new Vector3D(0, 1, 0);

	/**
	 * Rotation around the X-axis, controlling the tilt up/down.
	 * 
	 * - Positive values tilt the camera downward.
	 * - Negative values tilt the camera upward.
	 * - Expressed in degrees.
	 */
	public var pitch:Float = 0;

	/**
	 * Rotation around the Y-axis, controlling the left/right turn.
	 * 
	 * - Positive values turn the camera to the right.
	 * - Negative values turn the camera to the left.
	 * - Expressed in degrees.
	 */
	public var yaw:Float = 0;

	/**
	 * Rotation around the Z-axis, controlling the tilt sideways (roll).
	 * 
	 * - Positive values tilt the camera clockwise.
	 * - Negative values tilt the camera counterclockwise.
	 * - Expressed in degrees.
	 */
	public var roll:Float = 0;

	@:noCompletion private var __viewMatrix(default, null):Matrix3D = new Matrix3D();
	@:noCompletion private var __rotationMatrix(default, null):Matrix3D = new Matrix3D();

	public function new() {}

	/**
	 * Updates the camera's view matrix based on its position and rotation.
	 * 
	 * This function recalculates the `__viewMatrix`, which is used to transform
	 * world coordinates into the camera's local space. It applies rotation transformations 
	 * using the pitch, yaw, and roll angles and computes the final view matrix.
	 * 
	 * Steps:
	 * 1. Resets the `__viewMatrix` and `__rotationMatrix` to identity.
	 * 2. Applies rotation transformations to align the camera's orientation.
	 * 3. Defines the default axis directions (`forward`, `up`, `right`).
	 * 4. Transforms these axes using the rotation matrix.
	 * 5. Computes the camera position in view space.
	 * 6. Constructs the view matrix using the transformed axes and camera position.
	 * 
	 * This matrix is essential for rendering objects correctly from the camera's perspective.
	 */
	inline private function updateCameraView() {
		__viewMatrix.identity();
		__rotationMatrix.identity();

		// setup rotations
		__rotationMatrix.appendRotation(pitch * 180 / Math.PI, Vector3D.X_AXIS); // x
		__rotationMatrix.appendRotation(yaw * 180 / Math.PI, Vector3D.Y_AXIS); // y
		__rotationMatrix.appendRotation(roll * 180 / Math.PI, Vector3D.Z_AXIS); // z

		// eye shit
		var forward = Vector3D.Z_AXIS; // depth axis
		var up = Vector3D.Y_AXIS; // y axis
		var right = Vector3D.X_AXIS; // x axis

		// apply rotations
		forward = __rotationMatrix.transformVector(forward);
		up = __rotationMatrix.transformVector(up);
		right = __rotationMatrix.transformVector(right);

		// calc view position
		var negEye = new Vector3D(-eyePos.x, -eyePos.y, -eyePos.z);

		__viewMatrix.rawData = new Vector(16, true, [
			                 right.x,                  up.x,                  forward.x, 0,
			                 right.y,                  up.y,                  forward.y, 0,
			                 right.z,                  up.z,                  forward.z, 0,
			right.dotProduct(negEye), up.dotProduct(negEye), forward.dotProduct(negEye), 1
		]);
	}

	/**
	 * Transforms a given 3D vector from world space to the camera's view space.
	 * 
	 * This function applies the current `__viewMatrix` to the input vector,
	 * converting it from world coordinates to the camera's local coordinate system.
	 * 
	 * @param vector The `Vector3D` representing a point or direction in world space.
	 * @return A new `Vector3D` transformed into the camera's view space.
	 * 
	 * Example usage:
	 * ```haxe
	 * var worldPos = new Vector3D(10, 5, -20);
	 * var viewPos = applyViewTo(worldPos);
	 * ```
	 */
	inline private function applyViewTo(vector:Vector3D, ?origin:Vector3D = null) {
		var reference = origin != null ? origin : eyePos.add(new Vector3D(FlxG.width / 2, FlxG.height / 2));
		return __viewMatrix.transformVector(vector.subtract(reference)).add(reference);
	}

	// some helpers lol
	public function moveForward(amount:Float):Void {
		var forward:Vector3D = lookAt.subtract(eyePos);
		forward.normalize();
		forward.scaleBy(amount);
		eyePos.incrementBy(forward);
		lookAt.incrementBy(forward);
	}

	public function moveRight(amount:Float):Void {
		var right:Vector3D = up.crossProduct(lookAt.subtract(eyePos));
		right.normalize();
		right.scaleBy(amount);
		eyePos.incrementBy(right);
		lookAt.incrementBy(right);
	}

	public function moveUp(amount:Float):Void {
		var moveUp:Vector3D = up.clone();
		moveUp.normalize();
		moveUp.scaleBy(amount);
		eyePos.incrementBy(moveUp);
		lookAt.incrementBy(moveUp);
	}
}
