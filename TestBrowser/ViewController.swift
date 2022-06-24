//
//  ViewController.swift
//  TestBrowser
//
//  Created by Varun Kapoor on 15/06/22.
//

import UIKit
import WebKit

class ViewController: UIViewController {

    lazy var mainTextfield = UITextField()
    lazy var toolbarTextfield = UITextField()

    var webView: WKWebView!
    var toolbarBottomConstraint: NSLayoutConstraint?
    var addressBarBottomConstraint: NSLayoutConstraint?
    var collapsingToolbarAnimator: UIViewPropertyAnimator?
    var expandingToolbarAnimator: UIViewPropertyAnimator?
    var isCollapsed = false

    let addressBarExpandedConstant: CGFloat = -30
    let toolbarExpandedConstant: CGFloat = 0
    let addressBarMidConstant: CGFloat = -15
    let toolbarMidConstant: CGFloat = 15
    let addressBarExpandingMidConstant: CGFloat = 10
    let toolbarExpandingMidConstant: CGFloat = 40
    let addressBarCollapsedConstant: CGFloat = 15
    let toolbarCollapsedConstant: CGFloat = 55


    var lastOffsetY: CGFloat = 0
    let urlString = "https://addons.mozilla.org/en-US/firefox/addon/top-sites-button"

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardNotification(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)


        webView = WKWebView(frame: self.view.bounds, configuration: getWebViewConfiguration())
        view.addSubview(webView)
        
