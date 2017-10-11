//
//  ViewController.swift
//  Lion Search
//
//  Created by Besher on 2017-10-10.
//  Copyright © 2017 Besher Al Maleh. All rights reserved.
//

import Cocoa


class ViewController: NSViewController {
    
    var username: String = ""
    var userData: String = ""
    var fullName: String = ""
    var hyperion: String = ""
    var country: String = ""
    var state: String = ""
    var location: String = ""
    var brand: String = ""
    var jobTitle: String = ""
    var vpn: Bool = false
    var expired: Bool = false
    var expDate: String = ""
    var passUpdateDate: String = ""
    var passExpDate: String = ""
    var locked: Bool = false
    var disabled: Bool = false
    var badPassCount: String = ""
    var badPassTime: String = ""
    var lastLogon: String = ""
    var emailPrim: String = ""
//    var emailProx: String = ""
    var lyncVoice: Bool = false
    var lyncNum: String = ""
    var mfa: Bool = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

 

        
        DispatchQueue.main.async { [unowned self] in
            
            
            
            
            self.userData = self.shell("dscl", "localhost", "-read", "Active Directory/LL/All Domains/Users/besalmal")
            
            self.regex()
        }
        
        
        
        
        
        
        

        
        
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    
    
        @discardableResult
        func shell(_ args: String...) -> String {
            let task = Process()
            task.launchPath = "/usr/bin/env"
            task.arguments = args
    
            let pipe = Pipe()
            task.standardOutput = pipe
    
            task.launch()
//            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            
            guard let output: String = String(data: data, encoding: .utf8) else {
                return ""
            }
            
            guard !output.contains("read: Invalid Path") else { print ("DISCONNECTED")
                return "DISCONNECTED" }
            
            guard output.contains("dsAttrTypeNative") else { print("WRONG ID")
                return "WRONG ID" }
            
            return output
        }

    func regex() {
        
        
        let hypPat = "(?<=hcode: )\\w{6}"
        let namePat = "(?<=RealName:\\n )[^\\n]*"
        let countryPat = "(?<=Native:co: )\\w+\\b"
        let statePat = "(?<=State: )\\w+\\b"
        let locationPat = "(?<=Street:\\n )[^\\n]*"
        let brandPat = "(?<=Native:company: )\\w+\\b"
        let jobPat = "(?<=JobTitle:\\n )[^\\n]*"
        let passCountPat = "(?<=badPwdCount: )\\w+\\b"
        let emailPrimPat = "(?<=EMailAddress: )[^\\n]+"
//        let emailProxPat = "(?<=smtp:).+"
        let lyncNumPat = "(?<=tel:)[^\\n]+"
        let expDatePat = "(?<=accountExpires: )\\w+\\b"
        let passUpdatePat = "(?<=PasswordLastSet: )[^(\n)]+"
        let badPassTimePat = "(?<=badPasswordTime: )\\w+\\b"
        let lastLogonPat1 = "(?<=lastLogon: )\\w+\\b"
        let lastLogonPat2 = "(?<=lastLogonTimestamp: )\\w+\\b"
        
        //CONVERT FROM LDAP TIME TO UNIX TIME:
        func msToUNIX(_ input: Double) -> Double {
            return (input / 10000000) - 11644473600
        }
        
        
        //CONVERT FROM UNIX TIME TO FORMATTED DATE:
        
        func formatDate(_ unix: Double) -> String {
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .medium
            
            let date = Date(timeIntervalSince1970: unix)
            
            // US English Locale (en_US)
            dateFormatter.locale = Locale(identifier: "en_US")
            return dateFormatter.string(from: date)
        }
        

        
        
        //REGEX PATTERN MATCHING:
        func reg(_ pat: String) -> String {
            var output = ""
            let regStr = userData
            let regex = try! NSRegularExpression(pattern: pat, options: [])
            let matches = regex.matches(in: regStr, options: [], range: NSRange(location: 0, length: regStr.characters.count))
            
            
            for match in matches {
                for n in 0..<match.numberOfRanges {
                    let range = match.rangeAt(n)
                    let rstart = regStr.startIndex
                    let r = regStr.characters.index(rstart, offsetBy: range.location) ..<
                        regStr.characters.index(rstart, offsetBy: range.location + range.length)
                    output = regStr.substring(with: r)
                }
            }
            return output
        }
        

        hyperion = reg(hypPat)
        fullName = reg(namePat)
        country = reg(countryPat)
        state = reg(statePat)
        location = reg(locationPat)
        brand = reg(brandPat)
        jobTitle = reg(jobPat)
        vpn = userData.contains("RemoteAccessVPN")
        locked = !userData.contains("lockoutTime: 0")
        disabled = !userData.contains(":userAccountControl: 512")
        badPassCount = reg(passCountPat)
        emailPrim = reg(emailPrimPat)
//        emailProx = reg(emailProxPat)
        lyncVoice = userData.contains("LyncVoice:ACTIVATED")
        lyncNum = reg(lyncNumPat)
        passUpdateDate = reg(passUpdatePat)
        mfa = userData.contains("LionBOX-MFA")
        
        guard let expInterval: Double = Double(reg(expDatePat)) else { return }
        guard let passInterval: Double = Double(reg(passUpdatePat)) else { return }
        guard let badPassInterval: Double = Double(reg(badPassTimePat)) else { return }
        guard let lastLogonInterval1: Double = Double(reg(lastLogonPat1)) else { return }
        guard let lastLogonInterval2: Double = Double(reg(lastLogonPat2)) else { return }
        
        let unixExp = msToUNIX(expInterval)
        let unixPass = msToUNIX(passInterval)
        let unixBadPass = msToUNIX(badPassInterval)
        let unixToday = Date().timeIntervalSince1970
        let unixPassExpDate = unixPass + ( 86400 * 90 )
        let daysRemaining = Int(90 - ((unixToday - unixPass) / 86400))
        let unixLastLogon = lastLogonInterval1 > lastLogonInterval2 ? msToUNIX(lastLogonInterval1) : msToUNIX(lastLogonInterval2)
    
        
        expDate = formatDate(unixExp)
        passUpdateDate = formatDate(unixPass)
        passExpDate = formatDate(unixPassExpDate)
        badPassTime = formatDate(unixBadPass)
        lastLogon = formatDate(unixLastLogon)
        
        print("Hyperion code: " + hyperion)
        print("Full name: " + fullName)
        print("Country: " + country + ", " + state)
        print("Location: " + location)
        print("Brand: " + brand)
        print("Job title: " + jobTitle)
        print("VPN: " + String(vpn).capitalized)
        print("Locked: " + String(locked).capitalized)
        print("Disabled: " + String(disabled).capitalized)
        print("Bad password count: " + badPassCount)
        print("Bad password time: " + badPassTime)
        print("Primary e-mail address: " + emailPrim)
//        print("Proxy e-mail: " + emailProx)
        print("Lync Voice activated: " + String(lyncVoice).capitalized)
        if lyncVoice {
            print("Lync number: " + lyncNum)
        }
        if !expDate.contains("30828") {
            print("Account expires on: " + expDate)
        } else if disabled {
            print("Account expires on: Disabled")
        } else {
            print("Expiration date: Permanent employee")
        }
        print("Password was last updated on: " + passUpdateDate)
        if daysRemaining >= 0 {
            print("Password expires in \(daysRemaining) days, on " + passExpDate)
        } else {
            print("Password has expired \(-daysRemaining) days ago, on " + passExpDate)
        }
        
        print("MFA Enforcement: " + String(mfa).capitalized)
        print("The user has last logged in on: " + lastLogon)
    }
    

}

