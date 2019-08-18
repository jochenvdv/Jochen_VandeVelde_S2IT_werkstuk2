import Foundation

class VerkeersInfo {
    var coordinaten: Coordinaten
    var intensiteit: VerkeersIntensiteit
    
    init() {
        coordinaten = Coordinaten()
        intensiteit = VerkeersIntensiteit.NORMAAL
    }
    
    init(coordinaten: Coordinaten, intensiteit: VerkeersIntensiteit) {
        self.coordinaten = coordinaten
        self.intensiteit = intensiteit
    }
}
