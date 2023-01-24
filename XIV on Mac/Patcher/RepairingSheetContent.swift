//
//  RepairingSheetContent.swift
//  XIV on Mac
//
//  Created by Chris Backas on 1/23/23.
//

import SwiftUI

struct RepairingSheetContent: View
{
    @EnvironmentObject var repairController: RepairController
   
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
                Text("REPAIR_SHEET_HEADER")
                    .font(Font.title)
                ProgressView("", value: repairController.repairProgress, total: repairController.repairProgressMax)
                Text(repairController.repairStatus)
                Text(repairController.currentFile)
            }
            Spacer()
            
        }
        .frame(minWidth: 563, minHeight: 306)
        .padding()
        
    }
}

struct RepairingSheetContent_Previews: PreviewProvider
{
    static var previews: some View
    {
        RepairingSheetContent()
            .environmentObject(RepairController())
    }
}

