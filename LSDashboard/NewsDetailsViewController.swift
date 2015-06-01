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

// Controls display of details for items from News tab
class NewsDetailsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    // table cell identifiers
    let doneDetailsCellIdentifier = "newsDetailsItemCell"
    
    // area to display announcement text
    @IBOutlet weak var messageWebView: UIWebView!
    
    // reference to item for display
    var courseId: String?
    var itemIndex: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        var announcements = LearningStudio.api.userData!.announcements![courseId!]
        var announcement = announcements![itemIndex!]
        messageWebView.loadHTMLString(announcement["text"] as! String, baseURL: nil)
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
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 3 // submitter, startDisplayDate, subject
    }
    
    func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(doneDetailsCellIdentifier, forIndexPath: indexPath) as! UITableViewCell
        
        var announcements = LearningStudio.api.userData!.announcements![courseId!]
        var announcement = announcements![itemIndex!]
        
        var key = ""
        var value = ""
        
        // extract main (key) and detail (value) labels for row
        switch indexPath.row {
        case 0:
            key = "From"
            value = announcement["submitter"] as! String
        case 1:
            key = "Time"
            value = LearningStudio.api.convertCourseDate(courseId!, dateString: announcement["startDisplayDate"] as! String, humanize: true)
        case 2:
            key = "Subject"
            value = announcement["subject"] as! String
        default:
            key = ""
            value = ""
        }
     
        cell.textLabel!.text = key
        cell.detailTextLabel?.text = value
        
        return cell
    }
    
}
