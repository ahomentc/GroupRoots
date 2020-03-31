import UIKit
import Firebase

class ViewersController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate  {
    
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
                
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.tintColor = .black
        navigationItem.title = "Viewers"
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
        self.collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height), collectionViewLayout: layout)
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        self.collectionView?.register(ViewerCell.self, forCellWithReuseIdentifier: ViewerCell.cellId)
        self.collectionView?.register(NumHiddenCell.self, forCellWithReuseIdentifier: NumHiddenCell.cellId)
        self.collectionView.backgroundColor = UIColor.white
        view.addSubview(self.collectionView)
                
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.post(name: NSNotification.Name("tabBarColor"), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.post(name: NSNotification.Name("tabBarClear"), object: nil)
        navigationController?.view.setNeedsLayout()
        navigationController?.view.layoutIfNeeded()
        self.collectionView?.refreshControl?.endRefreshing()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item < viewers?.count ?? 0 {
            let userProfileController = UserProfileController(collectionViewLayout: UICollectionViewFlowLayout())
            userProfileController.user = viewers?[indexPath.item]
            navigationController?.pushViewController(userProfileController, animated: true)
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

