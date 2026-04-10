import Foundation
import CoreLocation

struct PaisInfo: Codable, Identifiable {
    let id: String
    let nombre: String
    let capital: String
    let sinonimos: [String]
    let latitud: Double
    let longitud: Double
    let bandera: String
    let descripcionGeneral: String
    let cultura: String
    let datosCuriosos: [String]
    let historia: String
    let clima: String
    let ubicacionGeografica: String
    let paisesColindantes: [String]
    let continent: String
    let population: Int
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitud, longitude: longitud)
    }
}

class BibliotecaPaises {
    static var todosLosPaises: [PaisInfo] = []
    private static var indiceBusqueda: [String: PaisInfo] = [:]
    
    static let geojsonAId: [String: String] = [
        "mexico": "mexico",
        "canada": "canada",
        "united states of america": "estados_unidos",
        "brazil": "brasil",
        "argentina": "argentina",
        "colombia": "colombia",
        "chile": "chile",
        "peru": "peru",
        "venezuela": "venezuela",
        "ecuador": "ecuador",
        "bolivia": "bolivia",
        "paraguay": "paraguay",
        "uruguay": "uruguay",
        "guyana": "guyana",
        "suriname": "surinam",
        "france": "francia",
        "germany": "alemania",
        "spain": "espana",
        "italy": "italia",
        "portugal": "portugal",
        "united kingdom": "reino_unido",
        "netherlands": "paises_bajos",
        "belgium": "belgica",
        "switzerland": "suiza",
        "austria": "austria",
        "sweden": "suecia",
        "norway": "noruega",
        "denmark": "dinamarca",
        "finland": "finlandia",
        "poland": "polonia",
        "russia": "rusia",
        "ukraine": "ucrania",
        "greece": "grecia",
        "turkey": "turquia",
        "romania": "rumania",
        "hungary": "hungria",
        "czech republic": "republica_checa",
        "czechia": "republica_checa",
        "slovakia": "eslovaquia",
        "croatia": "croacia",
        "serbia": "serbia",
        "china": "china",
        "japan": "japon",
        "south korea": "corea_del_sur",
        "north korea": "corea_del_norte",
        "india": "india",
        "pakistan": "pakistan",
        "bangladesh": "bangladesh",
        "indonesia": "indonesia",
        "thailand": "tailandia",
        "vietnam": "vietnam",
        "philippines": "filipinas",
        "malaysia": "malasia",
        "singapore": "singapur",
        "myanmar": "myanmar",
        "cambodia": "camboya",
        "laos": "laos",
        "mongolia": "mongolia",
        "nepal": "nepal",
        "sri lanka": "sri_lanka",
        "afghanistan": "afganistan",
        "iran": "iran",
        "iraq": "irak",
        "saudi arabia": "arabia_saudita",
        "united arab emirates": "emiratos_arabes",
        "israel": "israel",
        "jordan": "jordania",
        "syria": "siria",
        "lebanon": "libano",
        "yemen": "yemen",
        "oman": "oman",
        "kuwait": "kuwait",
        "qatar": "catar",
        "bahrain": "barein",
        "egypt": "egipto",
        "nigeria": "nigeria",
        "south africa": "sudafrica",
        "kenya": "kenia",
        "ethiopia": "etiopia",
        "ghana": "ghana",
        "tanzania": "tanzania",
        "uganda": "uganda",
        "mozambique": "mozambique",
        "madagascar": "madagascar",
        "cameroon": "camerun",
        "angola": "angola",
        "mali": "mali",
        "niger": "niger",
        "chad": "chad",
        "sudan": "sudan",
        "south sudan": "sudan_del_sur",
        "somalia": "somalia",
        "morocco": "marruecos",
        "algeria": "argelia",
        "tunisia": "tunez",
        "libya": "libia",
        "australia": "australia",
        "new zealand": "nueva_zelanda",
        "papua new guinea": "papua_nueva_guinea",
        "cuba": "cuba",
        "haiti": "haiti",
        "dominican republic": "republica_dominicana",
        "guatemala": "guatemala",
        "honduras": "honduras",
        "el salvador": "el_salvador",
        "nicaragua": "nicaragua",
        "costa rica": "costa_rica",
        "panama": "panama",
        "jamaica": "jamaica",
        "trinidad and tobago": "trinidad_y_tobago",
        "iceland": "islandia",
        "ireland": "irlanda",
        "luxembourg": "luxemburgo",
        "malta": "malta",
        "cyprus": "chipre",
        "albania": "albania",
        "bulgaria": "bulgaria",
        "moldova": "moldavia",
        "belarus": "bielorrusia",
        "lithuania": "lituania",
        "latvia": "letonia",
        "estonia": "estonia",
        "slovenia": "eslovenia",
        "bosnia and herzegovina": "bosnia",
        "north macedonia": "macedonia_del_norte",
        "montenegro": "montenegro",
        "kosovo": "kosovo",
        "kazakhstan": "kazajistan",
        "uzbekistan": "uzbekistan",
        "turkmenistan": "turkmenistan",
        "tajikistan": "tayikistan",
        "kyrgyzstan": "kirguistan",
        "azerbaijan": "azerbaiyan",
        "georgia": "georgia",
        "armenia": "armenia",
        "democratic republic of the congo": "congo_democratico",
        "republic of congo": "congo",
        "ivory coast": "costa_de_marfil",
        "burkina faso": "burkina_faso",
        "guinea": "guinea",
        "senegal": "senegal",
        "zambia": "zambia",
        "zimbabwe": "zimbabue",
        "malawi": "malawi",
        "rwanda": "ruanda",
        "burundi": "burundi",
        "benin": "benin",
        "togo": "togo",
        "sierra leone": "sierra_leona",
        "liberia": "liberia",
        "mauritania": "mauritania",
        "eritrea": "eritrea",
        "djibouti": "yibuti",
        "central african republic": "republica_centroafricana",
        "equatorial guinea": "guinea_ecuatorial",
        "gabon": "gabon",
        "namibia": "namibia",
        "botswana": "botsuana",
        "lesotho": "lesoto",
        "eswatini": "esuatini",
        "comoros": "comoras",
        "cape verde": "cabo_verde",
        "timor-leste": "timor_oriental",
        "brunei": "brunei",
        "taiwan": "taiwan",
        "maldives": "maldivas",
        "bhutan": "butan",
        "fiji": "fiyi",
        "solomon islands": "islas_salomon",
        "vanuatu": "vanuatu",
        "samoa": "samoa",
        "tonga": "tonga",
        "kiribati": "kiribati",
        "palau": "palaos",
        "micronesia": "micronesia",
        "marshall islands": "islas_marshall",
        "nauru": "nauru",
        "tuvalu": "tuvalu",
        "andorra": "andorra",
        "monaco": "monaco",
        "liechtenstein": "liechtenstein",
        "san marino": "san_marino",
        "vatican": "vaticano",
        "western sahara": "sahara_occidental"
    ]
    
