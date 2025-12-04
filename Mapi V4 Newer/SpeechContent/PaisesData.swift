import Foundation
import CoreLocation

struct PaisInfo: Codable, Identifiable {
    let id: String
    let nombre: String
    let sinonimos: [String]
    
    // Datos Geográficos
    let latitud: Double
    let longitud: Double
    let bandera: String
    
    // Información
    let descripcionGeneral: String
    let cultura: String
    let datosCuriosos: [String]
    
    // [NUEVO] Agrega estas dos líneas para arreglar el error:
    let continent: String
    let population: Int
    
    // Helper de coordenadas
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitud, longitude: longitud)
    }
}

class BibliotecaPaises {
    // ... (El resto de la clase se queda igual) ...
    static var todosLosPaises: [PaisInfo] = []
    
    static func cargarDatos() {
        guard let url = Bundle.main.url(forResource: "paises", withExtension: "json") else {
            print("❌ Error: No encontré paises.json")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            todosLosPaises = try decoder.decode([PaisInfo].self, from: data)
            print("✅ Éxito: Se cargaron \(todosLosPaises.count) países.")
        } catch {
            print("❌ Error leyendo el JSON: \(error)")
        }
    }
    
    static func buscar(texto: String) -> PaisInfo? {
        let busqueda = texto.lowercased()
        for pais in todosLosPaises {
            if busqueda.contains(pais.id) || busqueda.contains(pais.nombre.lowercased()) {
                return pais
            }
            for sinonimo in pais.sinonimos {
                if busqueda.contains(sinonimo) { return pais }
            }
        }
        return nil
    }
}
