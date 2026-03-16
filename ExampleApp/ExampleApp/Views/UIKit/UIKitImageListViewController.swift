
//  UIKitImageListViewController.swift
//
//  Copyright © 2026 Boris Nikolic. All rights reserved.

import RoundsImageKit
import UIKit

final class UIKitImageListViewController: UICollectionViewController {
    private let viewModel: ImageListViewModel
    private var dataSource: UICollectionViewDiffableDataSource<Int, ImageItem>!
    private lazy var errorContainerView = makeErrorView()

    // MARK: - Init

    init(viewModel: ImageListViewModel) {
        self.viewModel = viewModel
        super.init(collectionViewLayout: Self.makeLayout())
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Theme.Strings.appTitle
        view.backgroundColor = .systemGroupedBackground
        collectionView.backgroundColor = .systemGroupedBackground

        configureNavBar()
        configureDataSource()
        configureRefreshControl()
        updateImages(viewModel.images)
    }

    // MARK: - Public

    func updateImages(_ images: [ImageItem]) {
        guard dataSource != nil else { return }
        var snapshot = NSDiffableDataSourceSnapshot<Int, ImageItem>()
        snapshot.appendSections([0])
        snapshot.appendItems(images)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    func endRefreshing() {
        collectionView.refreshControl?.endRefreshing()
    }

    func showError(_ message: String) {
        errorContainerView.isHidden = false
        if let label = errorContainerView.viewWithTag(1001) as? UILabel {
            label.text = message
        }
        collectionView.isHidden = true
    }

    func hideError() {
        errorContainerView.isHidden = true
        collectionView.isHidden = false
    }

    // MARK: - Error View

    private func makeErrorView() -> UIView {
        let container = UIView()
        container.accessibilityIdentifier = Theme.AccessibilityID.errorView
        container.translatesAutoresizingMaskIntoConstraints = false
        container.isHidden = true

        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = Theme.loadingSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false

        let iconConfig = UIImage.SymbolConfiguration(pointSize: Theme.errorIconSize, weight: .regular)
        let iconView = UIImageView(image: UIImage(systemName: Theme.SFSymbol.errorTriangle, withConfiguration: iconConfig))
        iconView.tintColor = .orange

        let titleLabel = UILabel()
        titleLabel.text = Theme.Strings.errorTitle
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textAlignment = .center

        let messageLabel = UILabel()
        messageLabel.tag = 1001
        messageLabel.font = .preferredFont(forTextStyle: .caption1)
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        let retryButton = UIButton(type: .system)
        retryButton.setTitle(Theme.Strings.retryButton, for: .normal)
        retryButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
        retryButton.backgroundColor = Theme.brandPurple
        retryButton.setTitleColor(.white, for: .normal)
        retryButton.layer.cornerRadius = 8
        retryButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20)
        retryButton.accessibilityIdentifier = Theme.AccessibilityID.retryButton
        retryButton.accessibilityHint = Theme.Strings.retryHint
        retryButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            Task { await self.viewModel.fetchImages() }
        }, for: .touchUpInside)

        stack.addArrangedSubview(iconView)
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(messageLabel)
        stack.addArrangedSubview(retryButton)

        container.addSubview(stack)
        view.addSubview(container)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: view.topAnchor),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: Theme.gridPadding),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -Theme.gridPadding),
        ])

        return container
    }

    // MARK: - Layout

    private static func makeLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(Theme.gridItemFraction),
            heightDimension: .fractionalWidth(Theme.gridItemFraction)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(
            top: Theme.cellInset,
            leading: Theme.cellInset,
            bottom: Theme.cellInset,
            trailing: Theme.cellInset
        )

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalWidth(Theme.gridItemFraction)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item, item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: Theme.sectionInset,
            leading: Theme.sectionInset,
            bottom: Theme.sectionInset,
            trailing: Theme.sectionInset
        )

        return UICollectionViewCompositionalLayout(section: section)
    }

    // MARK: - Nav Bar

    private func configureNavBar() {
        let clearAction = UIAction(
            title: Theme.Strings.clearCache,
            image: UIImage(systemName: Theme.SFSymbol.clearCache)
        ) { [weak self] _ in
            guard let self else { return }
            Task { await self.viewModel.clearCache() }
        }
        let button = UIBarButtonItem(primaryAction: clearAction)
        button.tintColor = .label
        button.accessibilityIdentifier = Theme.AccessibilityID.clearCacheButton
        button.accessibilityLabel = Theme.Strings.clearCache
        button.accessibilityHint = Theme.Strings.clearCacheHint
        navigationItem.rightBarButtonItem = button
    }

    // MARK: - Refresh Control

    private func configureRefreshControl() {
        let refresh = UIRefreshControl()
        refresh.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            Task { await self.viewModel.fetchImages() }
        }, for: .valueChanged)
        collectionView.refreshControl = refresh
    }

    // MARK: - Data Source

    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<ImageCell, ImageItem> { cell, _, item in
            cell.configure(with: item)
        }

        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
    }
}

