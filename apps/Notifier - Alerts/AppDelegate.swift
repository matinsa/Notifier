//
//  AppDelegate.swift
//  Notifier Alerts
//
//  Copyright © 2020 dataJAR Ltd. All rights reserved.
//

import Cocoa
import SPMUtility
import UserNotifications

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    // Gimme some applicationDidFinishLaunching
    func applicationDidFinishLaunching(_ aNotification: Notification) {

        let actionIdentifier = "alert"
        var notificationString = ""
        var verboseMode = false

        // Exit if notificaiton center isn't running for the user
        guard !NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.notificationcenterui").isEmpty else {
            print("ERROR: Notification Center is not running...")
            exit(1)
        }

        // Ask permission, 10.15+ only
        if #available(macOS 10.15, *) {
            requestAuthorisation(verboseMode: verboseMode)
        }

        // See if we have any .userInfo when launched on, such as from user interaction
        if #available(macOS 10.15, *) {
            if let response = (aNotification as NSNotification).userInfo?[NSApplication.launchUserNotificationUserInfoKey] as? UNNotificationResponse {
                handleUNNotification(forResponse: response)
            }
        } else {
            if let notification = (aNotification as NSNotification).userInfo![NSApplication.launchUserNotificationUserInfoKey] as? NSUserNotification {
                handleNSUserNotification(forNotification: notification)
            }
        }

        // Parse arguments & post notification
        do {

            let argParser = ArgumentParser(commandName: "notifier", usage: "<options>", overview: "Send alert notifications, part of Notifier", seeAlso: "https://github.com/dataJAR/Notifier")
            let ncMessage = argParser.add(option: "--message", kind: String.self, usage: "message text - REQUIRED")
            let ncMessageAction = argParser.add(option: "--messageaction", kind: String.self)
            let ncMessageButton = argParser.add(option: "--messagebutton", kind: String.self)
            let ncMessageButtonAction = argParser.add(option: "--messagebuttonaction", kind: String.self)
            let ncSound = argParser.add(option: "--sound", kind: String.self )
            let ncSubtitle = argParser.add(option: "--subtitle", kind: String.self)
            let ncTitle = argParser.add(option: "--title", kind: String.self)
            let ncRemove = argParser.add(option: "--remove", kind: String.self)
            let ncVerbose = argParser.add(option: "--verbose", kind: Bool.self, usage: "Enables logging of actions. Check console for  'Notifier Log:' messages")

            let passedArgs = Array(CommandLine.arguments.dropFirst())
            let parsedResult = try argParser.parse(passedArgs)

            verboseMode = parsedResult.get(ncVerbose) ?? false

            if verboseMode {
                NSLog("Notifier Log: alert - verbose enabled")
            }

            // User UNUser API's for 10.15+, NSUser for older
            if #available(macOS 10.15, *) {

                if verboseMode {
                    NSLog("Notifier Log: alert - running on 10.15+")
                }

                let ncCenter =  UNUserNotificationCenter.current()
                let ncContent = UNMutableNotificationContent()

                ncCenter.delegate = self

                if verboseMode {
                    ncContent.userInfo["verboseMode"] = "enabled"
                }

                if parsedResult.get(ncRemove)?.lowercased() == "all" {
                    if verboseMode {
                        NSLog("Notifier Log: alert - ncRemove all")
                    }
                    ncCenter.removeAllDeliveredNotifications()
                    sleep(1)
                    if verboseMode {
                        NSLog("Notifier Log: alert - ncRemove all - done")
                    }
                    exit(0)

                } else {

                    if (parsedResult.get(ncMessage) != nil) {
                        if verboseMode {
                            NSLog("Notifier Log: alert - ncMessage")
                        }
                        ncContent.body = parsedResult.get(ncMessage)!
                        notificationString += ncContent.body
                        if verboseMode {
                            NSLog("Notifier Log: alert - notificationString - %@", notificationString)
                        }
                    }

                    if (parsedResult.get(ncMessageAction) != nil) {
                        if verboseMode {
                            NSLog("Notifier Log: alert - ncMessageAction")
                        }
                        if parsedResult.get(ncMessageAction)?.lowercased() == "logout" {
                            ncContent.userInfo["messageAction"] = "logout"
                            notificationString += "logout"
                            notificationString += actionIdentifier
                            if verboseMode {
                                NSLog("Notifier Log: alert - notificationString - %@", notificationString)
                            }
                        } else {
                            ncContent.userInfo["messageAction"] = parsedResult.get(ncMessageAction)!
                            notificationString += "\(String(describing: parsedResult.get(ncMessageAction)))"
                            if verboseMode {
                                NSLog("Notifier Log: alert - notificationString - %@", notificationString)
                            }
                        }
                    }

                    if (parsedResult.get(ncMessageButton) != nil) {
                        if verboseMode {
                            NSLog("Notifier Log: alert - ncMessageButton")
                        }
                        let actionTitle = parsedResult.get(ncMessageButton)
                        if verboseMode {
                            NSLog("Notifier Log: alert - ncMessageButton - %@", "\(String(describing: ncMessageButton))")
                        }
                        let ncAction = UNNotificationAction(identifier: "messagebutton", title: actionTitle!, options: .init(rawValue: 0))
                        let ncCategory = UNNotificationCategory(identifier: actionIdentifier, actions: [ncAction], intentIdentifiers: [], options: .customDismissAction)
                        ncCenter.setNotificationCategories([ncCategory])
                        ncContent.categoryIdentifier = actionIdentifier
                    } else {
                        if verboseMode {
                            NSLog("Notifier Log: alert - no ncMessageButton")
                        }
                        let ncCategory = UNNotificationCategory(identifier: actionIdentifier, actions: [], intentIdentifiers: [], options: .customDismissAction)
                        ncCenter.setNotificationCategories([ncCategory])
                        ncContent.categoryIdentifier = actionIdentifier
                    }

                    if (parsedResult.get(ncMessageButtonAction) != nil) {
                        if verboseMode {
                            NSLog("Notifier Log: alert - ncMessageButtonAction")
                        }
                        if parsedResult.get(ncMessageButtonAction)!.lowercased() == "logout" {
                            ncContent.userInfo["messageButtonAction"] = "logout"
                            notificationString += "logout"
                            if verboseMode {
                                NSLog("Notifier Log: alert - notificationString - %@", notificationString)
                            }
                        } else {
                            ncContent.userInfo["messageButtonAction"] = parsedResult.get(ncMessageButtonAction)!
                            notificationString += "\(String(describing: parsedResult.get(ncMessageButtonAction)))"
                            if verboseMode {
                                NSLog("Notifier Log: alert - notificationString - %@", notificationString)
                            }
                        }
                    }

                    if (parsedResult.get(ncSound) != nil) {
                        if verboseMode {
                            NSLog("Notifier Log: alert - ncSound")
                        }
                        if parsedResult.get(ncSound)?.lowercased() == "default" {
                            ncContent.sound = UNNotificationSound.default
                            notificationString += "\(String(describing: ncContent.sound))"
                            if verboseMode {
                                NSLog("Notifier Log: alert - notificationString - %@", notificationString)
                            }
                        } else {
                            ncContent.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: parsedResult.get(ncSound)!))
                            notificationString += "\(String(describing: ncContent.sound))"
                            if verboseMode {
                                NSLog("Notifier Log: alert - notificationString - %@", notificationString)
                            }
                        }
                    }

                    if (parsedResult.get(ncSubtitle) != nil) {
                        if verboseMode {
                            NSLog("Notifier Log: alert - ncSubtitle")
                        }
                        ncContent.subtitle = parsedResult.get(ncSubtitle)!
                        notificationString += ncContent.subtitle
                        if verboseMode {
                            NSLog("Notifier Log: alert - notificationString - %@", notificationString)
                        }
                    }

                    if (parsedResult.get(ncTitle) != nil) {
                        if verboseMode {
                            NSLog("Notifier Log: alert - ncTitle")
                        }
                        ncContent.title = parsedResult.get(ncTitle)!
                        notificationString += ncContent.title
                        if verboseMode {
                            NSLog("Notifier Log: alert - notificationString - %@", notificationString)
                        }
                    }

                    let ncContentbase64 = base64String(stringContent: notificationString)
                    if verboseMode {
                        NSLog("Notifier Log: alert - ncContentbase64 - %@", ncContentbase64)
                    }

                    if parsedResult.get(ncRemove)?.lowercased() == "prior" {
                        if verboseMode {
                            NSLog("Notifier Log: alert - ncRemove prior")
                        }
                        ncCenter.removeDeliveredNotifications(withIdentifiers: [ncContentbase64])
                        sleep(1)
                        if verboseMode {
                            NSLog("Notifier Log: alert - ncRemove prior - done")
                        }
                        exit(0)
                    } else {
                        if verboseMode {
                            NSLog("Notifier Log: alert - notification request")
                        }
                        let ncTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                        let ncRequest = UNNotificationRequest(identifier: ncContentbase64, content: ncContent, trigger: ncTrigger)
                        ncCenter.add(ncRequest)
                        sleep(1)
                        if verboseMode {
                            NSLog("Notifier Log: alert - notification delivered")
                        }
                        exit(0)
                    }
                }

            } else {

                if verboseMode {
                    NSLog("Notifier Log: alert - running on 10.10 - 10.14")
                }

                let ncCenter =  NSUserNotificationCenter.default
                let ncContent = NSUserNotification()
                var userInfoDict:[String:Any] = [:]

                ncCenter.delegate = self

                if verboseMode {
                    userInfoDict["verboseMode"] = "enabled"
                }

                if parsedResult.get(ncRemove)?.lowercased() == "all" {
                    if verboseMode {
                        NSLog("Notifier Log: alert - ncRemove all")
                    }
                    ncCenter.removeAllDeliveredNotifications()
                    sleep(1)
                    if verboseMode {
                        NSLog("Notifier Log: alert - ncRemove all - done")
                    }
                    exit(0)

                } else {

                    if (parsedResult.get(ncMessage) != nil) {
                        if verboseMode {
                            NSLog("Notifier Log: alert - ncMessage")
                        }
                        ncContent.informativeText = parsedResult.get(ncMessage)
                        notificationString += "\(String(describing: ncContent.informativeText))"
                        if verboseMode {
                            NSLog("Notifier Log: alert - notificationString - %@", notificationString)
                        }
                    }

                    if (parsedResult.get(ncMessageAction) != nil) {
                        if verboseMode {
                            NSLog("Notifier Log: alert - ncMessageAction")
                        }
                        if parsedResult.get(ncMessageAction)?.lowercased() == "logout" {
                            userInfoDict["messageAction"] = "logout"
                            notificationString += "logout"
                            notificationString += actionIdentifier
                            if verboseMode {
                                NSLog("Notifier Log: alert - notificationString - %@", notificationString)
                            }
                        } else {
                            userInfoDict["messageAction"] = parsedResult.get(ncMessageAction)
                            notificationString += "\(String(describing: parsedResult.get(ncMessageAction)))"
                            if verboseMode {
                                NSLog("Notifier Log: alert - notificationString - %@", notificationString)
                            }
                        }
                    }

                    if (parsedResult.get(ncMessageButton) != nil) {
                        if verboseMode {
                            NSLog("Notifier Log: alert - ncMessageButton")
                        }
                        ncContent.actionButtonTitle = parsedResult.get(ncMessageButton)!
                        if verboseMode {
                            NSLog("Notifier Log: alert - ncMessageButton - %@", "\(String(describing: ncMessageButton))")
                        }
                        notificationString += "\(String(describing: ncContent.hasActionButton))"
                        notificationString += ncContent.actionButtonTitle
                    } else {
                        if verboseMode {
                            NSLog("Notifier Log: alert - no ncMessageButton")
                        }
                        ncContent.hasActionButton = false
                        ncContent.otherButtonTitle = "Close"
                        if verboseMode {
                            NSLog("Notifier Log: alert - ncMessageButton - set to close")
                        }
                        notificationString += "\(String(describing: ncContent.hasActionButton))"
                        notificationString += ncContent.otherButtonTitle
                    }

                    if (parsedResult.get(ncMessageButtonAction) != nil) {
                        if verboseMode {
                            NSLog("Notifier Log: alert - ncMessageButtonAction")
                        }
                        if parsedResult.get(ncMessageButtonAction)!.lowercased() == "logout" {
                            userInfoDict["messageButtonAction"] = "logout"
                            notificationString += "logout"
                            if verboseMode {
                                NSLog("Notifier Log: alert - notificationString - %@", notificationString)
                            }
                        } else {
                            userInfoDict["messageButtonAction"] = parsedResult.get(ncMessageButtonAction)
                            notificationString += "\(String(describing: parsedResult.get(ncMessageButtonAction)))"
                            if verboseMode {
                                NSLog("Notifier Log: alert - notificationString - %@", notificationString)
                            }
                        }
                    }

                    if (parsedResult.get(ncSound) != nil){
                        if verboseMode {
                            NSLog("Notifier Log: alert - ncSound")
                        }
                        if parsedResult.get(ncSound)?.lowercased() == "default" {
                            ncContent.soundName = NSUserNotificationDefaultSoundName
                        } else {
                            ncContent.soundName = parsedResult.get(ncSound)!
                        }
                        notificationString += "\(String(describing: ncContent.soundName))"
                        if verboseMode {
                            NSLog("Notifier Log: alert - notificationString - %@", notificationString)
                        }
                    }

                    if (parsedResult.get(ncSubtitle) != nil){
                        if verboseMode {
                            NSLog("Notifier Log: alert - ncSubtitle")
                        }
                        ncContent.subtitle = parsedResult.get(ncSubtitle)!
                        notificationString += ncContent.subtitle!
                        if verboseMode {
                            NSLog("Notifier Log: alert - notificationString - %@", notificationString)
                        }
                    }

                    if (parsedResult.get(ncTitle) != nil){
                        if verboseMode {
                            NSLog("Notifier Log: alert - ncTitle")
                        }
                        ncContent.title = parsedResult.get(ncTitle)!
                        notificationString += ncContent.title!
                        if verboseMode {
                            NSLog("Notifier Log: alert - notificationString - %@", notificationString)
                        }
                    }

                    let ncContentbase64 = base64String(stringContent: notificationString)
                    ncContent.identifier = ncContentbase64
                    if verboseMode {
                        NSLog("Notifier Log: alert - ncContentbase64 - %@", ncContentbase64)
                    }

                    ncContent.userInfo = userInfoDict

                    if parsedResult.get(ncRemove)?.lowercased() == "prior" {
                        if verboseMode {
                            NSLog("Notifier Log: alert - ncRemove prior")
                        }
                        ncCenter.removeDeliveredNotification(ncContent)
                        sleep(1)
                        if verboseMode {
                            NSLog("Notifier Log: alert - ncRemove prior - done")
                        }
                        exit(0)
                    } else {
                        if verboseMode {
                            NSLog("Notifier Log: alert - notification request")
                        }
                        NSLog("Notifier Log: alert - message - userInfo %@", String(describing: ncContent.userInfo))
                        ncCenter.deliver(ncContent)
                        sleep(1)
                        if verboseMode {
                            NSLog("Notifier Log: alert - notification delivered")
                        }
                        exit(0)
                    }
                }
            }
        } catch ArgumentParserError.expectedValue(let value) {
            print("Missing value for argument \(value).")
            exit(1)
        } catch ArgumentParserError.expectedArguments( _, let stringArray) {
            print("Missing arguments: \(stringArray.joined()).")
            exit(1)
        } catch {
            print(error.localizedDescription)
            exit(1)
        }
    }

    // Insert code here to tear down your application
    func applicationWillTerminate(_ aNotification: Notification) {
    }

    // NSUser - Respond to click
    @available(macOS, obsoleted: 10.15)
    func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
        handleNSUserNotification(forNotification: notification)
    }

    // NSUser  - Ensure that notification is shown, even if app is active
    @available(macOS, obsoleted: 10.15)
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }

    // NSUser - Get value of the otherButton, used to mimic single button UNUser alerts
    @available(macOS, obsoleted: 10.15)
    @objc
    func userNotificationCenter(_ center: NSUserNotificationCenter, didDismissAlert notification: NSUserNotification){
        center.removeDeliveredNotification(notification)
        exit(0)
    }

    // UNUser - Respond to click
    @available(macOS 10.14, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "NewNotification") , object: nil, userInfo: response.notification.request.content.userInfo)
        handleUNNotification(forResponse: response)
    }

    // UNUser - Ensure that notification is shown, even if app is active
    @available(macOS 10.14, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler(.alert)
    }
}

@available(macOS 10.15, *)
    extension AppDelegate: UNUserNotificationCenterDelegate {
}

@available(macOS, obsoleted: 10.15)
    extension AppDelegate: NSUserNotificationCenterDelegate {
}
