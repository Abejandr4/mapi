import AVFoundation

class SpeechManager: NSObject, AVSpeechSynthesizerDelegate {
    
    static let shared = SpeechManager()
    private let synthesizer = AVSpeechSynthesizer()
    var alTerminarDeHablar: (() -> Void)?
    
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    func speak(text: String) {
        // 1. OBLIGATORIO: Configurar la sesión de audio para que suene fuerte
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // .playback asegura que suene incluso si el interruptor de silencio está activado
            try audioSession.setCategory(.playback, mode: .default, options: .duckOthers)
            try audioSession.setActive(true)
        } catch {
            print("❌ Error configurando audio: \(error)")
        }
        
        // 2. Detener si ya estaba hablando algo
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        // 3. Crear la voz
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Monica-compact")
        utterance.rate = 0.5
        utterance.volume = 1.0 // Volumen máximo
        for voice in AVSpeechSynthesisVoice.speechVoices() {
            print("\(voice.identifier) — \(voice.name) — \(voice.language)")
        }


        synthesizer.speak(utterance)
    }
    
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
    
    // Delegado: Cuando termina de hablar
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        // Desactivamos la sesión para ahorrar batería y limpiar estado
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        alTerminarDeHablar?()
    }
}
