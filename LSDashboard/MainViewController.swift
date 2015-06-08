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

// All view changes are initiated by this controller
class MainViewController: UIViewController {
    private var firstLoad = true
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if !firstLoad {
            return
        }
        
        firstLoad = false
        
        // The api class does some of the view switching
        // This class has references to all views
        LearningStudio.api.mainView = self
 
        // Only need to prompt for credential is they're missing
        if LearningStudio.api.restoreCredentials() {
            // Load the user info if credentials are present
            LearningStudio.api.getMe({ (error) -> Void in
                
                dispatch_async(dispatch_get_main_queue()) {

                    if error == nil {
                        self.showLoading() // proceed with loading
                    }
                    else {
                        self.showLogin() // force login
                    }
                }
            })

        }
        else {
            showLogin() // force login
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
        // archive the user data before clearing it from memory
        LearningStudio.api.saveUserDataArchive()
    }
    
    // MARK: - Screen Switching
    // still NOT the "right" way to switch screens, but I'm still learning...
    
    
    // Tabs can be viewed after data is loaded
    func showTabs() {
 
        dispatch_after( // login feels more graceful with a delay here... progress bar completes
                    dispatch_time(DISPATCH_TIME_NOW,Int64(0.5 * Double(NSEC_PER_SEC))), // 1/2 second
                    dispatch_get_main_queue()) {
            self.dismissViewControllerAnimated(false, completion: nil)
            self.performSegueWithIdentifier("tabsSegue", sender: self)
        }

    }
    
    // Login will be viewed when credentials are missing, logout occurs, or error occurs
    func showLogin() {
        self.dismissViewControllerAnimated(false, completion: nil)
        self.performSegueWithIdentifier("loginSegue", sender: self)
    }
    
    // Loading screen appears at startup and during data refreshes
    func showLoading() {
        self.dismissViewControllerAnimated(false, completion: nil)
        self.performSegueWithIdentifier("loadingSegue", sender: self)
    }
    
    // Generic error handler shows popup before forcing login
    func recoverFromError(shortReason: String, longReason: String) {
        let alert = UIAlertController(title: shortReason, message:longReason, preferredStyle: .Alert)
        let action = UIAlertAction(title:"Login Again", style: .Default, handler: nil)
        alert.addAction(action)
        presentViewController(alert, animated:true, completion: { () -> Void in
            self.showLogin()
        })
    }


}
