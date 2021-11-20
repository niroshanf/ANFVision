# ANFVision
Access text and images on a image using vision framework


## Usage

Import the framework

```objective-c
import ANFVision
```
#### Open camera / photo library 

You can choose or provide a photo to the framework by calling,

```objective-c

// open the photo library
ANFVisionManager.takePicture(source: .photoLibrary, delegate: self)

// open the camera
ANFVisionManager.takePicture(source: .camera, delegate: self)

```

By setting the view controller as the delegate you need to implement the two protocols UINavigationControllerDelegate and UIImagePickerControllerDelegate

Below sample implemetation will demostrate how to implement those protocols

```objective-c

extension UIViewController : UINavigationControllerDelegate { }

extension UIViewController: UIImagePickerControllerDelegate {

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {

        dismiss(animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        dismiss(animated: true, completion: nil)

        let originalImage: UIImage = info[.originalImage] as! UIImage

        ............... 
    }
}

```

#### Detect text

To detect text for the supplied image you can use the method `scanText`.
If the scan completed successsfully the noComplete will return success Result with array of all the detected text.
If any error occured, it will call the failure Result and you can handdle the error from your application. 

Parameters::

`image`: UIImage that has text you need to scan.  
`confidence`: confidence level you desire. Ranging from [0.0, 1.0] where 1.0 is most confident 

```objective-c

let imageToScan: UIImage = ...

ANFVisionManager.scanText(image: imageToScan, confidence: 0.5, onComplete: { result in
            
  switch result {
     case .success(let textArray):
         print(textArray)
     case .failure(let error):
         print(error.localizedDescription)
  }
            
})
```

### Detect faces on a picture

`detectFace` method will let you find faces on a given photo.
This method will allow to detect photos that have exact on face and will return error if more than one face detected or no face detected.
It uses Google's Cloud Vision API so in-order it to work you should have a valid API key from google.

Parameters::

`image`: UIImage that needs to detect the faces  
`apiKey`: Google Cloud Vision API key (https://cloud.google.com/)

```objective-c

let imageToScan: UIImage = ...

ANFVisionManager.detectFace(image: imageToScan, apiKey: "<Google Cloude Vision API key>") { result in
            
    switch result {
       case .success(let finalResults):
                    
           switch finalResults {
               case .noFaceDetected:
                  print("No face detected")
               case .moreThanOneFaceDetected:
                  print("More than one face detected")
               case .ok(let image):
                  print("Single face detected")
           }
                
        case .failure(let error):
            print(error.localizedDescription)
      }
}

```

## Author

Anthony Niroshan De Croos Fernandez, niroshanf@gmail.com

## License

ANFVision is available under the MIT license. See the LICENSE file for more info.
