import SwiftUI
import MapKit
import CoreLocation

// MARK: - 1. Estructuras de Datos (Unificadas)

// La información de un país/ciudad a mostrar en el mapa
struct City: Identifiable {
    let id = UUID()
    let name: String // Nombre de la Ciudad/Capital
    let country: String // Nombre del País
    let flag: String // Emoji de la Bandera
    let coordinate: CLLocationCoordinate2D // Coordenadas para el mapa
    let info: CountryInfo // Información detallada del país
}

// Información detallada del país (utilizada dentro de City)
struct CountryInfo {
    let description: String
    let population: Int
    let continent: String
}

// MARK: - 2. Biblioteca de Países (Simulación/Placeholder)

// Asumo la existencia de una clase o struct para la búsqueda de países,
// pero la lista de ciudades se mantiene en ContentView para simplificar
// el ejemplo de MapKit.
// Si tuvieras una clase 'BibliotecaPaises' separada, DEBERÍA tener una función:
/*
struct PaisInfo {
    let nombre: String // Para la voz
    let descripcionGeneral: String // Para la voz
    let city: City // Para el mapa
}

class BibliotecaPaises {
    static let ciudades: [City] = [ /* ... la lista de arriba ... */ ]

    // Función que necesita la funcionalidad de voz
    static func buscar(texto: String) -> PaisInfo? {
        let textoLimpio = texto.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Simulación de detección de México o Japón para la funcionalidad de voz
        if textoLimpio.contains("méxico") || textoLimpio.contains("mexico") {
            if let mexico = ciudades.first(where: { $0.country == "México" }) {
                return PaisInfo(nombre: "México", descripcionGeneral: mexico.info.description, city: mexico)
            }
        } else if textoLimpio.contains("japón") || textoLimpio.contains("japon") {
             if let japon = ciudades.first(where: { $0.country == "Japón" }) {
                return PaisInfo(nombre: "Japón", descripcionGeneral: japon.info.description, city: japon)
            }
        }
        return nil
    }

    // Adaptación para buscar City en el código unificado
    static func buscarCiudad(texto: String) -> City? {
        let textoLimpio = texto.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return ciudades.first { city in
            city.country.lowercased().contains(textoLimpio) ||
            city.name.lowercased().contains(textoLimpio) ||
            textoLimpio.contains(city.country.lowercased()) ||
            textoLimpio.contains(city.name.lowercased())
        }
    }
}
*/

// Para que el código compile y sea autocontenido, la lógica de búsqueda se simplifica
// e integra directamente en ContentView, utilizando solo la estructura City.
// Si tuvieras los archivos de voz, esta parte la manejarías en el archivo de BibliotecaPaises.


// MARK: - 3. Tarjeta de Información de Ciudad (View)

struct CityInfoCard: View {
    let city: City
    @Binding var showInfo: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Botón de cerrar (X)
            HStack {
                Spacer()
                Button {
                    showInfo = false
                    // Opcional: Detener el habla si está reproduciéndose al cerrar la tarjeta
                    // SpeechManager.shared.stop()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.gray)
                }
            }

            // Bandera y País
            HStack {
                Text(city.flag)
                    .font(.system(size: 70))
                Text(city.country)
                    .font(.title)
                    .bold()
            }

            Text(city.name)
                .font(.title2)
                .bold()

            // Info del país
            Text(city.info.description)
                .font(.body)
            
            Text("🌍 Continente: \(city.info.continent)")
            Text("👥 Población: \(city.info.population.formatted())")

            Spacer()
        }
        .padding(25)
        .frame(width: 330, height: 460)
        .background(.ultraThinMaterial)
        .cornerRadius(25)
        .shadow(radius: 20)
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(.white.opacity(0.3), lineWidth: 1)
        )
        .padding()
    }
}


// MARK: - 4. ContentView (Mapa y Voz)

struct ContentView: View {
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedCity: City? = nil
    @State private var showInfo = false
    
