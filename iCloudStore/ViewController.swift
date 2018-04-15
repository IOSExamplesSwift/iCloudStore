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
    var ubiquityURL: URL?
    var metaDataQuery: NSMetadataQuery?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadFile()
    }

    func loadFile() {
        let filemgr = FileManager.default
        
        ubiquityURL = filemgr.url(forUbiquityContainerIdentifier: nil)
        
        guard ubiquityURL != nil else {
            print ("Unable to access iCloud Account")
            print ("Open the Setting app and enter Apple ID into iCloud setting")
            return
        }
        
        ubiquityURL = ubiquityURL?.appendingPathComponent("Documents/savefile.txt")
        
        metaDataQuery = NSMetadataQuery()
        
        metaDataQuery?.predicate = NSPredicate(format: "%K like 'savefile.txt'", NSMetadataItemFSNameKey)
        metaDataQuery?.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.metaDataQueryDidFinishGathering), name: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: metaDataQuery!)
        
        metaDataQuery?.start()
    }
    
    @objc func metaDataQueryDidFinishGathering(notification: NSNotification) -> Void
    {
        let query: NSMetadataQuery = notification.object as! NSMetadataQuery
        
        query.disableUpdates()
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: query)
        
        query.stop()
        
        if query.resultCount == 1 {
            let resultURL = query.value(ofAttribute:  NSMetadataItemURLKey, forResultAt: 0) as! URL
            
            document = MyDocument(fileURL: resultURL as URL)
            
            document?.open(completionHandler: {(success: Bool) -> Void in
                if success {
                    print("iCloud file open OK")
                    self.textView.text = self.document?.userText
                    self.ubiquityURL = resultURL as URL
                } else {
                    print("iCloud file open failed")
                }
            })
        } else {
            if let url = ubiquityURL {
                document = MyDocument(fileURL: url)
                
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
        document?.userText = textView.text
        if let url = ubiquityURL {
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

