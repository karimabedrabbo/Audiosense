//
//  GameViewController.swift
//  virtualworld
//
//  Created by Karim Abedrabbo on 6/11/16.
//  Copyright (c) 2016 Karim Abedrabbo. All rights reserved.
//


import UIKit
import QuartzCore
import SceneKit
import GameController
import CoreMotion
import AVFoundation

class GameViewController: UIViewController, SCNSceneRendererDelegate {
    
    var boxNode = SCNNode()
    var cameraNode : SCNNode!
    var motionManager : CMMotionManager?
    var audioCubes = [SCNBox()]
    var audioCubesNodes = [SCNNode()]
    var audioNodes = [SCNNode()]
    var audioSources = [SCNAudioSource()]
    var playerActions = [SCNAction()]
    var audioPlayers : [SCNAudioPlayer?] = []
    var player:AVAudioPlayer = AVAudioPlayer()
    let ground = SCNPlane(width: 1000, height: 1000)
    var groundNode = SCNNode()
    var userTapsOnCubes = 0
    var zeroToEighteenInPlaySounds = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18]
    var totalCorrect = 0
    var numDeciderInPlaySounds = -1
    var blockTapped = -1
    var emptyDictionary = [Int: String]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
            }
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        for _ in (0...18){
            audioCubes.append(SCNBox())
            audioCubesNodes.append(SCNNode())
            audioNodes.append(SCNNode())
            audioSources.append(SCNAudioSource())
            playerActions.append(SCNAction())
            audioPlayers.append(nil)
            

            
        }
       
        sceneSetup()
        
        let alertController = UIAlertController(title: "Sound Localization Test", message:
            "Each sound will play 5 times. Tilt the device to find the playing sound and tap on the block that you believe is playing the sound. The test will start after the instructions end.", preferredStyle: UIAlertControllerStyle.alert)
        
        self.present(alertController, animated: true, completion: nil)
        
        
        
        
        let audioPath = Bundle.main.path(forResource: "art.scnassets/IntroFinal", ofType: "wav")
        
        do {
            player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: audioPath!))
            player.volume = 10
        }
        catch {
            print("error")
        }
        
        player.play()
        
        let delay = 15.3 * Double(NSEC_PER_SEC)
        let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time) {
            alertController.addAction(UIAlertAction(title: "Start", style: UIAlertActionStyle.default, handler: {action in self.playSounds()}))

           
        }
        
       
    }
    
    
    
   
    func sceneSetup(){
        
        //Setup the scene
        let sceneView = self.view as! SCNView
        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.sizeToFit()
        scene.background.contents = UIColor.black
        
        
        
        cameraNode = setupCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        //================================= Create Ground ====================================
        // Let's look for a collada file
        groundNode = SCNNode(geometry: ground)
        groundNode.position = SCNVector3(0,-20,0)
        groundNode.rotation = SCNQuaternion(x: 1, y: 0, z: 0, w: -1.5708)
        ground.firstMaterial?.diffuse.contents = UIColor.black
        ground.firstMaterial?.specular.contents = UIColor.white
        ground.firstMaterial?.shininess = 20.0
        ground.firstMaterial?.reflective.contents = scene.background.contents
        scene.rootNode.addChildNode(groundNode)
        boxNode.castsShadow = true
        boxNode.position.y = -5
        scene.rootNode.addChildNode(boxNode)
        
        
        
        //=================================Create Sound Towers====================================
        createSoundTowers(scene)
        loadAllSounds()
        
        
        
        
        // let moverForwardAction = SCNAction.repeatActionForever(SCNAction.moveByX(0, y: 0, z: -10, duration: 7))
        //  sceneView.autoenablesDefaultLighting = true
        //=================================Create Lights====================================
        
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = SCNLight.LightType.omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLight.LightType.ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
        
        sceneView.allowsCameraControl = true
        
        sceneView.delegate = self //Very important for the renderer function to work !!!!!!!!!!
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        
        
        
        //motion manager setup
        motionManager = CMMotionManager()
        motionManager?.deviceMotionUpdateInterval = 1.0 / 60.0
        let queue = OperationQueue()
        motionManager?.startDeviceMotionUpdates(using: CMAttitudeReferenceFrame.xArbitraryZVertical, to: queue) { [weak self] (data: CMDeviceMotion?, error: Error?) in
            guard let data = data else {return}
            let roll = CGFloat(data.attitude.roll)
            let rotateCamera = SCNAction.rotateBy(x: 0, y: (roll * -1)/40 , z: 0.0, duration: 0.1)
            self?.cameraNode.runAction(rotateCamera)
            
            
            
        }
 
    }
    
    
    
    func setupCamera()->SCNNode {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 0)
        cameraNode.camera?.usesOrthographicProjection = false
        // cameraNode.camera?.zNear = 0.01
        // cameraNode.camera?.zFar = 200
        cameraNode.camera?.automaticallyAdjustsZRange = true
        
        
        
        //scene.rootNode.addChildNode(cameraNode)
        return cameraNode
    }
    
    func getRandomColor() -> UIColor{
        
        let randomRed:CGFloat = CGFloat(drand48())
        
        let randomGreen:CGFloat = CGFloat(drand48())
        
        let randomBlue:CGFloat = CGFloat(drand48())

        
        return UIColor(red: randomRed, green: randomGreen, blue: randomBlue, alpha: 1.0)
        
    }
    
    func createSoundTowers(_ scene:SCNScene){
        for x in (0...18) {
            audioCubes[x] = SCNBox(width: 5, height: 5, length: 5, chamferRadius: 0)
            audioCubesNodes[x] = SCNNode(geometry: audioCubes[x])
            audioCubesNodes[x].position = SCNVector3(100 * cos(Double(x) * 0.17453292519),0, 100 * -sin(Double(x) * 0.17453292519))
            scene.rootNode.addChildNode(audioCubesNodes[x])
            audioCubes[x].firstMaterial?.diffuse.contents = UIColor.white
            audioCubes[x].firstMaterial?.specular.contents = UIColor.white
            audioCubes[x].firstMaterial?.shininess = 90.0
            
            audioCubesNodes[x].castsShadow = true
        }
    }
    
    func loadAllSounds()
    {
        var zeroToEighteen = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18]
        
        for x in 0...18
        {
            let numDecider = zeroToEighteen[Int(arc4random_uniform(UInt32(zeroToEighteen.count)))]
            //  print("num: \(num)")
            zeroToEighteen.remove(at: zeroToEighteen.index(of: numDecider)!)
            //    print("oneToEighteen: \(oneToEighteen)")
            
            audioCubesNodes[x].addChildNode(audioNodes[x])
            audioSources[x].isPositional = true
            audioSources[x].loops = false
            audioSources[x].volume = 2
            
            switch numDecider {
            case 0,1  :
                audioSources[x] = SCNAudioSource(named: "art.scnassets/250.wav")!
            case 2,3  :
                audioSources[x] = SCNAudioSource(named: "art.scnassets/500.wav")!
            case 4,5  :
                audioSources[x] = SCNAudioSource(named: "art.scnassets/750.wav")!
            case 6,7  :
                audioSources[x] = SCNAudioSource(named: "art.scnassets/1000.wav")!
            case 8,9  :
                audioSources[x] = SCNAudioSource(named: "art.scnassets/2000.wav")!
            case 10,11  :
                audioSources[x] = SCNAudioSource(named: "art.scnassets/3000.wav")!
            case 12,13  :
                audioSources[x] = SCNAudioSource(named: "art.scnassets/4000.wav")!
            case 14,15  :
                audioSources[x] = SCNAudioSource(named: "art.scnassets/6000.wav")!
            case 16,17  :
                audioSources[x] = SCNAudioSource(named: "art.scnassets/8000.wav")!
            default :
                let frequency = ["250","500","750","1000","2000","3000","4000","6000","8000"]
                let frequencyDecider = frequency[Int(arc4random_uniform(UInt32(frequency.count)))]
                SCNAudioSource(named: "art.scnassets/\(frequencyDecider).wav")!
            }
            
        }
    }
    
    func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        
        // check what nodes are tapped
        let tap = gestureRecognize.location(in: scnView)
        let hitResults = scnView.hitTest(tap, options: nil)
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result: AnyObject? = hitResults[0]
            let material = result!.node!.geometry!.firstMaterial!
            if(material.isEqual(groundNode.geometry!.firstMaterial))
            {
                return;
            }
            
            for index in 0...18
            {
                
                if (material.isEqual(audioCubesNodes[index].geometry!.firstMaterial))
                {
                    blockTapped = index
                    checker()
                }
                
            }
            
            
            let delay = 0.75 * Double(NSEC_PER_SEC)
            let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: time) {
                self.playSounds()
            }
            
            userTapsOnCubes += 1
    
            
            // highlight it
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.1
            material.diffuse.contents = UIColor(red: 0, green: 0, blue: 75, alpha: 1)
            SCNTransaction.commit()
            
            
        }
    }
    
    
  func playSounds()
  {
    

    if(userTapsOnCubes == 9)
    {
    let alertController = UIAlertController(title: "Results", message:
    "You got \(totalCorrect)/9 correct. Tap on a block to restart.", preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Restart", style: UIAlertActionStyle.default, handler: {action in self.refreshView()}))

    self.present(alertController, animated: true, completion: nil)
        
        
    }
    else
    {
    
        
        
        numDeciderInPlaySounds = zeroToEighteenInPlaySounds[Int(arc4random_uniform(UInt32(zeroToEighteenInPlaySounds.count)))]
    print("block tapped: \(blockTapped)")
        print("block playing: \(numDeciderInPlaySounds)")
        print()
        zeroToEighteenInPlaySounds.remove(at: zeroToEighteenInPlaySounds.index(of: numDeciderInPlaySounds)!)
    audioPlayers[numDeciderInPlaySounds] = SCNAudioPlayer(source: audioSources[numDeciderInPlaySounds])
    audioNodes[numDeciderInPlaySounds].addAudioPlayer(audioPlayers[numDeciderInPlaySounds]!)
        
    
    }
    }
    
    func checker()
    {
        if( numDeciderInPlaySounds == blockTapped)
        {
            totalCorrect += 1
        }
    }
    
    func refreshView() ->() {
        groundNode = SCNNode()
        userTapsOnCubes = 0
        zeroToEighteenInPlaySounds = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18]
        totalCorrect = 0
        numDeciderInPlaySounds = -1
        blockTapped = -1
        emptyDictionary = [Int: String]()
        viewDidAppear(true)
    }


}
