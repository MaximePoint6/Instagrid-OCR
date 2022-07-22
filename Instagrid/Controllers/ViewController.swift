//
//  ViewController.swift
//  Instagrid
//
//  Created by Maxime Point on 15/07/2022.
//

import UIKit
import AVFoundation
import Photos

class ViewController: UIViewController {
    
    @IBOutlet weak var appTitle: UILabel!
    @IBOutlet weak var appSubtitle: UILabel!
    @IBOutlet weak var horizontalAppSubtitle: UILabel!
    @IBOutlet var layouts: [UIButton]!
    @IBOutlet weak var currentLayoutView: LayoutView!
    var buttonClicked: UIButton!
    var orientation: Orientation = .portrait
    
    enum Orientation {
        case landscape
        case portrait
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // Initialize Swipe Gesture Recognizer
        let swipeGestureRecognizerUp = UIPanGestureRecognizer(target: self, action: #selector(didSwipe(_:)))
        currentLayoutView.addGestureRecognizer(swipeGestureRecognizerUp)
    }
    
    //MARK: DEvice orientation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if UIDevice.current.orientation.isLandscape {
            print("Landscape")
            orientation = .landscape
        } else {
            print("Portrait")
            orientation = .portrait
        }
    }
    
    private func setupUI() {
        appTitle.font = UIFont(name: "ThirstySoftRegular", size: 29)
        appSubtitle.font = UIFont(name: "Delm-Medium", size: 15)
        horizontalAppSubtitle.font = UIFont(name: "Delm-Medium", size: 15)
    }
    
    @IBAction func layoutSelection(_ sender: UIButton) {
        for layout in self.layouts {
            layout.isSelected = false
        }
        sender.isSelected = !sender.isSelected
        sender.setImage(UIImage(named: "Selected"), for: .selected)
        sender.contentVerticalAlignment = .fill
        sender.contentHorizontalAlignment = .fill
        
        if sender.tag == 0 {
            self.currentLayoutView.layoutType = .OneUpTwoDown
        } else if sender.tag == 1 {
            self.currentLayoutView.layoutType = .TwoUpOneDown
        } else {
            self.currentLayoutView.layoutType = .TwoUpTwoDown
        }
    }
    
    @IBAction func addPicture(_ sender: UIButton) {
        buttonClicked = sender
        showImagePickerOption()
    }
    
    //MARK: Swipe up and Swipe left
    @objc private func didSwipe(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began, .changed:
            transformeView(gesture: sender)
        case .ended, .cancelled:
            let translation = sender.translation(in: currentLayoutView)
            if translation.y > -100 || translation.x > -100 {
                resetLayoutView()
            }
        default:
            break
        }
    }
    
    private func transformeView(gesture: UIPanGestureRecognizer) {
        // Translation
        var translation = gesture.translation(in: currentLayoutView)
        switch orientation {
        case .portrait:
            if translation.y >= 0 {
                translation.y = 0
            } else if translation.y < -100 {
                animationView()
                picturesharing()
            } else {
                let translationTransform = CGAffineTransform(translationX: 0, y: translation.y)
                currentLayoutView.transform = translationTransform
            }
        case .landscape:
            if translation.x >= 0 {
                translation.x = 0
            } else if translation.x < -100 {
                animationView()
                picturesharing()
            } else {
                let translationTransform = CGAffineTransform(translationX: translation.x, y: 0)
                currentLayoutView.transform = translationTransform
            }
        }
    }
    
    private func animationView() {
        // Animation Question View
        let screenHeight = UIScreen.main.bounds.height
        let screenWidth = UIScreen.main.bounds.width
        let translationTransform: CGAffineTransform
        switch orientation {
        case .landscape:
            translationTransform = CGAffineTransform(translationX: -screenWidth, y: 0)
        case .portrait:
            translationTransform = CGAffineTransform(translationX: 0, y: -screenHeight)
        }
        UIView.animate(withDuration: 0.3, animations: {
          self.currentLayoutView.transform = translationTransform
        }, completion: { (success) in
          if success {
            self.resetLayoutView()
          }
        })
    }
    
    private func resetLayoutView() {
        UIView.animate(withDuration: 0.4, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: [], animations: {
          self.currentLayoutView.transform = .identity
        }, completion:nil)
      }
    
    //MARK: picture sharing
    private func picturesharing(){
        let items = [self.currentLayoutView.asImage()]
        let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
        present(ac, animated: true)
    }
    
    //MARK: ImagePicker
    private func showImagePickerOption() {
        let alertVC = UIAlertController(title: "Pick a Photo", message: "Choose a picture from Library or camera", preferredStyle: .actionSheet)
        
        // Image Picker for camera
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { [weak self] (action) in
            guard let self = self else {
                return
            }
            self.cameraAuthorization()
        }
        
        // Image Picker for library
        let libraryAction = UIAlertAction(title: "Library", style: .default) { [weak self] (action) in
            guard let self = self else {
                return
            }
            self.photosAutorization()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertVC.addAction(cameraAction)
        alertVC.addAction(libraryAction)
        alertVC.addAction(cancelAction)
        self.present(alertVC, animated: true, completion: nil)
    }
    
    private func cameraAuthorization() {
        // Authorization for Camera
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: // The user has previously granted access to the camera.
            let cameraImagePicker = self.imagePicker(sourceType: .camera)
            cameraImagePicker.delegate = self
            present(cameraImagePicker, animated: true){
            }
        case .notDetermined: // The user has not yet been asked for camera access.
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    let cameraImagePicker = self.imagePicker(sourceType: .camera)
                    cameraImagePicker.delegate = self
                    self.present(cameraImagePicker, animated: true){}
                }
            }
        case .denied: // The user has previously denied access.
            let alert = UIAlertController(title: "Setting", message: "This app is not authorized to use Camera. Please allow the app to use the camera in settings.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Setting", style: .default, handler: { (_) in
                DispatchQueue.main.async {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        case .restricted: // The user can't grant access due to restrictions.
            return
        @unknown default:
            fatalError()
        }
    }
    
    private func photosAutorization(){
        // Authorization for Photos
        let photoAuthorization = PHPhotoLibrary.authorizationStatus()
        switch photoAuthorization {
        case .authorized, .limited: // The user has previously granted access to the photo.
            let cameraImagePicker = self.imagePicker(sourceType: .photoLibrary)
            cameraImagePicker.delegate = self
            present(cameraImagePicker, animated: true){
            }
        case .notDetermined: // The user has not yet been asked for photos access.
            PHPhotoLibrary.requestAuthorization({status in
                if #available(iOS 14, *) {
                    if status == .authorized || status == .limited {
                        let libraryImagePicker = self.imagePicker(sourceType: .photoLibrary)
                        libraryImagePicker.delegate = self
                        self.present(libraryImagePicker, animated: true){}
                    }
                } else {
                    if status == .authorized {
                        let libraryImagePicker = self.imagePicker(sourceType: .photoLibrary)
                        libraryImagePicker.delegate = self
                        self.present(libraryImagePicker, animated: true){}
                    }
                }
            })
        case .denied: // The user has previously denied access.
            let alert = UIAlertController(title: "Setting", message: "This app is not authorized to use Photos. Please allow the app to use photos in settings.", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Setting", style: .default, handler: { (_) in
                DispatchQueue.main.async {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        case .restricted: // The user can't grant access due to restrictions.
            return
        @unknown default:
            fatalError()
        }
    }
    
    private func imagePicker(sourceType: UIImagePickerController.SourceType) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = sourceType
        return imagePicker
    }
    
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[.originalImage] as! UIImage
        self.buttonClicked.setImage(image, for: .normal)
        self.buttonClicked.setTitle("", for: .normal)
        buttonClicked.imageView?.contentMode = UIView.ContentMode.scaleAspectFill
        self.dismiss(animated: true, completion: nil)
    }
}