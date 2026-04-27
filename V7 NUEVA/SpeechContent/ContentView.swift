import SwiftUI
import MapKit
import CoreLocation
import Speech
import AVFoundation

// ==========================================
// MARK: - 1. VIEW MODEL
// ==========================================

final class MapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    @Published var route: MKRoute?
    @Published var lookAroundScene: MKLookAroundScene?
    @Published var isShowingLookAround = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var currentUserLocation: CLLocationCoordinate2D?
    
    private var manager: CLLocationManager?
    
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
            DispatchQueue.main.async {
                self.currentUserLocation = location.coordinate
            }
        }
    
    func calcularDistancia(hacia destino: CLLocationCoordinate2D) -> String? {
            guard let userCoord = currentUserLocation else { return nil }
            
            let puntoA = CLLocation(latitude: userCoord.latitude, longitude: userCoord.longitude)
            let puntoB = CLLocation(latitude: destino.latitude, longitude: destino.longitude)
            
            let distanciaEnMetros = puntoA.distance(from: puntoB)
            let distanciaEnKm = distanciaEnMetros / 1000
            
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 1
            
            let kmString = formatter.string(from: NSNumber(value: distanciaEnKm)) ?? "\(distanciaEnKm)"
            return "\(kmString) km"
        }
    
    func getDirections(to destination: CLLocationCoordinate2D) async {
        guard let userLocation = currentUserLocation else { return }
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile
        do {
            let response = try await MKDirections(request: request).calculate()
            await MainActor.run { self.route = response.routes.first }
        } catch {
            await MainActor.run {
                self.alertMessage = "No se encontró una ruta terrestre para llegar a este destino."
                self.showAlert = true
            }
        }
    }
    
    func getLookAroundScene(from coordinate: CLLocationCoordinate2D) async {
        do {
            let scene = try await MKLookAroundSceneRequest(coordinate: coordinate).scene
            await MainActor.run {
                self.lookAroundScene = scene
                if scene != nil {
                    self.isShowingLookAround = true
                } else {
                    self.alertMessage = "La vista 360° no está disponible en esta región."
                    self.showAlert = true
                }
            }
        } catch {
            print("Look Around error: \(error.localizedDescription)")
        }
    }
}

// ==========================================
// MARK: - 2. VISTAS DE INTERFAZ
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
                        
                        if let distancia = viewModel.calcularDistancia(hacia: pais.coordinate) {
                            InfoSection(
                                icono: "arrow.up.left.and.arrow.down.right.circle.fill",
                                titulo: "Distancia desde tu posición",
                                texto: "Estás a aproximadamente \(distancia) de este país.",
                                colorIcono: .green
                            )
                        }
                        
                        InfoSection(icono: "book.fill", titulo: "Historia", texto: pais.historia)
                        InfoSection(icono: "text.alignleft", titulo: "Descripción", texto: pais.descripcionGeneral)
                        InfoSection(icono: "paintpalette.fill", titulo: "Cultura", texto: pais.cultura)
                        InfoSection(icono: "cloud.sun.fill", titulo: "Clima", texto: pais.clima)
                        InfoSection(icono: "mappin.and.ellipse", titulo: "Ubicación", texto: pais.ubicacionGeografica)

                        if !pais.paisesColindantes.isEmpty {
                            InfoSection(
                                icono: "map.fill",
                                titulo: "Países Colindantes",
                                texto: pais.paisesColindantes.joined(separator: ", ")
                            )
                        }

                        if let dato = pais.datosCuriosos.first {
                            InfoSection(icono: "lightbulb.fill", titulo: "Dato Curioso", texto: dato, colorIcono: .yellow)
                        }
                        
    
                        Divider()
                        HStack(alignment: .center, spacing: 20) {
                            HStack(alignment: .center, spacing: 20) {
                                DataPill(icono: "building.columns.fill", texto: pais.capital)
                                DataPill(icono: "globe", texto: pais.continent)
                                DataPill(icono: "person.3.fill", texto: "\(pais.population.formatted()) hab.")
                            }
                        }
                        .padding(.top, 5)
                        Divider()

                        // Botones con padding extra abajo para separar del borde
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
                                Task { await viewModel.getLookAroundScene(from: pais.coordinate) }
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
                        .padding(.bottom, 20) // ← más espacio abajo del botón Ir
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
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(.white.opacity(0.4), lineWidth: 1))
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

// Pin minimalista — solo un círculo pequeño con la bandera
struct PinView: View {
    let bandera: String
    var body: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.85))
                .frame(width: 28, height: 28)
                .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 1)
            Text(bandera)
                .font(.system(size: 16))
        }
    }
}

// ==========================================
// MARK: - 3. CONTENT VIEW
// ==========================================

struct ContentView: View {
    @StateObject private var mapViewModel = MapViewModel()
    
