import AVFoundation

class SpeechManager: NSObject, AVSpeechSynthesizerDelegate {
    
    static let shared = SpeechManager()
    
    // El sintetizador
    private let synthesizer = AVSpeechSynthesizer()
    
    // [CORRECCIÓN] En lugar de delegate, usamos una variable simple para guardar la acción
    var alTerminarDeHablar: (() -> Void)?
    
    override init() {
        super.init()
        synthesizer.delegate = self // Conectamos el delegado interno
    }
    
    func speak(text: String, forceStopPrevious: Bool = true) {
        
        // 1. Configuración de Audio (Playback)
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, options: .duckOthers)
            try audioSession.setActive(true)
        } catch {
            print("Error audio session: \(error)")
        }
        
        // 2. Interrupción limpia
        if synthesizer.isSpeaking && forceStopPrevious {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        // 3. Creación de la frase
        let utterance = AVSpeechUtterance(string: text)
        
        // 4. Buscar voz mejorada (Enhanced) en Español MX
        let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == "es-MX" }
        if let enhancedVoice = voices.first(where: { $0.quality == .enhanced }) {
            utterance.voice = enhancedVoice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "es-MX")
        }
        
        // 5. Ajustes
        utterance.rate = 0.52
        utterance.pitchMultiplier = 1.0
        
        synthesizer.speak(utterance)
    }
    
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
    
    // Detectar cuando termina de hablar
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("SpeechManager: Terminé de hablar.")
        // [CORRECCIÓN] Ejecutamos la acción guardada
        alTerminarDeHablar?()
    }
}
