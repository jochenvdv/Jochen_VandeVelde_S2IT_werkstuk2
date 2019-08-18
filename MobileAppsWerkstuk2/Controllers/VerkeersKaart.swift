import Foundation
import UIKit
import MapKit
import CoreData

class VerkeersKaart: UIViewController {
    @IBOutlet weak var laatstGeupdate: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    
    var coreData: [NSManagedObject] = []
    var data: [VerkeersInfo] = []
    var coreDataGeladen = false
    
    static let url = URL(string: "https://opendata.brussels.be/api/records/1.0/search/?dataset=traffic-volume&facet=level_of_service")

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.laadData(skipCoreData: false)
        self.laadKaart()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func laadJSON() -> [VerkeersInfo] {
        // source: https://medium.com/@nimjea/json-parsing-in-swift-2498099b78f
            let task = URLSession.shared.dataTask(with: VerkeersKaart.url!) { (data, response, error) in
            guard let dataResponse = data,
                error == nil else {
                    print(error?.localizedDescription ?? "Response Error")
                    return
            }
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with:
                    dataResponse, options: []) as! [String:Any]
                self.data = self.mapJSON(json: jsonResponse)
                print("Data geladen van API")
                DispatchQueue.main.async {
                    self.persisteerData(data: self.data)
                    self.laadKaart()
                }
            } catch let parsingError {
                print("Error", parsingError)
            }
        }
        
        task.resume()
        
        return self.data
    }
    
    func mapJSON(json: [String:Any]) -> [VerkeersInfo] {
        var items = [VerkeersInfo]()
        // source:  https://developer.apple.com/swift/blog/?id=37
        if let records = json["records"] as? [[String:Any]] {
            
            for record in records {
                let verkeersInfo = VerkeersInfo()
                
                if let fields = record["fields"] as? [String: Any] {
                    if let geo_point_2d = fields["geo_point_2d"] as? [Double]{
                        verkeersInfo.coordinaten.breedtegraad = Double(geo_point_2d[0])
                        verkeersInfo.coordinaten.lengtegraad = Double(geo_point_2d[1])

                    }
                    
                    if let level_of_service = fields["level_of_service"] as? String {
                        if level_of_service == "VERT" {
                            verkeersInfo.intensiteit = VerkeersIntensiteit.NORMAAL
                        } else if level_of_service == "ORANGE" {
                            verkeersInfo.intensiteit = VerkeersIntensiteit.DRUK
                        } else if level_of_service == "ROUGE" {
                            verkeersInfo.intensiteit = VerkeersIntensiteit.EXTREEM
                        }
                    }
                }
                
                items.append(verkeersInfo)
            }
        }

        print(items)
        return items
    }
    
    func persisteerData(data: [VerkeersInfo]) {
        let tijd = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        
        laatstGeupdate.text = formatter.string(from: tijd)
        wisCoreData()
        
        // source: https://www.raywenderlich.com/7569-getting-started-with-core-data-tutorial
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        for verkeersInfo in data {
            let verkeersInfoEntity =
                NSEntityDescription.entity(forEntityName: "VerkeersInfoEntity",
                                           in: managedContext)!
            let verkeersInfoCore = NSManagedObject(entity: verkeersInfoEntity,
                                               insertInto: managedContext)
            verkeersInfoCore.setValue(String(describing: verkeersInfo.intensiteit), forKeyPath: "intensiteit")
            verkeersInfoCore.setValue(verkeersInfo.coordinaten.breedtegraad, forKeyPath: "breedtegraad")
            verkeersInfoCore.setValue(verkeersInfo.coordinaten.lengtegraad, forKeyPath: "lengtegraad")
            coreData.append(verkeersInfoCore)
        }
        
        let verkeersAppEntity =
            NSEntityDescription.entity(forEntityName: "VerkeersApplicatieEntity",
                                       in: managedContext)!
        let verkeersAppCore = NSManagedObject(entity: verkeersAppEntity,
                                               insertInto: managedContext)
        verkeersAppCore.setValue(tijd, forKeyPath: "lastUpdated")
        coreData.append(verkeersAppCore)
        
        do {
            try managedContext.save()
        } catch let error {
            print("error")
        }
    }
    
    func laadData(skipCoreData: Bool = false) {
        self.data = []
        
        if !skipCoreData {
            laadCoreData()
            if self.coreDataGeladen {
                laadJSON()
                return
            }
            return
        }
        
        laadJSON()
    }
    
    func wisCoreData() {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let managedContext = appDelegate!.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "VerkeersInfoEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try managedContext.execute(deleteRequest)
            try managedContext.save()
        } catch {
            print("error")
        }
        
        mapView.removeAnnotations(mapView.annotations)
    }
    
    func laadCoreData() {
        self.data = []
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let managedContext = appDelegate!.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "VerkeersInfoEntity")
        fetchRequest.returnsObjectsAsFaults = false
        
        do {
            let coreData = try managedContext.fetch(fetchRequest)
            for verkeersInfoEntity in coreData {
                let verkeersInfo = VerkeersInfo()
                verkeersInfo.coordinaten = Coordinaten(breedtegraad: verkeersInfoEntity.value(forKey: "breedtegraad") as! Double, lengtegraad: verkeersInfoEntity.value(forKey: "breedtegraad") as! Double)
                
                if verkeersInfoEntity.value(forKey: "intensiteit") as? String == "NORMAAL" {
                    verkeersInfo.intensiteit = VerkeersIntensiteit.NORMAAL
                } else if verkeersInfoEntity.value(forKey: "intensiteit") as? String == "DRUK" {
                    verkeersInfo.intensiteit = VerkeersIntensiteit.DRUK
                } else if verkeersInfoEntity.value(forKey: "intensiteit") as? String == "EXTREEM" {
                    verkeersInfo.intensiteit = VerkeersIntensiteit.EXTREEM
                }
                
                self.data.append(verkeersInfo)
            }
            print("Geladen uit Core Data")
            self.coreDataGeladen = true
        } catch let error {
            print("Kon niet laden uit Core Data")
        }
    }
    
    func laadKaart() {
        // source: https://www.ioscreator.com/tutorials/mapkit-ios-tutorial
        let coordinateBrussel = CLLocationCoordinate2DMake(50.850015, 4.374207)
        
        let span = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        let region = MKCoordinateRegionMake(coordinateBrussel, span)
        mapView.setRegion(region, animated: true)
        
        for info in self.data {
            let annotation = MKPointAnnotation()
            
            if info.intensiteit == VerkeersIntensiteit.NORMAAL {
                annotation.title = "Normaal verkeer"
            } else if info.intensiteit == VerkeersIntensiteit.DRUK {
                annotation.title = "Druk verkeer"
            } else if info.intensiteit == VerkeersIntensiteit.EXTREEM {
                annotation.title = "Extreem verkeer"
            }
            
            let coordinate = CLLocationCoordinate2DMake(info.coordinaten.breedtegraad, info.coordinaten.lengtegraad)
            annotation.coordinate = coordinate
            annotation.subtitle = ""
            mapView.addAnnotation(annotation)
        }
    }
    
    @IBAction func herlaad(_ sender: Any) {
        laadData(skipCoreData: true)
        laadKaart()
    }
    
}

