//
//  EventViewController.swift
//  kCalendarCopy
//
//  Created by Ken Polleck on 1/9/22.
//
//  Shows a table of possible calendar entries to fill the search fields
//
//  Based in part on:
//  1) https://medium.com/@fede_nieto/manage-calendar-events-with-eventkit-and-eventkitui-with-swift-74e1ecbe2524
//  2) https://gist.github.com/Fedenieto90/95de03d6f002a79adf54da7b8e7ae72d
//  3) https://dev.to/nemecek_f/how-to-use-ekcalendarchooser-in-swift-to-let-user-select-calendar-in-ios-4al5

import UIKit
import EventKitUI
import EventKit

class EventViewController: UIViewController, EKCalendarChooserDelegate, UITableViewDelegate, UITableViewDataSource {
    // EKEventViewDelegate

    @IBOutlet weak var eventsNavigationBar: UINavigationBar!
    @IBOutlet weak var eventTableView: UITableView!
    
    var mainVC = MainViewController()
    
    let calendarManager = EventsCalendarManager()
    var selectedDayCal1Events : [EKEvent] = []
    var selectedDayCal2Events : [EKEvent] = []
    
    var savedEvents : [String] = ["Deb Work"]
    var savedEventStarts : [String] = ["6:30"]
    var savedEventEnds : [String] = ["19:30"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        eventTableView.delegate = self
        eventTableView.dataSource = self
        
        getEventsFor(mainVC.selectedDate)
        
        // navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(showCalendarChooser))
        // navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addToCalendar))

    }
    
    func getEventsFor(_ date : Date) {
        // let calendarsToSearch : [EKCalendar] = [oneCalendar] // *TODO* Could I search both at the same time?
        
        /*
        guard let calendars = mainVC.calendarArray else {
            return
        }
         */
        
        // let calendarsToSearch : [EKCalendar] = [mainVC.calendarArray[0]!,mainVC.calendarArray[1]!]
        
        let startOfDay = date.stripTime()
        let endOfDay = Calendar.current.date(byAdding: .second, value: 86399, to: startOfDay)!
        
        let calendar1 = [mainVC.calendarArray[0]!]
        let predicate1 = calendarManager.eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: calendar1)
        selectedDayCal1Events = calendarManager.eventStore.events(matching: predicate1)
        
