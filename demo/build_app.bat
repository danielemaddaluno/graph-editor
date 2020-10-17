@ECHO OFF

rem Replaced: "main-ui-" --> "graph-editor-demo-"
rem Replaced: "target\classes\com\dlsc\jpackagefx\App.class" --> "target\classes\de\tesis\dynaware\grapheditor\demo\GraphEditorDemo.class"
rem Replaced: "JPackageScriptFX" --> "GraphEditorDemo"
rem Replaced: "com.dlsc.jpackagefx.AppLauncher" --> "de.tesis.dynaware.grapheditor.demo.GraphEditorDemo"
rem Replaced: "src/main/logo/" --> "src/main/resources/de/tesis/dynaware/grapheditor/demo/logo/"
rem Replaced: "JPackageScriptFX" --> "GraphEditorDemo"

rem ------ ENVIRONMENT --------------------------------------------------------
rem The script depends on various environment variables to exist in order to
rem run properly. The java version we want to use, the location of the java
rem binaries (java home), and the project version as defined inside the pom.xml
rem file, e.g. 1.0-SNAPSHOT.
rem
rem PROJECT_VERSION: version used in pom.xml, e.g. 1.0-SNAPSHOT
rem APP_VERSION: the application version, e.g. 1.0.0, shown in "about" dialog

set JAVA_VERSION=14
set MAIN_JAR=graph-editor-demo-%PROJECT_VERSION%.jar

rem Set desired installer type: "app-image" "msi" "exe".
set INSTALLER_TYPE=app-image

rem ------ SETUP DIRECTORIES AND FILES ----------------------------------------
rem Remove previously generated java runtime and installers. Copy all required
rem jar files into the input/libs folder.

IF EXIST target\java-runtime rmdir /S /Q  .\target\java-runtime
IF EXIST target\installer rmdir /S /Q target\installer

xcopy /S /Q target\libs\* target\installer\input\libs\
copy target\%MAIN_JAR% target\installer\input\libs\

rem ------ REQUIRED MODULES ---------------------------------------------------
rem Use jlink to detect all modules that are required to run the application.
rem Starting point for the jdep analysis is the set of jars being used by the
rem application.

echo detecting required modules

"%JAVA_HOME%\bin\jdeps" ^
  -q ^
  --multi-release %JAVA_VERSION% ^
  --ignore-missing-deps ^
  --class-path "target\installer\input\libs\*" ^
  --print-module-deps target\classes\de\tesis\dynaware\grapheditor\demo\GraphEditorDemo.class > temp.txt

set /p detected_modules=<temp.txt

echo detected modules: %detected_modules%

rem ------ MANUAL MODULES -----------------------------------------------------
rem jdk.crypto.ec has to be added manually bound via --bind-services or
rem otherwise HTTPS does not work.
rem
rem See: https://bugs.openjdk.java.net/browse/JDK-8221674

set manual_modules=jdk.crypto.ec,jdk.localedata,javafx.controls
echo manual modules: %manual_modules%

rem ------ RUNTIME IMAGE ------------------------------------------------------
rem Use the jlink tool to create a runtime image for our application. We are
rem doing this is a separate step instead of letting jlink do the work as part
rem of the jpackage tool. This approach allows for finer configuration and also
rem works with dependencies that are not fully modularized, yet.

echo creating java runtime image

call "%JAVA_HOME%\bin\jlink" ^
  --strip-native-commands ^
  --no-header-files ^
  --no-man-pages ^
  --compress=2 ^
  --strip-debug ^
  --add-modules %detected_modules%,%manual_modules% ^
  --output target/java-runtime


rem ------ PACKAGING ----------------------------------------------------------
rem In the end we will find the package inside the target/installer directory.

call "%JAVA_HOME%\bin\jpackage" ^
  --type %INSTALLER_TYPE% ^
  --dest target/installer ^
  --input target/installer/input/libs ^
  --name GraphEditorDemo ^
  --main-class de.tesis.dynaware.grapheditor.demo.GraphEditorDemo ^
  --main-jar %MAIN_JAR% ^
  --java-options -Xmx2048m ^
  --runtime-image target/java-runtime ^
  --icon src/main/resources/de/tesis/dynaware/grapheditor/demo/logo/windows/duke.ico ^
  --app-version %APP_VERSION% ^
  --vendor "ACME Inc." ^
  --copyright "Copyright © 2019-20 ACME Inc."
rem  --win-dir-chooser ^
rem  --win-shortcut ^
rem  --win-per-user-install ^
rem  --win-menu