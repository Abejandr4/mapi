import SwiftUI
import MapKit
import CoreLocation
import Speech
import AVFoundation

// ==========================================
// MARK: - 1. VIEW MODEL (Lógica de Mapa y Ubicación)
// ==========================================

final class MapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    // Ruta a dibujar (línea azul)
    @Published var route: MKRoute?
    
    // Look Around (Vista 360)
    @Published var lookAroundScene: MKLookAroundScene?
    @Published var isShowingLookAround = false
    
    // [NUEVO] Variables para manejar errores (Alertas)
    @Published var showAlert = false
    @Published var alertMessage = ""
    
    // Ubicación del usuario
    private var manager: CLLocationManager?
    private var currentUserLocation: CLLocationCoordinate2D?
    
    override init() {
        super.init()
        setupManager()
    }
    
    func setupManager() {
        manager = CLLocationManager()
        manager?.delegate = self
        manager?.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    // Pedir permisos y empezar a rastrear
    func requestPermission() {
        manager?.requestWhenInUseAuthorization()
        manager?.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.currentUserLocation = location.coordinate
    }
    
    // CALCULAR RUTA: Desde Mi Ubicación -> País Destino
    func getDirections(to destination: CLLocationCoordinate2D) async {
        guard let userLocation = currentUserLocation else {
            print("⚠️ No se ha detectado tu ubicación actual.")
            return
        }
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        
        do {
            let response = try await directions.calculate()
            await MainActor.run {
                self.route = response.routes.first
            }
        } catch {
            print("Error calculando ruta: \(error.localizedDescription)")
            // [CORRECCIÓN] Mostramos alerta si no hay carretera
            await MainActor.run {
                self.alertMessage = "No se encontró una ruta terrestre para llegar a este destino (posiblemente hay un océano en medio)."
                self.showAlert = true
            }
        }
    }
    
    // OBTENER VISTA 360 (Look Around)
    func getLookAroundScene(from coordinate: CLLocationCoordinate2D) async {
        do {
            let request = MKLookAroundSceneRequest(coordinate: coordinate)
            let scene = try await request.scene
            
            await MainActor.run {
                self.lookAroundScene = scene
                if scene != nil {
                    self.isShowingLookAround = true
                } else {
                    print("⚠️ Look Around no disponible para esta ubicación.")
                    // [CORRECCIÓN] Mostramos alerta si no hay datos 360
                    self.alertMessage = "La vista 360° (Look Around) no está disponible en esta región."
                    self.showAlert = true
                }
            }
        } catch {
            print("Error buscando escena: \(error.localizedDescription)")
        }
    }
}

// ==========================================
// MARK: - 2. VISTAS DE INTERFAZ (UI)
// ==========================================

// Tarjeta de información del país
struct CityInfoCard: View {
    let pais: PaisInfo // Usa el struct de PaisesData.swift
    @Binding var showInfo: Bool
    
    // Recibimos el ViewModel para ejecutar acciones (Ruta / 360)
    @ObservedObject var viewModel: MapViewModel

    var body: some View {
        ZStack(alignment: .topTrailing) {
            
            VStack(spacing: 0) {
                // HEADER
                VStack(spacing: 5) {
                    Text(pais.bandera)
                        .font(.system(size: 80))
                        .shadow(radius: 5)
                    
                    Text(pais.nombre)
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        .foregroundColor(.primary)
                }
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                Divider()
                
                // INFORMACIÓN SCROLLABLE
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 15) {
                        
                        InfoSection(icono: "book.fill", titulo: "Historia", texto: pais.descripcionGeneral)
                        InfoSection(icono: "paintpalette.fill", titulo: "Cultura", texto: pais.cultura)
                        
                        if let dato = pais.datosCuriosos.first {
                            InfoSection(icono: "lightbulb.fill", titulo: "Dato Curioso", texto: dato, colorIcono: .yellow)
                        }
                        
                        Divider()
                        
                        HStack(alignment: .center, spacing: 20) {
                            DataPill(icono: "globe", texto: pais.continent)
                            DataPill(icono: "person.3.fill", texto: "\(pais.population.formatted()) hab.")
                        }
                        .padding(.top, 5)
                        
                        Divider()
                        
                        // --- BOTONES DE ACCIÓN ---
                        HStack(spacing: 15) {
                            // 1. Botón Ruta
                            Button(action: {
                                Task {
                                    await viewModel.getDirections(to: pais.coordinate)
                                    // Solo cerramos la ficha si SÍ encontró ruta (opcional, aquí lo dejamos abierto para ver el error si falla)
                                    if viewModel.route != nil {
                                        withAnimation { showInfo = false }
                                    }
                                }
                            }) {
                                Label("Ir", systemImage: "car.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(15)
                            }
                            
                            // 2. Botón Look Around 360
                            Button(action: {
                                Task {
                                    await viewModel.getLookAroundScene(from: pais.coordinate)
                                }
                            }) {
                                Label("360°", systemImage: "binoculars.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.orange)
                                    .foregroundColor(.white)
                                    .cornerRadius(15)
                            }
                        }
                        .padding(.top, 10)
                        
                    }
                    .padding(20)
                }
            }
            
            // BOTÓN CERRAR
            Button(action: {
                withAnimation {
                    showInfo = false
                    SpeechManager.shared.stop()
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.gray.opacity(0.8))
                    .background(Circle().fill(Color.white).padding(2))
                    .shadow(radius: 3)
            }
            .padding(15)
        }
        .frame(width: 350, height: 600)
        .background(.regularMaterial)
        .cornerRadius(30)
        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(.white.opacity(0.4), lineWidth: 1)
        )
        .padding()
    }
}

