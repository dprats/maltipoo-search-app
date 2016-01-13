//
//  ViewController.swift
//  FlickFinder
//
//  Created by Jarrod Parkes on 1/29/15.
//  Copyright © 2015 Udacity. All rights reserved.
//

import UIKit

//CONSTANTS
let BASE_URL = "https://api.flickr.com/services/rest/"
let METHOD_NAME = "flickr.photos.search"
let API_KEY = //API KEY
let TEXT = "maltipoo" 
let EXTRAS = "url_m"
let FORMAT = "json"
let NO_JSON_CALLBACK = "1"



// MARK: - ViewController: UIViewController

class ViewController: UIViewController {
    
    
    

    // MARK: Properties
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var photoTitleLabel: UILabel!
    @IBOutlet weak var defaultLabel: UILabel!
    @IBOutlet weak var phraseTextField: UITextField!
    @IBOutlet weak var latitudeTextField: UITextField!
    @IBOutlet weak var longitudeTextField: UITextField!
    
    
    
    //tap recognizer
    var tapRecognizer:UITapGestureRecognizer? = nil
    var searchText:String = TEXT
    
    //BUTTONS

    @IBAction func searchPhotosByPhraseButtonTouchUp(sender: AnyObject) {
        
        if phraseTextField.text! == "" {
            photoTitleLabel.text = "please input a phrase to search"
            return
        }
        
        if let searchText = phraseTextField.text {
            print("about to search keyterm: \(searchText)")
            getImageFromFlick(searchText)
        } else {
            searchText = TEXT
            print("about to search maltipoo: \(TEXT)")
            getImageFromFlick(searchText)
        }
        
    }
    
    @IBAction func searchPhotosByLatLonButtonTouchUp(sender: AnyObject) {
        
        var lat = self.latitudeTextField.text!
        var long = self.longitudeTextField.text!
        
        if Float32(lat) < -90.0 || Float32(lat) > 90.0 || Float32(long) < -180.0 || Float32(long) > 180.0  {
            photoTitleLabel.text = "please input latitude between [-90,90] and longitude between [-180,180]"
            return
        }

        
        getImageFromLatLong(lat, long: long)
        
    }
    
    //TAP GESTURE FUNCTIONS
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initializing the textfield
        phraseTextField.text = TEXT
        
        
//        print("Initialize the tapRecognizer in viewDidLoad")
        tapRecognizer = UITapGestureRecognizer(target:self, action: "handleSingleTap:")
        tapRecognizer?.numberOfTapsRequired = 1
        
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        //add tap recognizer to dismiss keyboard
        self.addKeyboardDismissRecognizer()
        
        //subscribe to keyboard events so we can adjust the view to show hidden controls
        self.subscribeToKeyboardNotifications()
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        //remove tapRecognizer
        self.removeKeyboardDismissRecognizer()
        
