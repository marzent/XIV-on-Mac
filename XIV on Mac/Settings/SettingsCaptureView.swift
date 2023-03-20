//
//  SettingsCaptureView.swift
//  XIV on Mac
//
//  Created by Chris Backas on 3/19/23.
//

import SwiftUI
import KeyboardShortcuts

struct SettingsCaptureView: View {
    
    @AppStorage(ScreenCaptureHelper.captureFolderPref, store: .standard) var captureFolder : String = (FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask)[0] as NSURL).path ?? ""
    @AppStorage(ScreenCaptureHelper.videoCodecPref, store: .standard) var codecType : ScreenCaptureCodec = .h264

    var body: some View {
        VStack {
            HStack {
                Text("SETTINGS_CAPTURE_PERMISSIONS_CHECK")
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack {
                Button("SETTINGS_CAPTURE_PERMISSIONS_CHECK_BUTTON"){
                    if #available(macOS 13.0, *) {
                        ScreenCapture.checkCapturePermissions()
                    }
                }.fixedSize()
                Spacer()
            }
            HStack
            {
                Text("CAPTURE_FOLDER_LABEL")
                Text(captureFolder)
                    .frame(minWidth: 200)
                Spacer()
                Button("CAPTURE_FOLDER_SELECT_BUTTON")
                {
                    ScreenCaptureHelper.chooseFolder()
                }
            }

            HStack {
                KeyboardShortcuts.Recorder(NSLocalizedString("SETTINGS_TOGGLE_SCREEN_RECORDING",comment: ""), name: .toggleVideoCapture)
                Spacer()
            }
            
            HStack {
                Picker(selection: $codecType, label: Text("SETTINGS_CAPTURE_CODEC")) {
                    Text("SETTINGS_CAPTURE_CODEC_H264").tag(ScreenCaptureCodec.h264)
                    Text("SETTINGS_CAPTURE_CODEC_HEVC").tag(ScreenCaptureCodec.hevc)
                }.pickerStyle(RadioGroupPickerStyle())
                Spacer()
            }

            Spacer()
        }.padding()
    }
}

struct SettingsCaptureView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsCaptureView()
    }
}
