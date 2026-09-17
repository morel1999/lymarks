package app.lymarks.lymarks

import android.content.Intent
import android.os.SystemClock
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Cible du menu de partage Android (PRD F1, SAD M1).
 *
 * Activite distincte de [MainActivity], translucide, sans historique ni
 * entree dans les recents : la capture se fait par-dessus l'app source et
 * n'ouvre jamais Lymarks (UX Bible regle 2). Elle heberge son propre moteur
 * Flutter, lance sur l'entree Dart `shareMain`, qui ne monte que la feuille
 * de capture.
 *
 * Canal natif maison plutot que `receive_sharing_intent` : c'est le plan B
 * du Risk Register R3, et pour Android seul il tient en quelques lignes.
 */
class ShareActivity : FlutterActivity() {
    /** Instant de creation de l'activite : point de depart du chrono "< 2 s". */
    private val openedAt = SystemClock.elapsedRealtime()

    override fun getDartEntrypointFunctionName(): String = "shareMain"

    override fun getBackgroundMode(): BackgroundMode = BackgroundMode.transparent

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getShared" -> result.success(sharedPayload())
                    "close" -> {
                        // Duree entre l'ouverture de l'activite et la fermeture,
                        // rendue a Dart pour la journalisation du budget.
                        result.success(SystemClock.elapsedRealtime() - openedAt)
                        // finish(), jamais finishAndRemoveTask() : selon l'app
                        // source, cette activite peut vivre dans la tache de
                        // l'appelant, qu'il ne faut surtout pas fermer.
                        finish()
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun sharedPayload(): Map<String, Any?>? {
        val i = intent ?: return null
        if (i.action != Intent.ACTION_SEND) return null
        return mapOf(
            "text" to i.getStringExtra(Intent.EXTRA_TEXT),
            "subject" to i.getStringExtra(Intent.EXTRA_SUBJECT),
        )
    }

    companion object {
        const val CHANNEL = "app.lymarks/share"
    }
}
