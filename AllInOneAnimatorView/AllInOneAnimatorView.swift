//
//  AllInOneAnimatorView.swift
//  AllInOneAnimatorView
//
//  Created by Bharat Shilavat on 20/03/24.
//

import Foundation
import UIKit
import AVFoundation
import Lottie

public enum FileType: String {
    case mp4 = "mp4"
    case avi = "avi"
    case mov = "mov"
    case mkv = "mkv"
    case wmv = "wmv"
    case flv = "flv"
    case gif = "gif"   // Graphics Interchange Format (GIF) file
    case json = "json" // Lottie animation file
    case jpg = "jpg"   // JPEG image file
    case png = "png"   // PNG image file
    case jpeg = "jpeg" // JPEG image file
    case bmp = "bmp"   // Bitmap image file
    case tiff = "tiff" // TIFF image file
    case webp = "webp" // WebP image file
    case svg = "svg"   // Scalable Vector Graphics (SVG) file
}

public enum ContentViewType {
    case withInfo(fileOrUrlName: String?, fileType: FileType, viewContentMode: UIView.ContentMode? = nil, vedioGravity: AVLayerVideoGravity? = nil)
}

public class ContentView: UIView {
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var animationView: LottieAnimationView?
    private var imageView: UIImageView?
    private var gifView: UIImageView?
    private var volumeButton: UIButton!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setup(with contentType: ContentViewType) {
        setupView(contentType: contentType)
    }
    
    private func setupView(contentType: ContentViewType) {
        switch contentType {
        case .withInfo(let fileOrUrlName, let fileType, let contentMode, let vedioGravity):
            guard let file = fileOrUrlName else {
                print("File name and type must be provided")
                return
            }
            
            if let url = URL(string: file), url.isFileURL {
                // It's a valid file URL
                switch fileType {
                case .mp4, .avi, .mov, .mkv, .wmv, .flv:
                    setupLocalVideoPlayer(url: url, vedioGravity: vedioGravity)
                case .gif:
                    setupLocalGifView(url: url,contentMode: contentMode)
                case .json:
                    setupLocalAnimationView(animationName: file,contentMode: contentMode)
                case .jpg, .png, .jpeg, .bmp, .tiff, .webp, .svg:
                    if let image = UIImage(named: file) {
                        setupImageView(image: image,contentMode: contentMode)
                    } else {
                        print("Local image file not found")
                    }
                }
            } else if let localURL = Bundle.main.url(forResource: file, withExtension: fileType.rawValue) {
                // It's a local file
                switch fileType {
                case .mp4, .avi, .mov, .mkv, .wmv, .flv:
                    setupLocalVideoPlayer(url: localURL, vedioGravity: vedioGravity)
                case .gif:
                    setupLocalGifView(url: localURL,contentMode: contentMode)
                case .json:
                    setupLocalAnimationView(animationName: file,contentMode: contentMode)
                case .jpg, .png, .jpeg, .bmp, .tiff, .webp, .svg:
                    if let image = UIImage(named: file) {
                        setupImageView(image: image,contentMode: contentMode)
                    } else {
                        print("Local image file not found")
                    }
                }
            } else if let url = URL(string: file) {
                // It's a remote URL
                switch fileType {
                case .mp4, .avi, .mov, .mkv, .wmv, .flv:
                    setupRemoteVideoPlayer(url: url, vedioGravity: vedioGravity)
                case .gif:
                    setupRemoteGifView(url: url)
                case .json:
                    setupRemoteAnimationView(animationURL: url)
                case .jpg, .png, .jpeg, .bmp, .tiff, .webp, .svg:
                    setupRemoteImageView(url: url)
                }
            } else {
                // Neither a valid URL nor a local file
                print("Invalid file path: \(file)")
            }
        }
    }
    
    private func setupRemoteImageView(url: URL) {
        // Create a URLSessionDataTask to fetch the image data
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            // Check for errors
            guard error == nil else {
                print("Error downloading image: \(error!.localizedDescription)")
                return
            }
            
            guard let imageData = data else {
                print("No image data received")
                return
            }
            
            guard let image = UIImage(data: imageData) else {
                print("Failed to create image from data")
                return
            }
            
            DispatchQueue.main.async { [self] in
                setupImageView(image: image,contentMode: contentMode)
            }
        }
        
