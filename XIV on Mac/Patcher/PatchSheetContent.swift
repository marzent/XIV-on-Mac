//
//  PatchingSheetContent.swift
//  XIV on Mac
//
//  Created by Chris Backas on 1/22/23.
//

import SwiftUI

struct PatchingSheetContent: View
{
    @EnvironmentObject var patchController : PatchController
   
    var body: some View
    {
        VStack
        {
            HStack
            {
                Button("BUTTON_QUIT")
                {
                    Util.quit()
                }
                Spacer()
            }
            Group
            {
                Text("PATCH_SHEET_DOWNLOADING_HEADER")
                    .font(Font.title)
                ProgressView("", value: patchController.downloadProgress, total: patchController.downloadProgressMax)
                Text(patchController.downloadStatus)
                Text(patchController.downloadPatch)
                ProgressView("", value: patchController.patchProgress, total: patchController.patchProgressMax)
                Text(patchController.downloadPatchStatus)
            }
            Divider()
            Group
            {
                Text("PATCH_SHEET_INSTALLING_HEADER")
                    .font(Font.title)
                ProgressView("", value: patchController.installProgress, total: patchController.installProgressMax)
                Text(patchController.installStatus)
            }
            Spacer()
            
        }
        .frame(minWidth: 563, minHeight: 306)
        .padding()
        
    }
}

struct PatchingSheetContent_Previews: PreviewProvider
{
    static var previews: some View
    {
        PatchingSheetContent()
            .environmentObject(PatchController())
    }
}

