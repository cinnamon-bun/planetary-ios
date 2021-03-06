//
//  AboutViewController.swift
//  FBTT
//
//  Created by Christoph on 2/26/19.
//  Copyright © 2019 Verse Communications Inc. All rights reserved.
//

import Foundation
import UIKit

class AboutViewController: ContentViewController {

    private let identity: Identity
    private var about: About?

    private let aboutView = AboutView()

    private let dataSource = PostReplyDataSource()
    private lazy var delegate = PostReplyDelegate(on: self)
    private let prefetchDataSource = PostReplyDataSourcePrefetching()

    private var followingIdentities: Identities = []
    private var followedByIdentities: Identities = []

    private lazy var tableView: UITableView = {
        let view = UITableView.forVerse()
        view.dataSource = self.dataSource
        view.delegate = self.delegate
        view.prefetchDataSource = self.prefetchDataSource
        return view
    }()

    // TODO https://app.asana.com/0/914798787098068/1146899678085073/f
    // TODO improve init delegation
    init(with identity: Identity) {
        self.identity = identity
        let about = About(about: identity)
        self.about = about
        super.init(scrollable: false)
        self.aboutView.update(with: about)
        self.addActions()
    }

    convenience init(with about: About) {
        self.init(with: about.identity)
        self.update(with: about)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        Layout.fill(view: self.contentView, with: self.tableView, respectSafeArea: false)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage.verse.link,
                                                                 style: .plain,
                                                                 target: self,
                                                                 action: #selector(didPressCopyIdentifierIcon))

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.loadAbout()
        self.loadFeed()
        self.loadFollows()
        self.loadFollowedBy()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.setTableHeaderView(self.aboutView)
    }

    private func loadAbout() {
        Bots.current.about(identity: self.identity) {
            [weak self] about, error in
            Log.optional(error)
            guard let about = about else { return }
            self?.about = about
            self?.update(with: about)
        }
    }

    private func loadFeed() {
        Bots.current.feed(identity: self.identity) {
            [weak self] keyValues, error in
            if Log.optional(error) { return }
            self?.dataSource.keyValues = keyValues.posts.sortedByDateDescending().rootPosts()
            self?.tableView.forceReload()
        }
    }

    private func loadFollows() {
        Bots.current.follows(identity: self.identity) {
            [weak self] identities, error in
            Log.optional(error)
            self?.followingIdentities = identities
            self?.updateFollows()
        }
    }

    private func loadFollowedBy() {
        Bots.current.followedBy(identity: self.identity) {
            [weak self] identities, error in
            Log.optional(error)
            self?.followedByIdentities = identities
            self?.updateFollows()
        }
    }

    // MARK: Updates

    private func update(with about: About) {
        self.about = about
        self.navigationItem.title = about.name
        self.aboutView.update(with: about)
    }

    func update(with person: Person) {
        self.navigationItem.title = person.name
        self.aboutView.update(with: person)
    }

    private func updateFollows() {
        let allIdentities = Set(self.followedByIdentities + self.followingIdentities)

        Bots.current.abouts(identities: Array(allIdentities)) {
            [weak self] abouts, error in
            if Log.optional(error) { return }

            guard let followedByIdentities = self?.followedByIdentities,
                  let followingIdentities = self?.followingIdentities else { return }

            let followedBy = abouts.filter { followedByIdentities.contains($0.identity) }
            let following = abouts.filter { followingIdentities.contains($0.identity) }

            self?.aboutView.update(followedBy: followedBy, following: following)
        }
    }

    // MARK: Actions

    private let imagePicker = ImagePicker()

    private func addActions() {
        self.aboutView.editButton.action = self.didPressEdit
        self.aboutView.followingView.action = self.didTapFollowing
        self.aboutView.followedByView.action = self.didTapFollowedBy

        self.aboutView.editPhotoButton.addTarget(self,
                                                 action: #selector(editPhotoButtonTouchUpInside),
                                                 for: .touchUpInside)


        self.aboutView.followButton.onUpdate = {
            following in

            self.loadFollowedBy()

            if let about = self.about {
                self.update(with: about)
            }
        }
    }

