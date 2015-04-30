
//
//  ViewController.swift
//  HackieTalkie
//
//  Created by Michael Brennan on 10/19/14.
//  Copyright (c) 2014 HackieTalkie. All rights reserved.
//

import UIKit
import AVFoundation
import MultipeerConnectivity
import AudioToolbox

class ViewController: UIViewController, MCSessionDelegate, MCBrowserViewControllerDelegate, NSStreamDelegate, AVAudioRecorderDelegate {
    
    @IBOutlet weak var HailButton: UIButton!
    @IBOutlet weak var SpartyButton: UIButton!
    
    @IBOutlet weak var MSUScoreLabel: UILabel!
    @IBOutlet weak var MIScoreLabel: UILabel!
    @IBOutlet weak var ScoreFeed: UILabel!
    
    var MSU = 0 //MSU Score
    var MI = 0 //MI Score
    
    //http:stackoverflow/question/2403544
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
    
    
    @IBAction func touchingButton(sender: UIButton) {
        if let browser = browserViewController {
            if !recorder.recording {
                recorder.prepareToRecord()
                
                recorder.record()
                println("Recording now")
            }
        } else {
            browserViewController = MCBrowserViewController(serviceType: serviceType, session: session)
            browserViewController.delegate = self
            
            self.presentViewController(browserViewController, animated: false, completion: nil)
        }
    }
    
    @IBAction func doubleTapped(sender: UIButton) {
        println("Double tapped")
        if recorder.recording {
            println("Stopping Recording")
            recorder.stop()
            
            var error = NSErrorPointer()
            println("Contents of URL \(outputFileURL!)")
            session.sendData(NSData(contentsOfFile: outputFileURL!.path!), toPeers: session.connectedPeers, withMode: MCSessionSendDataMode.Reliable, error: error)
            println("Sent Data \(error)")
        }
    }
    
    var browserViewController : MCBrowserViewController!
    var assistant : MCAdvertiserAssistant!
    var session : MCSession!
    var peerID: MCPeerID!
    let serviceType = "Walkie-Talkie"
    
    var recorder: AVAudioRecorder!
    var player: AVAudioPlayer!
    var outputFileURL: NSURL?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var error = NSErrorPointer()
        AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, error: error)
        println("Audio Sess \(error)")
        
        let pathComponents = NSArray(objects: NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).last!,
            ["MyAudioMemo.m4a"].last!)
        outputFileURL = NSURL.fileURLWithPathComponents(pathComponents as [AnyObject])
        
        let recordSettings = [AVFormatIDKey : kAudioFormatMPEG4AAC, AVSampleRateKey : 44100.0, AVNumberOfChannelsKey : 2]
        
        recorder = AVAudioRecorder(URL: outputFileURL, settings: recordSettings as [NSObject : AnyObject], error: error)
        println("Recorder setup \(error)")
        
        
        // Creates Peer ID and Session
        peerID = MCPeerID(displayName: UIDevice.currentDevice().name)
        session = MCSession(peer: peerID)
        session.delegate = self
        
        // Creates advertiser and hands in session
        assistant = MCAdvertiserAssistant(serviceType: serviceType, discoveryInfo: nil, session: session)
        assistant.start()
        
    }
    
    
    //    MARK: -- Browser VC Delegate Methods --
    
    // Notifies the delegate, when the user taps the done button
    func browserViewControllerDidFinish(browserViewController: MCBrowserViewController!) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // Notifies delegate that the user taps the cancel button.
    func browserViewControllerWasCancelled(browserViewController: MCBrowserViewController!) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    
    //    MARK: -- Session Delegate Methods --
    
    // Remote peer changed state
    func session(session: MCSession!, peer peerID: MCPeerID!, didChangeState state: MCSessionState) {
        if state == .Connected {
            
        }
    }
    
    // Received a byte stream from remote peer
    func session(session: MCSession!, didReceiveStream stream: NSInputStream!, withName streamName: String!, fromPeer peerID: MCPeerID!) {
        
    }
    
    // Stream received event callback
    func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {
         playGame()
    }
    
    
    //    MARK: -- Unused Required Delegate Methods --
    
    // Received data from remote peer
    func session(session: MCSession!, didReceiveData data: NSData!, fromPeer peerID: MCPeerID!) {
        println("Recieved Data \(data.length)")
        delay(0.5){
            self.toggleFlash()
        }
        delay(1.5){
            self.toggleFlash()
        }
        
        var error = NSErrorPointer()
        player = AVAudioPlayer(data: data, error: error)
        player.play()
        
        delay(1.0){
            self.toggleFlash()
        }
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        delay(2.5){
            self.toggleFlash()
        }
        delay(1.0){
            self.toggleFlash()
        }
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        delay(3.5){
            self.toggleFlash()
        }
        
        println("AVAudioPlayer setup \(error)")
        println("Scoring to happen")
        playGame()
    }
    
    func toggleFlash() {
        let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        if (device.hasTorch) {
            device.lockForConfiguration(nil)
            if (device.torchMode == AVCaptureTorchMode.On) {
                device.torchMode = AVCaptureTorchMode.Off
            } else {
                device.setTorchModeOnWithLevel(1.0, error: nil)
            }
            device.unlockForConfiguration()
        } else {
            return
        }
    }
    
    // Start receiving a resource from remote peer
    func session(session: MCSession!, didStartReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, withProgress progress: NSProgress!) {
        
    }
    
    // Finished receiving a resource from remote peer and saved the content in a temporary location - the app is responsible for moving the file to a permanent location within its sandbox
    func session(session: MCSession!, didFinishReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, atURL localURL: NSURL!, withError error: NSError!) {
        
    }
    
    
    func playGame() {
        if (MSU != 5 || MI != 5){
            var coinFlip = Int(arc4random_uniform(7))
            if ((coinFlip % 2) == 0) {
                ScoreFeed.text = "Michigan Scored!"
                MI++
                MIScoreLabel.text = String(MI)
                HailButton.hidden = false
                SpartyButton.hidden = true
            }
            else {
                ScoreFeed.text = "MSU Scored!"
                MSU++
                MSUScoreLabel.text = String(MSU)
                HailButton.hidden = true
                SpartyButton.hidden = false
            }
        }
    }
    
}