//
//  IGStoryPreviewCell.swift
//  InstagramStories
//
//  Created by Boominadha Prakash on 06/09/17.
//  Copyright © 2017 DrawRect. All rights reserved.
//

import UIKit
import AVKit

protocol StoryPreviewProtocol: class {
    func didCompletePreview()
    func moveToPreviousStory()
    func didTapCloseButton()
}
enum SnapMovementDirectionState {
    case forward
    case backward
}
//Identifiers
fileprivate let snapViewTagIndicator: Int = 8

final class IGStoryPreviewCell: UICollectionViewCell, UIScrollViewDelegate {
    
    //MARK: - Delegate
    public weak var delegate: StoryPreviewProtocol? {
        didSet { storyHeaderView.delegate = self }
    }
    
    //MARK:- Private iVars
    private let scrollview: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.showsHorizontalScrollIndicator = false
        sv.isScrollEnabled = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    private lazy var storyHeaderView: IGStoryPreviewHeaderView = {
        let v = IGStoryPreviewHeaderView.init(frame: CGRect(x: 0,y: 0,width: frame.width,height: 80))
        return v
    }()
    private lazy var longPress_gesture: UILongPressGestureRecognizer = {
        let lp = UILongPressGestureRecognizer.init(target: self, action: #selector(didLongPress(_:)))
        lp.minimumPressDuration = 0.2
        return lp
    }()
    private lazy var tap_gesture: UITapGestureRecognizer = {
        let tg = UITapGestureRecognizer(target: self, action: #selector(didTapSnap(_:)))
        tg.numberOfTapsRequired = 1
        return tg
    }()
    private var previousSnapIndex: Int {
        return snapIndex - 1
    }
    private var snapViewXPos: CGFloat {
        return (snapIndex == 0) ? 0 : scrollview.subviews[previousSnapIndex].frame.maxX
    }
    private var videoSnapIndex: Int = 0
    //private var videoView: IGPlayerView?
    
    var retryBtn: IGRetryLoaderButton!
    
    //MARK:- Public iVars
    public var direction: SnapMovementDirectionState = .forward

    public var snapIndex: Int = 0 {
        didSet {
            scrollview.isUserInteractionEnabled = true
            switch direction {
            case .forward:
                if snapIndex < story?.snapsCount ?? 0 {
                    if let snap = story?.snaps[snapIndex] {
                        if snap.kind != MimeType.video {
                            if let snapView = getSnapview() {
                                startRequest(snapView: snapView, with: snap.url)
                            } else {
                                let snapView = createSnapView()
                                startRequest(snapView: snapView, with: snap.url)
                            }
                        }else {
                            if let videoView = getVideoView(with: snapIndex) {
                                startPlayer(videoView: videoView, with: snap.url)
                            }else {
                                let videoView = createVideoView()
                                startPlayer(videoView: videoView, with: snap.url)
                            }
                        }
                        storyHeaderView.lastUpdatedLabel.text = snap.lastUpdated
                    }
                }
            case .backward:
                if snapIndex < story?.snapsCount ?? 0 {
                    if let snap = story?.snaps[snapIndex] {
                        if snap.kind != MimeType.video {
                            if let snapView = getSnapview() {
                                self.startRequest(snapView: snapView, with: snap.url)
                            }
                        }else {
                            if let videoView = getVideoView(with: snapIndex) {
                                startPlayer(videoView: videoView, with: snap.url)
                            }
                            else {
                                let videoView = self.createVideoView()
                                self.startPlayer(videoView: videoView, with: snap.url)
                            }
                        }
                        storyHeaderView.lastUpdatedLabel.text = snap.lastUpdated
                    }
                }
            }
        }
    }
    public var story: IGStory? {
        didSet {
            storyHeaderView.story = story
            if let picture = story?.user.picture {
                storyHeaderView.snaperImageView.setImage(url: picture)
            }
            if let count = story?.snaps.count {
                scrollview.contentSize = CGSize(width: IGScreen.width * CGFloat(count), height: IGScreen.height)
            }
        }
    }
    
    //MARK: - Overriden functions
    override init(frame: CGRect) {
        super.init(frame: frame)
        scrollview.frame = bounds
        loadUIElements()
        installLayoutConstraints()
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        direction = .forward
        clearScrollViewGarbages()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: - Private functions
    private func loadUIElements() {
        scrollview.delegate = self
        scrollview.isPagingEnabled = true
        scrollview.backgroundColor = .black
        contentView.addSubview(scrollview)
        contentView.addSubview(storyHeaderView)
        scrollview.addGestureRecognizer(longPress_gesture)
        scrollview.addGestureRecognizer(tap_gesture)
    }
    private func installLayoutConstraints() {
        //Setting constraints for scrollview
        NSLayoutConstraint.activate([
            scrollview.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            scrollview.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            scrollview.topAnchor.constraint(equalTo: contentView.topAnchor),
            scrollview.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)])
    }
    private func createSnapView() -> UIImageView {
        let snapView = UIImageView(frame: CGRect(x: snapViewXPos, y: 0, width: scrollview.frame.width, height: scrollview.frame.height))
        snapView.tag = snapIndex + snapViewTagIndicator
        scrollview.addSubview(snapView)
        return snapView
    }
    private func getSnapview() -> UIImageView? {
        if let imageView = scrollview.subviews.filter({$0.tag == snapIndex + snapViewTagIndicator}).first as? UIImageView {
            return imageView
        }
        return nil
    }
    private func createVideoView() -> IGPlayerView {
        let videoView = IGPlayerView.init(frame: CGRect(x: snapViewXPos, y: 0, width: scrollview.frame.width, height: scrollview.frame.height))
        videoView.tag = snapIndex + snapViewTagIndicator
        videoView.playerObserverDelegate = self
        scrollview.addSubview(videoView)
        return videoView
    }
    private func getVideoView(with index: Int) -> IGPlayerView? {
        if let videoView = scrollview.subviews.filter({$0.tag == index + snapViewTagIndicator}).first as? IGPlayerView {
            return videoView
        }
        return nil
    }
    
    private func startRequest(snapView: UIImageView, with url: String) {
        snapView.setImage(url: url, style: .squared, completion: {[weak self]
            (result, error) in
            if let error = error, let strongSelf = self {
                debugPrint(error.localizedDescription)
                strongSelf.retryBtn = IGRetryLoaderButton.init(withURL: url)
                strongSelf.retryBtn.center = CGPoint(x: strongSelf.bounds.width/2, y: strongSelf.bounds.height/2)
                strongSelf.retryBtn.delegate = self
                snapView.isUserInteractionEnabled = true
                snapView.addSubview(strongSelf.retryBtn)
            } else {
                self?.startProgressors()
            }
        })
    }
    private func startPlayer(videoView: IGPlayerView, with url: String) {
        if scrollview.subviews.count > 0 {
            if story?.isCompletelyVisible == true {
                let videoResource = VideoResource(filePath: url)
                videoView.play(with: videoResource)
            }
        }
    }
    @objc private func didLongPress(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began || sender.state == .ended {
            let v = getProgressView(with: snapIndex)
            let videoView = scrollview.subviews.filter{v in v.tag == snapIndex + snapViewTagIndicator}.first as? IGPlayerView
            if sender.state == .began {
                if videoView != nil {
                    v?.pause()
                    videoView?.pause()
                }else {
                    v?.pause()
                }
            }else {
                if videoView != nil {
                    v?.resume()
                    videoView?.play()
                }else {
                    v?.resume()
                }
            }
            
        }
    }
    @objc private func didTapSnap(_ sender: UITapGestureRecognizer) {
        let touchLocation = sender.location(ofTouch: 0, in: self.scrollview)
        
        if let snapCount = story?.snapsCount {
            var n = snapIndex
            /*!
             * Based on the tap gesture(X) setting the direction to either forward or backward
             */
            if let snap = story?.snaps[n], snap.kind == .image, getSnapview()?.image == nil {
                //Remove retry button if tap forward or backward if it exists
                if let snapView = getSnapview(), let btn = retryBtn, snapView.subviews.contains(btn) {
                    snapView.removeRetryButton()
                }
                fillupLastPlayedSnap(n)
            }else {
                //Remove retry button if tap forward or backward if it exists
                if let videoView = getVideoView(with: n), let btn = retryBtn, videoView.subviews.contains(btn) {
                    videoView.removeRetryButton()
                }
                if getVideoView(with: n)?.player?.timeControlStatus != .playing {
                    fillupLastPlayedSnap(n)
                }
            }
            if touchLocation.x < scrollview.contentOffset.x + (scrollview.frame.width/2) {
                direction = .backward
                if snapIndex >= 1 && snapIndex <= snapCount {
                    clearLastPlayedSnaps(n)
                    stopSnapProgressors(with: n)
                    n -= 1
                    resetSnapProgressors(with: n)
                    willMoveToPreviousOrNextSnap(n: n)
                } else {
                    delegate?.moveToPreviousStory()
                }
            } else {
                if snapIndex >= 0 && snapIndex <= snapCount {
                    //Stopping the current running progressors
                    stopSnapProgressors(with: n)
                    direction = .forward
                    n += 1
                    willMoveToPreviousOrNextSnap(n: n)
                }
            }
        }
    }
    @objc private func didEnterForeground() {
        //startSnapProgress(with: snapIndex)
    }
    private func willMoveToPreviousOrNextSnap(n: Int) {
        if let count = story?.snapsCount {
            if n < count {
                //Move to next or previous snap based on index n
                let x = n.toFloat() * frame.width
                let offset = CGPoint(x: x,y: 0)
                scrollview.setContentOffset(offset, animated: false)
                story?.lastPlayedSnapIndex = n
                snapIndex = n
            } else {
                delegate?.didCompletePreview()
            }
        }
    }
    @objc private func didCompleteProgress() {
        let n = snapIndex + 1
        if let count = story?.snapsCount {
            if n < count {
                //Move to next snap
                let x = n.toFloat() * frame.width
                let offset = CGPoint(x: x,y: 0)
                scrollview.setContentOffset(offset, animated: false)
                story?.lastPlayedSnapIndex = n
                direction = .forward
                snapIndex = n
            }else {
                stopPlayer()
                delegate?.didCompletePreview()
            }
        }
    }
    private func getProgressView(with index: Int) -> IGSnapProgressView? {
        let progressView = storyHeaderView.getProgressView
        if progressView.subviews.count > 0 {
            let pv = progressView.subviews.filter({v in v.tag == index+progressViewTag}).first as? IGSnapProgressView
            guard let currentStory = self.story else {
                fatalError("story not found")
            }
            pv?.story = currentStory
            return pv
        }
        return nil
    }
    private func getProgressIndicatorView(with index: Int) -> UIView? {
        let progressView = storyHeaderView.getProgressView
        if progressView.subviews.count>0 {
            return progressView.subviews.filter({v in v.tag == index+progressIndicatorViewTag}).first
        }else{
            return nil
        }
    }
    private func fillUpMissingImageViews(_ sIndex: Int) {
        if sIndex != 0 {
            for i in 0..<sIndex {
                snapIndex = i
            }
            let xValue = sIndex.toFloat() * scrollview.frame.width
            scrollview.contentOffset = CGPoint(x: xValue, y: 0)
        }
    }
    //Before progress view starts we have to fill the progressView
    private func fillupLastPlayedSnap(_ sIndex: Int) {
        if let snap = story?.snaps[sIndex], snap.kind == .video {
            videoSnapIndex = sIndex
            stopPlayer()
        }
        if let holderView = self.getProgressIndicatorView(with: sIndex),
            let progressView = self.getProgressView(with: sIndex){
            progressView.frame.size.width = holderView.frame.width
        }
    }
    private func fillupLastPlayedSnaps(_ sIndex: Int) {
        //Coz, we are ignoring the first.snap
        if sIndex != 0 {
            for i in 0..<sIndex {
                if let holderView = self.getProgressIndicatorView(with: i),
                    let progressView = self.getProgressView(with: i){
                    progressView.frame.size.width = holderView.frame.width
                }
            }
        }
    }
    private func clearLastPlayedSnaps(_ sIndex: Int) {
        if let _ = self.getProgressIndicatorView(with: sIndex),
            let progressView = self.getProgressView(with: sIndex) {
            progressView.frame.size.width = 0
        }
    }
    private func clearScrollViewGarbages() {
        scrollview.contentOffset = CGPoint(x: 0, y: 0)
        if scrollview.subviews.count > 0 {
            var i = 0 + snapViewTagIndicator
            var snapViews = [UIView]()
            scrollview.subviews.forEach({ (imageView) in
                if imageView.tag == i {
                    snapViews.append(imageView)
                    i += 1
                }
            })
            if snapViews.count > 0 {
                snapViews.forEach({ (view) in
                    view.removeFromSuperview()
                })
            }
        }
    }
    private func gearupTheProgressors(type: MimeType, playerView: IGPlayerView? = nil) {
        if let holderView = getProgressIndicatorView(with: snapIndex),
            let progressView = getProgressView(with: snapIndex){
            progressView.story_identifier = self.story?.internalIdentifier
            progressView.snapIndex = snapIndex
            if type == .image {
                progressView.start(with: 5.0, width: holderView.frame.width, completion: {(identifier, snapIndex, isCancelledAbruptly) in
                    if isCancelledAbruptly == false {
                        self.didCompleteProgress()
                    }
                })
            }else {
                //Handled in delegate methods for videos
            }
        }
    }
    
    //MARK:- Internal functions
    func startProgressors() {
        if scrollview.subviews.count > 0 {
            let imageView = scrollview.subviews.filter{v in v.tag == snapIndex + snapViewTagIndicator}.first as? UIImageView
            if imageView?.image != nil && story?.isCompletelyVisible == true {
                self.gearupTheProgressors(type: .image)
            } else {
                // Didend displaying will call this startProgressors method. After that only isCompletelyVisible get true. Then we have to start the video if that snap contains video.
                if story?.isCompletelyVisible == true {
                    let videoView = scrollview.subviews.filter{v in v.tag == snapIndex + snapViewTagIndicator}.first as? IGPlayerView
                    let snap = story?.snaps[snapIndex]
                    if let vv = videoView, story?.isCompletelyVisible == true {
                        self.startPlayer(videoView: vv, with: snap!.url)
                    }
                }
            }
        }
    }
    
    //MARK: - Public functions
    public func willDisplayCellForZerothIndex(with sIndex: Int) {
        story?.isCompletelyVisible = true
        willDisplayCell(with: sIndex)
    }
    public func willDisplayCell(with sIndex: Int) {
        //Todo:Make sure to move filling part and creating at one place
        //Clear the progressor subviews before the creating new set of progressors.
        storyHeaderView.clearTheProgressorSubviews()
        storyHeaderView.createSnapProgressors()
        fillUpMissingImageViews(sIndex)
        fillupLastPlayedSnaps(sIndex)
        snapIndex = sIndex
        
        //Remove the previous observors
        NotificationCenter.default.removeObserver(self)
    }
    public func startSnapProgress(with sIndex: Int) {
        if let indicatorView = getProgressIndicatorView(with: sIndex),
            let pv = getProgressView(with: sIndex) {
            pv.start(with: 5.0, width: indicatorView.frame.width, completion: { (identifier, snapIndex, isCancelledAbruptly) in
                if isCancelledAbruptly == false {
                    self.didCompleteProgress()
                }
            })
        }
    }
    public func pauseSnapProgressors(with sIndex: Int) {
        story?.isCompletelyVisible = false
        getProgressView(with: sIndex)?.pause()
    }
    public func stopSnapProgressors(with sIndex: Int) {
        getProgressView(with: sIndex)?.stop()
    }
    public func resetSnapProgressors(with sIndex: Int) {
        self.getProgressView(with: sIndex)?.reset()
    }
    public func pausePlayer(with sIndex: Int) {
        getVideoView(with: sIndex)?.pause()
    }
    public func stopPlayer() {
        let videoView = getVideoView(with: videoSnapIndex)
        if videoView?.player?.timeControlStatus != .playing {
            getVideoView(with: videoSnapIndex)?.player?.replaceCurrentItem(with: nil)
        }
        videoView?.stop()
        //getVideoView(with: videoSnapIndex)?.player = nil
    }
    public func resumePlayer(with sIndex: Int) {
        getVideoView(with: sIndex)?.play()
    }
    public func didEndDisplayingCell() {
        //Here only the cell is completely visible. So this is the right place to add the observer.
        NotificationCenter.default.addObserver(self, selector: #selector(self.didEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    public func resumePreviousSnapProgress(with sIndex: Int) {
        getProgressView(with: sIndex)?.resume()
    }
    //Used the below function for image retry option
    public func retryRequest(view: UIView, with url: String) {
        if let v = view as? UIImageView {
            v.removeRetryButton()
            self.startRequest(snapView: v, with: url)
        }else if let v = view as? IGPlayerView {
            v.removeRetryButton()
            self.startPlayer(videoView: v, with: url)
        }
    }
}

//MARK: - Extension|StoryPreviewHeaderProtocol
extension IGStoryPreviewCell: StoryPreviewHeaderProtocol {
    func didTapCloseButton() {
        delegate?.didTapCloseButton()
    }
}

//MARK: - Extension|RetryBtnDelegate
extension IGStoryPreviewCell: RetryBtnDelegate {
    func retryButtonTapped() {
        self.retryRequest(view: retryBtn.superview!, with: retryBtn.contentURL!)
    }
}

//MARK: - Extension|IGPlayerObserverDelegate
extension IGStoryPreviewCell: IGPlayerObserver {
    
    func didStartPlaying() {
        if let videoView = getVideoView(with: snapIndex), videoView.currentTime <= 0 {
            //let videoView = scrollview.subviews.filter{v in v.tag == snapIndex + snapViewTagIndicator}.first as? IGPlayerView
            if videoView.error == nil && (story?.isCompletelyVisible)! == true {
                if let holderView = getProgressIndicatorView(with: snapIndex),
                    let progressView = getProgressView(with: snapIndex) {
                    progressView.story_identifier = self.story?.internalIdentifier
                    progressView.snapIndex = snapIndex
                    if let duration = videoView.currentItem?.asset.duration {
                        if Float(duration.value) > 0 {
                            progressView.start(with: duration.seconds, width: holderView.frame.width, completion: {(identifier, snapIndex, isCancelledAbruptly) in
                                if isCancelledAbruptly == false {
                                    self.videoSnapIndex = snapIndex
                                    self.stopPlayer()
                                    self.didCompleteProgress()
                                } else {
                                    self.videoSnapIndex = snapIndex
                                    self.stopPlayer()
                                }
                            })
                        }else {
                            debugPrint("Player error: Unable to play the video")
                        }
                    }
                }
            }
        }
    }
    func didFailed(withError error: String, for url: URL?) {
        debugPrint("Failed with error: \(error)")
        if let videoView = getVideoView(with: snapIndex), let videoURL = url {
            self.retryBtn = IGRetryLoaderButton(withURL: videoURL.absoluteString)
            self.retryBtn.center = CGPoint(x: self.bounds.width/2, y: self.bounds.height/2)
            self.retryBtn.delegate = self
            self.isUserInteractionEnabled = true
            videoView.addSubview(self.retryBtn)
        }
    }
    func didCompletePlay() {
        //Video completed
    }
    
    func didTrack(progress: Float) {
        //Delegate already handled. If we just print progress, it will print the player current running time
    }
}

extension IGStoryPreviewCell: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