        task.resume()
    }
    
    private func setupRemoteVideoPlayer(url: URL, vedioGravity:AVLayerVideoGravity?) {
        setupLocalVideoPlayer(url: url, vedioGravity: vedioGravity)
    }
    
    private func setupLocalVideoPlayer(url: URL, vedioGravity: AVLayerVideoGravity?) {
        player = AVPlayer(url: url)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = bounds
        
        // Set video gravity
        if let vedioGravity = vedioGravity {
            playerLayer?.videoGravity = vedioGravity
        } else {
            // Set default video gravity if no custom one is provided
            playerLayer?.videoGravity = .resizeAspectFill
        }
        
        if let playerLayer = playerLayer {
            layer.addSublayer(playerLayer)
        }
        
        player?.play()
        
        setupVolumeButton()
        
        // Add observer for player item status
        player?.currentItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: nil)
    }

    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            guard keyPath == #keyPath(AVPlayerItem.status) else {
                super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
                return
            }
            
            // Handle changes in AVPlayerItem's status here
            if let playerItem = object as? AVPlayerItem {
                switch playerItem.status {
                case .unknown:
                    print("AVPlayerItem status is unknown")
                case .readyToPlay:
                    print("AVPlayerItem is ready to play")
                case .failed:
                    print("AVPlayerItem failed to load")
                @unknown default:
                    break
                }
            }
        }
    
    private func setupVolumeButton() {
        let buttonSize = CGSize(width: 50, height: 50)
        let buttonFrame = CGRect(x: bounds.width - buttonSize.width - 10, y: bounds.height - buttonSize.height - 10, width: buttonSize.width, height: buttonSize.height)
        
        volumeButton = UIButton(type: .system)
        volumeButton.frame = buttonFrame
        volumeButton.setTitle("🔊", for: .normal)
        volumeButton.addTarget(self, action: #selector(volumeButtonTapped), for: .touchUpInside)
        
        addSubview(volumeButton)
    }
    
    @objc private func volumeButtonTapped() {
        if let player = player {
            player.isMuted = !player.isMuted
            let buttonTitle = player.isMuted ? "🔇" : "🔊"
            volumeButton.setTitle(buttonTitle, for: .normal)
        }
    }
    
    private func setupLocalAnimationView(animationName: String, contentMode: UIView.ContentMode?) {
        // SettingUp local animation view
        animationView = LottieAnimationView(name: animationName)
        animationView?.frame = bounds
        
        // Setting content mode
        if let contentMode = contentMode {
            animationView?.contentMode = contentMode
        } else {
            // Setting default content mode if no custom one is provided
            animationView?.contentMode = .scaleAspectFit
        }
            
        if let animationView = animationView {
            addSubview(animationView)
            animationView.loopMode = .loop
            animationView.play()
        }
    }

    
    private func setupRemoteAnimationView(animationURL: URL) {
        // Fetch Lottie animation data from the remote URL
        URLSession.shared.dataTask(with: animationURL) { [weak self] (data, _, error) in
            guard let self = self else { return }
            if let error = error {
                print("Error downloading animation data: \(error)")
                return
            }
            guard let data = data else {
                print("No data received for animation")
                return
            }
            DispatchQueue.main.async {
                self.setupAnimationWithData(data: data)
            }
        }.resume()
    }
    
    private func setupAnimationWithData(data: Data) {
        do {
            // Create Lottie animation from the fetched data
            let animation = try JSONDecoder().decode(LottieAnimation.self, from: data)
            animationView = LottieAnimationView(animation: animation)
            animationView?.frame = bounds
            animationView?.contentMode = .scaleAspectFit
                
            if let animationView = animationView {
                addSubview(animationView)
                animationView.loopMode = .loop
                animationView.play()
            }
        } catch {
            print("Failed to initialize Lottie animation: \(error)")
        }
    }
    
    private func setupImageView(image: UIImage, contentMode: UIView.ContentMode?) {
        imageView = UIImageView(image: image)
        
        // Setting content mode
        if let contentMode = contentMode {
            imageView?.contentMode = contentMode
        } else {
            // Setting default content mode if no custom one is provided
            imageView?.contentMode = .scaleAspectFit
        }
        
        if let imageView = imageView {
            addSubview(imageView)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
                imageView.topAnchor.constraint(equalTo: topAnchor),
                imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        }
    }

    
    private func setupLocalGifView(url: URL, contentMode: UIView.ContentMode?) {
        guard let localURL = Bundle.main.url(forResource: url.deletingPathExtension().lastPathComponent, withExtension: "gif") else {
            print("Local GIF file not found")
            return
        }
        gifView = UIImageView.fromLocalGif(url: localURL, frame: bounds)
        if let gifView = gifView {
            addSubview(gifView)
            // Seting content mode
            if let contentMode = contentMode {
                gifView.contentMode = contentMode
            } else {
                // Setting default content mode if no custom one is provided
                gifView.contentMode = .scaleAspectFit// or any other default value you prefer
            }
        }
    }

    
    private func setupRemoteGifView(url: URL) {
        gifView?.removeFromSuperview()
        UIImageView.fromRemoteGif(url: url, frame: bounds) { [weak self] imageView in
            guard let self = self, let gifView = imageView else { return }
            self.gifView = gifView
            self.gifView?.contentMode = .scaleAspectFit
            self.addSubview(gifView)
            gifView.contentMode = .scaleAspectFit
        }
    }
}

extension UIImageView {
    static func fromLocalGif(url: URL, frame: CGRect) -> UIImageView? {
        guard let gifData = try? Data(contentsOf: url) else { return nil }
        return fromGifData(gifData: gifData, frame: frame)
    }
    
    static func fromRemoteGif(url: URL, frame: CGRect, completion: @escaping (UIImageView?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let gifData = data, error == nil else {
                print("Failed to load GIF from remote URL:", error?.localizedDescription ?? "Unknown error")
                completion(nil)
                return
            }
            DispatchQueue.main.async {
                completion(fromGifData(gifData: gifData, frame: frame))
            }
        }.resume()
    }
    
    private static func fromGifData(gifData: Data, frame: CGRect) -> UIImageView? {
        guard let source = CGImageSourceCreateWithData(gifData as CFData, nil) else { return nil }
        var images = [UIImage]()
        let imageCount = CGImageSourceGetCount(source)
        for i in 0 ..< imageCount {
            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(UIImage(cgImage: image))
            }
        }
            
        let gifImageView = UIImageView(frame: frame)
        gifImageView.animationImages = images
        gifImageView.contentMode = .scaleAspectFit
        gifImageView.animationDuration = Double(imageCount) * 0.1
        gifImageView.startAnimating()
        return gifImageView
    }
}

