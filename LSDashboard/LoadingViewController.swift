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

// Controls loading view
class LoadingViewController: UIViewController {

    @IBOutlet weak var loadingProgress: UIProgressView! // feedback on loading progress
    @IBOutlet weak var greetingLabel: UILabel!  // greeting with user's name
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // Use refresh events to update loading progress
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshData:", name: "RefreshCourses", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshData:", name: "RefreshTimeZones", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshData:", name: "RefreshUpcomingEvents", object: nil)
        
    }
    
    override func viewWillAppear(animated: Bool) {
        // reset loading progress
        loadingProgress.progress = 0
        

        
        // load the user's activity
        LearningStudio.api.getMe({ (error) -> Void in
            
            // User details have been loaded during authentication with /me
            var firstName = LearningStudio.api.userData?.me!["firstName"] as! String
            self.greetingLabel.text = "Welcome, \(firstName)!"
            
            if error == nil {
                LearningStudio.api.reloadData({ (error) -> Void in
                    dispatch_async(dispatch_get_main_queue()) {
                        if error == nil {
                            // show the main display
                            LearningStudio.api.proceedToDashboard()
                        }
                        else {
                            // log the user out
                            LearningStudio.api.promptForCredentials()
                        }
                    }
                    self.incrementProgress()
                })
            }
            else {
               LearningStudio.api.promptForCredentials()
            }
        })
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Receive notifications of data being loaded
   func refreshData(notification: NSNotification) {
        incrementProgress()
    }
    

    // called 4 times - 3 events & manually above
    func incrementProgress() {
        dispatch_async(dispatch_get_main_queue()) {
            // progress loading indicator
            self.loadingProgress.setProgress(self.loadingProgress.progress + 0.25, animated: true)
        }
    }

}
