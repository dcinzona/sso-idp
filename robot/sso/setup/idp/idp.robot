*** Settings ***

Resource    cumulusci/robotframework/Salesforce.robot
Resource    robot/sso/resources/sso.robot

Suite Setup    Run keywords   
...     Get LightningExperienceTheme  name=IdpBrand
...     AND    Open test browser  wait=False
Suite Teardown  Close Browser

*** Test Cases ***

Via API
    [Documentation]  Get IdP Branding Set
    Should Be Equal  ${THEME}[DeveloperName]  IdpBrand

Via UI
    [Documentation]  Set IdP Branding Set
    Go to ThemeSettings
    Wait for aura
    Wait until keyword succeeds  5 seconds  2 seconds
    ...     Go to ThemeSettingsHome
    