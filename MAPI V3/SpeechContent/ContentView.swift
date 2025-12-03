import SwiftUI
import MapKit

// Ya no necesitamos las structs 'City' ni 'CountryInfo' aquí,
// porque TODO viene de PaisesData.swift

struct CityInfoCard: View {
    let pais: PaisInfo
    @Binding var showInfo: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            
            // --- CONTENIDO PRINCIPAL ---
            VStack(spacing: 0) {
                
                // 1. HEADER (Bandera y Nombre)
                VStack(spacing: 5) {
                    Text(pais.bandera)
                        .font(.system(size: 80))
                        .shadow(radius: 5)
                    
                    Text(pais.nombre)
                        .font(.largeTitle) // Letra más grande y legible
                        .fontWeight(.heavy)
                        .foregroundColor(.primary)
                }
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                Divider() // Línea separadora
                
                // 2. INFORMACIÓN CON SCROLL (Para que no se amontone)
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 15) {
                        
                        // Sección: Descripción
                        InfoSection(icono: "book.fill", titulo: "Historia", texto: pais.descripcionGeneral)
                        
                        // Sección: Cultura
                        InfoSection(icono: "paintpalette.fill", titulo: "Cultura", texto: pais.cultura)
                        
                        // Sección: Dato Curioso
                        if let dato = pais.datosCuriosos.first {
                            InfoSection(icono: "lightbulb.fill", titulo: "Dato Curioso", texto: dato, colorIcono: .yellow)
                        }
                        
                        Divider()
                        
                        // Datos Extra (Población y Continente)
                        HStack(alignment: .center, spacing: 20) {
                            DataPill(icono: "globe", texto: pais.continent)
                            DataPill(icono: "person.3.fill", texto: "\(pais.population.formatted()) hab.")
                        }
                        .padding(.top, 5)
                        
                    }
                    .padding(20)
                }
            }
            
            // --- BOTÓN CERRAR (Flotante en la esquina) ---
            Button(action: {
                withAnimation {
                    showInfo = false
                    SpeechManager.shared.stop()
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.gray.opacity(0.8))
                    .background(Circle().fill(Color.white).padding(2)) // Fondo blanco para que resalte
                    .shadow(radius: 3)
            }
            .padding(15)
        }
        // Diseño de la Tarjeta (Glassmorphism)
        .frame(width: 350, height: 550) // Un poco más grande
        .background(.regularMaterial) // Efecto vidrio esmerilado
        .cornerRadius(30)
        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(.white.opacity(0.4), lineWidth: 1)
        )
        .padding()
    }
}

// --- COMPONENTES AUXILIARES PARA ORDENAR EL CÓDIGO ---

// Sub-vista para las secciones de texto (Historia, Cultura, etc)
struct InfoSection: View {
    let icono: String
    let titulo: String
    let texto: String
    var colorIcono: Color = .blue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Image(systemName: icono)
                    .foregroundColor(colorIcono)
                Text(titulo)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            Text(texto)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true) // Evita que se corte el texto
        }
    }
}

// Sub-vista para las pastillas de datos (Población/Continente)
struct DataPill: View {
    let icono: String
    let texto: String
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icono)
            Text(texto)
                .font(.caption)
                .fontWeight(.bold)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(20)
    }
}

struct ContentView: View {
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedPais: PaisInfo? = nil // [CAMBIO] Usamos PaisInfo
    @State private var showInfo = false
    @State private var estadoTexto: String = "Toca el micro..."
    @State private var estaEscuchando = false

    // [CAMBIO IMPORTANTE]
    // BORRAMOS 'let cities = [...]'
    // Ahora el mapa leerá directo de 'BibliotecaPaises.todosLosPaises'

    func iniciarInteraccion() {
        if estaEscuchando {
            VoiceInputManager.shared.stopListening()
            estaEscuchando = false
            estadoTexto = "Pausa."
        } else {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            SpeechManager.shared.stop()
            estadoTexto = "Te escucho..."
            estaEscuchando = true
            
            VoiceInputManager.shared.startListening { resultado in
                self.estadoTexto = resultado
                self.procesarIntencion(textoUsuario: resultado)
            }
        }
    }
    
    func procesarIntencion(textoUsuario: String) {
        // Buscamos DIRECTO en el JSON cargado
        if let paisEncontrado = BibliotecaPaises.buscar(texto: textoUsuario) {
            
            // 1. Mover cámara (Usando lat/long del JSON)
            let newCamera = MapCamera(centerCoordinate: paisEncontrado.coordinate, distance: 2_000_000)
            position = .camera(newCamera)
            
            // 2. Mostrar tarjeta
            selectedPais = paisEncontrado
            showInfo = true
            
            // 3. Hablar
            self.estadoTexto = "Viajando a: \(paisEncontrado.nombre)"
            let dato = paisEncontrado.datosCuriosos.first ?? ""
            let guion = "Aquí está \(paisEncontrado.nombre). \(paisEncontrado.descripcionGeneral). Dato curioso: \(dato)"
            SpeechManager.shared.speak(text: guion)
            
            VoiceInputManager.shared.stopListening()
            estaEscuchando = false
            
        } else {
            self.estadoTexto = "No entendí. Prueba con un país del JSON."
            SpeechManager.shared.speak(text: "No encontré ese país en mi base de datos.")
        }
    }

    var body: some View {
        // [CAMBIO] El mapa itera sobre 'BibliotecaPaises.todosLosPaises'
        // Esto significa que CUALQUIER país que agregues al JSON aparecerá aquí como pin mágico 📍
        Map(position: $position) {
            ForEach(BibliotecaPaises.todosLosPaises) { pais in
                Annotation(pais.nombre, coordinate: pais.coordinate) {
                    Button {
                        let newCamera = MapCamera(centerCoordinate: pais.coordinate, distance: 2_000_000)
                        position = .camera(newCamera)
                        selectedPais = pais
                        showInfo = true
                    } label: {
                        VStack(spacing: 0) {
                            Image(systemName: "mappin").font(.system(size: 30)).foregroundColor(.red)
                            Text(pais.bandera).font(.system(size: 18))
                        }
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControlVisibility(.visible)
        .ignoresSafeArea()
        .overlay(alignment: .bottom) {
            VStack(spacing: 15) {
                if showInfo, let pais = selectedPais {
                    CityInfoCard(pais: pais, showInfo: $showInfo)
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(5)
                } else {
                    Text(estadoTexto)
                        .padding().background(.ultraThinMaterial).cornerRadius(10)
                    
                    Button(action: { iniciarInteraccion() }) {
                        Image(systemName: estaEscuchando ? "waveform" : "mic.fill")
                            .padding(30)
                            .background(estaEscuchando ? Color.red : Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.bottom, 30)
        }
        .onAppear {
            // CARGA CRÍTICA
            BibliotecaPaises.cargarDatos()
            VoiceInputManager.shared.requestAuthorization()
        }
        .animation(.spring(), value: showInfo)
    }
}

#Preview {
    ContentView()
}
