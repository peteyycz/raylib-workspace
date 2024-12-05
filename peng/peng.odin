package main

import "core:fmt"
import math "core:math"
import rl "vendor:raylib"


WINDOW_SIZE :: 700
GRID_WIDTH :: 20
CELL_SIZE :: 16
CANVAS_SIZE :: GRID_WIDTH * CELL_SIZE

tick_rate := f32(0.1)

Vec2i :: [2]int
MAX_SNAKE_LENGTH :: GRID_WIDTH * GRID_WIDTH

snake: [MAX_SNAKE_LENGTH]Vec2i
snake_length: int
tick_timer: f32 = tick_rate
move_direction: Vec2i
game_over: bool

food_pos: Vec2i

place_food :: proc() {
	occupied: [GRID_WIDTH][GRID_WIDTH]bool
	for bodypart in snake {
		occupied[bodypart.x][bodypart.y] = true
	}

	free_cells := make([dynamic]Vec2i, context.temp_allocator)
	for x in 0 ..< len(occupied) {
		for y in 0 ..< len(occupied[x]) {
			if !occupied[x][y] {
				append(&free_cells, Vec2i{x, y})
			}
		}
	}

	if len(free_cells) > 0 {
		random_cell_index := rl.GetRandomValue(0, i32(len(free_cells)) - 1)
		food_pos = free_cells[random_cell_index]
	}
}

restart :: proc() {
	game_over = false
	tick_rate = 0.1
	start_head_position := Vec2i{GRID_WIDTH / 2, GRID_WIDTH / 2}
	move_direction = {0, 1}
	snake_length = 3
	for i in 0 ..< snake_length {
		snake[i] = start_head_position - i * move_direction
	}
	place_food()
}

main :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT})
	rl.InitWindow(WINDOW_SIZE, WINDOW_SIZE, "Peng")
	rl.InitAudioDevice()

	restart()
	food_sprite := rl.LoadTexture("assets/food.png")
	head_sprite := rl.LoadTexture("assets/head.png")
	body_sprite := rl.LoadTexture("assets/body.png")
	tail_sprite := rl.LoadTexture("assets/tail.png")

	eat_sound := rl.LoadSound("assets/eat.wav")
	crash_sound := rl.LoadSound("assets/crash.wav")

	for !rl.WindowShouldClose() {
		if game_over {
			if rl.IsKeyDown(.ENTER) {
				restart()
			}
		} else {
			tick_timer -= rl.GetFrameTime()
		}

		if rl.IsKeyDown(.UP) {
			move_direction = {0, -1}
		}
		if rl.IsKeyDown(.DOWN) {
			move_direction = {0, 1}
		}
		if rl.IsKeyDown(.LEFT) {
			move_direction = {-1, 0}
		}
		if rl.IsKeyDown(.RIGHT) {
			move_direction = {1, 0}
		}

		if tick_timer <= 0 {
			next_part_pos := snake[0]
			defer tick_timer += tick_rate

			snake[0] += move_direction
			head_pos := snake[0]

			if head_pos == food_pos {
				rl.PlaySound(eat_sound)
				snake_length += 1
				place_food()
				tick_rate -= 0.005
			}

			if head_pos.x < 0 ||
			   head_pos.y < 0 ||
			   head_pos.x >= GRID_WIDTH ||
			   head_pos.y >= GRID_WIDTH {
				rl.PlaySound(crash_sound)
				game_over = true
			}

			for i in 1 ..< snake_length {
				if head_pos == snake[i] {
					rl.PlaySound(crash_sound)
					game_over = true
				}
				cur_pos := snake[i]
				snake[i] = next_part_pos
				next_part_pos = cur_pos
			}

		}


		rl.BeginDrawing()
		rl.ClearBackground({76, 83, 83, 255})

		camera := rl.Camera2D {
			zoom = f32(WINDOW_SIZE) / CANVAS_SIZE,
		}
		rl.BeginMode2D(camera)

		rl.DrawTextureV(food_sprite, {f32(food_pos.x), f32(food_pos.y)} * CELL_SIZE, rl.WHITE)

		for i in 0 ..< snake_length {
			part_sprite := body_sprite
			direction: Vec2i
			if i == 0 {
				part_sprite = head_sprite
				direction = snake[i] - snake[i + 1]
			} else if i == snake_length - 1 {
				part_sprite = tail_sprite
				direction = snake[i - 1] - snake[i]
			} else {
				direction = snake[i - 1] - snake[i]
			}

			rot := math.atan2(f32(direction.y), f32(direction.x)) * math.DEG_PER_RAD

			source := rl.Rectangle{0, 0, f32(part_sprite.width), f32(part_sprite.height)}
			dest := rl.Rectangle {
				f32(snake[i].x) * CELL_SIZE + 0.5 * CELL_SIZE,
				f32(snake[i].y) * CELL_SIZE + 0.5 * CELL_SIZE,
				CELL_SIZE,
				CELL_SIZE,
			}
			rl.DrawTexturePro(
				part_sprite,
				source,
				dest,
				{CELL_SIZE, CELL_SIZE} * 0.5,
				rot,
				rl.WHITE,
			)
		}


		if (game_over) {
			rl.DrawText("Game Over!", 4, 4, 25, rl.RED)
			rl.DrawText("Press ENTER to restart!", 4, 30, 21, rl.BLACK)
		}


		score := snake_length - 3
		score_str := fmt.ctprintf("Score: %v", score)
		rl.DrawText(score_str, 4, CANVAS_SIZE - 14, 10, rl.GRAY)

		rl.EndMode2D()
		rl.EndDrawing()

		free_all(context.temp_allocator)
	}

	rl.UnloadTexture(head_sprite)
	rl.UnloadTexture(food_sprite)
	rl.UnloadTexture(body_sprite)
	rl.UnloadTexture(tail_sprite)

	rl.CloseWindow()
}
