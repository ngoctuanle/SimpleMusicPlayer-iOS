//
//  AboutViewController.swift
//  MusicDemo
//
//  Created by Tuan Le on 1/23/16.
//  Copyright © 2016 Tuan Le. All rights reserved.
//

import UIKit
import MessageUI

class AboutViewController: UIViewController, UITableViewDataSource, UITableViewDelegate,MFMailComposeViewControllerDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var rateCell: UITableViewCell!
    @IBOutlet var guideCell: UITableViewCell!
    @IBOutlet var aboutCell: UITableViewCell!
    @IBOutlet var shareCell: UITableViewCell!
    @IBOutlet var feedbackCell: UITableViewCell!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        NSBundle.mainBundle().loadNibNamed("AboutCell", owner: self, options: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: "SettingsView")
        let builder = GAIDictionaryBuilder.createScreenView()
        tracker.send(builder.build() as [NSObject: AnyObject])
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 3
        } else {
            return 1
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 && indexPath.row == 0 { return rateCell! }
        //if indexPath.row == 1 { return guideCell! }
        if indexPath.section == 0 && indexPath.row == 1 { return shareCell! }
        if indexPath.section == 0 && indexPath.row == 2 { return aboutCell! }
        if indexPath.section == 1 && indexPath.row == 0 { return feedbackCell! }
        return rateCell!
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if indexPath.section == 0 && indexPath.row == 0 {
            let tracker = GAI.sharedInstance().defaultTracker
            let event = GAIDictionaryBuilder.createEventWithCategory("Action", action: "rateApp", label: nil, value: nil)
            tracker.send(event.build() as [NSObject : AnyObject])
            UIApplication.sharedApplication().openURL(NSURL(string : "https://itunes.apple.com/app/id1080880424")!)
        }
        if indexPath.section == 0 && indexPath.row == 1 {
            let tracker = GAI.sharedInstance().defaultTracker
            let event = GAIDictionaryBuilder.createEventWithCategory("Action", action: "shareApp", label: nil, value: nil)
            tracker.send(event.build() as [NSObject : AnyObject])
            
            let activityViewController = UIActivityViewController(
                activityItems: [NSURL(string: "https://itunes.apple.com/app/id1080880424")!],
                applicationActivities: nil)
            
            if let wPPC = activityViewController.popoverPresentationController {
                wPPC.sourceView = self.view
            }
            self.presentViewController(activityViewController, animated: true, completion: nil )
            
        }
        if indexPath.section == 0 && indexPath.row == 2 {
            let tracker = GAI.sharedInstance().defaultTracker
            let event = GAIDictionaryBuilder.createEventWithCategory("Action", action: "seeAboutTeam", label: nil, value: nil)
            tracker.send(event.build() as [NSObject : AnyObject])
            UIApplication.sharedApplication().openURL(NSURL(string : "http://gpaddy.com/home.html")!)
        }
        if indexPath.section == 1 && indexPath.row == 0 {
            let tracker = GAI.sharedInstance().defaultTracker
            let event = GAIDictionaryBuilder.createEventWithCategory("Action", action: "feedBackApp", label: nil, value: nil)
            tracker.send(event.build() as [NSObject : AnyObject])
            let mailComposeViewController = configuredMailComposeViewController()
            if MFMailComposeViewController.canSendMail() {
                self.presentViewController(mailComposeViewController, animated: true, completion: nil)
            } else {
                self.showSendMailErrorAlert()
            }
        }
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func showSendMailErrorAlert() {
        let sendMailErrorAlert = UIAlertView(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.", delegate: self, cancelButtonTitle: "OK")
        sendMailErrorAlert.show()
    }
    
    func configuredMailComposeViewController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
        
        mailComposerVC.setToRecipients(["contact.gpaddy@gmail.com"])
        mailComposerVC.setSubject("Feedback for app SoundHouse")
        mailComposerVC.setMessageBody("Sending from device run iOS \(UIDevice.currentDevice().systemVersion)", isHTML: false)
        
        return mailComposerVC
    }
}
