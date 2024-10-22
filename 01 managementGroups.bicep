targetScope = 'tenant'

// https://github.com/Azure/ALZ-Bicep/tree/main/infra-as-code/bicep/modules/managementGroups

//---------------------------------------------------------
// Resources
//---------------------------------------------------------

module resourceGroup_module './infra-as-code/bicep/modules/managementGroups/managementGroups.bicep' = {
  name: 'baseline managementGroups'
  params: {
    parTopLevelManagementGroupParentId: '41190772-6d43-43bd-becb-8ec5529d2492'
    parLandingZoneMgChildren: {
      'sandbox': {
        displayName: 'Sandbox'
        // children: {
        //   'mg-operations': {
        //     displayName: 'Operations'
        //   }
        // }
      }
    }
    parPlatformMgChildren: {
      security: {
        displayName: 'Security'
      }
    }
    parTopLevelManagementGroupPrefix: 'alz'
    parTopLevelManagementGroupDisplayName: 'Super Landing Zones'
    parLandingZoneMgAlzDefaultsEnable: true // Deploys following child Landing Zone Management groups if set to true: Corp, Online
    parPlatformMgAlzDefaultsEnable: true // Deploys following child Platform Management groups if set to true: Management, Connectivity, Identity
    parLandingZoneMgConfidentialEnable: false
    parTelemetryOptOut: false
  }
}
