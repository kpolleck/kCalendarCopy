//
//  CalendarListTableCell.swift
//  kCalendarCopy
//
//  Created by Ken Polleck on 7/23/23.
//

import UIKit

// KEP 2023-07-23 I tried to use outlets, but I couldn't connect the storyboard to this CLASS using the Assistant Editor, and the labels were nill to the program.  Using tags instead.

class CalendarListTableCell: UITableViewCell {

    @IBOutlet weak var calendarName: UILabel!
    @IBOutlet weak var calendarInfo: UILabel!
    @IBOutlet weak var actOnCalendarSwitch: UISwitch!
    
    override func awakeFromNib() {
        print("init CalendarListTableCell")
        super.awakeFromNib()
        // Initialization code
    }
    
    func customize(_ customString: String) {  // *TODO* Probably should use this to update cell instead of in CalendarListTableView
    }

    @IBAction func actOnCalendarSwitchChanged(_ sender: Any) {
        // letting work be done in CalendarListTableView
    }
}