// MARK: - Image Cell

private final class ImageCell: UICollectionViewCell {
    private let cachedImageView = UICachedImageView()
    private let idLabel = PaddedLabel()
    private let gradientView = GradientView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cachedImageView.prepareForReuse()
    }

    func configure(with item: ImageItem) {
        cachedImageView.load(from: item.url)
        idLabel.text = Theme.Strings.imageBadge(item.id)
        isAccessibilityElement = true
        accessibilityIdentifier = "\(Theme.AccessibilityID.imageCell)_\(item.id)"
        accessibilityLabel = Theme.Strings.imageLabel(item.id)
        accessibilityHint = Theme.Strings.imageHint
        accessibilityTraits = .image
    }

    private func setupViews() {
        contentView.layer.cornerRadius = Theme.cornerRadius
        contentView.clipsToBounds = true
        contentView.backgroundColor = .tertiarySystemFill

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = Float(Theme.shadowOpacity)
        layer.shadowRadius = Theme.shadowRadius
        layer.shadowOffset = CGSize(width: 0, height: Theme.shadowOffsetY)
        layer.cornerRadius = Theme.cornerRadius
        layer.borderWidth = Theme.borderWidth
        layer.borderColor = UIColor.black.withAlphaComponent(Theme.borderOpacity).cgColor

        cachedImageView.imageContentMode = .scaleAspectFill
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: Theme.placeholderIconSize, weight: .regular)
        cachedImageView.placeholder = UIImage(
            systemName: Theme.SFSymbol.photoPlaceholder,
            withConfiguration: symbolConfig
        )?.withTintColor(.quaternaryLabel, renderingMode: .alwaysOriginal)
        cachedImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cachedImageView)

        gradientView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(gradientView)

        idLabel.font = .monospacedDigitSystemFont(ofSize: Theme.badgeLabelFontSize, weight: .bold)
        idLabel.textColor = .white
        idLabel.textAlignment = .center
        idLabel.backgroundColor = Theme.brandPurple
        idLabel.layer.cornerRadius = Theme.badgeCornerRadius
        idLabel.clipsToBounds = true
        idLabel.accessibilityIdentifier = Theme.AccessibilityID.imageBadge
        idLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(idLabel)

        NSLayoutConstraint.activate([
            cachedImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cachedImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cachedImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cachedImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            gradientView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            gradientView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: Theme.gradientHeightMultiplier),

            idLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Theme.badgePadding),
            idLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Theme.badgePadding),
            idLabel.heightAnchor.constraint(equalToConstant: Theme.badgeLabelHeight),
        ])
    }
}

// MARK: - Padded Label

private final class PaddedLabel: UILabel {
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + Theme.paddedLabelExtraWidth, height: size.height)
    }
}

// MARK: - Gradient View

private final class GradientView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }

    override init(frame: CGRect) {
        super.init(frame: frame)
        guard let gradient = layer as? CAGradientLayer else { return }
        gradient.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(Theme.gradientOpacity).cgColor]
        gradient.locations = [0.0, 1.0]
        isUserInteractionEnabled = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