    @State private var position: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 23, longitude: -102),
        span: MKCoordinateSpan(latitudeDelta: 45, longitudeDelta: 45)
    ))
    @State private var selectedPais: PaisInfo? = nil
    @State private var showInfo = false
    @State private var estadoTexto: String = "Agita para buscar un país"
    @State private var estaEscuchando = false

    func iniciarInteraccion() {
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
        guard let paisEncontrado = BibliotecaPaises.buscar(texto: textoUsuario) else { return }
        VoiceInputManager.shared.stopListening()
        estaEscuchando = false
        moverCamara(a: paisEncontrado.coordinate)
        selectedPais = paisEncontrado
        showInfo = true
        mapViewModel.route = nil
        estadoTexto = "Viajando a: \(paisEncontrado.nombre)"
        let dato = paisEncontrado.datosCuriosos.first ?? ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            SpeechManager.shared.speak(text: "Aquí está \(paisEncontrado.nombre). \(paisEncontrado.descripcionGeneral). Su capital es: \(paisEncontrado.capital).  \(paisEncontrado.historia). Su clima es \(paisEncontrado.clima). Se encuentra en \(paisEncontrado.ubicacionGeografica).  \(paisEncontrado.capital). Los países colindantes son  \(paisEncontrado.paisesColindantes). El continente en que se encuentra es   \(paisEncontrado.continent). Su población es de  apróximadamente \(paisEncontrado.population) habitantes . Dato curioso: \(dato)")
        }
    }

    // Movimiento de cámara suave sin animación SwiftUI —
    // usa MapCameraPosition directo para que MapKit maneje la interpolación
    func moverCamara(a coordinate: CLLocationCoordinate2D) {
        withAnimation(.easeOut(duration: 0.6)) {
            position = .camera(MapCamera(
                centerCoordinate: coordinate,
                distance: 5_000_000,
                heading: 0,
                pitch: 0
            ))
        }
    }

    func abrirPais(_ pais: PaisInfo) {
        // Primero mostrar tarjeta inmediatamente
        selectedPais = pais
        showInfo = true
        mapViewModel.route = nil
        SpeechManager.shared.stop()
        // Mover cámara después con pequeño delay para no competir con la animación de la tarjeta
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            moverCamara(a: pais.coordinate)
        }
        let dato = pais.datosCuriosos.first ?? ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            SpeechManager.shared.speak(text: "Aquí está \(pais.nombre). \(pais.descripcionGeneral). Su capital es: \(pais.capital).  \(pais.historia). Su clima es \(pais.clima). Se encuentra en \(pais.ubicacionGeografica).  Los países colindantes son  \(pais.paisesColindantes). El continente en que se encuentra es   \(pais.continent). Su población es de  apróximadamente \(pais.population) habitantes . Dato curioso: \(dato)")
        }
    }

    func buscarPaisPorToque(coordinate: CLLocationCoordinate2D) {
        DispatchQueue.global(qos: .userInteractive).async {
            let nombreGeo = GeoJSONManager.shared.buscarPais(en: coordinate)
            guard let nombre = nombreGeo else { return }
            guard let paisFinal = BibliotecaPaises.buscarPorNombreIngles(nombre) else {
                print("❌ Sin match para: '\(nombre)'")
                return
            }
            DispatchQueue.main.async {
                self.abrirPais(paisFinal)
            }
        }
    }

    var body: some View {
        MapReader { proxy in
            Map(position: $position) {
                UserAnnotation()
                if let route = mapViewModel.route {
                    MapPolyline(route).stroke(.blue, lineWidth: 5)
                }
                // Pin minimalista — solo bandera en círculo pequeño
                ForEach(BibliotecaPaises.todosLosPaises) { pais in
                    Annotation("", coordinate: pais.coordinate) {
                        PinView(bandera: pais.bandera)
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
                        .transition(.opacity)
                        .zIndex(5)
                } else {
                    HStack(spacing: 16) {
                        Text(estadoTexto)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.75))
                            .multilineTextAlignment(.center)
                        ZStack {
                            if estaEscuchando {
                                Circle().stroke(Color.cyan.opacity(0.4), lineWidth: 1).frame(width: 38, height: 38)
                                Circle().stroke(Color.cyan.opacity(0.2), lineWidth: 1).frame(width: 52, height: 52)
                            }
                            Image(systemName: "mic")
                                .font(.system(size: 22, weight: .light))
                                .foregroundColor(estaEscuchando ? .cyan.opacity(0.9) : .white.opacity(0.3))
                        }
                        .frame(width: 44, height: 44)
                        .onTapGesture { iniciarInteraccion() }
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 14)
                    .background(.ultraThinMaterial)
                    .cornerRadius(24)
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.12), lineWidth: 0.8))
                }
            }
            .padding(.bottom, 30)
        }
        .onAppear {
            BibliotecaPaises.cargarDatos()
            GeoJSONManager.shared.cargar()
            VoiceInputManager.shared.requestAuthorization()
            mapViewModel.requestPermission()
            ShakeManager.shared.start {
                DispatchQueue.main.async {
                    self.iniciarInteraccion()
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showInfo)
    }
}

#Preview { ContentView() }
