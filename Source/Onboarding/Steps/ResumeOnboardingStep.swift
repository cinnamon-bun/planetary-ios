//
//  ResumeOnboardingStep.swift
//  Planetary
//
//  Created by Christoph on 11/15/19.
//  Copyright © 2019 Verse Communications Inc. All rights reserved.
//

import Foundation
import UIKit

class ResumeOnboardingStep: OnboardingStep {

    init() {
        super.init(.resume)
    }

    override func customizeView() {
        self.view.primaryButton.isHidden = true
    }

    override func didStart() {

        self.view.lookBusy(after: 0)

        // SIMULATE ONBOARDING
        if self.data.simulated {
            self.scheduledNext()
            return
        }

        Onboarding.resume() {
            [weak self] context, error in
            if Log.optional(error) { self?.alert(); return }
            self?.data.context = context
            self?.scheduledNext()
        }
    }

    private func scheduledNext() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.view.lookReady()
            self.next();
        }
    }

    private func alert() {

        // this will try Onboarding.start() again, creating a new
        // configuration and such
        let tryAgain = UIAlertAction(title: Text.tryAgain.text,
                                     style: .default)
        {
            [weak self] action in
            self?.didStart()
        }

        AppController.shared.choose(from: [tryAgain],
                                    style: .alert,
                                    title: Text.Onboarding.somethingWentWrong.text,
                                    message: Text.Onboarding.resumeRetryMessage.text)
    }
}