    @objc private func editPhotoButtonTouchUpInside() {
        self.imagePicker.present(openCameraInSelfieMode: true) {
            [unowned self] image in
            self.publishPhotoThenDismiss(image)
        }
    }

    @objc private func didPressCopyIdentifierIcon() {
        let copy = UIAlertAction(title: Text.copyPublicIdentifier.text, style: .default) { _ in
            if let identity = self.about?.identity {
                UIPasteboard.general.string = identity
            }
        }

        let cancel = UIAlertAction(title: Text.cancel.text, style: .cancel) { _ in }

        AppController.shared.choose(from: [copy, cancel])
    }

    private func publishPhotoThenDismiss(_ image: UIImage?) {

        guard let uiimage = image else { return }

        AppController.shared.showProgress()

        Bots.current.addBlob(jpegOf: uiimage, largestDimension: 1000) {
            [weak self] image, error in

            if Log.optional(error)                                          { AppController.shared.hideProgress(); return }
            guard let about = self?.about?.mutatedCopy(image: image) else   { AppController.shared.hideProgress(); return }

            Bots.current.publish(content: about) {
                _, error in
                AppController.shared.hideProgress()
                if Log.optional(error) { return }

                self?.aboutView.imageView.fade(to: uiimage)
                self?.imagePicker.dismiss()
            }
        }
    }

    private func didPressEdit() {
        guard let about = self.about else { return }
        let controller = EditAboutViewController(with: about)
        controller.saveCompletion = {
            [weak self] _ in
            AppController.shared.showProgress()
            Bots.current.publish(content: controller.about) {
                _, error in
                Log.optional(error)
                AppController.shared.hideProgress() {
                    self?.update(with: controller.about)
                    self?.dismiss(animated: true)
                }
            }
        }
        let feature = FeatureViewController(rootViewController: controller)
        self.navigationController?.present(feature, animated: true, completion: nil)
    }

    private func didTapFollowing() {
        let controller = ContactsViewController(title: .followingShortCount,
                                                identity: self.identity,
                                                identities: self.followingIdentities)
        self.navigationController?.pushViewController(controller, animated: true)
    }

    private func didTapFollowedBy() {
        let controller = ContactsViewController(title: .followedByShortCount,
                                                identity: self.identity,
                                                identities: self.followedByIdentities)
        self.navigationController?.pushViewController(controller, animated: true)
    }

    // MARK: Notifications

    override func didBlockUser(notification: NSNotification) {
        guard let identity = notification.object as? Identity else { return }
        guard identity == self.identity else { return }
        self.navigationController?.remove(viewController: self)
    }
}

fileprivate class AboutPostView: KeyValueView {

    lazy var view = PostCellView()

    convenience init() {
        self.init(frame: .zero)
        self.tapGesture = self.view.tapGesture
        let separator = Layout.addSeparator(toTopOf: self, height: 10, color: UIColor.background.table)
        Layout.addSeparator(toBottomOf: separator)
        Layout.fill(view: self,
                    with: self.view,
                    insets: UIEdgeInsets.top(10))
        self.view.pinBottomToSuperviewBottom()
        Layout.addSeparator(toBottomOf: self)
    }

    override func update(with keyValue: KeyValue) {
        self.view.update(with: keyValue)
    }
}

extension AboutViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
    {
        guard let uiimage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }

        AppController.shared.showProgress()

        Bots.current.addBlob(jpegOf: uiimage, largestDimension: 1000) {
            [weak self] image, error in
            if Log.optional(error)                                          { AppController.shared.hideProgress(); return }
            guard let about = self?.about?.mutatedCopy(image: image) else   { AppController.shared.hideProgress(); return }
            Bots.current.publish(content: about) {
                _, error in
                AppController.shared.hideProgress()
                if Log.optional(error) { return }
                self?.aboutView.imageView.fade(to: uiimage)
                picker.dismiss(animated: true, completion: nil)
            }
        }
    }
}
