//
//  ViewController.swift
//  PickAFlower
//
//  Created by Veldanov, Anton on 4/17/20.
//  Copyright © 2020 Anton Veldanov. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  let wikipediaURL = "https://en.wikipedia.org/w/api.php"
  let imagePicker = UIImagePickerController()

  
  
  
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var labelView: UILabel!
  
  
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    imagePicker.delegate = self
    imagePicker.sourceType = .camera
    imagePicker.allowsEditing = true // normally true
  }
  
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage{
      imageView.image = userPickedImage
      // Convert CIimage!
      guard let ciimage = CIImage(image: userPickedImage) else {
        fatalError("Error: could not convert to CIImage")
      }
      
      detect(image: ciimage)
      
    }
    
    imagePicker.dismiss(animated: true, completion: nil)
    
    
  }
  
  
  func detect(image:CIImage){
    // link to our model
    guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else{
      fatalError("Error: Loading CoreML failed")
    }
    
    let request = VNCoreMLRequest(model: model) { (request, error) in
      guard let classification = request.results?.first as? VNClassificationObservation else{
        fatalError("Error: Model failed to process image")
      }
      // assign result to the title
      self.navigationItem.title = classification.identifier.capitalized
      self.requestInfo(flowerName: classification.identifier)
      
      UINavigationBar.appearance().barTintColor = UIColor(red: 0.0/255.0, green: 204.0/255.0, blue: 102.0/255.0, alpha: 1.0)
    }
    
    
    let handler = VNImageRequestHandler(ciImage: image)
    do{
      try handler.perform([request])
    }catch{
      print(error)
    }
    
    
    
    
  }
  
  
  func requestInfo(flowerName:String){
    
    let parameters : [String:String] = [
    "format" : "json",
    "action" : "query",
    "prop" : "extracts|pageimages",
    "exintro" : "",
    "explaintext" : "",
    "titles" : flowerName,
    "indexpageids" : "",
    "redirects" : "1",
    "pithumbsize": "500"
    ]

    
    
    AF.request(wikipediaURL, method: .get, parameters: parameters).responseJSON { (response) in
      if !(response.error != nil){
        print("Got WIKI info")
//        print(response)
        print(JSON(response.value))
        
        let flowerJSON : JSON = JSON(response.value!)
        let pageid = flowerJSON["query"]["pageids"][0].stringValue
        
        let flowerDescription = JSON(response.value!)["query"]["pages"][pageid]["extract"].stringValue
        
        let flowerImageURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
        print(flowerImageURL)
        
        
        self.imageView.sd_setImage(with: URL(string: flowerImageURL))
        self.labelView.text = flowerDescription
        
      }
      
    }
    
  }
  
  
  @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
    present(imagePicker, animated: true, completion: nil)
  }
  
  
  
}

