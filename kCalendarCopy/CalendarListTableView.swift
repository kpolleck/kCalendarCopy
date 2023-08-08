//
//  CalendarListTableView.swift
//  kCalendarCopy
//
//  Handles TableView for list of calendars on main view
//
//  Created by Ken Polleck on 11/6/22.
//

import UIKit
import EventKitUI
import EventKit
// import FSCalendar

// Table that shows the two calendars
// Pressing a calendar calls showCalendarChooser
// Long Press currently doesn't do anything

extension MainViewController:  UITableViewDelegate, UITableViewDataSource, EKCalendarChooserDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    // create a cell for each table view row
    // KEP-2023-07-23 I had been programming creating subviews, but they were created every time this was called, not just initially.  I've now created a Custom UITableViewCell Class.
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // create a new cell if needed or reuse an old one
        let cell = calendarTableView.dequeueReusableCell(withIdentifier: "calendarListTableCell") as! CalendarListTableCell
        
        // set the content from the data model
        cell.calendarName?.text = self.calendarList[indexPath.row]
        cell.calendarName?.adjustsFontSizeToFitWidth = true
        cell.backgroundColor = self.calendarColor[indexPath.row]
        
        // Count of matches
        let label = cell.calendarInfo!
        label.text = "Matches:" + String(format: "%d",self.calendarMatches[indexPath.row])
        
        let cellSwitch = cell.actOnCalendarSwitch!
        if actOnCalendarSwitches.count < 2 {
            actOnCalendarSwitches.append(cellSwitch)
        }
        
        // set up switch change
        cellSwitch.addTarget(self, action: #selector(switchChanged(sender:)), for: .valueChanged)
        
        // set up long press gesture recognizer
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.tableViewCellLongPressed))
        longPressGestureRecognizer.minimumPressDuration = 0.5
        cell.addGestureRecognizer(longPressGestureRecognizer)
        
        return cell
    }
    
    @objc func switchChanged(sender : UISwitch) {
        
        let whichSwitchChanged = calendarTableView.indexPath(for: sender.superview?.superview as! UITableViewCell)!.row
        if whichSwitchChanged == actOnCalendar { // switch which was on is being turned off
            actOnCalendar = -1
        } else { // switch which was off is being turned on
            actOnCalendar = whichSwitchChanged
            updateStatus("Now toggling \"\(calendarArray[whichSwitchChanged]!.title)\" calendar.")
        }
        setUIFeatures()
    }
    
    // method to run when table view cell is tapped
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // print("You tapped cell number \(indexPath.row).")
        selectedCalendarRow = indexPath.row
        showCalendarChooser()
        tableView.deselectRow(at: indexPath, animated: true) // Leaves the color of the cell (vs. selected=gray)
    }
    
    @objc func tableViewCellLongPressed() {
        updateLog("Long Press")
    }
    
    func showCalendarChooser() {
        let vc = EKCalendarChooser(selectionStyle: .single, displayStyle: .allCalendars, entityType: .event, eventStore: calendarManager.eventStore)
        vc.showsDoneButton = false
        vc.showsCancelButton = true
        vc.delegate = self
        
        // let afterPresent = { print("presented")} // One way to write code to be shown as a completion hanlder
        present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
        // Note:  Code continues while vc is being presented
    }
    
    func calendarChooserDidFinish(_ calendarChooser: EKCalendarChooser) {
        calendarChooser.dismiss(animated: true, completion: nil)
    }
    
    func calendarChooserSelectionDidChange(_ calendarChooser: EKCalendarChooser) {
        let selectedCalendar = calendarChooser.selectedCalendars.first!
        calendarChooser.dismiss(animated: true, completion: nil)
        
        calendarArray[selectedCalendarRow] = selectedCalendar
        calendarList[selectedCalendarRow] = selectedCalendar.title
        calendarColor[selectedCalendarRow] = UIColor(cgColor: selectedCalendar.cgColor)
        calendarValid[selectedCalendarRow] = true
        
        if calendarArray[0] != nil && calendarArray[1] != nil { // only save if both calendars have been chosen
            defaults.set([calendarArray[0]?.calendarIdentifier,calendarArray[1]?.calendarIdentifier], forKey: "calendarIDArray")
        }
        
        updateEventDates()
        setUIFeatures()
    }
    
    func calendarChooserDidCancel(_ calendarChooser: EKCalendarChooser) {
        calendarChooser.dismiss(animated: true, completion: nil)
    }
}
