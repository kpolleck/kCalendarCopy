//
//  StatusHistoryViewController.swift
//  kCalendarCopy
//
//  Shows status history
//
//  Created by Ken Polleck on 6/9/23.
//

import UIKit

class StatusHistoryViewController: UIViewController {
    
    @IBOutlet weak var historyField: UITextView!
    
    var mainVC = MainViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // historyField.isScrollEnabled = true
        // historyField.isUserInteractionEnabled = true
        historyField.font = UIFont.systemFont(ofSize: 16)
        // historyField.backgroundColor = UIColor(red: 39/255, green: 53/255, blue: 182/255, alpha: 1)
        historyField.textColor = UIColor.white
        historyField.backgroundColor = UIColor(red: 100/255, green: 100/255, blue: 100/255, alpha: 1)
        historyField.text = mainVC.statusHistory
    }
        
    @IBAction func cancel(_ sender: Any) {
        self.presentingViewController?.dismiss(animated: true, completion:nil)
    }
    
    @IBAction func clear(_ sender: Any) {
        mainVC.statusHistory = ""
        historyField.text = ""
    }
}
