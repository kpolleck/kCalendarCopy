//
//  ViewController.swift
//  kCalendarCopy
//
//  Created by Ken Polleck on 1/9/22.
//
//  Based in part on:
//  1) https://medium.com/@fede_nieto/manage-calendar-events-with-eventkit-and-eventkitui-with-swift-74e1ecbe2524
//  2) https://gist.github.com/Fedenieto90/95de03d6f002a79adf54da7b8e7ae72d
//  3) https://dev.to/nemecek_f/how-to-use-ekcalendarchooser-in-swift-to-let-user-select-calendar-in-ios-4al5

import UIKit
import EventKitUI
import EventKit

class EventViewController: UIViewController, EKCalendarChooserDelegate {
    // EKEventViewDelegate
    
    // let eventStore = EKEventStore() // now part of EventsCalendarManager
    let calendarManager = EventsCalendarManager()
    var selectedCalendar : EKCalendar?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        selectedCalendar = calendarManager.eventStore.defaultCalendarForNewEvents
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(showCalendarChooser))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addToCalendar))
    }
    
    @objc func showCalendarChooser() {
        let vc = EKCalendarChooser(selectionStyle: .single, displayStyle: .allCalendars, entityType: .event, eventStore: calendarManager.eventStore)
        vc.showsDoneButton = false
        vc.showsCancelButton = true
        vc.delegate = self
        
        let afterPresent = { print("presented")}
        present(UINavigationController(rootViewController: vc), animated: true, completion: afterPresent)
        // Note:  Code continues while vc is being presented
    }
    
    @objc func addToCalendar() {
        
        let newEvent = EKEvent(eventStore: calendarManager.eventStore)
        newEvent.calendar = selectedCalendar
        newEvent.title = "Event Test"
        newEvent.startDate = Date()
        newEvent.endDate = Date()
        
        calendarManager.addEventToCalendar(event: newEvent, completion: { (result) in
            switch result {
            case .success:
                print("Success.  Added" + newEvent.title + " to " + newEvent.calendar.title)
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
    
    func calendarChooserDidFinish(_ calendarChooser: EKCalendarChooser) {
        // print("Dismissing calendarChooser")
        // print(calendarChooser.selectedCalendars)
        calendarChooser.dismiss(animated: true, completion: nil)
    }
    
    func calendarChooserSelectionDidChange(_ calendarChooser: EKCalendarChooser) {
        selectedCalendar = calendarChooser.selectedCalendars.first!
        print(calendarChooser.selectedCalendars)
        print("Changed calendarChooser selection")
        calendarChooser.dismiss(animated: true, completion: nil)
    }
    
    func calendarChooserDidCancel(_ calendarChooser: EKCalendarChooser) {
        // print("Cancelling calendarChooser")
        calendarChooser.dismiss(animated: true, completion: nil)
    }
}
