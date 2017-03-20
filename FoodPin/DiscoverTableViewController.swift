//
//  DiscoverTableViewController.swift
//  FoodPin
//
//  Created by Yi-Yun Chen on 2017/3/16.
//  Copyright © 2017年 AppCoda. All rights reserved.
//

import UIKit
import CloudKit

class DiscoverTableViewController: UITableViewController {

    
    @IBOutlet var spinner: UIActivityIndicatorView!
    
    var restaurants: [CKRecord] = []
    var imageCache = NSCache<AnyObject, AnyObject>()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = UIRefreshControl()
        refreshControl?.backgroundColor = UIColor.white
        refreshControl?.tintColor = UIColor.gray
        refreshControl?.addTarget(self, action: #selector(getRecordsFromCloud), for: UIControlEvents.valueChanged)
        
        
        spinner.hidesWhenStopped = true
        spinner.center = view.center
        view.addSubview(spinner)
        spinner.startAnimating()
        
        getRecordsFromCloud()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return restaurants.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! DiscoverTableViewCell
        
        let restaurant = restaurants[indexPath.row]
        //cell.textLabel?.text = restaurant.object(forKey: "name") as? String
        cell.typeLabel.text = restaurant.object(forKey: "type") as? String
        cell.nameLabel.text = restaurant.object(forKey: "name") as? String
        cell.locationLabel.text = restaurant.object(forKey: "location") as? String
        
        // lazy loading image
        //cell.storeImageView.image = UIImage(named: "photoalbum")
        //cell.imgaeView.contentMode = .scaleAspectFit
        
        // 檢查圖是否已存在快取中
        if let imageFileURL = imageCache.object(forKey: restaurant.recordID) as? URL {
            //print("Get image form cache")
            cell.storeImageView.image = UIImage(data: NSData(contentsOf: imageFileURL)! as Data)
        } else {
            
            let publicDatabase = CKContainer.init(identifier: "iCloud.doupi0331").publicCloudDatabase
            let fetchRecordsImageOperation = CKFetchRecordsOperation(recordIDs: [restaurant.recordID])
            fetchRecordsImageOperation.desiredKeys = ["image"]
            fetchRecordsImageOperation.queuePriority = .veryHigh
            
            fetchRecordsImageOperation.perRecordCompletionBlock = {
                (record: CKRecord?, recordID: CKRecordID?, error: Error?) -> Void in
                
                if error != nil {
                    print("Failed to get restaurant image: \(error!.localizedDescription)")
                    return
                }
                
                if let restaurantRecord = record {
                    OperationQueue.main.addOperation({
                        if let imageAsset = restaurantRecord.object(forKey: "image") as? CKAsset {
                            cell.storeImageView.image = UIImage(data: NSData(contentsOf: imageAsset.fileURL)! as Data)
                            
                            // 加入圖像到快取中
                            self.imageCache.setObject(imageAsset.fileURL as AnyObject, forKey: restaurant.recordID)
                        }
                    })
                }
            }
            
            publicDatabase.add(fetchRecordsImageOperation)
        }
        

        
        /*if let image = restaurant.object(forKey: "image") {
            let imageAsset = image as! CKAsset
            cell.imageView?.image = UIImage(data: NSData(contentsOf: imageAsset.fileURL)! as Data)
        }*/
        
            
        return cell
    }

    // Cloud data
    func getRecordsFromCloud() {
        
        // 清除資料
        restaurants.removeAll()
        tableView.reloadData()
        
        let cloudContainer = CKContainer.init(identifier: "iCloud.doupi0331")
        let publicDatabase = cloudContainer.publicCloudDatabase
        let predicate = NSPredicate(value: true)
        
        // 新增查詢
        let query = CKQuery(recordType: "Restaurant", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let queryOperation = CKQueryOperation(query: query)
        //queryOperation.desiredKeys = ["name", "image"]
        queryOperation.desiredKeys = ["name","type","location"]
        queryOperation.queuePriority = .veryHigh
        queryOperation.resultsLimit = 50
        queryOperation.recordFetchedBlock = { (record: CKRecord!) -> Void in
            if let restaurantRecord = record {
                self.restaurants.append(restaurantRecord)
            }
        }
        
        queryOperation.queryCompletionBlock = { (cursor: CKQueryCursor?, error: Error?) -> Void in
            if error != nil {
                print("Failed to get data from iCloud - \(error!.localizedDescription)")
                return
            }
            
            print("Successfully retrieve the data from iCloud")
            OperationQueue.main.addOperation({
                self.spinner.stopAnimating()
                self.tableView.reloadData()
            })
        }
        
        publicDatabase.add(queryOperation)
        
        self.refreshControl?.endRefreshing()
        
        /* 未篩選欄位
         publicDatabase.perform(query, inZoneWith: nil, completionHandler: {
            (results, error) -> Void in
            if error != nil {
                print(error!)
                return
            }
            if let results = results {
                print("Completed the download of Restaurant data")
                self.restaurants = results
                
                OperationQueue.main.addOperation({
                    self.tableView.reloadData()
                })
                
            }
        })*/
    }

    
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