        //usubscrive from keyboard notifications
        self.unsubscribeToKeyboardNotifications()
    }
    
    // MARK: Show/Hide Keyboard
    
    func addKeyboardDismissRecognizer() {
        // add the recognizer to dismiss the keyboard
        self.view.addGestureRecognizer(tapRecognizer!)
        
    }
    
    func removeKeyboardDismissRecognizer() {
        print("Remove the recognizer to dismiss the keyboard")
        //remove the recognizer to dismiss the keyboard
        self.view.removeGestureRecognizer(tapRecognizer!)
    }
    
    func handleSingleTap(recognizer: UITapGestureRecognizer) {
        //end editing here
        self.view.endEditing(true)
    
    }
    
    func subscribeToKeyboardNotifications() {
        //subscribe to keyboardWillShow
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        //subscribe to keyboardWillHide
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        
        
    }
    
    func unsubscribeToKeyboardNotifications() {
        //ubsubscribe to the keyboardsWillShow
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        //shift the view's frame up
        if self.photoImageView.image != nil {
            self.defaultLabel.alpha = 0.0
        }
        if self.view.frame.origin.y == 0.0 {
            self.view.frame.origin.y -= self.getKeyboardHeight(notification) / 2
        }
        
    }
    
    func keyboardWillHide(notification: NSNotification) {
        
        if self.photoImageView.image == nil {
            self.defaultLabel.alpha = 1.0
        }
        
        if self.view.frame.origin.y != 0.0 {
            self.view.frame.origin.y += self.getKeyboardHeight(notification) / 2
        }
        
    }
    
    func getKeyboardHeight(notification: NSNotification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.CGRectValue().height
    }
    
    
    //FUNCTION TO GET IMAGES FROM FLICKR
    
    func getImageFromFlick(sender: String){
        

        
        //get session
        let session = NSURLSession.sharedSession()
        
        //get url
        
        
        let urlString = BASE_URL + "?method=" + METHOD_NAME + "&api_key=" + API_KEY + "&text=" + sender + "&format=" + FORMAT + "&extras=" + EXTRAS + "&nojsoncallback=" + NO_JSON_CALLBACK
    
        let url = NSURL(string: urlString)
        
        //get request
        let request = NSURLRequest(URL: url!)
        
        //initialize task
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            guard (error == nil) else {
                print("error with task")
                return
            }
            
            guard let data = data else {
                print("no data areceived")
                return
            }
            
            var parsedResult: AnyObject!
            
            do {
                
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as! NSDictionary
//                print(parsedResult)
                
                let photosDictionary = parsedResult["photos"] as! NSDictionary
                let photoArray = photosDictionary["photo"]! as! [[String:AnyObject]]
                
                //grab random index
                let randomPhotoIndex = Int(arc4random_uniform(UInt32(photoArray.count)))
                //grab random photo from the array 
                let randomPhoto = photoArray[randomPhotoIndex]
            
                
                //get the urlString of the image
                let imageUrlString = randomPhoto["url_m"] as! String
                
                //get the NSURL using the string
                let imageNSURL = NSURL(string: imageUrlString)!
                
                //get the data using the NSURL
                if let imageData = NSData(contentsOfURL: imageNSURL) {
                    dispatch_async(dispatch_get_main_queue(), {
                    
                        self.photoImageView.image = UIImage(data: imageData)
                        self.photoTitleLabel.text = randomPhoto["title"] as! String
                    })
                } else {
                    print("could not convert image data from NSURL")
                }
                
                
            } catch {
                print("problem getting the JSON object")
            }
            
          
        }
        
            
        //execute task
        task.resume()
        
        
    }
    
    
    func getImageFromLatLong(lat: String, long: String){
        
        let sender = "maltipoo"
        
        let minLong = String(Float32(long)!)
        let minLat = String(Float32(lat)!)
        let maxLong = String(Float32(long)! + 10)
        let maxLat = String(Float32(lat)! + 10)
        
        let CSVBox = minLong + "," + minLat + "," + maxLong + "," + maxLat
        print(CSVBox)
        
        //session
        let session = NSURLSession.sharedSession()
        
        //get url
        let urlString = BASE_URL + "?method=" + METHOD_NAME + "&api_key=" + API_KEY + "&bbox=" + CSVBox + "&format=" + FORMAT + "&extras=" + EXTRAS + "&nojsoncallback=" + NO_JSON_CALLBACK
        let url = NSURL(string: urlString)
        let request = NSURLRequest(URL: url!)
        
        //set up the task
        let task = session.dataTaskWithRequest(request){ (data, response, error) in
        
            //if there was an error, return
            guard error == nil else {
                print("error getting image from lat/long")
                return
            }
            
            //if there is no data received
            guard let data = data else {
                print ("no data returned from image via lat/long")
                return
            }
            
             var parsedResult: AnyObject!
            
            do {
                
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as! NSDictionary
                //                print(parsedResult)
                
                let photosDictionary = parsedResult["photos"] as! NSDictionary
                let photoArray = photosDictionary["photo"]! as! [[String:AnyObject]]
                
                //grab random index
                let randomPhotoIndex = Int(arc4random_uniform(UInt32(photoArray.count)))
                //grab random photo from the array
                let randomPhoto = photoArray[randomPhotoIndex]
                
                
                //get the urlString of the image
                let imageUrlString = randomPhoto["url_m"] as! String
                
                //get the NSURL using the string
                let imageNSURL = NSURL(string: imageUrlString)!
                
                //get the data using the NSURL
                if let imageData = NSData(contentsOfURL: imageNSURL) {
                    dispatch_async(dispatch_get_main_queue(), {
                        
                        self.photoImageView.image = UIImage(data: imageData)
                        self.photoTitleLabel.text = randomPhoto["title"] as! String
                    })
                } else {
                    print("could not convert image data from NSURL")
                }
                
                
            } catch {
                print("problem getting the JSON object")
            }
            
        
        }
        
        
        
        task.resume()
        
    }
    
}