import Foundation

// 1. Definimos la estructura que coincide con el JSON
// Agregamos 'Codable' para que Swift sepa traducirlo automático
struct PaisInfo: Codable {
    let id: String
    let nombre: String
    let sinonimos: [String] // ¡Ya preparamos el terreno para la Opción A!
    let descripcionGeneral: String
    let cultura: String
    let datosCuriosos: [String]
}

class BibliotecaPaises {
    
    // Ya no escribimos los datos aquí. Ahora tenemos una lista vacía que se llenará sola.
    static var todosLosPaises: [PaisInfo] = []
    
    // Función para cargar el archivo al iniciar la app
    static func cargarDatos() {
        // Buscamos el archivo en el paquete de la app
        guard let url = Bundle.main.url(forResource: "paises", withExtension: "json") else {
            print("❌ Error: No encontré el archivo paises.json")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            todosLosPaises = try decoder.decode([PaisInfo].self, from: data)
            print("✅ Éxito: Se cargaron \(todosLosPaises.count) países desde el JSON.")
        } catch {
            print("❌ Error leyendo el JSON: \(error)")
        }
    }
    
    // Función de búsqueda inteligente (Ya incluye lógica de la Opción A)
    static func buscar(texto: String) -> PaisInfo? {
        let busqueda = texto.lowercased()
        
        // Recorremos la lista cargada
        for pais in todosLosPaises {
            // Checamos si el nombre coincide (ej: "méxico")
            if busqueda.contains(pais.id) || busqueda.contains(pais.nombre.lowercased()) {
                return pais
            }
            
            // Checamos los sinónimos (ej: "república mexicana")
            for sinonimo in pais.sinonimos {
                if busqueda.contains(sinonimo) {
                    return pais
                }
            }
        }
        return nil
    }
}