    // Estados de la funcionalidad de voz
    @State private var estadoTexto: String = "Toca el micrófono para hablar"
    @State private var estaEscuchando = false

    // La lista de ciudades (completa, como la tenías)
    let cities: [City] = [
        // ----------------- CONTINENTE AMERICANO ---------------
        City(name: "Washington D. C.", country: "Estados Unidos", flag: "🇺🇸", coordinate: .init(latitude: 38.9072, longitude: -77.0369), info: CountryInfo(description: "Potencia global, centro político y económico con gran diversidad cultural.", population: 331000000, continent: "América")),
        City(name: "Ottawa", country: "Canadá", flag: "🇨🇦", coordinate: .init(latitude: 45.4215, longitude: -75.6972), info: CountryInfo(description: "País con gran extensión territorial, naturaleza y sociedad multicultural.", population: 38000000, continent: "América")),
        City(name: "Ciudad de México", country: "México", flag: "🇲🇽", coordinate: .init(latitude: 19.4326, longitude: -99.1332), info: CountryInfo(description: "Historia prehispánica y colonial, gastronomía y centro económico regional.", population: 128000000, continent: "América")),
        City(name: "Brasilia", country: "Brasil", flag: "🇧🇷", coordinate: .init(latitude: -15.8267, longitude: -47.9218), info: CountryInfo(description: "País continental con gran diversidad ecológica y cultural; capital moderna.", population: 213000000, continent: "América")),
        City(name: "Buenos Aires", country: "Argentina", flag: "🇦🇷", coordinate: .init(latitude: -34.6037, longitude: -58.3816), info: CountryInfo(description: "Centro cultural y económico de la región del Cono Sur, tango y gastronomía.", population: 45000000, continent: "América")),
        City(name: "Bogotá", country: "Colombia", flag: "🇨🇴", coordinate: .init(latitude: 4.7110, longitude: -74.0721), info: CountryInfo(description: "Capital andina con rica historia, cultura y crecimiento urbano.", population: 51000000, continent: "América")),
        City(name: "Santiago", country: "Chile", flag: "🇨🇱", coordinate: .init(latitude: -33.4489, longitude: -70.6693), info: CountryInfo(description: "Centro financiero y cultural del Pacífico sur, con variada geografía.", population: 19000000, continent: "América")),

        // ----------------- CONTINENTE EUROPEO -----------------
        City(name: "Londres", country: "Reino Unido", flag: "🇬🇧", coordinate: .init(latitude: 51.5074, longitude: -0.1278), info: CountryInfo(description: "Centro financiero y cultural global, con historia y diversidad.", population: 67000000, continent: "Europa")),
        City(name: "París", country: "Francia", flag: "🇫🇷", coordinate: .init(latitude: 48.8566, longitude: 2.3522), info: CountryInfo(description: "Cuna del arte, la moda y la gastronomía; alto atractivo turístico.", population: 67000000, continent: "Europa")),
        City(name: "Berlín", country: "Alemania", flag: "🇩🇪", coordinate: .init(latitude: 52.5200, longitude: 13.4050), info: CountryInfo(description: "Economía sólida e historia contemporánea importante en Europa.", population: 83000000, continent: "Europa")),
        City(name: "Roma", country: "Italia", flag: "🇮🇹", coordinate: .init(latitude: 41.9028, longitude: 12.4964), info: CountryInfo(description: "Patrimonio histórico y cultural inmenso; centro turístico y artístico.", population: 60000000, continent: "Europa")),
        City(name: "Madrid", country: "España", flag: "🇪🇸", coordinate: .init(latitude: 40.4168, longitude: -3.7038), info: CountryInfo(description: "Capital vibrante con patrimonio, gastronomía y vida cultural intensa.", population: 47000000, continent: "Europa")),
        City(name: "Moscú", country: "Rusia", flag: "🇷🇺", coordinate: .init(latitude: 55.7558, longitude: 37.6173), info: CountryInfo(description: "Gran capital euroasiática con influencia geopolítica histórica y actual.", population: 145000000, continent: "Europa / Asia")),
        City(name: "Ámsterdam", country: "Países Bajos", flag: "🇳🇱", coordinate: .init(latitude: 52.3676, longitude: 4.9041), info: CountryInfo(description: "Centro financiero y cultural con tradición comercial e innovación.", population: 17500000, continent: "Europa")),
        City(name: "Bruselas", country: "Bélgica", flag: "🇧🇪", coordinate: .init(latitude: 50.8503, longitude: 4.3517), info: CountryInfo(description: "Sede principal de instituciones europeas y capital diplomática.", population: 11500000, continent: "Europa")),
        City(name: "Viena", country: "Austria", flag: "🇦🇹", coordinate: .init(latitude: 48.2082, longitude: 16.3738), info: CountryInfo(description: "Centro histórico de música clásica y alta calidad de vida.", population: 9000000, continent: "Europa")),
        City(name: "Estocolmo", country: "Suecia", flag: "🇸🇪", coordinate: .init(latitude: 59.3293, longitude: 18.0686), info: CountryInfo(description: "Innovación tecnológica, diseño y alto estándar social.", population: 10300000, continent: "Europa")),
        City(name: "Oslo", country: "Noruega", flag: "🇳🇴", coordinate: .init(latitude: 59.9139, longitude: 10.7522), info: CountryInfo(description: "Economía basada en recursos, alto desarrollo humano y naturaleza.", population: 5400000, continent: "Europa")),
        City(name: "Copenhague", country: "Dinamarca", flag: "🇩🇰", coordinate: .init(latitude: 55.6761, longitude: 12.5683), info: CountryInfo(description: "Diseño, bienestar social y ciudad puntera en sostenibilidad.", population: 5800000, continent: "Europa")),
        City(name: "Varsovia", country: "Polonia", flag: "🇵🇱", coordinate: .init(latitude: 52.2297, longitude: 21.0122), info: CountryInfo(description: "Historia compleja, crecimiento económico y centro de Europa del Este.", population: 38000000, continent: "Europa")),
        City(name: "Berna", country: "Suiza", flag: "🇨🇭", coordinate: .init(latitude: 46.9480, longitude: 7.4474), info: CountryInfo(description: "Capital federal (Berna); Zúrich es centro económico principal.", population: 8700000, continent: "Europa")),
        City(name: "Dublín", country: "Irlanda", flag: "🇮🇪", coordinate: .init(latitude: 53.3498, longitude: -6.2603), info: CountryInfo(description: "Centro tecnológico y cultural con fuerte influencia anglófona.", population: 5000000, continent: "Europa")),
        City(name: "Praga", country: "República Checa", flag: "🇨🇿", coordinate: .init(latitude: 50.0755, longitude: 14.4378), info: CountryInfo(description: "Ciudad histórica y turística con patrimonio arquitectónico notable.", population: 10700000, continent: "Europa")),

        // -------------CONTIENTE ASIATICO -----------------
        City(name: "Pekín", country: "China", flag: "🇨🇳", coordinate: .init(latitude: 39.9042, longitude: 116.4074), info: CountryInfo(description: "Capital política de una potencia económica y cultural milenaria.", population: 1402000000, continent: "Asia")),
        City(name: "Tokio", country: "Japón", flag: "🇯🇵", coordinate: .init(latitude: 35.6895, longitude: 139.6917), info: CountryInfo(description: "Gran metrópoli líder en tecnología, cultura y economía asiática.", population: 125800000, continent: "Asia")),
        City(name: "Seúl", country: "Corea del Sur", flag: "🇰🇷", coordinate: .init(latitude: 37.5665, longitude: 126.9780), info: CountryInfo(description: "Centro tecnológico y cultural del dinámico Asia oriental.", population: 51780000, continent: "Asia")),
        City(name: "Nueva Delhi", country: "India", flag: "🇮🇳", coordinate: .init(latitude: 28.6139, longitude: 77.2090), info: CountryInfo(description: "Centro político de una nación vasta y diversa, con rápido crecimiento.", population: 1402000000, continent: "Asia")),
        City(name: "Singapur", country: "Singapur", flag: "🇸🇬", coordinate: .init(latitude: 1.3521, longitude: 103.8198), info: CountryInfo(description: "Ciudad-estado líder en finanzas, logística y estabilidad regional.", population: 5900000, continent: "Asia")),
        City(name: "Yakarta", country: "Indonesia", flag: "🇮🇩", coordinate: .init(latitude: -6.2088, longitude: 106.8456), info: CountryInfo(description: "Gran metrópoli del sudeste asiático con fuerte influencia económica.", population: 276000000, continent: "Asia")),
        City(name: "Bangkok", country: "Tailandia", flag: "🇹🇭", coordinate: .init(latitude: 13.7563, longitude: 100.5018), info: CountryInfo(description: "Centro turístico y comercial con rica vida cultural y religiosa.", population: 70000000, continent: "Asia")),
        City(name: "Hanoi", country: "Vietnam", flag: "🇻🇳", coordinate: .init(latitude: 21.0278, longitude: 105.8342), info: CountryInfo(description: "Capital histórica con creciente importancia económica regional.", population: 98000000, continent: "Asia")),
        City(name: "Kuala Lumpur", country: "Malasia", flag: "🇲🇾", coordinate: .init(latitude: 3.1390, longitude: 101.6869), info: CountryInfo(description: "Centro económico y cultural de Malasia con desarrollo urbano rápido.", population: 33000000, continent: "Asia")),
        City(name: "Manila", country: "Filipinas", flag: "🇵🇭", coordinate: .init(latitude: 14.5995, longitude: 120.9842), info: CountryInfo(description: "Gran área metropolitana con fuerte conexión histórica y cultural.", population: 109000000, continent: "Asia")),
        City(name: "Riad", country: "Arabia Saudita", flag: "🇸🇦", coordinate: .init(latitude: 24.7136, longitude: 46.6753), info: CountryInfo(description: "Centro político y económico del Golfo y gran productor energético.", population: 35000000, continent: "Asia")),
        City(name: "Abu Dabi", country: "Emiratos Árabes Unidos", flag: "🇦🇪", coordinate: .init(latitude: 24.4539, longitude: 54.3773), info: CountryInfo(description: "Capital federal con fuerte inversión en infraestructuras y energía.", population: 9800000, continent: "Asia")),
        City(name: "Doha", country: "Catar", flag: "🇶🇦", coordinate: .init(latitude: 25.2854, longitude: 51.5310), info: CountryInfo(description: "Pequeño pero influyente estado del Golfo por su riqueza energética.", population: 2900000, continent: "Asia")),
        City(name: "Ankara", country: "Turquía", flag: "🇹🇷", coordinate: .init(latitude: 39.9334, longitude: 32.8597), info: CountryInfo(description: "Capital política de una nación entre Europa y Asia, con historia diversa.", population: 84000000, continent: "Asia / Europa")),
        City(name: "Teherán", country: "Irán", flag: "🇮🇷", coordinate: .init(latitude: 35.6892, longitude: 51.3890), info: CountryInfo(description: "Centro político y cultural de un país con larga historia regional.", population: 85000000, continent: "Asia")),
        City(name: "Bagdad", country: "Irak", flag: "🇮🇶", coordinate: .init(latitude: 33.3152, longitude: 44.3661), info: CountryInfo(description: "Ciudad con gran importancia histórica y geopolítica en la región.", population: 43000000, continent: "Asia")),
        City(name: "Jerusalén", country: "Israel", flag: "🇮🇱", coordinate: .init(latitude: 31.7683, longitude: 35.2137), info: CountryInfo(description: "Ciudad con gran relevancia histórica, cultural y religiosa; disputa política.", population: 9000000, continent: "Asia")),

        // ---------------- CONTINENTE AFRICANO ------------
        City(name: "El Cairo", country: "Egipto", flag: "🇪🇬", coordinate: .init(latitude: 30.0444, longitude: 31.2357), info: CountryInfo(description: "Centro histórico del Norte de África y puerta entre África y Oriente Medio.", population: 104000000, continent: "África")),
        City(name: "Pretoria", country: "Sudáfrica", flag: "🇿🇦", coordinate: .init(latitude: -25.7479, longitude: 28.2293), info: CountryInfo(description: "Sede administrativa; Ciudad del Cabo es sede legislativa y centro económico.", population: 60000000, continent: "África")),
        City(name: "Nairobi", country: "Kenia", flag: "🇰🇪", coordinate: .init(latitude: -1.2921, longitude: 36.8219), info: CountryInfo(description: "Importante hub regional para África Oriental, con vida salvaje cercana.", population: 54000000, continent: "África")),
        City(name: "Addis Abeba", country: "Etiopía", flag: "🇪🇹", coordinate: .init(latitude: 9.1450, longitude: 40.4897), info: CountryInfo(description: "Sede de la Unión Africana y centro político del Cuerno de África.", population: 117000000, continent: "África")),
        City(name: "Abuja", country: "Nigeria", flag: "🇳🇬", coordinate: .init(latitude: 9.0765, longitude: 7.3986), info: CountryInfo(description: "Capital administrativa de la mayor economía de África por población.", population: 206000000, continent: "África")),
        City(name: "Argel", country: "Argelia", flag: "🇩🇿", coordinate: .init(latitude: 36.7538, longitude: 3.0588), info: CountryInfo(description: "País grande del Magreb con recursos energéticos y herencia histórica.", population: 43000000, continent: "África")),
        City(name: "Rabat", country: "Marruecos", flag: "🇲🇦", coordinate: .init(latitude: 34.0209, longitude: -6.8416), info: CountryInfo(description: "Capital administrativa; mezcla de cultura árabe, bereber y mediterránea.", population: 37000000, continent: "África")),

        // -------------OCEANIA-----------------
        City(name: "Canberra", country: "Australia", flag: "🇦🇺", coordinate: .init(latitude: -35.2809, longitude: 149.1300), info: CountryInfo(description: "Capital planificada y centro político de Australia.", population: 26000000, continent: "Oceanía")),
        City(name: "Wellington", country: "Nueva Zelanda", flag: "🇳🇿", coordinate: .init(latitude: -41.2865, longitude: 174.7762), info: CountryInfo(description: "Capital compacta y creativa, con naturaleza cercana y cultura maorí.", population: 5100000, continent: "Oceanía"))
    ]

