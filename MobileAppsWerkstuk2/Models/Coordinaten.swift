import Foundation
import MapKit

class Coordinaten {
    var breedtegraad: Double
    var lengtegraad: Double
    
    init() {
        breedtegraad = 0.0
        lengtegraad = 0.0
    }
    
    init(breedtegraad: Double, lengtegraad: Double) {
        self.breedtegraad = breedtegraad
        self.lengtegraad = lengtegraad
    }
}