// Subcomponente: Sección de texto
struct InfoSection: View {
    let icono: String
    let titulo: String
    let texto: String
    var colorIcono: Color = .blue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Image(systemName: icono).foregroundColor(colorIcono)
                Text(titulo).font(.headline).foregroundColor(.secondary)
            }
            Text(texto).font(.body).fixedSize(horizontal: false, vertical: true)
        }
    }
}

// Subcomponente: Pastilla de dato
struct DataPill: View {
    let icono: String
    let texto: String
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icono)
            Text(texto).font(.caption).fontWeight(.bold)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(20)
    }
}

// ==========================================
// MARK: - 3. CONTENT VIEW (Principal)
// ==========================================

struct ContentView: View {
    // Instancia del ViewModel que maneja mapas y permisos
    @StateObject private var mapViewModel = MapViewModel()
    
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedPais: PaisInfo? = nil
    @State private var showInfo = false
    @State private var estadoTexto: String = "Toca el micro..."
    @State private var estaEscuchando = false

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
        if let paisEncontrado = BibliotecaPaises.buscar(texto: textoUsuario) {
            
            // 1. [CORRECCIÓN] DETENEMOS MICRO PRIMERO
            // Esto libera el canal de audio para que el SpeechSynthesizer pueda tomar control
            VoiceInputManager.shared.stopListening()
            estaEscuchando = false
            
            // Animación de cámara
            let newCamera = MapCamera(centerCoordinate: paisEncontrado.coordinate, distance: 2_000_000)
            withAnimation {
                position = .camera(newCamera)
            }
            
            selectedPais = paisEncontrado
            showInfo = true
            mapViewModel.route = nil // Limpiar ruta anterior
            
            // 2. Feedback de voz (Ahora se ejecutará después de detener el micro)
            self.estadoTexto = "Viajando a: \(paisEncontrado.nombre)"
            let dato = paisEncontrado.datosCuriosos.first ?? ""
            let guion = "Aquí está \(paisEncontrado.nombre). \(paisEncontrado.descripcionGeneral). Dato curioso: \(dato)"
            
            // Pequeño delay para asegurar que el audio session cambió
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                SpeechManager.shared.speak(text: guion)
            }
            
        } else {
            // Opcional: Feedback si no encuentra
             // self.estadoTexto = "No encontré ese país."
        }
    }

    var body: some View {
        Map(position: $position) {
            
            // 1. Mostrar ubicación del usuario (Punto azul)
            UserAnnotation()
            
            // 2. Mostrar la ruta si existe
            if let route = mapViewModel.route {
                MapPolyline(route)
                    .stroke(.blue, lineWidth: 5)
            }
            
            // 3. Iterar países del JSON
            ForEach(BibliotecaPaises.todosLosPaises) { pais in
                Annotation(pais.nombre, coordinate: pais.coordinate) {
                    Button {
                        // Acción al tocar el pin
                        withAnimation {
                            let newCamera = MapCamera(centerCoordinate: pais.coordinate, distance: 2_000_000)
                            position = .camera(newCamera)
                            selectedPais = pais
                            showInfo = true
                            mapViewModel.route = nil // Limpiar ruta al seleccionar nuevo país
                        }
                    } label: {
                        VStack(spacing: 0) {
                           Image(systemName: "mappin")
                                .font(.system(size: 30))
                              .foregroundColor(.red)
                               .shadow(radius: 2)
                            Text(pais.bandera)
                                .font(.system(size: 18))
                        }
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControlVisibility(.visible)
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .ignoresSafeArea()
        
        // MODIFICADOR PARA EL LOOK AROUND (VISOR 360)
        .lookAroundViewer(isPresented: $mapViewModel.isShowingLookAround, initialScene: mapViewModel.lookAroundScene)
        
        // [CORRECCIÓN] ALERTA DE ERRORES (Rutas / 360)
        // Esto muestra el aviso si fallan las direcciones o el 360
        .alert("Aviso", isPresented: $mapViewModel.showAlert) {
            Button("Entendido", role: .cancel) { }
        } message: {
            Text(mapViewModel.alertMessage)
        }
        
        // OVERLAY FLOTANTE (Tarjeta o Micrófono)
        .overlay(alignment: .bottom) {
            VStack(spacing: 15) {
                
                // Si hay un país seleccionado, mostrar la tarjeta con botones
                if showInfo, let pais = selectedPais {
                    CityInfoCard(pais: pais, showInfo: $showInfo, viewModel: mapViewModel)
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(5)
                } else {
                    // Si no, mostrar controles de voz
                    VStack {
                        Text(estadoTexto)
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(10)
                            .multilineTextAlignment(.center)
                        
                        Button(action: { iniciarInteraccion() }) {
                            Image(systemName: estaEscuchando ? "waveform" : "mic.fill")
                                .padding(30)
                                .background(estaEscuchando ? Color.red : Color.blue)
                                .foregroundColor(.white)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                    }
                }
            }
            .padding(.bottom, 30)
        }
        .onAppear {
            BibliotecaPaises.cargarDatos()
            VoiceInputManager.shared.requestAuthorization()
            mapViewModel.requestPermission()
        }
        .animation(.spring(), value: showInfo)
    }
}

// Vista Previa
#Preview {
    ContentView()
}
