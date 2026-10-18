allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    if (project.name == "flutter_quick_video_encoder") {
        afterEvaluate {
            val extension = project.extensions.findByName("android")
            if (extension != null) {
                try {
                    val compileSdkProperty = extension.javaClass.getMethod("setCompileSdk", Int::class.java)
                    compileSdkProperty.invoke(extension, 34)
                } catch (e: Exception) {
                    try {
                        val compileSdkVerProperty = extension.javaClass.getMethod("setCompileSdkVersion", Int::class.java)
                        compileSdkVerProperty.invoke(extension, 34)
                    } catch (ignored: Exception) {}
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
