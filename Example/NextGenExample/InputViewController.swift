//
//  InputViewController.swift
//

import UIKit
import NextGenDataManager
import MBProgressHUD

class InputViewController: UIViewController {
    
    @IBOutlet weak private var manifestXMLTextField: UITextField!
    @IBOutlet weak private var appDataXMLTextField: UITextField!
    @IBOutlet weak private var cpeStyleXMLTextField: UITextField!
    
    private var hud: MBProgressHUD?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTapView))
        self.view.addGestureRecognizer(singleTapGestureRecognizer)
        
        manifestXMLTextField.text = "https://cpe-manifest.s3.amazonaws.com/xml/urn:dece:cid:eidr-s:EE48-FE4D-B363-71AF-A3AB-G/FantasticBeasts_V1.2_Manifest.xml"
        appDataXMLTextField.text = "https://cpe-manifest.s3.amazonaws.com/xml/urn:dece:cid:eidr-s:EE48-FE4D-B363-71AF-A3AB-G/FantasticBeasts_V1.1_AppData.xml"
        cpeStyleXMLTextField.text = "https://cpe-manifest.s3.amazonaws.com/xml/urn:dece:cid:eidr-s:EE48-FE4D-B363-71AF-A3AB-G/FantasticBeasts_V1.1_style.xml"
    }
    
    @objc private func onTapView() {
        manifestXMLTextField.endEditing(true)
        appDataXMLTextField.endEditing(true)
        cpeStyleXMLTextField.endEditing(true)
    }
    
    @IBAction private func onLoad() {
        if let manifestXMLURLString = manifestXMLTextField.text, let manifestXMLURL = URL(string: manifestXMLURLString) {
            hud = MBProgressHUD.showAdded(to: self.view, animated: true)
            
            var appDataXMLURL: URL?
            var cpeStyleXMLURL: URL?
            if let appDataXMLURLString = appDataXMLTextField.text {
                appDataXMLURL = URL(string: appDataXMLURLString)
            }
            
            if let cpeStyleXMLURLString = cpeStyleXMLTextField.text {
                cpeStyleXMLURL = URL(string: cpeStyleXMLURLString)
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try CPEXMLSuite.load(manifestXMLURL: manifestXMLURL, appDataXMLURL: appDataXMLURL, cpeStyleXMLURL: cpeStyleXMLURL) { [unowned self] in
                        DispatchQueue.main.async {
                            self.hud?.hide(true)
                            
                            NextGenLauncher.sharedInstance?.launchExperience(fromViewController: self)
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.hud?.hide(true)
                        
                        let alertController = UIAlertController(title: "Error parsing files", message: "\(error)", preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                        self.navigationController?.present(alertController, animated: true, completion: nil)
                    }
                }
            }
        } else {
            let alertController = UIAlertController(title: "Error parsing files", message: "The specified Manifest XML file could not be found.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.navigationController?.present(alertController, animated: true, completion: nil)
        }
    }
    
}
