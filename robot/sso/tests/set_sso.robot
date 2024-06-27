*** Settings ***

Resource    cumulusci/robotframework/Salesforce.robot
Library     cumulusci.robotframework.PageObjects

Suite Setup    Run keywords
...  Get URLs for switching
...  AND  Open test browser  wait=False
Suite Teardown  Close Browser
Force tags      forms

*** Variables ***

${saveLocator}                       id=BrandSetup:brandSetupForm:settingsDetail:editButtons:Save
${thePagebrandingDetailFormLocator}  id=thePage:brandingDetailForm:BrandingDetail:brandingDetailButtons:Edit

*** Keywords *** 

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

*** Test Cases ***

Via UI
    [Documentation]  Set SSO
    Switch to classic
    Go to MyDomainSettingsEdit
    Input form data  Certificate  checked
    Click Save
    Wait until keyword succeeds  5 seconds  2 seconds
    ...  Location should contain  /domainname/DomainName.apexp