    static func cargarDatos() {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let url = Bundle.main.url(forResource: "paises", withExtension: "json") else {
                print("❌ Error: No encontré paises.json")
                return
            }
            do {
                let data = try Data(contentsOf: url)
                var indice: [String: PaisInfo] = [:]
                let paises = try JSONDecoder().decode([PaisInfo].self, from: data)
                for pais in paises {
                    indice[pais.id] = pais
                    indice[pais.nombre.lowercased()] = pais
                    for sinonimo in pais.sinonimos { indice[sinonimo] = pais }
                }
                DispatchQueue.main.async {
                    todosLosPaises = paises
                    indiceBusqueda = indice
                    print("✅ Éxito: Se cargaron \(paises.count) países.")
                }
            } catch {
                print("❌ Error leyendo el JSON: \(error)")
            }
        }
    }
    
    static func buscar(texto: String) -> PaisInfo? {
        let busqueda = texto.lowercased()
        if let exacto = indiceBusqueda[busqueda] { return exacto }
        for (clave, pais) in indiceBusqueda {
            if busqueda.contains(clave) { return pais }
        }
        return nil
    }
    
    static func buscarPorNombreIngles(_ nombreIngles: String) -> PaisInfo? {
        let clave = nombreIngles.lowercased()
        if let id = geojsonAId[clave], let pais = indiceBusqueda[id] {
            return pais
        }
        return indiceBusqueda[clave]
    }
}
