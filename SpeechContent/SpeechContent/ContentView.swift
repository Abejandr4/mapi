import SwiftUI

struct ContentView: View {
    
    @State private var estadoTexto: String = "Toca el botón para hablar"
    @State private var estaEscuchando = false
    
    var body: some View {
        VStack(spacing: 40) {
            
            Text("Globo Accesible")
                .font(.largeTitle)
                .bold()
            
            Text(estadoTexto)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .multilineTextAlignment(.center)
            
            // BOTÓN PRINCIPAL (Micrófono)
            Button(action: {
                iniciarInteraccion()
            }) {
                VStack {
                    Image(systemName: estaEscuchando ? "waveform" : "mic.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                    
                    Text(estaEscuchando ? "Escuchando..." : "Hablar")
                        .fontWeight(.bold)
                }
                .padding(30)
                .background(estaEscuchando ? Color.red : Color.blue)
                .foregroundColor(.white)
                .clipShape(Circle())
                .shadow(radius: 10)
            }
            
            // BOTÓN SIMULACIÓN (Pruebas sin hablar)
            Button("🧪 Simular: 'Quiero saber de México'") {
                procesarIntencion(textoUsuario: "méxico")
            }
            .padding()
            .background(Color.green.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(8)
            
        }
        .padding()
        .onAppear {
            BibliotecaPaises.cargarDatos()
                        
                        // 2. Pedir permisos
                        VoiceInputManager.shared.requestAuthorization()
                        
                        // 3. Configurar voz
                        SpeechManager.shared.alTerminarDeHablar = {
                            print("Evento: Terminó de hablar")
            }
        }
    }
    
    func iniciarInteraccion() {
        if estaEscuchando {
            VoiceInputManager.shared.stopListening()
            estaEscuchando = false
            estadoTexto = "Pausa."
        } else {
            // Feedback vibración
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            SpeechManager.shared.stop()
            estadoTexto = "Te escucho..."
            estaEscuchando = true
            
            VoiceInputManager.shared.startListening { resultado in
                self.estadoTexto = resultado
                
                // Si detecta un país, procesamos automáticamente
                if let _ = BibliotecaPaises.buscar(texto: resultado) {
                    VoiceInputManager.shared.stopListening()
                    self.estaEscuchando = false
                    self.procesarIntencion(textoUsuario: resultado)
                }
            }
        }
    }
    
    func procesarIntencion(textoUsuario: String) {
        if let infoPais = BibliotecaPaises.buscar(texto: textoUsuario) {
            self.estadoTexto = "Hablando de: \(infoPais.nombre)"
            let guion = "Viajando a \(infoPais.nombre). \(infoPais.descripcionGeneral). ¿Te gustaría saber un dato curioso?"
            SpeechManager.shared.speak(text: guion)
        } else {
            SpeechManager.shared.speak(text: "No entendí qué país dijiste. Intenta con México o Japón.")
        }
    }
}

#Preview {
    ContentView()
}
