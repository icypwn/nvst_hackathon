//
//  ShieldConfigurationExtension.swift
//  nvstShieldConfig
//
//  Created by Ethan Harbinger on 3/7/26.
//

import ManagedSettings
import ManagedSettingsUI
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        let appName = application.localizedDisplayName ?? "this app"

        return ShieldConfiguration(
            backgroundBlurStyle: .systemThickMaterialDark,
            backgroundColor: UIColor.black.withAlphaComponent(0.85),
            title: ShieldConfiguration.Label(
                text: "Time to Invest!",
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: "You need to invest screen time to use \(appName).",
                color: .lightGray
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Request Time",
                color: .white
            ),
            primaryButtonBackgroundColor: UIColor.systemGreen,
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Not Now",
                color: .lightGray
            )
        )
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        configuration(shielding: application)
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemThickMaterialDark,
            backgroundColor: UIColor.black.withAlphaComponent(0.85),
            title: ShieldConfiguration.Label(
                text: "Time to Invest!",
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: "You need to invest screen time to use this site.",
                color: .lightGray
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Request Time",
                color: .white
            ),
            primaryButtonBackgroundColor: UIColor.systemGreen,
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Not Now",
                color: .lightGray
            )
        )
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        configuration(shielding: webDomain)
    }
}
