/*
* LearningStudio Mobile Dashboard for iOS
*
* Need Help or Have Questions?
* Please use the PDN Developer Community at https://community.pdn.pearson.com
*
* @category   LearningStudio Sample Application - Mobile
* @author     Wes Williams <wes.williams@pearson.com>
* @author     Pearson Developer Services Team <apisupport@pearson.com>
* @copyright  2015 Pearson Education, Inc.
* @license    http://www.apache.org/licenses/LICENSE-2.0  Apache 2.0
* @version    1.0
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*
* Portions of this work are reproduced from work created and
* shared by Apple and used according to the terms described in
* the License. Apple is not otherwise affiliated with the
* development of this work.
*/

import UIKit

// Controls the settings tab
class SettingsTabViewController: UITableViewController {
    // table cell identifiers
    let textCellIdentifier = "textSettingsCell"
    let courseCellIdentifier = "courseSettingsCell"
    let optionCellIdentifier = "optionSettingsCell"
    
    // section identifiers
    let courseSectionIndex = 0
    let optionSectionIndex = 1
    let refreshSectionIndex = 2
    let logoutSectionIndex = 3
    
    // row identifiers
    let pastOptionRowIndex = 0
    let futureOptionRowIndex = 1
    
    // option configuration
    
    let pastViewLabelText = "Past View"
    let futureViewLabelText = "Future View"
    
    // the number of days of past activity to display
    let pastDateOptions = [
        ["title": "Yesterday", "detail": "I am active", "value" : "1" ],
        ["title": "3 Days", "detail": "I skip days", "value" : "3"],
        ["title": "Week", "detail": "I procrastinate", "value" : "7"],
        ["title": "Month", "detail": "I rarely participate", "value" : "30"],
    ]
    // the number of days of future activity to display
    let futureDateOptions = [
        ["title": "Tomorrow", "detail": "One day at a time", "value": "1" ],
        ["title": "3 Days", "detail": "Aware of what's next", "value": "3"],
        ["title": "Week", "detail": "Aware of the week", "value": "7"],
        ["title": "2 Weeks", "detail": "Planning ahead", "value": "14"],
        ["title": "Month", "detail": "Really on top of it", "value": "30"],
        ["title": "Quarter", "detail": "Prefer to see it coming", "value": "90"],
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // monitor when options are updated. need to refresh the screen
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshData:", name: "RefreshOptions", object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
     override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 4 // courses, options, refresh, logout
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch section {
        case courseSectionIndex:
            // show active and hidden courses
            return LearningStudio.api.userData!.courses!.count +
                    LearningStudio.api.userData!.hiddenCourses!.count
        case optionSectionIndex:
            return 2 // begin, end
        case refreshSectionIndex:
            return 1
        case logoutSectionIndex:
            return 1
        default: // n/a
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection: Int) -> String? {
        
        switch titleForHeaderInSection  {
        case courseSectionIndex:
            return "Courses"
        case optionSectionIndex:
            return "Options"
        default :
            return ""
        }
    }
    
    override func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case courseSectionIndex:
            var cell = tableView.dequeueReusableCellWithIdentifier(courseCellIdentifier, forIndexPath: indexPath) as! UITableViewCell
            
            var course: [String:AnyObject]?
            var activeCourses = LearningStudio.api.userData!.courses!.count
            if indexPath.row < activeCourses { // active courses should display with checkmark
                course = LearningStudio.api.userData!.courses![indexPath.row] as [String:AnyObject]
                cell.accessoryType = UITableViewCellAccessoryType.Checkmark
            }
            else { // hidden courses should display without checkmark
                course = LearningStudio.api.userData!.hiddenCourses![indexPath.row-activeCourses] as [String:AnyObject]
                cell.accessoryType = UITableViewCellAccessoryType.None
            }
            
            cell.textLabel?.text = course!["displayCourseCode"] as? String
            cell.detailTextLabel?.text = course!["title"] as? String
            
            return cell
        case optionSectionIndex:
            var cell = tableView.dequeueReusableCellWithIdentifier(optionCellIdentifier, forIndexPath: indexPath) as! UITableViewCell
            
            if indexPath.row == pastOptionRowIndex {
                cell.textLabel?.text = pastViewLabelText
                // show title for past preference
                cell.detailTextLabel?.text = getPastViewDaysTitle()
            }
            else if indexPath.row == futureOptionRowIndex {
                cell.textLabel?.text = futureViewLabelText
                // show title for future preference
                cell.detailTextLabel?.text = getFutureViewDaysTitle()
            }
            return cell
        case refreshSectionIndex:
            var cell = tableView.dequeueReusableCellWithIdentifier(textCellIdentifier, forIndexPath: indexPath) as! UITableViewCell
            cell.textLabel?.text = "Refresh Data"
            return cell
        case logoutSectionIndex:
            var cell = tableView.dequeueReusableCellWithIdentifier(textCellIdentifier, forIndexPath: indexPath) as! UITableViewCell
            cell.textLabel?.text = "Logout"
            return cell
        default: // n/a
            var cell = tableView.dequeueReusableCellWithIdentifier(textCellIdentifier, forIndexPath: indexPath) as! UITableViewCell
            cell.textLabel?.text = "None"
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.section == courseSectionIndex { // toggle course as active or hidden
            var deletedCourse: [String:AnyObject]?
            var activeCourses = LearningStudio.api.userData!.courses!.count
            var ignored = false
            if indexPath.row < activeCourses {
                // move course object from active to hidden courses
                deletedCourse = LearningStudio.api.userData!.courses!.removeAtIndex(indexPath.row)
                LearningStudio.api.userData!.hiddenCourses!.append(deletedCourse!)
                ignored = true
            }
            else {
                // move course option from hidden to active courses
                deletedCourse = LearningStudio.api.userData!.hiddenCourses!.removeAtIndex(indexPath.row-activeCourses)
                LearningStudio.api.userData!.courses!.append(deletedCourse!)
                ignored = false
            }
            
            // notify of the change in courses
            NSNotificationCenter.defaultCenter().postNotificationName("RefreshCourses", object:self)
            
            // lookup courses to ignore
            var ignoredCourses : [String:Bool]? = NSUserDefaults.standardUserDefaults().objectForKey(LearningStudio.api.defaultIgnoredCoursesKey) as? [String:Bool]
            if ignoredCourses == nil { // init if not present
                ignoredCourses = [:]
            }
            
            // update the ignoredCourses values for this course
            var courseId = String(deletedCourse!["id"] as! Int)
            if !ignored {
                // removing it will keep this object small
                ignoredCourses?.removeValueForKey(courseId)
            }
            else {
                ignoredCourses![courseId] = true
            }
            
            // save ignoredCourse values
            NSUserDefaults.standardUserDefaults().setObject(ignoredCourses!, forKey: LearningStudio.api.defaultIgnoredCoursesKey)
            // alert of changes in display options
            NSNotificationCenter.defaultCenter().postNotificationName("RefreshOptions", object:self)
        }
        else if indexPath.section == refreshSectionIndex { // refresh data
            LearningStudio.api.proceedWithRefresh()
        }
        else if indexPath.section == logoutSectionIndex { // logout
            LearningStudio.api.promptForCredentials()
        }
    }
    
