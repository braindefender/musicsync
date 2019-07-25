//
//  ViewController.swift
//  Music Sync
//
//  Created by Никита Широков on 30/10/2017.
//  Copyright © 2017 Ink Studios. All rights reserved.
//

import UIKit
import MediaPlayer

class ViewController: UIViewController {
	
	struct Song: Codable {
		var artist: String
		var title: String
//		var album: String
	}
	
	var serverSong = Song(artist: "", title: "")
	
	@IBOutlet var serverSongTitleLabel: UILabel!
	@IBOutlet var serverSongArtistLabel: UILabel!
	
    let player = MPMusicPlayerController.systemMusicPlayer
    
    var songArtist: String = ""
    var songTitle: String = ""
    var songAlbum: String = ""
    
    var serverIp = "192.168.0.100"
    var serverPort = 9696
    
    @IBOutlet var uiTitle: UILabel!
    @IBOutlet var uiSecondLine: UILabel!
	
	@IBOutlet var localSongCoverImageBackView: UIImageView!
	@IBOutlet var localSongCoverImageView: UIImageView!
	
	@IBOutlet var localSongCoverBlurView: UIVisualEffectView!
	
	
	@IBAction func testButtonHandler(_ sender: Any) {
		render()
	}
	
    @IBAction func button(_ sender: Any) {
        let pTime = player.currentPlaybackTime
        let time = pTime == 0 ? "\(pTime)" : "\(pTime+0.2)"
        let urlSession = URLSession(configuration: .default)
        var dataTask: URLSessionDataTask?
        
        let queryTitle = URLQueryItem(name: "title", value: songTitle)
        let queryArtist = URLQueryItem(name: "artist", value: songArtist)
        let queryTime = URLQueryItem(name: "time", value: time)
        var urlComponents = generateUrl()
            urlComponents.path = "/song"
            urlComponents.queryItems = [queryTitle, queryArtist, queryTime]
        
        if let url = urlComponents.url {
            dataTask = urlSession.dataTask(with: url) { data, response, error in
                if let error = error {
                    print("DataTask error: " + error.localizedDescription + "\n")
                } else {
                    self.player.pause()
                }
            }
            dataTask?.resume()
        }
    }
	
	
	
    func generateUrl() -> URLComponents {
        
        var urlComponents = URLComponents()
            urlComponents.scheme = "http"
            urlComponents.host = self.serverIp;
            urlComponents.port = self.serverPort
        
        return urlComponents
    }
    
    func setup() {
		render()
        if let _ = searchForServer() {
            
        }
		_ = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(getServerSongInfo), userInfo: nil, repeats: true)
		getServerSongInfo()
		updateNowPlayingItem()
    }
    
    @objc func getServerSongInfo() {
        var urlComponents = generateUrl()
            urlComponents.path = "/status"
        
        let urlSession = URLSession(configuration: .default)
        var dataTask: URLSessionDataTask?
        
        if let url = urlComponents.url {
            dataTask = urlSession.dataTask(with: url) { data, response, error in
                if let error = error {
                    print("DataTask error: " + error.localizedDescription + "\n")
                }
                guard let validData = data else {
                    print("Error: did not receive data")
                    return
                }
				do {
					let jsonString = String.init(data: validData, encoding: String.Encoding.utf8)!
					let json = try JSONDecoder().decode(Song.self, from: Data(base64Encoded: jsonString)!)
					self.serverSong.artist = json.artist
					self.serverSong.title = json.title
					DispatchQueue.main.async {
						self.serverSongTitleLabel.text = self.serverSong.title
						self.serverSongArtistLabel.text = self.serverSong.artist
					}
					
				} catch {
					print(error)
				}
            }
            dataTask?.resume()
        }
		
    }
    
    func searchForServer() -> Bool? {
//        TODO
//        serverIp =
//        serverPort =
        return true
    }
    
    func getWiFiAddress() -> String? {
        var address : String?
        
        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }
        
        // For each interface ...
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            
            // Check for IPv4 or IPv6 interface:
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                
                // Check interface name:
                let name = String(cString: interface.ifa_name)
                if  name == "en0" {
                    
                    // Convert interface address to a human readable string:
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        freeifaddrs(ifaddr)
        
        return address
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        player.beginGeneratingPlaybackNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateNowPlayingItem), name: Notification.Name.MPMusicPlayerControllerNowPlayingItemDidChange, object: player)
    }

	func render() {
		self.localSongCoverBlurView.effect = nil
		let animator = UIViewPropertyAnimator(duration: 1.0,
		                                      timingParameters: UICubicTimingParameters(animationCurve: .easeInOut))
		
		
		animator.addAnimations {
			self.localSongCoverBlurView.effect = UIBlurEffect(style: UIBlurEffectStyle.light)
		}
		animator.startAnimation()
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
			animator.pauseAnimation()
			animator.stopAnimation(true)
		}
	}
	
    @objc func updateNowPlayingItem() {
        if let mediaItem = player.nowPlayingItem {
            songTitle = mediaItem.value(forProperty: MPMediaItemPropertyTitle) as! String
            songArtist = mediaItem.value(forProperty: MPMediaItemPropertyArtist) as! String
            songAlbum = mediaItem.value(forProperty: MPMediaItemPropertyAlbumTitle) as! String
			localSongCoverImageView.image = mediaItem.artwork?.image(at: CGSize(width: 64, height: 64))
			localSongCoverImageBackView.image = mediaItem.artwork?.image(at: CGSize(width: 64, height: 64))
            uiTitle.text = songTitle
            uiSecondLine.text = songArtist + " – " + songAlbum
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

