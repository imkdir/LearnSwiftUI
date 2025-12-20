//
//  MapView.swift
//  SwiftTalk
//
//  Created by 程東 on 12/17/25.
//

import SwiftUI
import MapKit

struct Place: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
}

let places: [Place] = [
    Place(name: "Gasthaus Haveleck", coordinate: CLLocationCoordinate2D(latitude: 53.187240, longitude: 13.088585)),
    Place(name: "Hotel & Ferienanlage Precise Resort Marina Wolfsbruch", coordinate: CLLocationCoordinate2D(latitude: 53.179984, longitude: 12.899209)),
    Place(name: "Pension Lindenhof", coordinate: CLLocationCoordinate2D(latitude: 52.966637, longitude: 13.281789)),
    Place(name: "Gut Zernikow", coordinate: CLLocationCoordinate2D(latitude: 53.091639, longitude: 13.093251)),
    Place(name: "Ziegeleipark Mildenberg", coordinate: CLLocationCoordinate2D(latitude: 53.031421, longitude: 13.30988)),
    Place(name: "Hotel und Restaurant \"Zum Birkenhof\"", coordinate: CLLocationCoordinate2D(latitude: 53.112691, longitude: 13.104139)),
    Place(name: "Campingpark Himmelpfort", coordinate: CLLocationCoordinate2D(latitude: 53.167976, longitude: 13.23558)),
    Place(name: "Maritim Hafenhotel Reinsberg", coordinate: CLLocationCoordinate2D(latitude: 53.115591, longitude: 12.889571)),
    Place(name: "Ferienwohnung in der Mühle Himmelpfort", coordinate: CLLocationCoordinate2D(latitude: 53.175714, longitude: 13.232601)),
    Place(name: "Gut Boltenhof", coordinate: CLLocationCoordinate2D(latitude: 53.115685, longitude: 13.25494)),
    Place(name: "Werkshof Wolfsruh", coordinate: CLLocationCoordinate2D(latitude: 53.053821, longitude: 13.083495)),
    Place(name: "Jugendherberge Ravensbrück", coordinate: CLLocationCoordinate2D(latitude: 53.191610, longitude: 13.159954))
].shuffled()

extension MKMapRect {
    static let laufpark = MKMapRect(origin:
        MKMapPoint(x: 143758507.60971117, y: 86968700.835495561),
            size: MKMapSize(width: 437860.61378830671, height: 749836.27541357279))
}

struct MapView: View {
    @State private var count: Int = places.count
    
    var body: some View {
        Map {
            ForEach(places.prefix(count)) { place in
                Marker(place.name, coordinate: place.coordinate)
                    .tint(.blue)
            }
        }
        Stepper("Count", value: $count, in: 0...places.count)
            .padding()
    }
}
