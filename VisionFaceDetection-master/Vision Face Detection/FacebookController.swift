//
//  FacebookController.swift
//  Vision Face Detection
//
//  Created by Chris Gomez on 11/29/17.
//  Copyright © 2017 Droids On Roids. All rights reserved.
//

import Foundation
import FacebookCore
import FacebookLogin
import FBSDKLoginKit
import UIKit

class FacebookController: UIViewController {
    
    var profilePicture: UIImageView!
    
    struct ProfileRequest: GraphRequestProtocol {
        
        var graphPath: String = "/me"
        
        var parameters: [String : Any]? = ["fields": "id, name, gender, relationship_status, birthday, email, picture"]
        
        var accessToken: AccessToken? = AccessToken.current
        
        var httpMethod: GraphRequestHTTPMethod = .GET
        
        var apiVersion: GraphAPIVersion = .defaultVersion
        
        struct Response: GraphResponseProtocol {
            
            var name: String?
            var id: String?
            var gender: String?
            var relationship_status: String?
            var birthday: String?
            var email: String?
            var profilePictureUrl: String?
            
            init(rawResponse: Any?) {
                guard let response = rawResponse as? Dictionary<String, Any> else {
                    return
                }
                
                if let name = response["name"] as? String {
                    self.name = name
                }
                
                if let id = response["id"] as? String {
                    self.id = id
                }
                
                if let gender = response["gender"] as? String {
                    self.gender = gender
                }
                
                if let relationship_status = response["relationship_status"] as? String {
                    self.relationship_status = relationship_status
                }
                
                if let email = response["email"] as? String {
                    self.email = email
                }
                
                if let picture = response["picture"] as? Dictionary<String, Any> {
                    
                    if let data = picture["data"] as? Dictionary<String, Any> {
                        if let url = data["url"] as? String {
                            self.profilePictureUrl = url
                        }
                    }
                }
            }
        }
    }
    
