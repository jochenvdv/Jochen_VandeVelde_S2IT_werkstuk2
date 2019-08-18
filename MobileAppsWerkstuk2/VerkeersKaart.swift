import UIKit
import MapKit

class VerkeersKaart: UIViewController, MKMapViewDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        laadKaart()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func laadKaart() {
        
    }
    
    @IBAction func herlaad(_ sender: Any) {
        laadKaart()
    }
    
}

