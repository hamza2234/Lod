package com.ludonova.host

import org.godotengine.godot.GodotActivity

/**
 * Kotlin stays as the Android host only.
 *
 * The lobby, login, game board, dice market, dice roll, and animations are all
 * implemented in the Godot project copied into Android assets at build time.
 */
class MainActivity : GodotActivity()
