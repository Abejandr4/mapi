//
//  GeojsonManager.swift
//  SpeechContent
//
//  Created by iOS Lab on 10/04/26.
//
import Foundation
import CoreLocation

struct PaisPoligono {
    let nombre: String
    let poligonos: [[[CLLocationCoordinate2D]]]
}

class GeoJSONManager {
    static let shared = GeoJSONManager()
    private var paises: [PaisPoligono] = []

    func cargar() {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let url = Bundle.main.url(forResource: "countries", withExtension: "geojson"),
                  let data = try? Data(contentsOf: url),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let features = json["features"] as? [[String: Any]] else {
                print("❌ Error cargando countries.geojson")
                return
            }

            var resultado: [PaisPoligono] = []

            for feature in features {
                guard let props = feature["properties"] as? [String: Any],
                      let nombre = props["name"] as? String,
                      let geometry = feature["geometry"] as? [String: Any],
                      let tipo = geometry["type"] as? String else { continue }

                var todosLosPoligonos: [[[CLLocationCoordinate2D]]] = []

                if tipo == "Polygon",
                   let coords = geometry["coordinates"] as? [[[Double]]] {
                    let anillo = coords.map { anillo in
                        anillo.compactMap { punto -> CLLocationCoordinate2D? in
                            guard punto.count >= 2 else { return nil }
                            return CLLocationCoordinate2D(latitude: punto[1], longitude: punto[0])
                        }
                    }
                    todosLosPoligonos.append(anillo)

                } else if tipo == "MultiPolygon",
                          let coords = geometry["coordinates"] as? [[[[Double]]]] {
                    for poligono in coords {
                        let anillo = poligono.map { anillo in
                            anillo.compactMap { punto -> CLLocationCoordinate2D? in
                                guard punto.count >= 2 else { return nil }
                                return CLLocationCoordinate2D(latitude: punto[1], longitude: punto[0])
                            }
                        }
                        todosLosPoligonos.append(anillo)
                    }
                }

                resultado.append(PaisPoligono(nombre: nombre, poligonos: todosLosPoligonos))
            }

            DispatchQueue.main.async {
                self.paises = resultado
                // Print para ver nombres exactos del GeoJSON
                print("✅ GeoJSON cargado: \(resultado.count) países")
                resultado.prefix(30).forEach { print("📍 '\($0.nombre)'") }
            }
        }
    }

    func buscarPais(en coordinate: CLLocationCoordinate2D) -> String? {
        for pais in paises {
            for poligono in pais.poligonos {
                guard let anilloPrincipal = poligono.first else { continue }
                if puntoEnPoligono(coordinate, poligono: anilloPrincipal) {
                    return pais.nombre
                }
            }
        }
        return nil
    }

    private func puntoEnPoligono(_ punto: CLLocationCoordinate2D, poligono: [CLLocationCoordinate2D]) -> Bool {
        var dentro = false
        let n = poligono.count
        var j = n - 1
        for i in 0..<n {
            let xi = poligono[i].longitude, yi = poligono[i].latitude
            let xj = poligono[j].longitude, yj = poligono[j].latitude
            let intersecta = ((yi > punto.latitude) != (yj > punto.latitude)) &&
                (punto.longitude < (xj - xi) * (punto.latitude - yi) / (yj - yi) + xi)
            if intersecta { dentro = !dentro }
            j = i
        }
        return dentro
    }
}
