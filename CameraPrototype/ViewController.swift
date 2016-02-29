//
//  ViewController.swift
//  CameraPrototype
//
//  Created by Heydar Maboudi Afkham on 28/02/16.
//  Copyright © 2016 Heydar Maboudi Afkham. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, UINavigationControllerDelegate
{
    @IBOutlet weak var ip_field: UITextField?
    @IBOutlet weak var image_view: UIImageView?
    
    @IBOutlet weak var orig_size: UITextField?
    @IBOutlet weak var send_size: UITextField?
    
    @IBOutlet weak var slider: UISlider?
    
    private var cameraSession: AVCaptureSession?
    private var imageOutput: AVCaptureStillImageOutput?
    
    var imagePicker: UIImagePickerController!
    var has_image: Bool!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        has_image = false
        slider?.addTarget(self, action:"slider_changed:", forControlEvents: UIControlEvents.ValueChanged )
        
        cameraSession = AVCaptureSession()
        imageOutput = AVCaptureStillImageOutput()

        cameraSession!.sessionPreset = AVCaptureSessionPresetPhoto
        let backCamera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        let input: AVCaptureDeviceInput!
        do {
            input = try AVCaptureDeviceInput(device: backCamera)
        } catch _ as NSError {
            input = nil
        }
        
        if input != nil && cameraSession!.canAddInput(input) {
            cameraSession!.addInput(input)
            
            imageOutput!.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
            if cameraSession!.canAddOutput(imageOutput) {
                cameraSession!.addOutput(imageOutput)
                cameraSession!.startRunning()
            }
        }

    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func select_photo(sender:UIButton)
    {
        if let videoConnection = imageOutput!.connectionWithMediaType(AVMediaTypeVideo)
        {
            videoConnection.videoOrientation = AVCaptureVideoOrientation.Portrait
            imageOutput?.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: {(sampleBuffer, error) in
            if (sampleBuffer != nil)
            {
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                
                self.set_image(UIImage(data:imageData))
                
            }
            else
            {
                // Fail, no data
            }
            })
        }
    }
    
    func set_image(image:UIImage!)
    {
        image_view!.image = image
        has_image = true
        orig_size!.text = NSStringFromCGSize((image_view?.image?.size)!)
        send_size!.text = NSStringFromCGSize((image_view?.image?.size)!)
        slider?.setValue( (slider?.maximumValue)! , animated: true )
    }
    
    func resize_image( image:UIImage, scale:CGFloat ) -> UIImage
    {
        let h = round(image.size.height * scale)
        let w = round(image.size.width * scale)
        
        UIGraphicsBeginImageContext(CGSizeMake(w,h))
        image.drawInRect(CGRectMake(0,0,w,h))
        let new_image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return new_image
    }
    
    @IBAction func send_photo(sender:UIButton)
    {
        if( has_image == true )
        {
            let scale = CGFloat(round( (slider?.value)! ) / 5.0)
            let simg = resize_image((image_view?.image)!, scale: scale)
            
            print( NSStringFromCGSize(simg.size) )
            let jpeg_data = UIImageJPEGRepresentation(simg, 0.9 )
            
            let url = NSURL(string:"http://10.0.1.3:8888")
            let session = NSURLSession.sharedSession()
            let request = NSMutableURLRequest(URL: url!)
            request.HTTPMethod = "POST"
            request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.HTTPBody = jpeg_data
            let task = session.dataTaskWithRequest(request)
            {
                (
                let data, let response, let error) in
                
                guard let _:NSData = data, let _:NSURLResponse = response  where error == nil else {
                    print("error")
                    return
                }
                
                let dataString = NSString(data: data!, encoding: NSUTF8StringEncoding)
                print(dataString)
                
            }
            task.resume()
        }
    }
    
    @IBAction func slider_changed(sender:AnyObject!)
    {
        if( has_image == true )
        {
            let value:Int = Int( round( (slider?.value)! ) )
            
            // Not a good code under here
            let s = image_view!.image?.size
            let h = (s?.height)! / 5.0
            let w = (s?.width)! / 5.0
            
            let new_size = CGSize(width: round(w*CGFloat(value)), height: round(h*CGFloat(value)) )
            send_size!.text = NSStringFromCGSize(new_size)
            
        }
        else
        {
            slider?.setValue( (slider?.maximumValue)! , animated: true )
        }
    }
}

