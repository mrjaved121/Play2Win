# Flutter's Dart AOT code (libapp.so) is unaffected by R8 — these rules only
# cover the Android/Kotlin plugin glue layer. Most plugins ship their own
# consumer-rules.pro (merged automatically), so this stays minimal; add
# specific -keep rules here if a release build ever crashes where debug
# doesn't (usually a plugin using reflection R8 stripped).