        webView.scrollView.delegate = self
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
            webView.navigationDelegate = self
            mainTextfield.text = urlString
        }

        mainTextfield.returnKeyType = .go
        mainTextfield.delegate = self

        setupToolbar()

    }

    func setupToolbar() {
        let toolbar = UIToolbar(frame: .zero)
        view.addSubview(toolbar)
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.heightAnchor.constraint(equalToConstant: 62).isActive = true
        toolbar.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        toolbar.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        toolbarBottomConstraint = toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        toolbarBottomConstraint?.isActive = true

        view.addSubview(mainTextfield)
        mainTextfield.translatesAutoresizingMaskIntoConstraints = false
        mainTextfield.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16).isActive = true
        mainTextfield.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16).isActive = true
        addressBarBottomConstraint = mainTextfield.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: addressBarExpandedConstant)
        addressBarBottomConstraint?.isActive = true
    }

    func setupCollapsingToolbarAnimator() {
        addressBarBottomConstraint?.constant = addressBarMidConstant
      toolbarBottomConstraint?.constant = toolbarMidConstant
      collapsingToolbarAnimator = UIViewPropertyAnimator(duration: 0.1, curve: .linear) { [weak self] in
//          self?.mainTextfield.alpha = 0
          self?.view.layoutIfNeeded()
      }


      collapsingToolbarAnimator?.addCompletion { [weak self] _ in
        guard let self = self else { return }

          self.addressBarBottomConstraint?.constant = self.addressBarCollapsedConstant
          self.toolbarBottomConstraint?.constant = self.toolbarCollapsedConstant
        UIViewPropertyAnimator(duration: 0.2, curve: .easeOut) { [weak self] in
          guard let self = self else { return }
          self.mainTextfield.transform = CGAffineTransform(scaleX: 1.2, y: 0.8)
          self.mainTextfield.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
          self.view.layoutIfNeeded()
        }.startAnimation()
      }
      
      collapsingToolbarAnimator?.pauseAnimation()
    }

    func setupExpandingToolbarAnimator() {
        addressBarBottomConstraint?.constant = addressBarExpandingMidConstant
        toolbarBottomConstraint?.constant = toolbarExpandingMidConstant
        expandingToolbarAnimator = UIViewPropertyAnimator(duration: 0.1, curve: .linear) { [weak self] in
            self?.view.layoutIfNeeded()
        }
        expandingToolbarAnimator?.addCompletion { [weak self] _ in
            guard let self = self else { return }
            self.toolbarBottomConstraint?.constant = self.toolbarExpandedConstant
            self.addressBarBottomConstraint?.constant = self.addressBarExpandedConstant
            UIViewPropertyAnimator(duration: 0.2, curve: .easeIn) { [weak self] in
                self?.mainTextfield.transform = .identity
                self?.mainTextfield.transform = .identity
                self?.view.layoutIfNeeded()
            }.startAnimation()
        }
        expandingToolbarAnimator?.pauseAnimation()
    }

    func webViewDidScroll(yOffsetChange: CGFloat) {
        let offsetChangeBeforeFullAnimation = CGFloat(30)
        let animationFractionComplete = abs(yOffsetChange) / offsetChangeBeforeFullAnimation
        let thresholdBeforeAnimationCompletion = CGFloat(0.6)
        let isScrollingDown = yOffsetChange < 0

        if isScrollingDown {
            guard !isCollapsed else { return }

            if collapsingToolbarAnimator == nil || collapsingToolbarAnimator?.state == .inactive {
                setupCollapsingToolbarAnimator()
            }

            if animationFractionComplete < thresholdBeforeAnimationCompletion {
                collapsingToolbarAnimator?.fractionComplete = animationFractionComplete
            } else {
                isCollapsed = true
                collapsingToolbarAnimator?.continueAnimation(withTimingParameters: nil, durationFactor: 0)
            }
        } else {
            guard isCollapsed else { return }
            if expandingToolbarAnimator == nil || expandingToolbarAnimator?.state == .inactive {
                setupExpandingToolbarAnimator()
            }

            if animationFractionComplete < thresholdBeforeAnimationCompletion {
                expandingToolbarAnimator?.fractionComplete = animationFractionComplete
            } else {
                isCollapsed = false
                expandingToolbarAnimator?.continueAnimation(withTimingParameters: nil, durationFactor: 0)
            }
        }
    }

    func getWebViewConfiguration() -> WKWebViewConfiguration {
        let userController = WKUserContentController()
        userController.add(self, name: "observer")
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userController
         return configuration
    }


    @objc func keyboardNotification(notification: NSNotification) {
         guard let userInfo = notification.userInfo else { return }

         let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
         let endFrameY = endFrame?.origin.y ?? 0

         if endFrameY >= UIScreen.main.bounds.size.height {
           self.toolbarBottomConstraint?.constant = toolbarExpandedConstant
             self.addressBarBottomConstraint?.constant = addressBarExpandedConstant
         } else {
             let bottomInset = (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0.0)
             self.toolbarBottomConstraint?.constant = -1 * ((endFrame?.size.height ?? 0.0) - bottomInset)
             self.addressBarBottomConstraint?.constant = -1 * ((endFrame?.size.height ?? 0.0) - bottomInset + 30)
         }

        let duration:TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
        let animationCurveRawNSN = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
        let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
        let animationCurve:UIView.AnimationOptions = UIView.AnimationOptions(rawValue: animationCurveRaw)

         UIView.animate(withDuration: duration, delay: TimeInterval(0), options: animationCurve, animations: {
             self.view.layoutIfNeeded()
         }, completion: nil)
       }

}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let url = URL(string: textField.text ?? "") {
            let request = URLRequest(url: url)
            webView.load(request)
            textField.inputAccessoryView = nil
            textField.resignFirstResponder()
            return false
        }

        return true
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if isCollapsed{
            return false
        }
        return true
    }

}



extension ViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("var firstbtn = document.getElementsByClassName('Button Button--action GetFirefoxButton-button Button--puffy')[0]; firstbtn.innerText = 'Hello'; let btn = document.createElement('button'); btn.className = 'Button Button--action GetFirefoxButton-button Button--puffy'; btn.innerHTML = 'Add to Orion'; btn.addEventListener('click', function () {var downloadLink = document.getElementsByClassName('InstallButtonWrapper-download-link')[0].href; window.webkit.messageHandlers.observer.postMessage(downloadLink);}); document.body.appendChild(btn); firstbtn.parentNode.replaceChild(btn, firstbtn);") { (result, error) in
            if error == nil {
                print(result ?? "")
            }
            print("evaluated JavaScript")

        }
    }
}

extension ViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {


        let alert = UIAlertController(title: "xpi URL", message: message.body as? String ?? "", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default)
        alert.addAction(okAction)
        present(alert, animated: true)
    }


}

extension ViewController: UIScrollViewDelegate {

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        lastOffsetY = scrollView.contentOffset.y
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        webViewDidScroll(yOffsetChange: lastOffsetY - scrollView.contentOffset.y)
    }
}
