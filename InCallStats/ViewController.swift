//
//  ViewController.swift
//  InCallStats
//
//  Created by Max Cobb on 16/06/2021.
//

import UIKit
import AgoraRtcKit
import AgoraUIKit_iOS

class ViewController: UIViewController {
    var videoFeeds: [UInt: AgoraSingleVideoView] = [:] {
        didSet {
            self.videoHolder.subviews.forEach { $0.removeFromSuperview() }
            for (index, vidFeed) in videoFeeds.enumerated() {
                if index > 3 {
                    // this example only displays the first 4 video feeds
                    continue
                }
                var endPos: CGPoint = .zero
                if index > 1 { endPos.y = self.view.bounds.height / 2 }
                if index % 2 == 1 { endPos.x = self.view.bounds.width / 2 }
                self.videoHolder.addSubview(vidFeed.value)
                vidFeed.value.frame = .init(
                    origin: endPos,
                    size: CGSize(
                        width: self.view.bounds.width / 2,
                        height: self.view.bounds.height / 2
                    )
                )
            }
        }
    }
    var localVideoFeed: AgoraSingleVideoView?
    var videoHolder = UIView()
    var feedStats: [UInt: String] = [:]
    var agkit: AgoraRtcEngineKit?
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(self.videoHolder)
        self.videoHolder.frame = self.view.bounds
        self.videoHolder.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        self.agkit = AgoraRtcEngineKit.sharedEngine(
            withAppId: <#Agora App ID#>, delegate: self
        )
        self.agkit?.enableVideo()


        self.agkit?.joinChannel(
            byToken: <#Temp Token#>, channelId: "test", info: nil, uid: 0,
            joinSuccess: { first, uid, success in
                self.localVideoFeed = self.addUserVideo(with: 0)
            }
        )
    }

    @discardableResult
    func addUserVideo(with uid: UInt) -> AgoraSingleVideoView {
        if let vidFeed = self.videoFeeds[uid] {
            return vidFeed
        }
        let remoteVideoView = AgoraSingleVideoView(uid: uid, micColor: .systemBlue)
        remoteVideoView.audioMuted = false
        self.videoFeeds[uid] = remoteVideoView
        if uid == 0 {
            self.agkit?.setupLocalVideo(remoteVideoView.canvas)
        } else {
            self.agkit?.setupRemoteVideo(remoteVideoView.canvas)
        }

        return remoteVideoView
    }

    func updateStats(for uid: UInt, with stats: String) {
        if let videoFeed = self.videoFeeds[uid] {
            if let statsView = videoFeed.subviews.first(
                where: { $0 is UILabel }
            ) {
                (statsView as? UILabel)?.text = stats
                print(statsView)
            } else {
                let newView = UILabel()
                newView.font = .systemFont(ofSize: UIFont.smallSystemFontSize)
                videoFeed.addSubview(newView)
                newView.frame = .init(
                    origin: .zero, size: CGSize(
                        width: self.view.bounds.width / 2,
                        height: self.view.bounds.height / 2
                    )
                )
                newView.numberOfLines = 0
                newView.textAlignment = .center
                newView.text = stats
            }
        }
    }
}

extension AgoraRtcRemoteVideoStats {
    var statsViewText: String {
        """
        Received Bitrate: \(self.receivedBitrate)
        Packet Loss Rate: \(self.packetLossRate)
        Active Time: \(self.totalActiveTime)
        Output Frame Rate: \(self.decoderOutputFrameRate)
        Frame Dimensions: \(self.width)x\(self.height)
        """
    }
}
extension AgoraRtcLocalVideoStats {
    var statsViewText: String {
        """
        Encoded Bitrate: \(self.encodedBitrate)
        Sent Target Bitrate: \(self.sentTargetBitrate)
        Packet Loss Rate: \(self.txPacketLossRate)
        Capture Frame Rate: \(self.captureFrameRate)
        Frame Dimensions: \(self.encodedFrameWidth)x\(self.encodedFrameHeight)
        """
    }
}

extension ViewController: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit, remoteVideoStats stats: AgoraRtcRemoteVideoStats) {
        self.updateStats(for: stats.uid, with: stats.statsViewText)
    }
    func rtcEngine(_ engine: AgoraRtcEngineKit, localVideoStats stats: AgoraRtcLocalVideoStats) {
        self.updateStats(for: 0, with: stats.statsViewText)
    }
    func rtcEngine(_ engine: AgoraRtcEngineKit, remoteVideoStateChangedOfUid uid: UInt, state: AgoraVideoRemoteState, reason: AgoraVideoRemoteStateReason, elapsed: Int) {
        self.addUserVideo(with: uid)
    }
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        self.videoFeeds.removeValue(forKey: uid)
    }
}

