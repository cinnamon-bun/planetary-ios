//
//  Created by Christoph on 1/17/19.
//  Copyright © 2019 Verse Communications Inc. All rights reserved.
//

import Foundation
import UIKit

// Convenience types to simplify writing completion closures.
typealias AboutCompletion = ((About?, Error?) -> Void)
typealias AboutsCompletion = (([About], Error?) -> Void)
typealias AddImageCompletion = ((Image?, Error?) -> Void)
typealias BlobsAddCompletion = ((BlobIdentifier, Error?) -> Void)
typealias ContactCompletion = ((Contact?, Error?) -> Void)
typealias ContactsCompletion = (([Identity], Error?) -> Void)
typealias ErrorCompletion = ((Error?) -> Void)
typealias FeedCompletion = ((Feed, Error?) -> Void)
typealias RootsCompletion = ((KeyValues, Error?) -> Void)
typealias HashtagCompletion = ((Hashtag?, Error?) -> Void)
typealias HashtagsCompletion = (([Hashtag], Error?) -> Void)
typealias PublishCompletion = ((MessageIdentifier, Error?) -> Void)
typealias RefreshCompletion = ((Error?, TimeInterval) -> Void)
typealias SecretCompletion = ((Secret?, Error?) -> Void)
typealias SyncCompletion = ((Error?, TimeInterval, Int) -> Void)
typealias ThreadCompletion = ((KeyValue?, KeyValues, Error?) -> Void)
typealias UIImageCompletion = ((Identifier?, UIImage?, Error?) -> Void)

// Abstract interface to any SSB bot implementation.
protocol Bot {

    // MARK: Name

    var name: String { get }
    var version: String { get }

    // MARK: AppLifecycle
    func resume()
    func suspend()
    func exit()
    
    // MARK: Identity

    var identity: Identity? { get }

    // TODO https://app.asana.com/0/914798787098068/1109609875273529/f
    func createSecret(completion: SecretCompletion)

    // MARK: Sync

    // Sync is the bot reaching out to remote peers and gathering the latest
    // data from the network.  This only updates the local log and requires
    // calling `refresh` to ensure the view database is updated.
    var isSyncing: Bool { get }
    func sync(completion: @escaping SyncCompletion)

    // TODO: this is temporary until live-streaming is deployed on the pubs
    func syncNotifications(completion: @escaping SyncCompletion)

    // MARK: Refresh

    // Refresh is the filling of the view database from the bot's index.  Note
    // that `sync` and `refresh` can be called at different intervals, it's just
    // that `refresh` should be called before `recent` if the newest data is desired.
    var isRefreshing: Bool { get }
    func refresh(completion: @escaping RefreshCompletion)

    // MARK: Login

    func login(network: NetworkKey, hmacKey: HMACKey?, secret: Secret, completion: @escaping ErrorCompletion)
    func logout(completion: @escaping ErrorCompletion)

    // MARK: Publish

    // TODO https://app.asana.com/0/914798787098068/1114777817192216/f
    // TOOD for some lower level applications it might make sense to add Secret to publish
    // so that you can publish as multiple IDs (think groups or invites)
    // The `content` argument label is required to avoid conflicts when specialized
    // forms of `publish` are created.  For example, `publish(post)` will publish a
    // `Post` model, but then also the embedded `Hashtag` models.
    func publish(content: ContentCodable, completion: @escaping PublishCompletion)

    // MARK: Post Management

    func delete(message: MessageIdentifier, completion: @escaping ErrorCompletion)
    func update(message: MessageIdentifier, content: ContentCodable, completion: @escaping ErrorCompletion)

    // MARK: About

    var about: About? { get }
    func about(completion: @escaping AboutCompletion)
    func about(identity: Identity, completion:  @escaping AboutCompletion)
    func abouts(identities: Identities, completion:  @escaping AboutsCompletion)

    // MARK: Contact

    func follow(_ identity: Identity, completion: @escaping ContactCompletion)
    func unfollow(_ identity: Identity, completion: @escaping ContactCompletion)

    func follows(identity: Identity, completion:  @escaping ContactsCompletion)
    func followedBy(identity: Identity, completion:  @escaping ContactsCompletion)
    
    func friends(identity: Identity, completion:  @escaping ContactsCompletion)

    // TODO the func names should be swapped
    func blocks(identity: Identity, completion:  @escaping ContactsCompletion)
    func blockedBy(identity: Identity, completion:  @escaping ContactsCompletion)

    // MARK: Block

    func block(_ identity: Identity, completion: @escaping PublishCompletion)
    func unblock(_ identity: Identity, completion: @escaping PublishCompletion)

    // MARK: Hashtags

    func hashtags(completion: @escaping HashtagsCompletion)
    func posts(with hashtag: Hashtag, completion: @escaping FeedCompletion)
    
    // MARK: Feed

    /// Returns all the messages of type .post that do not have a root.
    /// In other words, this returns all the roots for recent threads.
    /// The `before` and `after` Identifier arguments should be
    /// used to bound the returned items so that duplicates are
    /// not included.
    func recent(newer than: Date,
                before: MessageIdentifier?,
                count: Int,
                wantPrivate: Bool,
                completion: @escaping RootsCompletion)
    func recent(older than: Date,
                after: MessageIdentifier?,
                count: Int,
                wantPrivate: Bool,
                completion: @escaping RootsCompletion)

    // old version
    func recent(completion: @escaping RootsCompletion)

    /// Returns all the messages created by the specified Identity.
    /// This is useful for showing all the posts from a particular
    /// person, like in an About screen.
    func feed(identity: Identity, completion: @escaping FeedCompletion)

    /// Returns the thread of messages related to the specified message.  The root
    /// of the thread will be returned if it is not the specified message.
    func thread(keyValue: KeyValue, completion: @escaping ThreadCompletion)
    func thread(rootKey: MessageIdentifier, completion: @escaping ThreadCompletion)

    /// Returns all the messages in a feed that mention the active identity.
    func mentions(completion: @escaping FeedCompletion)

    /// Notifications (unifies mentions, replies, follows) for the active identity.
    func notifications(completion: @escaping FeedCompletion)

    // MARK: Blob publishing

    func addBlob(data: Data, completion: @escaping BlobsAddCompletion)

    // TODO https://app.asana.com/0/914798787098068/1122165003408766/f
    // TODO consider if this is appropriate to know about UIImage at this level
    @available(*, deprecated)
    func addBlob(jpegOf image: UIImage,
                 largestDimension: UInt?,
                 completion: @escaping AddImageCompletion)

    // MARK: Blob loading

    func data(for identifier: BlobIdentifier,
              completion: @escaping ((BlobIdentifier, Data?, Error?) -> Void))

    // MARK: Statistics

    var statistics: BotStatistics { get }
}

// temporary extension to allow compiling without having
// to FakeBot
extension Bot {

    func recent(newer than: Date,
                before to: MessageIdentifier?,
                count: Int = 100,
                wantPrivate: Bool,
                completion: @escaping RootsCompletion) {}

    func recent(older than: Date,
                after: MessageIdentifier?,
                count: Int = 100,
                wantPrivate: Bool,
                completion: @escaping RootsCompletion) {}

    // lifecycle
    func resume()  { print("TODO:lifecycle:resume") }
    func suspend() { print("TODO:lifecycle:suspend") }
    func exit()    { print("TODO:lifecycle:exit") }
    
    
    func notifications(completion: @escaping FeedCompletion) {
        print("TODO:notifications")
    }
}
