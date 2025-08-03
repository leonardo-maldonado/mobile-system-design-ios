import UIKit
import Combine

class ImageGalleryViewController: UIViewController {
    
    enum Section: Int {
        case pinned
        case recents
    }
    
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, Media>!
    private var cancellables = Set<AnyCancellable>()
    private var viewModel: ImageGalleryViewModel = .init()
            
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureCollectionView()
        configureDataSource()
        configureDataSourceHeader()
        bindItems()
        viewModel.loadAll()
    }
    
    func createLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in
            guard let section = Section(rawValue: sectionIndex) else { return nil }
            switch section {
            case .pinned:
                return ImageGalleryFactory.makePinnedSection()
            case .recents:
                return ImageGalleryFactory.makeRecentsSection()
            }
        }
    }
    
    private func configureCollectionView() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.register(
            ImageGalleryCell.self,
            forCellWithReuseIdentifier: ImageGalleryCell.reuseIdentifier
        )
        collectionView.register(
            UICollectionReusableView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "Header"
        )
        collectionView.prefetchDataSource = self
        view.addSubview(collectionView)
    }
    
    private func configureDataSource() {
        self.dataSource = UICollectionViewDiffableDataSource<Section, Media>(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, item in

            guard
                let self = self,
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: ImageGalleryCell.reuseIdentifier,
                    for: indexPath
                ) as? ImageGalleryCell
            else {
                return UICollectionViewCell()
            }

            self.configure(cell: cell, for: item, at: indexPath)

            return cell
        }
    }
    
    private func configure(cell: ImageGalleryCell, for item: Media, at indexPath: IndexPath) {
        cell.configure(with: item)
        
        Task {
            let result = await viewModel.prefetch(for: item)
            
            await MainActor.run {
                guard
                    let currentIndexPath = collectionView.indexPath(for: cell),
                    currentIndexPath == indexPath
                else {
                    return
                }
                
                switch result {
                case .success(let media):
                    cell.configure(with: media)
                case .failure:
                    print("Failed to load image for \(item.url)")
                }
            }
        }
    }
    
    func configureDataSourceHeader() {
        self.dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            guard kind == UICollectionView.elementKindSectionHeader else {
                return nil
            }
            
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: "Header",
                for: indexPath
            )
            
            if header.subviews.isEmpty {
                let label = UILabel(frame: header.bounds)
                label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                label.font = UIFont.boldSystemFont(ofSize: 20)
                label.textAlignment = .left
                header.addSubview(label)
            }
            
            if let label = header.subviews.first as? UILabel {
                let section = Section(rawValue: indexPath.section)
                label.text = {
                    switch section {
                    case .pinned: return "Pinned Collections"
                    case .recents: return "Recent Days"
                    case .none: return ""
                    }
                }()
            }
            
            return header
        }
    }
    
    private func bindItems() {
        viewModel.$items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                guard let self = self else { return }
                var snapshot = NSDiffableDataSourceSnapshot<Section, Media>()
                snapshot.appendSections([.pinned, .recents])
                let pinnedItems = items.filter { $0.type == .pinned }
                let recentsItems = items.filter { $0.type == .recents }
                snapshot.appendItems(pinnedItems, toSection: .pinned)
                snapshot.appendItems(recentsItems, toSection: .recents)
                self.dataSource.apply(snapshot, animatingDifferences: true)
            }
            .store(in: &cancellables)
    }
}

extension ImageGalleryViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(
        _ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath])
    {
        for indexPath in indexPaths {
            let item = viewModel.items[indexPath.item]
            weak var viewModel = self.viewModel
            Task {
                guard let viewModel else { return }
                print("Prefetching \(item.id)")
                await _ = viewModel.prefetch(for: item)
            }
        }
    }
}
