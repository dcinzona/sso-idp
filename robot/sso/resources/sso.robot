*** Settings ***

Resource    cumulusci/robotframework/Salesforce.robot
Library     cumulusci.robotframework.PageObjects
...  robot/sso/resources/BrandingManagerPageObject.py

*** Variables ***

${saveLocator}                       id=BrandSetup:brandSetupForm:settingsDetail:editButtons:Save
${thePagebrandingDetailFormLocator}  id=thePage:brandingDetailForm:BrandingDetail:brandingDetailButtons:Edit

*** Keywords *** 

Get LightningExperienceTheme
    [Arguments]  &{brand}    
    @{records} =  Salesforce Query  LightningExperienceTheme
    ...              select=Id,DeveloperName
    ...              where=DeveloperName='${brand}[name]'
    ${THEME} =  Get From List  ${records}  0
    Set suite variable  ${THEME}

Go to ThemeSettings
    [Documentation]
    ...  Go directly to the LightningExperienceTheme Settings Page
    Go to page      BrandingManager     ${THEME}[Id]

Go to ThemeSettingsHome
    [Documentation]
    ...  Go directly to the LightningExperienceTheme Settings Page
    Go to page      BrandingManager     home

Switch to classic
    Go to  ${switcher classic url}
    Wait for aura

Switch to lightning
    ${org info}=  Get org info
    Go to  ${switcher lex url}
    Wait for aura

Get urls for switching
    ${org info}=  Get org info
    set suite variable  ${switcher lex url}
    ...  ${org info['instance_url']}/ltng/switcher?destination=lex
    set suite variable  ${switcher classic url}
    ...  ${org info['instance_url']}/ltng/switcher?destination=classic
 
Click Save
    [Documentation]  Click on the Save INPUT element
    Click Element  ${saveLocator}  
    Wait for aura

Go to MyDomainSettingsEdit
    [Documentation]
    ...  Go directly to the My Domain Settings Page

    &{org}=  Get org info
    ${url}=  Set variable
    ...  ${org['instance_url']}/domainname/EditLogin.apexp?isdtp=p1
    Go to  ${url}