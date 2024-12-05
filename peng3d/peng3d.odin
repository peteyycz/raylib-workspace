package main

import "core:fmt"
import rl "vendor:raylib"

WINDOW_SIZE :: 700

Player :: struct {
	position: rl.Vector3,
}

FLOOR_OFFSET :: 0.5

render_player :: proc(player: ^Player) {
	rot_vector := rl.Vector3{0, 0, 1}
	rl.DrawCylinderEx(
		FLOOR_OFFSET + player.position,
		FLOOR_OFFSET + player.position + rot_vector,
		1,
		1,
		30,
		rl.PURPLE,
	)
	rl.DrawCylinderWiresEx(
		FLOOR_OFFSET + player.position,
		FLOOR_OFFSET + player.position + rot_vector,
		1,
		1,
		30,
		rl.DARKPURPLE,
	)
}

move_player :: proc(player: ^Player, speed: rl.Vector3) {
	player.position += speed
}

player: Player

current_time: f32 = 0
previous_time: f32 = 0
delta_time: f32 = 0


handle_movement :: proc() -> rl.Vector3 {
	movement := rl.Vector3{0, 0, 0}
	if rl.IsKeyDown(.W) {
		movement += {-0.1, 0, 0}
	}
	if rl.IsKeyDown(.A) {
		movement += {0, -0.1, 0}
	}
	if rl.IsKeyDown(.S) {
		movement += {0.1, 0, 0}
	}
	if rl.IsKeyDown(.D) {
		movement += {0, 0.1, 0}
	}

	return movement
}

draw_axis_lines :: proc(start_position: rl.Vector3, length: f32 = 10) {
	// X-axis (Red)
	rl.DrawLine3D(start_position, start_position + rl.Vector3{length, 0, 0}, rl.RED)
	// Y-axis (Green)
	rl.DrawLine3D(start_position, start_position + rl.Vector3{0, length, 0}, rl.GREEN)
	// Z-axis (Blue)
	rl.DrawLine3D(start_position, start_position + rl.Vector3{0, 0, length}, rl.BLUE)
}

// Custom grid drawing function for X-Z plane
draw_xy_grid :: proc(slices: int, spacing: f32) {
	// Draw vertical lines (X-axis lines)
	for i in -slices ..= slices {
		x := f32(i) * spacing
		rl.DrawLine3D(
			rl.Vector3{x, -f32(slices) * spacing, 0}, // Start point
			rl.Vector3{x, f32(slices) * spacing, 0}, // End point
			rl.LIGHTGRAY,
		)
	}

	// Draw horizontal lines (Y-axis lines)
	for i in -slices ..= slices {
		y := f32(i) * spacing
		rl.DrawLine3D(
			rl.Vector3{-f32(slices) * spacing, y, 0}, // Start point
			rl.Vector3{f32(slices) * spacing, y, 0}, // End point
			rl.LIGHTGRAY,
		)
	}
}

clamp_vector3 :: proc(min, max: f32, v: rl.Vector3) -> rl.Vector3 {
	return {clamp(v.x, min, max), clamp(v.y, min, max), clamp(v.z, min, max)}
}

main :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT})
	rl.InitWindow(WINDOW_SIZE, WINDOW_SIZE, "Peng3d")
	rl.SetTargetFPS(60)

	player = Player {
		position = {0, 0, 0},
	}

	camera := rl.Camera3D {
		position   = {55, 2, 50},
		target     = {0, 0, 0},
		up         = {0, 0, 1},
		fovy       = 45,
		projection = .PERSPECTIVE,
	}

	current_time = f32(rl.GetTime())
	delta_time = current_time - previous_time
	previous_time = current_time

	friction := f32(-0.05)
	speed := rl.Vector3{0, 0, 0}

	for !rl.WindowShouldClose() {
		// rl.UpdateCamera(&camera, .FREE)
		rl.BeginDrawing()
		defer rl.EndDrawing()
		rl.ClearBackground(rl.RAYWHITE)

		speed = clamp_vector3(-1, 1, speed + handle_movement() * delta_time)
		speed += speed * friction

		move_player(&player, speed)

		// 3D Scene
		rl.BeginMode3D(camera)

		draw_xy_grid(100, 1.0)

		place := rl.Vector3{0, 0, 0}
		size := rl.Vector3{50, 50, FLOOR_OFFSET * 2}
		rl.DrawCube(place, size.x, size.y, size.z, rl.GRAY)
		rl.DrawCubeWires(place, size.x, size.y, size.z, rl.DARKGRAY)
		draw_axis_lines({1, 1, 1})

		render_player(&player)

		rl.EndMode3D()

		// Developer tools
		rl.DrawFPS(10, 10)
	}

	rl.CloseWindow()
}
