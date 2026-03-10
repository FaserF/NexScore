allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val compileSdkVersion = 35
val minSdkVersion = 21
val targetSdkVersion = 35

subprojects {
    project.extra["compileSdkVersion"] = compileSdkVersion
    project.extra["minSdkVersion"] = minSdkVersion
    project.extra["targetSdkVersion"] = targetSdkVersion
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
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
