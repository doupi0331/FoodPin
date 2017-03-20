//
//  AddRestaurantController.swift
//  FoodPin
//
//  Created by Simon Ng on 31/8/15.
//  Copyright © 2015 AppCoda. All rights reserved.
//

import UIKit
import CoreData
import CloudKit

class AddRestaurantController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet var imageView:UIImageView!

    @IBOutlet var nameTextField:UITextField!
    @IBOutlet var typeTextField:UITextField!
    @IBOutlet var locationTextField:UITextField!
    @IBOutlet var phoneNumberTextField:UITextField!
    @IBOutlet var yesButton:UIButton!
    @IBOutlet var noButton:UIButton!
    
    var isVisited = true
    
    var restaurant:Restaurant!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                let imagePicker = UIImagePickerController()
                imagePicker.allowsEditing = false
                imagePicker.sourceType = .photoLibrary
                imagePicker.delegate = self
                
                self.present(imagePicker, animated: true, completion: nil)
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - UIImagePickerControllerDelegate methods
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        imageView.image = info[UIImagePickerControllerOriginalImage] as? UIImage
        imageView.contentMode = UIViewContentMode.scaleAspectFill
        imageView.clipsToBounds = true
                    
        let leadingConstraint = NSLayoutConstraint(item: imageView, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: imageView.superview, attribute: NSLayoutAttribute.leading, multiplier: 1, constant: 0)
        leadingConstraint.isActive = true
        
        let trailingConstraint = NSLayoutConstraint(item: imageView, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: imageView.superview, attribute: NSLayoutAttribute.trailing, multiplier: 1, constant: 0)
        trailingConstraint.isActive = true
                    
        let topConstraint = NSLayoutConstraint(item: imageView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: imageView.superview, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 0)
        topConstraint.isActive = true
                    
        let bottomConstraint = NSLayoutConstraint(item: imageView, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: imageView.superview, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: 0)
        bottomConstraint.isActive = true
                    
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Action methods
    
    @IBAction func save(_ sender:UIBarButtonItem) {
        let name = nameTextField.text
        let type = typeTextField.text
        let location = locationTextField.text
        let phoneNumber = phoneNumberTextField.text
        
        // Validate input fields
        if name == "" || type == "" || location == "" {
            let alertController = UIAlertController(title: "Oops", message: "We can't proceed because one of the fields is blank. Please note that all fields are required.", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
            
            return
        }
        
        if let managedObjectContext = (UIApplication.shared.delegate as? AppDelegate)?.managedObjectContext {
            restaurant = NSEntityDescription.insertNewObject(forEntityName: "Restaurant", into: managedObjectContext) as! Restaurant
            restaurant.name = name!
            restaurant.type = type!
            restaurant.location = location!
            restaurant.phoneNumber = phoneNumber!
            
            if let restaurantImage = imageView.image {
                restaurant.image = UIImagePNGRepresentation(restaurantImage)
            }
            restaurant.isVisited = isVisited as NSNumber?
            
            do {
                try managedObjectContext.save()
            } catch {
                print(error)
                return
            }
            
            // save data to iCloud
            saveRecordToCloud(restaurant: restaurant)
        }
        
        // Dismiss the view controller
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func toggleBeenHereButton(_ sender: UIButton) {
        // Yes button clicked
        if sender == yesButton {
            isVisited = true
            yesButton.backgroundColor = UIColor(red: 235.0/255.0, green: 73.0/255.0, blue: 27.0/255.0, alpha: 1.0)
            noButton.backgroundColor = UIColor.gray
        } else if sender == noButton {
            isVisited = false
            yesButton.backgroundColor = UIColor.gray
            noButton.backgroundColor = UIColor(red: 235.0/255.0, green: 73.0/255.0, blue: 27.0/255.0, alpha: 1.0)
        }
    }
    
    func saveRecordToCloud(restaurant: Restaurant) {
        let record = CKRecord(recordType: "Restaurant")
        record.setValue(restaurant.name, forKey: "name")
        record.setValue(restaurant.type, forKey: "type")
        record.setValue(restaurant.location, forKey: "location")
        record.setValue(restaurant.phoneNumber, forKey: "phone")
        
        // 調整圖的大小
        let originalImage = UIImage(data: restaurant.image!)!
        let scalingFactor = (originalImage.size.width > 1024) ? 1024 / originalImage.size.width : 1.0
        let scaledImage = UIImage(data: restaurant.image!, scale: scalingFactor)!
        
        // 將檔案寫入暫存，並取得暫存檔案路徑
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(restaurant.name)
        do{
            try UIImageJPEGRepresentation(scaledImage, 0.8)?.write(to: fileURL,  options: .atomicWrite)
            
        } catch {
            print("Failed to save the temporary image")
        }
        
        // 建立要上傳的圖
        let imageAsset = CKAsset(fileURL: fileURL)
        record.setValue(imageAsset, forKey: "image")
        
        // 上傳至iCloud
        let publicDatabase = CKContainer.init(identifier: "iCloud.doupi0331").publicCloudDatabase
        publicDatabase.save(record, completionHandler: {
            (record: CKRecord?, error: Error?) -> Void in
            do {
               try FileManager.default.removeItem(at: fileURL)
            } catch {
                print("Failed to save record to the cloud: \(error.localizedDescription)")
            }
        })
        
        
    }
}
