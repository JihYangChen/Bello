//
//  ViewController.swift
//  ARViewer
// http://texnotes.me/post/5/ for tutorial
//
//  Created by Faris Sbahi on 6/6/17.
//  Copyright © 2017 Faris Sbahi. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import AVFoundation

class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var finishView: UIView!
    @IBOutlet weak var againButton: UIButton!
    @IBOutlet weak var finalscoreLabel: UILabel!
    @IBOutlet weak var mask: UIView!
    @IBOutlet weak var startView: UIView!
    @IBOutlet weak var startButton: UIButton!
    
    var player: AVAudioPlayer!
    var timer: Timer!
    let initSeconds = 15
    var seconds: Int = 15
    
    private var userScore: Int = 0 {
        didSet {
            // ensure UI update runs on main thread
            DispatchQueue.main.async {
                if self.mask.isHidden {
                    self.scoreLabel.text = String(self.userScore)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
//        sceneView.showsStatistics = true
        
        // Create a new empty scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        sceneView.scene.physicsWorld.contactDelegate = self
        for _ in 1...21 {
            self.addNewShip2()
        }
        
        self.scoreLabel.text = "0"
        self.startView.isHidden = false
        self.mask.isHidden = false
        self.userScore = 0
        self.timerLabel.textColor = UIColor.white
        self.timerLabel.text = "\(self.seconds)"
//        self.finishView.layer.cornerRadius = 10
        self.againButton.layer.cornerRadius = 8
        self.finishView.isHidden = true
        self.againButton.layer.borderWidth = 1.5
        self.againButton.layer.borderColor = UIColor.black.cgColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.configureSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    @IBAction func startButtonTouchUpInside(_ sender: Any) {
        self.startView.isHidden = true
        self.mask.isHidden = true
        self.runTimer()
    }
    @IBAction func restartButtonTouchUpInside(_ sender: Any) {
        self.mask.isHidden = true
        self.finishView.isHidden = true
        self.scoreLabel.text = "0"
        self.timerLabel.textColor = UIColor.white
        self.userScore = 0
        self.seconds = self.initSeconds
        self.timerLabel.text = "\(self.initSeconds)"
        self.runTimer()
    }
    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        print("Session failed with error: \(error.localizedDescription)")
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    func runTimer() {
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(ViewController.updateTimer)), userInfo: nil, repeats: true)
    }
    
    @objc func updateTimer() {
        self.seconds -= 1     //This will decrement(count down)the seconds.
        self.timerLabel.text = "\(seconds)" //This will update the label.
        self.timerLabel.textColor = self.seconds > 5 ? UIColor.white : UIColor.red
        self.timerLabel.isHidden  = self.seconds < 0
        if self.seconds == 0 {
            self.mask.isHidden = false
            UIView.transition(with: self.finishView, duration: 0.8, options: UIViewAnimationOptions.transitionFlipFromRight, animations: {
                self.finishView.isHidden = false
            }, completion: nil)
            self.finalscoreLabel.text = self.scoreLabel.text
            self.timer.invalidate()
        }
    }
    
/*
     // ARKit detects planes in the Real World to serve as anchors--we can add a node manually to visualize them.
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        // This visualization covers only detected planes.
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        print("flat plane detected")
        
        // Create a SceneKit plane to visualize the node using its position and extent.
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        let planeNode = SCNNode(geometry: plane)
        planeNode.position = SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z)
        
        // SCNPlanes are vertically oriented in their local coordinate space.
        // Rotate it to match the horizontal orientation of the ARPlaneAnchor.
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
        
        // ARKit owns the node corresponding to the anchor, so make the plane a child node.
        node.addChildNode(planeNode)
    }
 */
    
    // MARK: - Actions
    
    @IBAction func didTapScreen(_ sender: UITapGestureRecognizer) { // fire bullet in direction camera is facing
        
        // Play torpedo sound when bullet is launched
        
        self.playSoundEffect(ofType: .torpedo)
        guard let scene = SCNScene(named: "art.scnassets/c.scn"), let bulletsNode = scene.rootNode.childNode(withName: "c", recursively: true) else { return }
//        bulletsNode.setAsBullet()
        let shape = SCNPhysicsShape(node: bulletsNode, options: nil)
        bulletsNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: shape)
        bulletsNode.physicsBody?.isAffectedByGravity = false
        bulletsNode.physicsBody?.categoryBitMask = CollisionCategory.bullets.rawValue
        bulletsNode.physicsBody?.contactTestBitMask = CollisionCategory.ship.rawValue
        
        
        let (direction, position) = self.getUserVector()
        bulletsNode.position = position // SceneKit/AR coordinates are in meters
        
        let bulletDirection = direction
        bulletsNode.physicsBody?.applyForce(bulletDirection, asImpulse: true)
        sceneView.scene.rootNode.addChildNode(bulletsNode)
        
    }
    
    // MARK: - Game Functionality
    
    func configureSession() {
        if ARWorldTrackingConfiguration.isSupported { // checks if user's device supports the more precise ARWorldTrackingSessionConfiguration
                                                            // equivalent to `if utsname().hasAtLeastA9()`
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = ARWorldTrackingConfiguration.PlaneDetection.horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
        } else {
            // slightly less immersive AR experience due to lower end processor
            let configuration = AROrientationTrackingConfiguration()
            
            // Run the view's session
            sceneView.session.run(configuration)
        }
    }
    
    func addNewShip() {
        if let scene = SCNScene(named: "art.scnassets/minion.scn"), let cubeNode = scene.rootNode.childNode(withName: "minion", recursively: true) {
            let posX = floatBetween(-0.5, and: 0.5)
            let posY = floatBetween(-0.5, and: 0.5  )
            cubeNode.position = SCNVector3(posX, posY, -1) // SceneKit/AR coordinates are in meters
            
            let box = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
            cubeNode.geometry = box
            let shape = SCNPhysicsShape(geometry: box, options: nil)
            cubeNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: shape)
            cubeNode.physicsBody?.isAffectedByGravity = false
            cubeNode.physicsBody?.categoryBitMask = CollisionCategory.ship.rawValue
            cubeNode.physicsBody?.contactTestBitMask = CollisionCategory.bullets.rawValue
            sceneView.scene.rootNode.addChildNode(cubeNode)
        }
    }
    
    func addNewShip2() {
        if let scene = SCNScene(named: "art.scnassets/minion.scn"), let cubeNode = scene.rootNode.childNode(withName: "minion", recursively: true) {
            let posX = floatBetween(-1.5, and: 1.5)
            let posY = floatBetween(-0.5, and: 0.5  )
            cubeNode.position = SCNVector3(posX, posY, -1) // SceneKit/AR coordinates are in meters
            
            let box = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
            cubeNode.geometry = box
            let shape = SCNPhysicsShape(geometry: box, options: nil)
            cubeNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: shape)
            cubeNode.physicsBody?.isAffectedByGravity = false
            cubeNode.physicsBody?.categoryBitMask = CollisionCategory.ship.rawValue
            cubeNode.physicsBody?.contactTestBitMask = CollisionCategory.bullets.rawValue
            sceneView.scene.rootNode.addChildNode(cubeNode)
        }
    }
    
    func removeNodeWithAnimation(_ node: SCNNode, explosion: Bool) {
        
        // Play collision sound for all collisions (bullet-bullet, etc.)
        
        self.playSoundEffect(ofType: .collision)
        
        if explosion {
            
            // Play explosion sound for bullet-ship collisions
            
            self.playSoundEffect(ofType: .explosion)
            
            let particleSystem = SCNParticleSystem(named: "explosion", inDirectory: nil)
            let systemNode = SCNNode()
            systemNode.addParticleSystem(particleSystem!)
            // place explosion where node is
            systemNode.position = node.position
            sceneView.scene.rootNode.addChildNode(systemNode)
        }
        
        // remove node
        node.removeFromParentNode()
    }
    
    func getUserVector() -> (SCNVector3, SCNVector3) { // (direction, position)
        if let frame = self.sceneView.session.currentFrame {
            let mat = SCNMatrix4(frame.camera.transform) // 4x4 transform matrix describing camera in world space
            let dir = SCNVector3(-1 * mat.m31, -1 * mat.m32, -1 * mat.m33) // orientation of camera in world space
            let pos = SCNVector3(mat.m41, mat.m42, mat.m43) // location of camera in world space
            
            return (dir, pos)
        }
        return (SCNVector3(0, 0, -1), SCNVector3(0, 0, -0.2))
    }
    
    func floatBetween(_ first: Float,  and second: Float) -> Float { // random float between upper and lower bound (inclusive)
        return (Float(arc4random()) / Float(UInt32.max)) * (first - second) + second
    }
    
    // MARK: - Contact Delegate
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        //print("did begin contact", contact.nodeA.physicsBody!.categoryBitMask, contact.nodeB.physicsBody!.categoryBitMask)
        if contact.nodeA.physicsBody?.categoryBitMask == CollisionCategory.ship.rawValue || contact.nodeB.physicsBody?.categoryBitMask == CollisionCategory.ship.rawValue { // this conditional is not required--we've used the bit masks to ensure only one type of collision takes place--will be necessary as soon as more collisions are created/enabled
            
            print("Hit ship!")
            self.removeNodeWithAnimation(contact.nodeB, explosion: false) // remove the bullet
            self.userScore += 1
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: { // remove/replace ship after half a second to visualize collision
                self.removeNodeWithAnimation(contact.nodeA, explosion: true)
                self.addNewShip()
            })
            
        }
    }
    
    // MARK: - Sound Effects
    
    func playSoundEffect(ofType effect: SoundEffect) {
        
        // Async to avoid substantial cost to graphics processing (may result in sound effect delay however)
        DispatchQueue.main.async {
            do
            {
                if let effectURL = Bundle.main.url(forResource: effect.rawValue, withExtension: "mp3") {
                    
                    self.player = try AVAudioPlayer(contentsOf: effectURL)
                    self.player.play()
                    
                }
            }
            catch let error as NSError {
                print(error.description)
            }
        }
    }
    
}

struct CollisionCategory: OptionSet {
    let rawValue: Int
    
    static let bullets  = CollisionCategory(rawValue: 1 << 0) // 00...01
    static let ship = CollisionCategory(rawValue: 1 << 1) // 00..10
}

extension utsname {
    func hasAtLeastA9() -> Bool { // checks if device has at least A9 chip for configuration
        var systemInfo = self
        uname(&systemInfo)
        let str = withUnsafePointer(to: &systemInfo.machine.0) { ptr in
            return String(cString: ptr)
        }
        switch str {
        case "iPhone8,1", "iPhone8,2", "iPhone8,4", "iPhone9,1", "iPhone9,2", "iPhone9,3", "iPhone9,4": // iphone with at least A9 processor
            return true
        case "iPad6,7", "iPad6,8", "iPad6,3", "iPad6,4", "iPad6,11", "iPad6,12": // ipad with at least A9 processor
            return true
        default:
            return false
        }
    }
}

enum SoundEffect: String {
    case explosion = "explosion"
    case collision = "collision"
    case torpedo = "torpedo"
}
