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
    private var loginViewController: LoginViewController!
    private var tabViewController: TabViewController!
    private var loadingViewController: LoadingViewController!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
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
    // NOT the "right" way to switch screens, but I'm still learning...
    
    
    // Tabs can be viewed after data is loaded
    func showTabs() {
        if tabViewController == nil {
            tabViewController = storyboard?.instantiateViewControllerWithIdentifier("Tabs") as! TabViewController
        }
        
        dispatch_after( // login feels more graceful with a delay here... progress bar completes
                    dispatch_time(DISPATCH_TIME_NOW,Int64(0.5 * Double(NSEC_PER_SEC))), // 1/2 second
                    dispatch_get_main_queue()) {
            self.switchViewController(to: self.tabViewController)
        }
    }
    
    // Login will be viewed when credentials are missing, logout occurs, or error occurs
    func showLogin() {
        if loginViewController == nil {
            loginViewController = storyboard?.instantiateViewControllerWithIdentifier("Login") as! LoginViewController
        }
        
        var previousViewController: UIViewController? = findCurrentViewController()
        switchViewController(to: loginViewController)
    }
    
    // Loading screen appears at startup and during data refreshes
    func showLoading() {
        if loadingViewController == nil {
            loadingViewController = storyboard?.instantiateViewControllerWithIdentifier("Loading") as! LoadingViewController
        }
        
        var previousViewController: UIViewController? = findCurrentViewController()
        switchViewController(to: loadingViewController)
    }
    
    // Determine which view controller is currently in charge
    private func findCurrentViewController() -> UIViewController? {
        
        if loadingViewController != nil && loadingViewController.parentViewController == self {
            return loadingViewController
        }
        else if loginViewController != nil && loginViewController.parentViewController == self {
            return loginViewController
        }
        else if tabViewController != nil && tabViewController.parentViewController == self {
            return tabViewController
        }
        
        return nil
    }
    
    // Switch to the provided view controller
    private func switchViewController(to toController:UIViewController?) {
        
        var fromController: UIViewController? = findCurrentViewController()
        
        if fromController == toController {
            return
        }
        
        if fromController != nil {
            fromController!.willMoveToParentViewController(nil)
            fromController!.view.removeFromSuperview()
            fromController!.removeFromParentViewController()
        }
        
        if toController != nil {
            self.addChildViewController(toController!)
            self.view.insertSubview(toController!.view, atIndex: 0)
            toController!.didMoveToParentViewController(self)
        }
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
