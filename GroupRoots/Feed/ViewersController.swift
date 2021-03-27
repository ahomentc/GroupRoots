import UIKit
import Firebase
import PanModal

protocol ViewersControllerDelegate {
//    func dismissViewersController(_ controller: UIViewController)
    func didTapUser(user: User)
}

class ViewersController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, PanModalPresentable  {
    
    var delegate: ViewersControllerDelegate?
    
    var shortFormHeight: PanModalHeight {
//        return .maxHeight
        return .contentHeight(550)
    }

    var longFormHeight: PanModalHeight {
        return .maxHeightWithTopInset(100)
    }
    
    var panScrollable: UIScrollView? {
        return nil
    }
    
    var viewers: [User]? {
        didSet {
//            navigationItem.title = String(viewers!.count) + " viewers"
            DispatchQueue.main.async{
                guard self.collectionView != nil else { return }
                self.collectionView.reloadData()
            }
        }
    }
    
    var viewsCount: Int? {
        didSet {
            DispatchQueue.main.async{
                guard self.collectionView != nil else { return }
                self.collectionView.reloadData()
            }
        }
    }
    
    var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
                
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(doneSelected))
        navigationItem.leftBarButtonItem?.tintColor = .white
        navigationItem.title = "Viewers"
        let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.backgroundColor = UIColor.black
        
        self.view.backgroundColor = UIColor.init(white: 0, alpha: 0.75)
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
        let navbarHeight = self.navigationController?.navigationBar.frame.size.height ?? 0
        self.collectionView = UICollectionView(frame: CGRect(x: 0, y: 10, width: view.frame.width, height: view.frame.height - navbarHeight - 50 - 20), collectionViewLayout: layout)
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        self.collectionView?.register(ViewerCell.self, forCellWithReuseIdentifier: ViewerCell.cellId)
        self.collectionView?.register(NumHiddenCell.self, forCellWithReuseIdentifier: NumHiddenCell.cellId)
        self.collectionView.backgroundColor = UIColor.clear
        view.addSubview(self.collectionView)
                
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.post(name: NSNotification.Name("tabBarColor"), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.view.setNeedsLayout()
        navigationController?.view.layoutIfNeeded()
        NotificationCenter.default.post(name: NSNotification.Name("tabBarClear"), object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.post(name: NSNotification.Name("tabBarClear"), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.backgroundColor = UIColor.black
    }
    
    @objc private func doneSelected(){
        self.dismiss(animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item < viewers?.count ?? 0 {
//            let userProfileController = UserProfileController(collectionViewLayout: UICollectionViewFlowLayout())
//            userProfileController.user = viewers?[indexPath.item]
//            navigationController?.pushViewController(userProfileController, animated: true)
            guard let viewers = viewers else { return }
            let tappedUser = viewers[indexPath.item]
            self.dismiss(animated: true, completion: {
                self.delegate?.didTapUser(user: tappedUser)
            })
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if viewsCount ?? 0 == 0 { return 0 }
        return (viewers?.count ?? 0) + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item >= viewers?.count ?? 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NumHiddenCell.cellId, for: indexPath) as! NumHiddenCell
            cell.num_total = viewsCount ?? 0
            cell.num_visible = viewers?.count ?? 0
            return cell
        }
        else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ViewerCell.cellId, for: indexPath) as! ViewerCell
            cell.user = viewers?[indexPath.item]
            return cell
        }
    }
}

//MARK: - UICollectionViewDelegateFlowLayout

extension ViewersController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 66)
    }
}

