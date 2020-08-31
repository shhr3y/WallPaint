//
//  MainController.swift
//  WallPaint
//
//  Created by Shrey Gupta on 31/08/20.
//  Copyright © 2020 Shrey Gupta. All rights reserved.
//

import UIKit
import CoreImage

class MainController: UIViewController {
    //MARK: - Properties
    var hueRange: Float = 40
    
    var ciImage: CIImage?
    var defaultHue: Float?
    let image: UIImage = #imageLiteral(resourceName: "image-1").withRenderingMode(.alwaysOriginal)
    
    lazy var displayImage: UIImageView = {
        let iv = UIImageView()
        iv.image = self.image
//        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        
        iv.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(touchedScreen(touch:)))
        iv.addGestureRecognizer(tap)
        
        return iv
    }()
    
    private let selectImageContainer: UIView = {
        let container = UIView()
        
        let button = UIButton(type: .system)
        button.setTitle("Select Image", for: .normal)
        button.addTarget(self, action: #selector(handleSelectImage), for: .touchUpInside)
        
        container.addSubview(button)
        button.anchor(top: container.topAnchor, left: container.leftAnchor, bottom: container.bottomAnchor, right: container.rightAnchor)
        
        return container
    }()
    
    private let slider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = 0.5
        
        slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        return slider
    }()
    
    lazy var hueLabel: UILabel = {
        let label = UILabel()
        label.text = NSString(format:"%.2lf", slider.value) as String
        return label
    }()
    
    private let switchWhite: UISwitch = {
        let sw = UISwitch()
        sw.isOn = false
        return sw
    }()
    
    //MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.ciImage = CIImage(image: displayImage.image!)
        configureUI()
        // Do any additional setup after loading the view.
    }
    
    //MARK: - Selectors
    @objc func sliderChanged() {
        hueLabel.text = NSString(format:"%.2lf", slider.value) as String
    }
    
    @objc func handleRunTapped() {
        render()
    }
    
    @objc func handleClearTapped() {
        displayImage.image = self.image
        self.ciImage = CIImage(image: displayImage.image!)
    }
    
    @objc func touchedScreen(touch: UITapGestureRecognizer) {
        let touchPoint = touch.location(in: self.view)
        let frame = displayImage.frame.size
        guard let rgbColour = displayImage.image?.getPixelColors2(atLocation: touchPoint, withFrameSize: frame) else { return }
        
        view.backgroundColor = rgbColour
        
        let red = Float(rgbColour.rgba.red)
        let green = Float(rgbColour.rgba.green)
        let blue = Float(rgbColour.rgba.blue)
        
        let hsv = RGBtoHSV(r: red, g: green, b: blue)
        
        self.defaultHue = hsv.h * 360
        
        print("DEBUG:- HUE: \(defaultHue) for COLOR: \(red*255) \(green*255) \(blue*255)")
    }
    
    @
    
    
    
    //MARK: - Helper Functions
    
    func render() {
        self.ciImage = CIImage(image: displayImage.image!)
        guard let defaultHue = self.defaultHue else { return }
        
        let centerHueAngle: Float = defaultHue/360.0
        var destCenterHueAngle: Float = slider.value
        let minHueAngle: Float = (defaultHue - hueRange/2.0) / 360
        let maxHueAngle: Float = (defaultHue + hueRange/2.0) / 360
        let hueAdjustment = centerHueAngle - destCenterHueAngle
        if destCenterHueAngle == 0 && !switchWhite.isOn {
            destCenterHueAngle = 1 //force red if slider angle is 0
        }
        let size = 64
        var cubeData = [Float](repeating: 0, count: size * size * size * 4)
        var rgb: [Float] = [0, 0, 0]
        var hsv: (h : Float, s : Float, v : Float)
        var newRGB: (r : Float, g : Float, b : Float)
        var offset = 0
        for z in 0 ..< size {
            rgb[2] = Float(z) / Float(size) // blue value
            for y in 0 ..< size {
                rgb[1] = Float(y) / Float(size) // green value
                for x in 0 ..< size {
                    rgb[0] = Float(x) / Float(size) // red value
                    hsv = RGBtoHSV(r: rgb[0], g: rgb[1], b: rgb[2])
                    if hsv.h < minHueAngle || hsv.h > maxHueAngle {
                        newRGB.r = rgb[0]
                        newRGB.g = rgb[1]
                        newRGB.b = rgb[2]
                    } else {
                        if switchWhite.isOn {
                            hsv.s = 0
                            hsv.v = hsv.v - hueAdjustment
                        } else {
                            hsv.h = destCenterHueAngle == 1 ? 0 : hsv.h - hueAdjustment //force red if slider angle is 360
                        }
                        newRGB = HSVtoRGB(h: hsv.h, s:hsv.s, v:hsv.v)
                    }
                    cubeData[offset] = newRGB.r
                    cubeData[offset+1] = newRGB.g
                    cubeData[offset+2] = newRGB.b
                    cubeData[offset+3] = 1.0
                    offset += 4
                }
            }
        }
        let b = cubeData.withUnsafeBufferPointer { Data(buffer: $0) }
        let data = b as NSData
        let colorCube = CIFilter(name: "CIColorCube")!
        colorCube.setValue(size, forKey: "inputCubeDimension")
        colorCube.setValue(data, forKey: "inputCubeData")
        colorCube.setValue(ciImage, forKey: kCIInputImageKey)
        if let outImage = colorCube.outputImage {
            let context = CIContext(options: nil)
            let outputImageRef = context.createCGImage(outImage, from: outImage.extent)
            displayImage.image = UIImage(cgImage: outputImageRef!)
        }
    }
    
    func RGBtoHSV(r : Float, g : Float, b : Float) -> (h : Float, s : Float, v : Float) {
        var h : CGFloat = 0
        var s : CGFloat = 0
        var v : CGFloat = 0
        let col = UIColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1.0)
        col.getHue(&h, saturation: &s, brightness: &v, alpha: nil)
        return (Float(h), Float(s), Float(v))
    }
    
    func HSVtoRGB(h : Float, s : Float, v : Float) -> (r : Float, g : Float, b : Float) {
        var r : Float = 0
        var g : Float = 0
        var b : Float = 0
        let C = s * v
        let HS = h * 6.0
        let X = C * (1.0 - fabsf(fmodf(HS, 2.0) - 1.0))
        if (HS >= 0 && HS < 1) {
            r = C
            g = X
            b = 0
        } else if (HS >= 1 && HS < 2) {
            r = X
            g = C
            b = 0
        } else if (HS >= 2 && HS < 3) {
            r = 0
            g = C
            b = X
        } else if (HS >= 3 && HS < 4) {
            r = 0
            g = X
            b = C
        } else if (HS >= 4 && HS < 5) {
            r = X
            g = 0
            b = C
        } else if (HS >= 5 && HS < 6) {
            r = C
            g = 0
            b = X
        }
        let m = v - C
        r += m
        g += m
        b += m
        return (r, g, b)
    }
 
    func configureUI() {
        view.backgroundColor = .white
        
        navigationItem.title = "Wall Paint"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Run", style: .plain, target: self, action: #selector(handleRunTapped))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(handleClearTapped))
        
        view.addSubview(slider)
        slider.anchor(left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingLeft: 10, paddingBottom: 40, paddingRight: 10)
        
        view.addSubview(hueLabel)
        hueLabel.anchor(left: view.leftAnchor, bottom: slider.topAnchor)
        
        
        view.addSubview(displayImage)
        displayImage.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, bottom: hueLabel.topAnchor, right: view.rightAnchor, paddingBottom: 20)
        
        view.addSubview(switchWhite)
        switchWhite.anchor(bottom: slider.topAnchor, right: view.rightAnchor)
    }
}