    // Función adaptada para buscar una City
    func buscarCity(texto: String) -> City? {
        let textoLimpio = texto.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return cities.first { city in
            // Permite buscar por nombre de país o capital, o si el texto contiene el nombre
            textoLimpio.contains(city.country.lowercased()) ||
            textoLimpio.contains(city.name.lowercased())
        }
    }

    
    // MARK: - Lógica de Voz
    
    // Función central de inicio/parada de escucha
    func iniciarInteraccion() {
        if estaEscuchando {
            // Detener la escucha
            VoiceInputManager.shared.stopListening()
            estaEscuchando = false
            estadoTexto = "Pausa."
        } else {
            // Iniciar la escucha
            // Feedback vibración (asumiendo UIImpactFeedbackGenerator es accesible)
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            SpeechManager.shared.stop() // Detener cualquier reproducción en curso
            estadoTexto = "Te escucho..."
            estaEscuchando = true
            
            // Iniciar la escucha y manejar el resultado
            VoiceInputManager.shared.startListening { resultado in
                self.estadoTexto = resultado
                
                // Procesar el texto hablado
                self.procesarIntencion(textoUsuario: resultado)
                
                // Detener la escucha después de obtener el resultado
                VoiceInputManager.shared.stopListening()
                self.estaEscuchando = false
            }
        }
    }
    
