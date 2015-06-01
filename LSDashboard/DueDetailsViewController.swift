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

// Controls display of details for items from Due tab
class DueDetailsViewController: UITableViewController  {
    // table cell identifiers
    let dueDetailsCellIdentifier = "dueDetailsItemCell"

    // reference to item for display
    var courseId: String?
    var itemIndex: Int?
    
    // section identifiers
    let detailSectionIndex = 0
    let scheduleSectionIndex = 1
    
    // detail section row identifiers
    let sectionDetailRowIndex = 0
    let titleDetailRowIndex = 1
    let typeDetailRowIndex = 2
    let dateDetailRowIndex = 3
    
    // schedule section row identifiers
    let startDateScheduleRowIndex = 0
    let availableBeforeScheduleRowIndex = 1
    let endDateScheduleRowIndex = 2
    let availableAfterScheduleRowIndex = 3
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
        // detail identifiers can be released if not displayed
        if !(self.isViewLoaded()  && self.view.window != nil) {
            courseId = nil
            itemIndex = nil
        }
    }

    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2 // detail and schedule
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch section {
        case detailSectionIndex:
            return 4 // category, titleHeading, title, type
            
        case scheduleSectionIndex:
            return 4 // startDateTime, endDateTime, canAccessBeforeStartDateTime, canAccessAfterEndDateTime
        default:
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection: Int) -> String? {
        switch titleForHeaderInSection {
        case detailSectionIndex:
            return "Item"
        case scheduleSectionIndex:
            return "Schedule"
        default:
            return ""
        }
    }
    
    override func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(dueDetailsCellIdentifier, forIndexPath: indexPath) as! UITableViewCell
       
        var upcomingEvents = LearningStudio.api.userData!.upcomingEvents![courseId!]
        var upcomingEvent = upcomingEvents![itemIndex!]
        
        var key = ""
        var value = ""
        
        // extract main (key) and detail (value) labels for row
        switch indexPath.section {
        case detailSectionIndex:
            switch indexPath.row {
            case sectionDetailRowIndex:
                key = "Section"
                value = upcomingEvent["titleHeading"] as! String
            case titleDetailRowIndex:
                key = "Title"
                value = upcomingEvent["title"] as! String
            case typeDetailRowIndex:
                key = "Type"
                var type = upcomingEvent["type"] as! String
                switch type {
                   case "IQT":
                    value = "Assessment"
                default:
                    value = type
                }
            case dateDetailRowIndex:
                key = "Date"
                var when = upcomingEvent["when"] as! [String:String]
                var eventTime = LearningStudio.api.convertCourseDate(courseId!, dateString: when["time"]!, humanize: true)
                value = eventTime
            default:
                key = ""
                value = ""
            }
        case scheduleSectionIndex:
            var schedule = upcomingEvent["schedule"] as! [String:AnyObject]
            var accessSchedule = schedule["accessSchedule"] as! [String:AnyObject]
            
            switch indexPath.row {
            case startDateScheduleRowIndex:
                key = "Start"
                if accessSchedule["startDateTime"] == nil {
                    value = "Course Start Date"
                }
                else {
                    value = LearningStudio.api.convertCourseDate(courseId!, dateString: accessSchedule["startDateTime"] as! String, humanize: true)
                }
            case availableBeforeScheduleRowIndex:
                key = "Available Before"
                var accessBefore = accessSchedule["canAccessBeforeStartDateTime"] as! Bool
                value = accessBefore ? "Yes" : "No"
            case endDateScheduleRowIndex:
                key = "End"
                if accessSchedule["endDateTime"] == nil {
                    value = "Course End Date"
                }
                else {
                    value = LearningStudio.api.convertCourseDate(courseId!, dateString: accessSchedule["endDateTime"] as! String, humanize: true)
                }
            case availableAfterScheduleRowIndex:
                key = "Avalable After"
                var accessAfter = accessSchedule["canAccessAfterEndDateTime"] as! Bool
                value = accessAfter ? "Yes" : "No"
            default:
                key = ""
                value = ""
            }
        default:
            key = ""
            value = ""
        }

        cell.textLabel!.text = key
        cell.detailTextLabel?.text = value
        
        return cell
    }
}
