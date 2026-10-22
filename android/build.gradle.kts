allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://storage.googleapis.com/download.flutter.io")
        }
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
    project.evaluationDependsOn(":app")
}

subprojects {
    if (project.name == "agora_rtc_engine" || project.name == "iris_method_channel") {
        afterEvaluate {
            val android = project.extensions.findByName("android")
            if (android != null) {
                for (method in android.javaClass.methods) {
                    if (method.name in listOf("setCompileSdk", "setCompileSdkVersion", "compileSdkVersion")) {
                        if (method.parameterTypes.size == 1) {
                            try {
                                if (method.parameterTypes[0] == Int::class.javaPrimitiveType || method.parameterTypes[0] == java.lang.Integer::class.java) {
                                    method.invoke(android, 35)
                                }
                            } catch (_: Throwable) {
                            }
                        }
                    }
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