    // Only the options preform seques right now
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let indexPath = tableView.indexPathForCell(sender as! UITableViewCell)
        let optionController = segue.destinationViewController as! SettingOptionsViewController
        
        // prepare display with choices for chosen option
        if sender?.textLabel!?.text == pastViewLabelText {
            optionController.title = "How much past activity?"
            optionController.options = pastDateOptions
            optionController.optionKey = LearningStudio.api.defaultPastViewDaysKey // name of the option to update
        }
        else if sender?.textLabel!?.text == futureViewLabelText {
            optionController.title = "How far into the future?"
            optionController.options = futureDateOptions
            optionController.optionKey = LearningStudio.api.defaultFutureViewDaysKey // name of the option to update
        }
        
    }
    
    func refreshData(notification: NSNotification) {
        tableView.reloadData()
        
        // Alert the user that these changes will not take effect automatically
        let alertController = UIAlertController(title: "Refresh Required", message:
            "'Refresh Data' before leaving this tab.", preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Got it", style: UIAlertActionStyle.Default,handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    // MARK: find titles of options
    
    // lookup past option title to prevent repitition of values
    private func getPastViewDaysTitle() -> String {
        let selectedOption = NSUserDefaults.standardUserDefaults().stringForKey(LearningStudio.api.defaultPastViewDaysKey)
        return getOptionTitle(pastDateOptions,
            selectedOption: selectedOption,
            defaultValue: String(LearningStudio.api.pastViewDaysDefault))
    }
    
    // lookup past option title to prevent repitition of values
    private func getFutureViewDaysTitle() -> String {
        let selectedOption = NSUserDefaults.standardUserDefaults().stringForKey(LearningStudio.api.defaultFutureViewDaysKey)
        return getOptionTitle(futureDateOptions,
            selectedOption: selectedOption,
            defaultValue: String(LearningStudio.api.futureViewDaysDefault))
    }
    
    // shared logic for finding titles of options
    private func getOptionTitle(options: [[String:String]], selectedOption: String?, defaultValue: String) -> String {
        var displayValue = ""
        
        for option in options {
            if selectedOption == nil && defaultValue == option["value"] {
                displayValue = option["title"]!
                break
            }
            else if option["value"] == selectedOption {
                displayValue = option["title"]!
                break
            }
        }
        return displayValue
    }
}
