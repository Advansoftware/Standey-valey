# Regras do R8 (usadas no build "release").
#
# Sem elas, o R8 renomeia as classes do Kotlin (kotlin.coroutines.Continuation,
# por exemplo) e as funções "suspend" dos plugins — como o shared_preferences,
# que usa Pigeon — deixam de ser resolvidas em release. O app abre e quebra na
# hora de ler as preferências.
-keepattributes *Annotation*, InnerClasses, Signature, Exceptions, EnclosingMethod

-keep class kotlin.** { *; }
-keep class kotlinx.coroutines.** { *; }

# plugins do Flutter (o shared_preferences e o motor de IA usam Pigeon)
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.**
-dontwarn kotlin.**
-dontwarn kotlinx.**
