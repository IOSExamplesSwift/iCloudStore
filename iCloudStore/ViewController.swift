//
//  ViewController.swift
//  iCloudStore
//
//  Created by Douglas Alexander on 3/24/18.
//  Copyright © 2018 Douglas Alexander. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var textView: UITextView!
    
    var document: MyDocument?
    var documentURL: URL?
    
    // name ubiquitURL because the document stored on iCloud is ubiquitous as it canbe accessed by any device
    var ubiquityURL: URL?
    
    // iClod document search is preformed using NSMetaDataQuery
    var metaDataQuery: NSMetadataQuery?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadFile()
    }

    func loadFile() {
        let filemgr = FileManager.default
        
        // ceate the ubiquityURL; passing in nil defaults to the 1st container list in the entitlements file
        ubiquityURL = filemgr.url(forUbiquityContainerIdentifier: nil)
        
        // validte the URL
        guard ubiquityURL != nil else {
            print ("Unable to access iCloud Account")
            print ("Open the Setting app and enter Apple ID into iCloud setting")
            return
        }
        
        // append the 'Doucuments' sub-directory to the URL path
        ubiquityURL = ubiquityURL?.appendingPathComponent("Documents/savefile.txt")
        
        // searching iCloud storage requires using an instance ofNSMetatDataQuery
        metaDataQuery = NSMetadataQuery()
        
        // search the iCloud storage are to find 'savefile.txt'
        metaDataQuery?.predicate = NSPredicate(format: "%K like 'savefile.txt'", NSMetadataItemFSNameKey)
        metaDataQuery?.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        
        // setup an observer to hanlde the search completion
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.metaDataQueryDidFinishGathering), name: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: metaDataQuery!)
        
        // start the query
        metaDataQuery?.start()
    }
    
    
    // method to handle search completion
    @objc func metaDataQueryDidFinishGathering(notification: NSNotification) -> Void
    {
        // get the query object
        let query: NSMetadataQuery = notification.object as! NSMetadataQuery
        
        // disbale the query - don't need additional responses
        query.disableUpdates()
        
        // remove the notification observer -
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: query)
        
        // and stop the query
        query.stop()
        
        // verify that at least 1 match occurred
        if query.resultCount == 1 {
            
            // get the URL of the 1st document
            let resultURL = query.value(ofAttribute:  NSMetadataItemURLKey, forResultAt: 0) as! URL
            
            // get the document from the resultURL using MyDocument class
            document = MyDocument(fileURL: resultURL as URL)
            
            // open the document will trigger a call to load(fromContents:) method in the MyDocument object
            document?.open(completionHandler: {(success: Bool) -> Void in
                
                // if successful assign the text to textView property so the user can see it
                if success {
                    print("iCloud file open OK")
                    self.textView.text = self.document?.userText
                    self.ubiquityURL = resultURL as URL
                } else {
                    print("iCloud file open failed")
                }
            })
        } else {
            // the file does not exsist;
            if let url = ubiquityURL {
                
                // create the document object
                document = MyDocument(fileURL: url)
                
                // save the document object on iCloud
                document?.save(to: url, for: .forCreating, completionHandler: { (success: Bool) -> Void in
                    if success {
                        print("iCloud create OK")
                    } else {
                        print("iCloud create feiled")
                    }
                })
            }
        }
    }
    
    
    @IBAction func saveDocument(_ sender: Any) {
        // get the user entered text
        document?.userText = textView.text
        
        // create the destination URL
        if let url = ubiquityURL {
            
            // save the document using overWrite option
            document?.save(to: url, for: .forOverwriting, completionHandler: { (success: Bool) -> Void in
                if success {
                    print("Save ownerwite OK")
                } else {
                    print("Save overwrite failed")
                }
            })
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

