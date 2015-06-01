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

// Controls display of details for items from Done tab
class DoneDetailsViewController: UITableViewController {
    // table cell identifiers
    let doneDetailsCellIdentifier = "doneDetailsItemCell"
    
     // reference to item for display
    var courseId: String?
    var itemIndex: Int?
    
    // section identifiers
    let topicSectionIndex = 0
    let detailSectionIndex = 1
    
    // topic row identifiers
    let typeTopicRowIndex = 0
    let titleTopicRowIndex = 1
    
    // detail row identifiers
    let personDetailRowIndex = 0
    let typeDetailRowIndex = 1
    let titleDetailRowIndex = 2
    let timeDetailRowIndex = 3
    
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
        return 2 // topic and detail
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch section {
        case topicSectionIndex:
            return 2 // title, objectType
            
        case detailSectionIndex:
            return 4 // person, title, objectType, postedTime
        default:
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection: Int) -> String? {
        switch titleForHeaderInSection {
        case topicSectionIndex:
            return "Topic"
        case detailSectionIndex:
            return "Detail"
        default:
            return ""
        }
    }
    
    override func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(doneDetailsCellIdentifier, forIndexPath: indexPath) as! UITableViewCell
        
        var happenings = LearningStudio.api.userData!.happenings![courseId!]
        var happening = happenings![itemIndex!]
        
        var key = ""
        var value = ""
        
        // extract main (key) and detail (value) labels for row
        switch indexPath.section {
        case topicSectionIndex:
            var target = happening["target"] as! [String:AnyObject]
            switch indexPath.row {
            case typeTopicRowIndex:
                key = "Type"
                var type = target["objectType"] as! String
                switch type {
                case "dropbox-basket":
                    value = "Dropbox Basket"
                case "thread-topic":
                    value = "Discussion Topic"
                case "course":
                    value = "Course"
                case "gradable-item":
                    value = "Grade"
                default:
                    value = type
                }
            case titleTopicRowIndex:
                key = "Title"
                value = target["title"] as! String
            default:
                key = ""
                value = ""
            }
        case detailSectionIndex:
            var object = happening["object"] as! [String:AnyObject]
            switch indexPath.row {
            case personDetailRowIndex:
                key = "Person"
                var actor = happening["actor"] as! [String:AnyObject]
                if actor["title"] == nil {
                    value = "N/A"
                }
                else {
                    value = actor["title"] as! String
                }
            case typeDetailRowIndex:
                key = "Type"
                var type = object["objectType"] as! String
                switch type {
                case "dropbox-submission":
                    value = "Dropbox Submission"
                case "thread-topic":
                    value = "Discussion Topic"
                case "thread-post":
                    value = "Discussion Post"
                case "grade":
                    value = "Grade Available"
                case "exam-submission":
                    value = "Exam Submission"
                default:
                    value = type
                }
            case titleDetailRowIndex:
                key = "Title"
                if object["title"] != nil {
                    value = object["title"] as! String
                }
                else {
                    var target = happening["target"] as! [String:AnyObject]
                    value = target["title"] as! String
                }
            case timeDetailRowIndex:
                key = "Time"
                value = LearningStudio.api.convertCourseDate(courseId!, dateString: happening["postedTime"] as! String, humanize: true)
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
