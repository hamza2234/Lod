import org.gradle.api.tasks.Sync

plugins {
    id("com.android.application")
}

android {
    namespace = "com.ludonova.host"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.ludonova.host"
        minSdk = 23
        targetSdk = 36
        versionCode = 1
        versionName = "0.1.0"
    }
}

val syncGodotProject by tasks.registering(Sync::class) {
    description = "Copies the Godot game project into Android assets."
    from(rootProject.layout.projectDirectory.dir("../godot-dice-preview")) {
        exclude(".godot/**")
        exclude("README.md")
    }
    into(layout.projectDirectory.dir("src/main/assets"))
}

tasks.matching { it.name.startsWith("pre") && it.name.endsWith("Build") }.configureEach {
    dependsOn(syncGodotProject)
}

dependencies {
    implementation("org.godotengine:godot:4.4.1.stable")
}