        let calendar2 = [mainVC.calendarArray[1]!]
        let predicate2 = calendarManager.eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: calendar2)
        selectedDayCal2Events = calendarManager.eventStore.events(matching: predicate2)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var rowCount = 0
        if section == 0 {
            rowCount = savedEvents.count
        } else if section == 1 {
            rowCount = selectedDayCal1Events.count
        } else if section == 2 {
            rowCount = selectedDayCal2Events.count
        }
        return rowCount
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Saved"
        } else if section == 1 {
            return mainVC.calendarArray[0]!.title
        } else if section == 2 {
            return mainVC.calendarArray[1]!.title
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionHeaderView = UITableViewHeaderFooterView()
        if section == 0 {
            sectionHeaderView.contentView.backgroundColor = UIColor.lightGray
        } else if section == 1 {
            sectionHeaderView.contentView.backgroundColor = mainVC.calendarColor[0]
        } else if section == 2 {
            sectionHeaderView.contentView.backgroundColor = mainVC.calendarColor[1]
        }
        // sectionHeaderView.contentView.tintColor = UIColor.black
        sectionHeaderView.textLabel?.textColor = UIColor.black
        return sectionHeaderView
    }
    
    /* willDisplayHeaderView doesn't seem to be needed
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        guard let view = view as? UITableViewHeaderFooterView else { return }

        if section == 0 {
            view.backgroundView?.backgroundColor = UIColor.blue
        } else if section == 1 {
            view.backgroundView?.backgroundColor = mainVC.calendarColor[0]
        } else if section == 2 {
            view.backgroundView?.backgroundColor = mainVC.calendarColor[1]
        }
        // view.textLabel?.backgroundColor = UIColor.clear // Doesn't seem to be needed
        view.textLabel?.textColor = UIColor.black
    }
    */
    
    // create a cell for each table view row
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // create a new cell if needed or reuse an old one
        let cell:UITableViewCell = (eventTableView.dequeueReusableCell(withIdentifier: "eventCell", for: indexPath) as UITableViewCell?)!
        
        let section = indexPath.section
        let row = indexPath.row
        
        if section == 0 {
            cell.textLabel?.text = savedEvents[row]
            cell.detailTextLabel?.text = savedEventStarts[row] + "-" + savedEventEnds[row]
        } else if section == 1 {
            cell.textLabel?.text = selectedDayCal1Events[row].title
            cell.detailTextLabel?.text = selectedDayCal1Events[row].startDate.formatDate("HH:mm") + "-" + selectedDayCal1Events[row].endDate.formatDate("HH:mm")
        } else if section == 2 {
            cell.textLabel?.text = selectedDayCal2Events[row].title
            cell.detailTextLabel?.text = selectedDayCal2Events[row].startDate.formatDate("HH:mm") + "-" + selectedDayCal2Events[row].endDate.formatDate("HH:mm")
        }
        return cell
    }
    
    // method to run when table view cell is tapped
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let row = indexPath.row
        var eventText = ""
        var eventStart = ""
        var eventEnd = ""
        
        if section == 0 {
            eventText = savedEvents[row]
            eventStart = savedEventStarts[row]
            eventEnd = savedEventEnds[row]
        } else if section == 1 {
            eventText = selectedDayCal1Events[row].title
            eventStart = selectedDayCal1Events[row].startDate.formatDate("HH:mm")
            eventEnd = selectedDayCal1Events[row].endDate.formatDate("HH:mm")
        } else if section == 2 {
            eventText = selectedDayCal2Events[row].title
            eventStart = selectedDayCal2Events[row].startDate.formatDate("HH:mm")
            eventEnd = selectedDayCal2Events[row].endDate.formatDate("HH:mm")
        }
        
        // *TODO* Allow for invalid start and end dates
        mainVC.updateStatus("You selected \(eventText)")
        mainVC.searchField.text = eventText
        mainVC.matchStartTime = eventStart
        mainVC.matchEndTime = eventEnd
        mainVC.startPicker.date = Date(time: eventStart)
        mainVC.endPicker.date = Date(time: eventEnd)
        
        mainVC.updateMainView() // KP20240105a Update bottom section to show correct text for Sync mode
        
        dismiss(animated: true, completion: nil)
        
        // Removed next line; no longer using navigationVC
        // self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    // Not currently used
    @objc func showCalendarChooser() {
        let vc = EKCalendarChooser(selectionStyle: .single, displayStyle: .allCalendars, entityType: .event, eventStore: calendarManager.eventStore)
        vc.showsDoneButton = false
        vc.showsCancelButton = true
        vc.delegate = self
        
        let afterPresent = { print("presented")}
        present(UINavigationController(rootViewController: vc), animated: true, completion: afterPresent)
        // Note:  Code continues while vc is being presented
    }
    
    // Not currently used
    @objc func addToCalendar() {
        
        let newEvent = EKEvent(eventStore: calendarManager.eventStore)
        newEvent.calendar = calendarManager.eventStore.defaultCalendarForNewEvents // just to have something here for now
        newEvent.title = "Event Test"
        newEvent.startDate = Date()
        newEvent.endDate = Date()
        
        calendarManager.addEventToCalendar(event: newEvent, completion: { (result) in
            switch result {
            case .success:
                break
                // print("Success.  Added" + newEvent.title + " to " + newEvent.calendar.title)
            case .failure(let error):
                print("Failure")
                print(error)
            }
        })
    }
    
    /*
     let editEventVC = EKEventEditViewController()
     editEventVC.eventStore = eventStore
     editEventVC.event = newEvent
     present(editEventVC, animated: true)
     */
    
}
