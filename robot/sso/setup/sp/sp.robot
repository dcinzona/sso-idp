*** Settings ***

Resource    cumulusci/robotframework/Salesforce.robot
Resource    robot/sso/resources/sso.robot

Suite Setup    Run keywords
...  Get LightningExperienceTheme  name=SpBrand
...  AND    Open test browser  wait=False
Suite Teardown  Close Browser

*** Test Cases ***

Set Up Branding
    [Documentation]  Set SP Branding Set
    Should Be Equal  ${THEME}[DeveloperName]  SpBrand
    Go to ThemeSettings
    Wait for aura
    Wait until keyword succeeds  5 seconds  2 seconds
    ...     Go to ThemeSettingsHome

Set Up SSO Provider
    [Documentation]  Set SSO
    Get urls for switching
    Switch to classic
    Go to MyDomainSettingsEdit
    Input form data   Scratch Org IDP  checked
    Click Save
    Wait until keyword succeeds  5 seconds  2 seconds
    ...  Location should contain  /domainname/DomainName.apexp
    Switch to lightning