    func loadData(){
        
        AccessToken.refreshCurrentToken()
        
        let colors = Colors()
        self.view.backgroundColor = UIColor.clear
        let backgroundLayer = colors.gl
        backgroundLayer?.frame = view.frame
        self.view.layer.insertSublayer(backgroundLayer!, at: 0)
        
        let navBar: UINavigationBar = UINavigationBar()
        navBar.frame = CGRect(x: 0, y: 20, width: self.view.frame.size.width, height: 44)
        navBar.backgroundColor = UIColor.clear
        navBar.setBackgroundImage(UIImage(), for: .default)
        navBar.barStyle = .black
        navBar.shadowImage = UIImage()
        navBar.isTranslucent = true
        let navTitle = UINavigationItem(title: "Facebook")
        let button = UIBarButtonItem(title: "Done",
                                     style:.plain,
                                     target:self,
                                     action:#selector(done))
        button.tintColor = UIColor.white
        if AccessToken.current != nil {
            navTitle.rightBarButtonItem = button
        }
        navBar.setItems([navTitle], animated: true)
        self.view.addSubview(navBar)
        
        displayLogin()
        
        if AccessToken.current != nil{
            let profile = UILabel(frame: CGRect(x: self.view.frame.midX+75, y: 225, width:self.view.frame.size.width - 100, height: 225))
            let connection = GraphRequestConnection()
            connection.add(ProfileRequest()) { response, result in
                switch result {
                case .success(let response):
                    print("Custom Graph Request Succeeded: \(response)")
                    print("My facebook id is \(response.id!)") //Make sure to safely unwrap these :)
                    print("My name is \(response.name!)")
                    print("My gender is \(response.gender!)")
                    //print("My birthday is \(response.birthday!)")
                    //print("My relationship status is \(response.relationship_status!)")
                    print("My email is \(response.email!)")
                    profile.text = "Name: \(response.name!) \nGender: \(response.gender!) \nEmail: \(response.email!)"
                    let pictureURL = "https://graph.facebook.com/\(response.id!)/picture?type=large&return_ssl_resources=1"
                    self.profilePicture.frame = CGRect(x: self.view.frame.midX-125, y: 225, width: 100, height: 100)
                    self.profilePicture.center = CGPoint(x: self.view.frame.midX-125, y: 225)
                    self.profilePicture.image = UIImage(data: NSData(contentsOf: URL(string: pictureURL)!)! as! Data)
                case .failed(let error):
                    print("Custom Graph Request Failed: \(error)")
                }
            }
            connection.start()
            profile.center = CGPoint(x: self.view.frame.midX+75, y: 225)
            profile.textColor = UIColor.white
            profile.textAlignment = .left
            profile.numberOfLines = 0
            profile.font = UIFont.preferredFont(forTextStyle: .largeTitle)
            profile.font = UIFont(name: "Avenir-Light", size: 22)
            profile.lineBreakMode = .byWordWrapping
            profile.adjustsFontSizeToFitWidth = true
            self.view.addSubview(profile)
        } else {
            let welcomeLabel = UILabel(frame: CGRect(x: self.view.frame.midX, y: 200, width: self.view.frame.size.width - 100, height: 300))
            welcomeLabel.center = CGPoint(x: self.view.frame.midX, y: 200)
            welcomeLabel.text = "Please login with Facebook to continue."
            welcomeLabel.textColor = UIColor.white
            welcomeLabel.textAlignment = .left
            welcomeLabel.numberOfLines = 0
            welcomeLabel.font = UIFont.preferredFont(forTextStyle: .largeTitle)
            welcomeLabel.font = UIFont(name: "Avenir-Light", size: 40)
            welcomeLabel.lineBreakMode = .byWordWrapping
            welcomeLabel.adjustsFontSizeToFitWidth = true
            self.view.addSubview(welcomeLabel)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        profilePicture = UIImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        if AccessToken.current == nil {
            profilePicture.center = CGPoint(x: view.frame.midX, y: view.frame.maxY - 100)
            profilePicture.image = UIImage(named: "fb-art")
        }
        view.addSubview(profilePicture)
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeDown.direction = UISwipeGestureRecognizerDirection.down
        self.view.addGestureRecognizer(swipeDown)
        
        self.loadData()
    }
    
    /*********************** FACEBOOK METHODS ********************************/
    
    func displayLogin(){
        
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: self.view.frame.midX, y: 400, width: 200, height: 50)
        button.backgroundColor = UIColor.clear
        button.layer.cornerRadius = 5
        button.layer.borderWidth = 3
        button.layer.borderColor = UIColor.magenta.cgColor
        
        if AccessToken.current == nil {
            button.setTitle("Login to Facebook", for: .normal)
            button.addTarget(self, action: #selector(loginWithReadPermissions), for: .touchUpInside)
        } else {
            button.setTitle("Logout of Facebook", for: .normal)
            button.addTarget(self, action: #selector(logOut), for: .touchUpInside)
        }
        button.center = CGPoint(x: self.view.frame.midX, y: 400)
        
        //loginButton.center = CGPoint(x: self.view.frame.midX, y: 400)
        self.view.addSubview(button)
    }
    
    func loginManagerDidComplete(_ result: LoginResult) {
        let alert: UIAlertController
        switch result {
        case .cancelled:
            alert = UIAlertController(title: "Login Cancelled", message: "User cancelled login.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
            { action -> Void in
                alert.dismiss(animated: true, completion: nil)
            })
        case .failed(let error):
            alert = UIAlertController(title: "Login Fail", message: "Login failed with error \(error)", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
            { action -> Void in
                alert.dismiss(animated: true, completion: nil)
            })
        case .success(_, _, _):
            alert = UIAlertController(title: "Login Success",  message: "Login succeeded. To get back to this page just swipe up.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
            { action -> Void in
                self.dismiss(animated: true, completion: nil)
            })
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func loginWithReadPermissions() {
        let loginManager = LoginManager()
        loginManager.logIn(readPermissions: [.publicProfile, .userFriends, .email], viewController: self) { result in
            self.loginManagerDidComplete(result)
        }
    }
    
    @objc func logOut() {
        let loginManager = LoginManager()
        loginManager.logOut()
        
        let alertController = UIAlertController(title: "Logout", message: "Logged out.", preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
        { action -> Void in
            self.dismiss(animated: true, completion: nil)
        })
        present(alertController, animated: true, completion: nil)
    }
    
    /*********************** END FACEBOOK/SERVER METHODS ********************************/

    @objc func done(){
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        
        // if the user swipes in any direction
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            
            // which direction
            switch swipeGesture.direction {
                
            case UISwipeGestureRecognizerDirection.down:
                self.dismiss(animated: true, completion: nil)
                break
            default:
                break
            }
        }
    }
}

class Colors {
    
    var gl:CAGradientLayer!
    
    init() {
        let colorTop = UIColor(red:0.99, green:0.27, blue:0.42, alpha:1.0).cgColor
        let colorBottom = UIColor(red:0.25, green:0.37, blue:0.98, alpha:1.0).cgColor
        
        self.gl = CAGradientLayer()
        self.gl.colors = [colorTop, colorBottom]
        self.gl.locations = [0.0, 1.0]
    }
}
