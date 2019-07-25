//
//  AppDelegate.swift
//  Music Sync Server
//
//  Created by Никита Широков on 30/10/2017.
//  Copyright © 2017 Ink Studios. All rights reserved.
//

import Cocoa
import Swifter
import Foundation

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
	struct Song: Codable {
		var artist: String
		var title: String
	}
	
    func getQueryParamDictionary(queryParams: [(String, String)]) -> [String : String] {
        var res: [String : String] = [:]
        for item in queryParams {
            res["\(item.0)"] = "\(item.1)"
        }
        return res
    }
    
    func handleSetSong(request: HttpRequest) -> HttpResponse {
        
        let params = self.getQueryParamDictionary(queryParams: request.queryParams)
        let songArtist: String = params["artist"] ?? ""
        let songTitle: String = params["title"] ?? ""
        let songTime: String = params["time"] ?? ""
        
        let script = """
        
        tell application "iTunes"
            activate
            set results to (every file track of playlist "Library" whose name contains "\(songTitle)" and artist contains "\(songArtist)")
            repeat with t in results
                play t
                set player position to \(songTime)
            end repeat
        end tell
        
        """
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            if let output: NSAppleEventDescriptor = scriptObject.executeAndReturnError(&error) {
                print(output.stringValue ?? "")
            } else {
                print("error: \(error)")
            }
        }
        
        return .ok(.html("song set!"))
    }
    
    func handleStatus(request: HttpRequest) -> HttpResponse {
        
        let script = """
        
        tell application "iTunes"
        	if player state is not stopped then
        		set myTrack to current track
        		set songName to name of myTrack
        		set songArtist to artist of myTrack
        		return songArtist & "—" & songName
        	end if
        end tell
        
        """
		
		var currentSong: Song = Song(artist: "", title: "")
		
		var error: NSDictionary?
		if let scriptObject = NSAppleScript(source: script) {
			if let output: NSAppleEventDescriptor = scriptObject.executeAndReturnError(&error) {
				let arr = (output.stringValue ?? " — ").split("—")
				currentSong.artist = arr[0]
				currentSong.title = arr[1]
				print("\(currentSong.artist) – \(currentSong.title)")
			} else {
				print("error: \(error)")
			}
		}
		var json: Data = Data()
		do {
			try json = JSONEncoder().encode(currentSong)
		} catch {
			print("Error encoding song object to JSON.")
		}
		print(json.base64EncodedString())
		return .ok(.text(json.base64EncodedString()))
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            let server = HttpServer()
                server["/song"] = handleSetSong
                server["/status"] = handleStatus
            
            try server.start(9696, forceIPv4: true)
            
            print("Server has started on port: \(try server.port()). Try to connect now...")
            RunLoop.main.run()
            
        } catch {
            print("Server start error: \(error)")
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

}