    // Función que procesa la entrada de voz y actúa sobre el mapa
    func procesarIntencion(textoUsuario: String) {
        if let infoCity = buscarCity(texto: textoUsuario) {
            
            // 1. Mover el mapa a la ubicación del país
            let newCamera = MapCamera(centerCoordinate: infoCity.coordinate, distance: 5_000_000) // Zoom a 5000km
            position = .camera(newCamera)
            
            // 2. Mostrar la tarjeta de información
            selectedCity = infoCity
            showInfo = true
            
            // 3. Hablar la descripción
            self.estadoTexto = "Hablando de: \(infoCity.country)"
            let guion = "Viajando a \(infoCity.country). \(infoCity.info.description). La capital es \(infoCity.name)."
            SpeechManager.shared.speak(text: guion)
            
        } else {
            // Si no se detecta un país
            self.estadoTexto = "No entendí qué país dijiste. Intenta con México o Japón."
            SpeechManager.shared.speak(text: self.estadoTexto)
        }
    }

    
    // MARK: - Interfaz de Usuario
    
    var body: some View {
        
        // El Map ocupa todo el espacio
        Map(position: $position) {
            ForEach(cities) { city in
                Annotation(city.name, coordinate: city.coordinate) {
                    Button {
                        // 1. Establecer la cámara en la ciudad seleccionada
                        let newCamera = MapCamera(centerCoordinate: city.coordinate, distance: 5_000_000)
                        position = .camera(newCamera)
                        
                        // 2. Mostrar la tarjeta de información
                        selectedCity = city
                        showInfo = true
                        
                        // 3. (Opcional) Leer la info al tocar la bandera en el mapa
                        // let guion = "Viajando a \(city.country). \(city.info.description). La capital es \(city.name)."
                        // SpeechManager.shared.speak(text: guion)
                        
                    } label: {
                        VStack(spacing: 0) {
                            Image(systemName: "mappin")
                                .font(.system(size: 30))
                                .foregroundColor(.red)
                            Text(city.flag)
                                .font(.system(size: 18))
                        }
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControlVisibility(.visible)
        .ignoresSafeArea()
        
        // El contenido de la UI se superpone sobre el mapa
        .overlay(alignment: .bottom) {
            VStack(spacing: 15) {
                
                // Muestra la tarjeta de información del país seleccionado
                if showInfo, let city = selectedCity {
                    CityInfoCard(city: city, showInfo: $showInfo)
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(5)
                } else {
                    
                    // Texto de Estado
                    Text(estadoTexto)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                        .multilineTextAlignment(.center)
                    
                    // BOTÓN PRINCIPAL (Micrófono) - En el centro inferior
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
                    Button("🧪 Simular: 'Quiero ir a Japón'") {
                        procesarIntencion(textoUsuario: "Japón")
                    }
                    .padding()
                    .background(Color.green.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .shadow(radius: 5)
                }
                
            }
            .padding(.bottom, 30) // Espacio inferior para que no quede pegado al borde
        }
        .onAppear {
            // Configuración inicial del mapa
            position = .camera(
                MapCamera(
                    centerCoordinate: .init(latitude: 20, longitude: 0),
                    distance: 50_000_000,
                    heading: 0,
                    pitch: 0
                )
            )
            
            // Lógica de inicialización de Voz (asumiendo que SpeechManager y VoiceInputManager están disponibles)
            // BibliotecaPaises.cargarDatos() // Ya no es necesario si la lista está en ContentView
            VoiceInputManager.shared.requestAuthorization()
            
            // Configurar el callback al terminar de hablar (opcional, para feedback de UI)
            SpeechManager.shared.alTerminarDeHablar = {
                print("Evento: Terminó de hablar")
                // Puedes añadir lógica aquí, por ejemplo:
                // self.estadoTexto = "Toca el micrófono para hablar"
            }
        }
        .animation(.spring(), value: showInfo)
        .animation(.default, value: estaEscuchando)
    }
}

// MARK: - Vistas de Previsualización

#Preview {
    ContentView()
}
