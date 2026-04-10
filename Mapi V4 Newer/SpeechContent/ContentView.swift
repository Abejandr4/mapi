import SwiftUI
import MapKit
import CoreLocation
import Speech
import AVFoundation

// ==========================================
// MARK: - 1. VIEW MODEL (Lógica de Mapa y Ubicación)
// ==========================================

final class MapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    @Published var route: MKRoute?
    @Published var lookAroundScene: MKLookAroundScene?
    @Published var isShowingLookAround = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    
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
    
    func requestPermission() {
        manager?.requestWhenInUseAuthorization()
        manager?.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.currentUserLocation = location.coordinate
    }
    
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
            await MainActor.run {
                self.alertMessage = "No se encontró una ruta terrestre para llegar a este destino (posiblemente hay un océano en medio)."
                self.showAlert = true
            }
        }
    }
    
    func getLookAroundScene(from coordinate: CLLocationCoordinate2D) async {
        do {
            let request = MKLookAroundSceneRequest(coordinate: coordinate)
            let scene = try await request.scene
            
            await MainActor.run {
                self.lookAroundScene = scene
                if scene != nil {
                    self.isShowingLookAround = true
                } else {
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

struct CityInfoCard: View {
    let pais: PaisInfo
    @Binding var showInfo: Bool
    @ObservedObject var viewModel: MapViewModel

    var body: some View {
        ZStack(alignment: .topTrailing) {
            
            VStack(spacing: 0) {
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
                        
                        HStack(spacing: 15) {
                            Button(action: {
                                Task {
                                    await viewModel.getDirections(to: pais.coordinate)
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
    @StateObject private var mapViewModel = MapViewModel()
    
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedPais: PaisInfo? = nil
    @State private var showInfo = false
    @State private var estadoTexto: String = "Agita para buscar un país"
    @State private var estaEscuchando = false

    func iniciarInteraccion() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()

        if estaEscuchando {
            VoiceInputManager.shared.stopListening()
            estaEscuchando = false
            estadoTexto = "Agita para buscar un país"
        } else {
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
            VoiceInputManager.shared.stopListening()
            estaEscuchando = false
            
            let newCamera = MapCamera(centerCoordinate: paisEncontrado.coordinate, distance: 2_000_000)
            withAnimation {
                position = .camera(newCamera)
            }
            
            selectedPais = paisEncontrado
            showInfo = true
            
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
            
            mapViewModel.route = nil
            
            self.estadoTexto = "Viajando a: \(paisEncontrado.nombre)"
            let dato = paisEncontrado.datosCuriosos.first ?? ""
            let guion = "Aquí está \(paisEncontrado.nombre). \(paisEncontrado.descripcionGeneral). Dato curioso: \(dato)"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                SpeechManager.shared.speak(text: guion)
            }
        }
    }

    // NUEVO: Toque en cualquier parte del mapa
    func buscarPaisPorToque(coordinate: CLLocationCoordinate2D) {
        // Ignorar si ya hay una tarjeta abierta
        guard !showInfo else { return }
        
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()
        let locale = Locale(identifier: "es_MX")
        
        geocoder.reverseGeocodeLocation(location, preferredLocale: locale) { placemarks, error in
            guard let placemark = placemarks?.first,
                  let countryName = placemark.country else { return }
            
            if let paisEncontrado = BibliotecaPaises.buscar(texto: countryName.lowercased()) {
                DispatchQueue.main.async {
                    let newCamera = MapCamera(centerCoordinate: paisEncontrado.coordinate, distance: 2_000_000)
                    withAnimation {
                        position = .camera(newCamera)
                    }
                    
                    selectedPais = paisEncontrado
                    showInfo = true
                    mapViewModel.route = nil
                    
                    let generator = UIImpactFeedbackGenerator(style: .heavy)
                    generator.prepare()
                    generator.impactOccurred()
                    
                    let dato = paisEncontrado.datosCuriosos.first ?? ""
                    let guion = "Aquí está \(paisEncontrado.nombre). \(paisEncontrado.descripcionGeneral). Dato curioso: \(dato)"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        SpeechManager.shared.speak(text: guion)
                    }
                }
            }
        }
    }

    var body: some View {
        MapReader { proxy in
            Map(position: $position) {
                
                // 1. Ubicación del usuario
                UserAnnotation()
                
                // 2. Ruta si existe
                if let route = mapViewModel.route {
                    MapPolyline(route)
                        .stroke(.blue, lineWidth: 5)
                }
                
                // 3. Pins de países
                ForEach(BibliotecaPaises.todosLosPaises) { pais in
                    Annotation(pais.nombre, coordinate: pais.coordinate) {
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
            .mapStyle(.standard(elevation: .realistic))
            .mapControlVisibility(.visible)
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .ignoresSafeArea()
            .onTapGesture { screenPoint in
                guard let coordinate = proxy.convert(screenPoint, from: .local) else { return }
                buscarPaisPorToque(coordinate: coordinate)
            }
        }
        .lookAroundViewer(isPresented: $mapViewModel.isShowingLookAround, initialScene: mapViewModel.lookAroundScene)
        .alert("Aviso", isPresented: $mapViewModel.showAlert) {
            Button("Entendido", role: .cancel) { }
        } message: {
            Text(mapViewModel.alertMessage)
        }
        .overlay(alignment: .bottom) {
            VStack(spacing: 15) {
                if showInfo, let pais = selectedPais {
                    CityInfoCard(pais: pais, showInfo: $showInfo, viewModel: mapViewModel)
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(5)
                } else {
                    HStack(spacing: 16) {
                        Text(estadoTexto)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.75))
                            .multilineTextAlignment(.center)

                        ZStack {
                            if estaEscuchando {
                                Circle()
                                    .stroke(Color.cyan.opacity(0.4), lineWidth: 1)
                                    .frame(width: 38, height: 38)
                                Circle()
                                    .stroke(Color.cyan.opacity(0.2), lineWidth: 1)
                                    .frame(width: 52, height: 52)
                            }

                            Image(systemName: "mic")
                                .font(.system(size: 22, weight: .light))
                                .foregroundColor(
                                    estaEscuchando
                                        ? .cyan.opacity(0.9)
                                        : .white.opacity(0.3)
                                )
                        }
                        .frame(width: 44, height: 44)
                        .onTapGesture { iniciarInteraccion() }
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 14)
                    .background(.ultraThinMaterial)
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(.white.opacity(0.12), lineWidth: 0.8)
                    )
                }
            }
            .padding(.bottom, 30)
        }
        .onAppear {
            BibliotecaPaises.cargarDatos()
            VoiceInputManager.shared.requestAuthorization()
            mapViewModel.requestPermission()

            ShakeManager.shared.start {
                DispatchQueue.main.async {
                    self.iniciarInteraccion()
                }
            }
        }
        .animation(.spring(), value: showInfo)
    }
}

#Preview {
    ContentView()
}
