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
    afterEvaluate {
        val extension = extensions.findByName("android")
        if (extension != null) {
            try {
                val namespaceMethod = extension.javaClass.getMethod("getNamespace")
                val currentNamespace = namespaceMethod.invoke(extension)
                if (currentNamespace == null) {
                    val dynamicNamespace = "com.example.${project.name.replace(":", "").replace("-", "")}"
                    println("[AGP Namespace Fix] Injecting namespace '$dynamicNamespace' for subproject '${project.name}'")
                    val setNamespaceMethod = extension.javaClass.getMethod("setNamespace", String::class.java)
                    setNamespaceMethod.invoke(extension, dynamicNamespace)
                }
            } catch (e: Exception) {
                println("[AGP Namespace Fix] Failed to set namespace for '${project.name}': $e")
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
